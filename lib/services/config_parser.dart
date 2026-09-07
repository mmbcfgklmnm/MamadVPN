import 'dart:convert';
import '../models/server_node.dart';
import '../models/app_settings.dart';

class ConfigParser {
  /// Parse multiple configs, base64 subscription text, Clash YAML, or Sing-box JSON
  static List<ServerNode> parseMultiple(String content, {String? subscriptionId}) {
    final List<ServerNode> nodes = [];
    if (content.trim().isEmpty) return nodes;

    String text = content.trim();

    // 1. Check if the payload is base64 encoded
    // Strip BOM and non-printable characters
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }

    if (!text.contains('://') && !text.contains('proxies:') && !text.contains('"outbounds"')) {
      final decoded = _tryBase64Decode(text);
      if (decoded != text && (decoded.contains('://') || decoded.contains('proxies:') || decoded.contains('"outbounds"'))) {
        text = decoded;
      }
    }

    // 2. Check for Sing-box JSON format
    if (text.trim().startsWith('{') && text.contains('"outbounds"')) {
      final jsonNodes = _parseSingBoxJson(text, subscriptionId);
      if (jsonNodes.isNotEmpty) return jsonNodes;
    }

    // 3. Check for Clash YAML format
    if (text.contains('proxies:')) {
      final clashNodes = _parseClashYaml(text, subscriptionId);
      if (clashNodes.isNotEmpty) return clashNodes;
    }

    // 4. Line by line standard URI parser
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // In case individual lines are base64 encoded
      if (!line.contains('://') && line.length > 20) {
        final decodedLine = _tryBase64Decode(line);
        if (decodedLine.contains('://')) {
          line = decodedLine;
        }
      }

      final node = parseSingle(line, subscriptionId: subscriptionId);
      if (node != null) {
        nodes.add(node);
      }
    }

    return nodes;
  }

  /// Parse a single config URI
  static ServerNode? parseSingle(String uriStr, {String? subscriptionId}) {
    final trimmed = uriStr.trim();
    if (trimmed.startsWith('vless://')) {
      return _parseVless(trimmed, subscriptionId);
    } else if (trimmed.startsWith('vmess://')) {
      return _parseVmess(trimmed, subscriptionId);
    } else if (trimmed.startsWith('trojan://')) {
      return _parseTrojan(trimmed, subscriptionId);
    } else if (trimmed.startsWith('ss://')) {
      return _parseShadowsocks(trimmed, subscriptionId);
    } else if (trimmed.startsWith('hysteria2://') || trimmed.startsWith('hy2://')) {
      return _parseHysteria2(trimmed, subscriptionId);
    } else if (trimmed.startsWith('wireguard://') || trimmed.startsWith('wg://')) {
      return _parseWireguard(trimmed, subscriptionId);
    }
    return null;
  }

  // -------------------------------------------------------------
  // VLESS Parser
  // -------------------------------------------------------------
  static ServerNode? _parseVless(String uriStr, String? subscriptionId) {
    try {
      final uri = Uri.parse(uriStr);
      final uuid = uri.userInfo;
      final host = uri.host;
      final port = uri.port;
      final name = uri.fragment.isNotEmpty ? Uri.decodeComponent(uri.fragment) : 'VLESS $host';
      final params = uri.queryParameters;

      return ServerNode(
        id: 'vless_${uuid}_${host}_$port',
        name: name,
        protocol: 'vless',
        address: host,
        port: port,
        uuid: uuid,
        network: params['type'] ?? 'tcp',
        security: params['security'] ?? 'none',
        sni: params['sni'] ?? params['host'] ?? '',
        path: params['path'] != null ? Uri.decodeComponent(params['path']!) : '',
        flow: params['flow'] ?? '',
        publicKey: params['pbk'] ?? '',
        shortId: params['sid'] ?? '',
        fingerprint: params['fp'] ?? 'chrome',
        alpn: params['alpn']?.split(',') ?? [],
        subscriptionId: subscriptionId,
        rawUri: uriStr,
      );
    } catch (e) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // VMess Parser
  // -------------------------------------------------------------
  static ServerNode? _parseVmess(String uriStr, String? subscriptionId) {
    try {
      final raw = uriStr.substring('vmess://'.length).trim();
      final decodedJson = _tryBase64Decode(raw);
      final Map<String, dynamic> json = jsonDecode(decodedJson);

      final address = json['add']?.toString() ?? '';
      final port = int.tryParse(json['port']?.toString() ?? '') ?? 443;
      final uuid = json['id']?.toString() ?? '';
      final name = json['ps']?.toString() ?? 'VMess $address';

      return ServerNode(
        id: 'vmess_${uuid}_${address}_$port',
        name: name,
        protocol: 'vmess',
        address: address,
        port: port,
        uuid: uuid,
        encryption: json['scy']?.toString() ?? 'auto',
        network: json['net']?.toString() ?? 'tcp',
        security: (json['tls'] == 'tls') ? 'tls' : 'none',
        sni: json['sni']?.toString() ?? json['host']?.toString() ?? '',
        path: json['path']?.toString() ?? '',
        subscriptionId: subscriptionId,
        rawUri: uriStr,
      );
    } catch (e) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // Trojan Parser
  // -------------------------------------------------------------
  static ServerNode? _parseTrojan(String uriStr, String? subscriptionId) {
    try {
      final uri = Uri.parse(uriStr);
      final password = uri.userInfo;
      final host = uri.host;
      final port = uri.port;
      final name = uri.fragment.isNotEmpty ? Uri.decodeComponent(uri.fragment) : 'Trojan $host';
      final params = uri.queryParameters;

      return ServerNode(
        id: 'trojan_${host}_$port',
        name: name,
        protocol: 'trojan',
        address: host,
        port: port,
        uuid: password,
        network: params['type'] ?? 'tcp',
        security: params['security'] ?? 'tls',
        sni: params['sni'] ?? '',
        path: params['path'] != null ? Uri.decodeComponent(params['path']!) : '',
        alpn: params['alpn']?.split(',') ?? [],
        subscriptionId: subscriptionId,
        rawUri: uriStr,
      );
    } catch (e) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // Shadowsocks Parser (SIP002 & legacy)
  // -------------------------------------------------------------
  static ServerNode? _parseShadowsocks(String uriStr, String? subscriptionId) {
    try {
      final uri = Uri.parse(uriStr);
      final name = uri.fragment.isNotEmpty ? Uri.decodeComponent(uri.fragment) : 'Shadowsocks';

      String host = uri.host;
      int port = uri.port;
      String method = 'chacha20-ietf-poly1305';
      String password = '';

      if (uri.userInfo.isNotEmpty) {
        final decodedUserInfo = _tryBase64Decode(uri.userInfo);
        if (decodedUserInfo.contains(':')) {
          final parts = decodedUserInfo.split(':');
          method = parts[0];
          password = parts.sublist(1).join(':');
        } else {
          password = uri.userInfo;
        }
      } else {
        final rawAuthority = uriStr.substring(5).split('#').first;
        final decoded = _tryBase64Decode(rawAuthority);
        if (decoded.contains('@')) {
          final parts = decoded.split('@');
          final userinfo = parts[0].split(':');
          method = userinfo[0];
          password = userinfo.sublist(1).join(':');

          final hostPort = parts[1].split(':');
          host = hostPort[0];
          port = int.tryParse(hostPort[1]) ?? 8388;
        }
      }

      return ServerNode(
        id: 'ss_${host}_$port',
        name: name,
        protocol: 'shadowsocks',
        address: host,
        port: port,
        uuid: password,
        encryption: method,
        subscriptionId: subscriptionId,
        rawUri: uriStr,
      );
    } catch (e) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // Hysteria 2 Parser
  // -------------------------------------------------------------
  static ServerNode? _parseHysteria2(String uriStr, String? subscriptionId) {
    try {
      final uri = Uri.parse(uriStr);
      final password = uri.userInfo;
      final host = uri.host;
      final port = uri.port;
      final name = uri.fragment.isNotEmpty ? Uri.decodeComponent(uri.fragment) : 'Hysteria2 $host';
      final params = uri.queryParameters;

      return ServerNode(
        id: 'hy2_${host}_$port',
        name: name,
        protocol: 'hysteria2',
        address: host,
        port: port,
        uuid: password,
        security: 'tls',
        sni: params['sni'] ?? host,
        subscriptionId: subscriptionId,
        rawUri: uriStr,
      );
    } catch (e) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // WireGuard Parser
  // -------------------------------------------------------------
  static ServerNode? _parseWireguard(String uriStr, String? subscriptionId) {
    try {
      final uri = Uri.parse(uriStr);
      final privateKey = uri.userInfo;
      final host = uri.host;
      final port = uri.port;
      final name = uri.fragment.isNotEmpty ? Uri.decodeComponent(uri.fragment) : 'WireGuard $host';
      final params = uri.queryParameters;

      return ServerNode(
        id: 'wg_${host}_$port',
        name: name,
        protocol: 'wireguard',
        address: host,
        port: port,
        uuid: privateKey,
        publicKey: params['public_key'] ?? '',
        subscriptionId: subscriptionId,
        rawUri: uriStr,
      );
    } catch (e) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // Clash YAML Parser (Proxies list)
  // -------------------------------------------------------------
  static List<ServerNode> _parseClashYaml(String yamlText, String? subscriptionId) {
    final List<ServerNode> nodes = [];
    try {
      final lines = yamlText.split(RegExp(r'[\r\n]+'));
      bool inProxies = false;
      Map<String, String> currentProxy = {};

      void commitProxy() {
        if (currentProxy.isEmpty) return;
        final name = currentProxy['name'] ?? 'Clash Node';
        final type = (currentProxy['type'] ?? 'vless').toLowerCase();
        final server = currentProxy['server'] ?? '';
        final port = int.tryParse(currentProxy['port'] ?? '') ?? 443;
        final uuid = currentProxy['uuid'] ?? currentProxy['password'] ?? '';

        if (server.isNotEmpty) {
          nodes.add(ServerNode(
            id: 'clash_${type}_${server}_$port',
            name: name,
            protocol: type,
            address: server,
            port: port,
            uuid: uuid,
            network: currentProxy['network'] ?? 'tcp',
            security: (currentProxy['tls'] == 'true' || currentProxy['tls'] == '1') ? 'tls' : 'none',
            sni: currentProxy['servername'] ?? currentProxy['sni'] ?? '',
            path: currentProxy['ws-path'] ?? currentProxy['path'] ?? '',
            flow: currentProxy['flow'] ?? '',
            subscriptionId: subscriptionId,
          ));
        }
        currentProxy = {};
      }

      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('proxies:')) {
          inProxies = true;
          continue;
        }
        if (inProxies) {
          if (!line.startsWith(' ') && !line.startsWith('\t') && trimmed.endsWith(':')) {
            // Reached another top-level section (e.g. proxy-groups:, rules:)
            commitProxy();
            break;
          }

          if (trimmed.startsWith('- name:')) {
            commitProxy();
            final nameVal = trimmed.substring('- name:'.length).trim().replaceAll(RegExp(r'^["\x27]|["\x27]$'), '');
            currentProxy['name'] = nameVal;
          } else if (trimmed.startsWith('name:')) {
            final nameVal = trimmed.substring('name:'.length).trim().replaceAll(RegExp(r'^["\x27]|["\x27]$'), '');
            currentProxy['name'] = nameVal;
          } else if (trimmed.contains(':')) {
            final parts = trimmed.split(':');
            final k = parts[0].trim().replaceAll(RegExp(r'^-\s*'), '');
            final v = parts.sublist(1).join(':').trim().replaceAll(RegExp(r'^["\x27]|["\x27]$'), '');
            currentProxy[k] = v;
          }
        }
      }
      commitProxy();
    } catch (_) {}
    return nodes;
  }

  // -------------------------------------------------------------
  // Sing-Box JSON Parser (Outbounds list)
  // -------------------------------------------------------------
  static List<ServerNode> _parseSingBoxJson(String jsonText, String? subscriptionId) {
    final List<ServerNode> nodes = [];
    try {
      final Map<String, dynamic> data = jsonDecode(jsonText);
      final List<dynamic>? outbounds = data['outbounds'];
      if (outbounds != null) {
        for (final item in outbounds) {
          if (item is Map<String, dynamic>) {
            final type = item['type']?.toString().toLowerCase() ?? '';
            if (['vless', 'vmess', 'trojan', 'shadowsocks', 'hysteria2'].contains(type)) {
              final tag = item['tag']?.toString() ?? 'SingBox Node';
              final server = item['server']?.toString() ?? '';
              final port = int.tryParse(item['server_port']?.toString() ?? '') ?? 443;
              final uuid = item['uuid']?.toString() ?? item['password']?.toString() ?? '';

              if (server.isNotEmpty) {
                nodes.add(ServerNode(
                  id: 'singbox_${type}_${server}_$port',
                  name: tag,
                  protocol: type,
                  address: server,
                  port: port,
                  uuid: uuid,
                  subscriptionId: subscriptionId,
                ));
              }
            }
          }
        }
      }
    } catch (_) {}
    return nodes;
  }

  // Safe Base64 decoding with whitespace stripping and padding normalization
  static String _tryBase64Decode(String input) {
    try {
      // Remove all spaces, newlines, and carriage returns
      var clean = input.replaceAll(RegExp(r'\s+'), '');
      var normalized = clean.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      return utf8.decode(base64Decode(normalized));
    } catch (e) {
      return input;
    }
  }

  /// Builds a full Sing-Box or Xray runtime configuration JSON with Clash API enabled for live traffic monitoring
  static String generateSingBoxConfig(ServerNode node, AppSettings settings) {
    final Map<String, dynamic> config = {
      'log': {'level': 'info', 'timestamp': true},
      // Clash API enables authentic real-time traffic statistics at 127.0.0.1:9090
      'experimental': {
        'clash_api': {
          'external_controller': '127.0.0.1:9090',
          'external_ui': '',
          'secret': '',
        }
      },
      'dns': {
        'servers': [
          {
            'tag': 'dns-remote',
            'address': settings.dnsServer,
            'detour': 'proxy',
          },
          {
            'tag': 'dns-local',
            'address': 'local',
            'detour': 'direct',
          }
        ],
        'rules': [
          {'outbound': 'any', 'server': 'dns-local'},
        ]
      },
      'inbounds': [
        // Mixed HTTP / SOCKS proxy inbound on 127.0.0.1:20808
        {
          'type': 'mixed',
          'tag': 'mixed-in',
          'listen': '127.0.0.1',
          'listen_port': settings.mixedPort,
          'sniff': true,
        },
        // Virtual TUN interface inbound (if in TUN mode)
        if (settings.coreMode == CoreMode.tun)
          {
            'type': 'tun',
            'tag': 'tun-in',
            'interface_name': 'mamadvpn-tun',
            'inet4_address': '172.19.0.1/30',
            'auto_route': true,
            'strict_route': true,
            'stack': 'system',
            'sniff': true,
            'mtu': settings.mtu,
          }
      ],
      'outbounds': [
        node.toSingBoxOutbound(),
        {
          'type': 'direct',
          'tag': 'direct',
        },
        {
          'type': 'block',
          'tag': 'block',
        }
      ],
      'route': {
        'auto_detect_interface': true,
        'rules': [
          {'protocol': 'dns', 'outbound': 'dns-remote'},
          if (settings.routingMode == RoutingMode.bypassLanAndIran) ...[
            {'geoip': 'private', 'outbound': 'direct'},
            {'geoip': 'ir', 'outbound': 'direct'},
            {'geosite': 'ir', 'outbound': 'direct'},
            {'geosite': 'category-ads-all', 'outbound': 'block'},
          ],
          {'outbound': 'proxy'},
        ]
      }
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }
}
