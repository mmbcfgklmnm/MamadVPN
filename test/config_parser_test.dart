import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadvpn/models/app_settings.dart';
import 'package:mamadvpn/services/config_parser.dart';

void main() {
  group('ConfigParser Tests', () {
    test('Parse VLESS Reality URI', () {
      const uri = 'vless://uuid123@example.com:443?security=reality&sni=speedtest.net&type=tcp&flow=xtls-rprx-vision&pbk=pubkey123#Frankfurt';
      final node = ConfigParser.parseSingle(uri);

      expect(node, isNotNull);
      expect(node!.protocol, 'vless');
      expect(node.address, 'example.com');
      expect(node.port, 443);
      expect(node.uuid, 'uuid123');
      expect(node.security, 'reality');
      expect(node.sni, 'speedtest.net');
      expect(node.publicKey, 'pubkey123');
      expect(node.name, 'Frankfurt');
    });

    test('Parse VMess Base64 URI', () {
      final jsonPayload = {
        "v": "2",
        "ps": "Amsterdam",
        "add": "ams.example.com",
        "port": 443,
        "id": "vmess-uuid-456",
        "aid": 0,
        "net": "ws",
        "type": "none",
        "host": "ams.example.com",
        "path": "/ws",
        "tls": "tls"
      };
      final base64Payload = base64Encode(utf8.encode(jsonEncode(jsonPayload)));
      final uri = 'vmess://$base64Payload';

      final node = ConfigParser.parseSingle(uri);
      expect(node, isNotNull);
      expect(node!.protocol, 'vmess');
      expect(node.name, 'Amsterdam');
      expect(node.address, 'ams.example.com');
      expect(node.port, 443);
      expect(node.uuid, 'vmess-uuid-456');
      expect(node.network, 'ws');
      expect(node.security, 'tls');
      expect(node.path, '/ws');
    });

    test('Parse Trojan URI', () {
      const uri = 'trojan://trojanPass@trojan.example.com:443?sni=trojan.example.com#Istanbul';
      final node = ConfigParser.parseSingle(uri);

      expect(node, isNotNull);
      expect(node!.protocol, 'trojan');
      expect(node.address, 'trojan.example.com');
      expect(node.uuid, 'trojanPass');
      expect(node.name, 'Istanbul');
    });

    test('Parse Hysteria2 URI', () {
      const uri = 'hysteria2://hy2Pass@hy2.example.com:8443?sni=apple.com#NewYork';
      final node = ConfigParser.parseSingle(uri);

      expect(node, isNotNull);
      expect(node!.protocol, 'hysteria2');
      expect(node.address, 'hy2.example.com');
      expect(node.port, 8443);
      expect(node.uuid, 'hy2Pass');
      expect(node.name, 'NewYork');
    });

    test('Parse multiline Base64 encoded subscription', () {
      const plainList = '''vless://u1@fra.com:443#DE-Node
vmess://base64payload
trojan://pass1@ams.com:443#NL-Node''';

      // Base64 encode with newlines embedded (standard v2ray base64)
      final rawBase64 = base64Encode(utf8.encode(plainList));
      final multilineBase64 = '${rawBase64.substring(0, 20)}\r\n${rawBase64.substring(20)}';

      final nodes = ConfigParser.parseMultiple(multilineBase64);
      expect(nodes.length, greaterThanOrEqualTo(2));
      expect(nodes.any((n) => n.name == 'DE-Node'), isTrue);
      expect(nodes.any((n) => n.name == 'NL-Node'), isTrue);
    });

    test('Parse Clash YAML proxies format', () {
      const clashYaml = '''
proxies:
  - name: "Clash German VLESS"
    type: vless
    server: de.example.com
    port: 443
    uuid: 1234-5678
    tls: true
    servername: de.example.com
  - name: "Clash Trojan"
    type: trojan
    server: tr.example.com
    port: 443
    password: mypassword
''';
      final nodes = ConfigParser.parseMultiple(clashYaml);
      expect(nodes.length, 2);
      expect(nodes[0].name, 'Clash German VLESS');
      expect(nodes[0].protocol, 'vless');
      expect(nodes[0].address, 'de.example.com');
      expect(nodes[1].name, 'Clash Trojan');
      expect(nodes[1].uuid, 'mypassword');
    });

    test('Parse Sing-Box JSON outbounds format', () {
      const singboxJson = '''
{
  "outbounds": [
    {
      "type": "vless",
      "tag": "SingBox VLESS Node",
      "server": "sb.example.com",
      "server_port": 443,
      "uuid": "uuid-sb-123"
    }
  ]
}
''';
      final nodes = ConfigParser.parseMultiple(singboxJson);
      expect(nodes.length, 1);
      expect(nodes[0].name, 'SingBox VLESS Node');
      expect(nodes[0].address, 'sb.example.com');
    });

    test('Generate Sing-Box configuration with Clash API enabled and valid routing', () {
      const uri = 'vless://uuid123@example.com:443?security=reality&sni=speedtest.net&type=tcp&flow=xtls-rprx-vision&pbk=pubkey123#Frankfurt';
      final node = ConfigParser.parseSingle(uri)!;
      const settings = AppSettings(
        routingMode: RoutingMode.bypassLanAndIran,
        coreMode: CoreMode.tun,
      );

      final configJson = ConfigParser.generateSingBoxConfig(node, settings);
      expect(configJson, contains('mamadvpn-tun'));
      expect(configJson, contains('clash_api'));
      expect(configJson, contains('127.0.0.1:9090'));
      expect(configJson, contains('speedtest.net'));
      expect(configJson, contains('pubkey123'));
      expect(configJson, contains('dns-out'));
      expect(configJson, contains('"final": "proxy"'));
    });

    test('Parse VLESS XHTTP URI and generate Xray configuration', () {
      const uri = 'vless://a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d@chatgpt.com:8080?security=none&type=xhttp&path=/stream#CDN%20CLOUDFLARE';
      final node = ConfigParser.parseSingle(uri);

      expect(node, isNotNull);
      expect(node!.protocol, 'vless');
      expect(node.address, 'chatgpt.com');
      expect(node.port, 8080);
      expect(node.network, 'xhttp');
      expect(node.path, '/stream');

      const settings = AppSettings(
        routingMode: RoutingMode.bypassLanAndIran,
        coreMode: CoreMode.systemProxy,
      );

      final xrayConfig = ConfigParser.generateXrayConfig(node, settings);
      expect(xrayConfig, contains('"network": "xhttp"'));
      expect(xrayConfig, contains('"path": "/stream"'));
      expect(xrayConfig, contains('StatsService'));
      expect(xrayConfig, contains('10085'));
    });

    test('Generate Android Xray configuration with SOCKS 10808, DNS hijacking, and sniffing', () {
      const uri = 'vless://uuid123@example.com:443?security=reality&sni=speedtest.net&type=tcp&flow=xtls-rprx-vision&pbk=pubkey123#Frankfurt';
      final node = ConfigParser.parseSingle(uri)!;
      const settings = AppSettings(
        routingMode: RoutingMode.bypassLanAndIran,
      );

      final androidConfig = ConfigParser.generateAndroidXrayConfig(node, settings);
      final Map<String, dynamic> json = jsonDecode(androidConfig);

      // Verify inbounds
      final inbounds = json['inbounds'] as List;
      final socksInbound = inbounds.firstWhere((i) => i['protocol'] == 'socks');
      expect(socksInbound['port'], 10808);
      expect(socksInbound['settings']['udp'], true);
      expect(socksInbound['sniffing']['enabled'], true);

      // Verify DNS
      expect(json['dns']['servers'], contains('1.1.1.1'));
      expect(json['dns']['servers'], contains('8.8.8.8'));

      // Verify outbounds
      final outbounds = json['outbounds'] as List;
      expect(outbounds.any((o) => o['tag'] == 'proxy'), true);
      expect(outbounds.any((o) => o['tag'] == 'dns-out'), true);

      // Verify routing
      final rules = json['routing']['rules'] as List;
      final dnsRule = rules.firstWhere((r) => r['outboundTag'] == 'dns-out');
      expect(dnsRule['port'], '53');
    });
  });
}

