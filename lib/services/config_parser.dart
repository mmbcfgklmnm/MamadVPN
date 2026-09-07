import 'dart:convert';
import '../models/server_node.dart';
import '../models/app_settings.dart';

class ConfigParser {
  /// Parse multiple configs or base64 subscription text
  static List<ServerNode> parseMultiple(String content, {String? subscriptionId}) {
    final List<ServerNode> nodes = [];
    if (content.trim().isEmpty) return nodes;

    String text = content.trim();

    // Check if the entire payload is base64 encoded (typical for v2ray subscriptions)
    if (!text.contains('\n') && !text.contains('://')) {
      try {
        final decoded = _tryBase64Decode(text);
        if (decoded.isNotEmpty) {
          text = decoded;
        }
      } catch (_) {}
    }

    final lines = text.split(RegExp(r'[\r\n]+'));
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

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
        // Entire authority might be base64 encoded
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

  // Helper for safe Base64 decoding with padding normalization
  static String _tryBase64Decode(String input) {
    try {
      var normalized = input.replaceAll('-', '+').replaceAll('_', '/').trim();
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      return utf8.decode(base64Decode(normalized));
    } catch (e) {
      return input;
    }
  }

  /// Builds a full Sing-Box or Xray runtime configuration JSON
  static String generateSingBoxConfig(ServerNode node, AppSettings settings) {
    final Map<String, dynamic> config = {
      'log': {'level': 'info', 'timestamp': true},
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
        // Mixed HTTP / SOCKS proxy inbound
        {
          'type': 'mixed',
          'tag': 'mixed-in',
          'listen': '127.0.0.1',
          'listen_port': settings.mixedPort,
          'sniff': true,
        },
        // Virtual TUN interface inbound
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
