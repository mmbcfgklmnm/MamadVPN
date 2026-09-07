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

    test('Parse Multiple configs from multiline string', () {
      const multiline = '''
vless://u1@h1.com:443?security=none#Node1
trojan://p1@h2.com:443#Node2
      ''';
      final nodes = ConfigParser.parseMultiple(multiline);
      expect(nodes.length, 2);
      expect(nodes[0].name, 'Node1');
      expect(nodes[1].name, 'Node2');
    });

    test('Generate Sing-Box configuration', () {
      const uri = 'vless://uuid123@example.com:443?security=reality&sni=speedtest.net&type=tcp&flow=xtls-rprx-vision&pbk=pubkey123#Frankfurt';
      final node = ConfigParser.parseSingle(uri)!;
      const settings = AppSettings(
        routingMode: RoutingMode.bypassLanAndIran,
        coreMode: CoreMode.tun,
      );

      final configJson = ConfigParser.generateSingBoxConfig(node, settings);
      expect(configJson, contains('mamadvpn-tun'));
      expect(configJson, contains('speedtest.net'));
      expect(configJson, contains('pubkey123'));
    });
  });
}
