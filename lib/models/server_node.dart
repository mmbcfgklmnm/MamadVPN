import 'dart:convert';

class ServerNode {
  final String id;
  String name;
  final String protocol; // 'vless', 'vmess', 'trojan', 'shadowsocks', 'hysteria2', 'wireguard'
  final String address;
  final int port;
  final String uuid; // Password, UUID, or secret key
  final String encryption;
  final String network; // 'tcp', 'ws', 'grpc', 'quic', 'http'
  final String security; // 'none', 'tls', 'reality'
  final String sni;
  final String path;
  final String flow;
  final String publicKey;
  final String shortId;
  final String fingerprint;
  final List<String> alpn;
  final String? subscriptionId;
  int? ping; // in milliseconds, -1 means timeout, null means not tested
  DateTime? lastTested;
  final String rawUri;

  ServerNode({
    required this.id,
    required this.name,
    required this.protocol,
    required this.address,
    required this.port,
    required this.uuid,
    this.encryption = 'none',
    this.network = 'tcp',
    this.security = 'none',
    this.sni = '',
    this.path = '',
    this.flow = '',
    this.publicKey = '',
    this.shortId = '',
    this.fingerprint = 'chrome',
    this.alpn = const [],
    this.subscriptionId,
    this.ping,
    this.lastTested,
    this.rawUri = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'protocol': protocol,
      'address': address,
      'port': port,
      'uuid': uuid,
      'encryption': encryption,
      'network': network,
      'security': security,
      'sni': sni,
      'path': path,
      'flow': flow,
      'publicKey': publicKey,
      'shortId': shortId,
      'fingerprint': fingerprint,
      'alpn': alpn,
      'subscriptionId': subscriptionId,
      'ping': ping,
      'lastTested': lastTested?.toIso8601String(),
      'rawUri': rawUri,
    };
  }

  factory ServerNode.fromJson(Map<String, dynamic> json) {
    return ServerNode(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Node',
      protocol: (json['protocol'] ?? 'vless').toString().toLowerCase(),
      address: json['address'] ?? '',
      port: (json['port'] is int) ? json['port'] : int.tryParse(json['port'].toString()) ?? 443,
      uuid: json['uuid'] ?? '',
      encryption: json['encryption'] ?? 'none',
      network: json['network'] ?? 'tcp',
      security: json['security'] ?? 'none',
      sni: json['sni'] ?? '',
      path: json['path'] ?? '',
      flow: json['flow'] ?? '',
      publicKey: json['publicKey'] ?? '',
      shortId: json['shortId'] ?? '',
      fingerprint: json['fingerprint'] ?? 'chrome',
      alpn: (json['alpn'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      subscriptionId: json['subscriptionId'],
      ping: json['ping'] is int ? json['ping'] : int.tryParse(json['ping']?.toString() ?? ''),
      lastTested: json['lastTested'] != null ? DateTime.tryParse(json['lastTested']) : null,
      rawUri: json['rawUri'] ?? '',
    );
  }

  /// Generates a Sing-Box compatible outbound configuration object
  Map<String, dynamic> toSingBoxOutbound() {
    final Map<String, dynamic> outbound = {
      'tag': 'proxy',
      'type': protocol == 'hysteria2' ? 'hysteria2' : protocol,
      'server': address,
      'server_port': port,
    };

    if (protocol == 'vless') {
      outbound['uuid'] = uuid;
      if (flow.isNotEmpty) outbound['flow'] = flow;
    } else if (protocol == 'vmess') {
      outbound['uuid'] = uuid;
      outbound['security'] = encryption.isEmpty ? 'auto' : encryption;
      outbound['alter_id'] = 0;
    } else if (protocol == 'trojan') {
      outbound['password'] = uuid;
    } else if (protocol == 'shadowsocks') {
      outbound['method'] = encryption.isEmpty ? 'chacha20-ietf-poly1305' : encryption;
      outbound['password'] = uuid;
    } else if (protocol == 'hysteria2') {
      outbound['password'] = uuid;
    }

    // TLS / Reality
    if (security == 'tls' || security == 'reality') {
      final tls = <String, dynamic>{
        'enabled': true,
        'server_name': sni.isNotEmpty ? sni : address,
      };
      if (alpn.isNotEmpty) tls['alpn'] = alpn;
      if (fingerprint.isNotEmpty) {
        tls['utls'] = {'enabled': true, 'fingerprint': fingerprint};
      }
      if (security == 'reality') {
        tls['reality'] = {
          'enabled': true,
          'public_key': publicKey,
          'short_id': shortId,
        };
      }
      outbound['tls'] = tls;
    }

    // Transport (WebSocket / gRPC / HTTPUpgrade)
    if (network == 'ws') {
      outbound['transport'] = {
        'type': 'ws',
        'path': path.isEmpty ? '/' : path,
        if (sni.isNotEmpty) 'headers': {'Host': sni},
      };
    } else if (network == 'grpc') {
      outbound['transport'] = {
        'type': 'grpc',
        'service_name': path,
      };
    } else if (network == 'xhttp' || network == 'splithttp' || network == 'httpupgrade') {
      outbound['transport'] = {
        'type': 'httpupgrade',
        'path': path.isEmpty ? '/' : path,
        if (sni.isNotEmpty) 'host': sni,
      };
    }

    return outbound;
  }

  /// Generates an Xray-core compatible outbound configuration object
  Map<String, dynamic> toXrayOutbound() {
    final Map<String, dynamic> outbound = {
      'tag': 'proxy',
      'protocol': protocol == 'hysteria2' ? 'vless' : protocol,
    };

    if (protocol == 'vless') {
      outbound['settings'] = {
        'vnext': [
          {
            'address': address,
            'port': port,
            'users': [
              {
                'id': uuid,
                'encryption': encryption.isNotEmpty ? encryption : 'none',
                if (flow.isNotEmpty) 'flow': flow,
              }
            ]
          }
        ]
      };
    } else if (protocol == 'vmess') {
      outbound['settings'] = {
        'vnext': [
          {
            'address': address,
            'port': port,
            'users': [
              {
                'id': uuid,
                'alterId': 0,
                'security': encryption.isNotEmpty ? encryption : 'auto',
              }
            ]
          }
        ]
      };
    } else if (protocol == 'trojan') {
      outbound['settings'] = {
        'servers': [
          {
            'address': address,
            'port': port,
            'password': uuid,
          }
        ]
      };
    } else if (protocol == 'shadowsocks') {
      outbound['settings'] = {
        'servers': [
          {
            'address': address,
            'port': port,
            'method': encryption.isNotEmpty ? encryption : 'chacha20-ietf-poly1305',
            'password': uuid,
          }
        ]
      };
    }

    final streamSettings = <String, dynamic>{};

    // Transport
    final net = network.toLowerCase();
    if (net == 'xhttp' || net == 'splithttp') {
      streamSettings['network'] = 'xhttp';
      streamSettings['xhttpSettings'] = {
        'path': path.isNotEmpty ? path : '/',
        'host': sni.isNotEmpty ? sni : address,
        'mode': 'auto',
      };
    } else if (net == 'ws') {
      streamSettings['network'] = 'ws';
      streamSettings['wsSettings'] = {
        'path': path.isNotEmpty ? path : '/',
        'headers': {
          'Host': sni.isNotEmpty ? sni : address,
        }
      };
    } else if (net == 'grpc') {
      streamSettings['network'] = 'grpc';
      streamSettings['grpcSettings'] = {
        'serviceName': path,
        'multiMode': true,
      };
    } else if (net == 'httpupgrade') {
      streamSettings['network'] = 'httpupgrade';
      streamSettings['httpupgradeSettings'] = {
        'path': path.isNotEmpty ? path : '/',
        'host': sni.isNotEmpty ? sni : address,
      };
    } else {
      streamSettings['network'] = 'tcp';
    }

    // Security
    if (security == 'reality') {
      streamSettings['security'] = 'reality';
      streamSettings['realitySettings'] = {
        'show': false,
        'fingerprint': fingerprint.isNotEmpty ? fingerprint : 'chrome',
        'serverName': sni.isNotEmpty ? sni : address,
        'publicKey': publicKey,
        'shortId': shortId,
        'spiderX': '',
      };
    } else if (security == 'tls') {
      streamSettings['security'] = 'tls';
      streamSettings['tlsSettings'] = {
        'serverName': sni.isNotEmpty ? sni : address,
        'fingerprint': fingerprint.isNotEmpty ? fingerprint : 'chrome',
        if (alpn.isNotEmpty) 'alpn': alpn,
      };
    } else {
      streamSettings['security'] = 'none';
    }

    outbound['streamSettings'] = streamSettings;
    return outbound;
  }
}
