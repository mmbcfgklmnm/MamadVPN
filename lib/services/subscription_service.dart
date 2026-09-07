import 'dart:convert';
import 'dart:io';
import '../models/server_node.dart';
import '../models/subscription.dart';
import 'config_parser.dart';

class SubscriptionFetchResult {
  final Subscription subscription;
  final List<ServerNode> nodes;

  SubscriptionFetchResult({required this.subscription, required this.nodes});
}

class SubscriptionService {
  /// Fetch remote subscription with certificate safety, redirects, and User-Agent negotiation
  Future<SubscriptionFetchResult> fetchSubscription({
    required String id,
    required String name,
    required String url,
    int? intervalHours,
  }) async {
    final uri = Uri.parse(url.trim());

    // 1. First attempt with v2rayNG User-Agent
    var (body, headers) = await _doGet(uri, 'v2rayNG/1.8.12');
    var nodes = ConfigParser.parseMultiple(body, subscriptionId: id);

    // 2. If no nodes parsed, retry with ClashMeta User-Agent (many panels serve Clash YAML format)
    if (nodes.isEmpty) {
      final (clashBody, clashHeaders) = await _doGet(uri, 'ClashMeta/1.18.0');
      final clashNodes = ConfigParser.parseMultiple(clashBody, subscriptionId: id);
      if (clashNodes.isNotEmpty) {
        body = clashBody;
        headers = clashHeaders;
        nodes = clashNodes;
      }
    }

    if (nodes.isEmpty) {
      throw Exception('Could not parse any valid nodes from subscription. Please verify URL.');
    }

    // Parse subscription user-info quota header (upload, download, total, expire)
    int upload = 0;
    int download = 0;
    int total = 0;
    DateTime? expire;

    final userInfoHeader = headers['subscription-userinfo'];
    if (userInfoHeader != null) {
      final parts = userInfoHeader.split(';');
      for (final part in parts) {
        final kv = part.trim().split('=');
        if (kv.length == 2) {
          final k = kv[0].trim().toLowerCase();
          final v = int.tryParse(kv[1].trim()) ?? 0;
          if (k == 'upload') upload = v;
          if (k == 'download') download = v;
          if (k == 'total') total = v;
          if (k == 'expire' && v > 0) {
            expire = DateTime.fromMillisecondsSinceEpoch(v * 1000);
          }
        }
      }
    }

    final sub = Subscription(
      id: id,
      name: name.isNotEmpty ? name : 'Sub ${uri.host}',
      url: url,
      updatedAt: DateTime.now(),
      autoUpdateIntervalHours: intervalHours ?? 24,
      nodeCount: nodes.length,
      uploadBytes: upload,
      downloadBytes: download,
      totalBytes: total,
      expireDate: expire,
    );

    return SubscriptionFetchResult(subscription: sub, nodes: nodes);
  }

  Future<(String, Map<String, String>)> _doGet(Uri uri, String userAgent) async {
    final client = HttpClient()
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true)
      ..connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, userAgent);
      request.headers.set(HttpHeaders.acceptHeader, '*/*');
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip, deflate');

      final response = await request.close().timeout(const Duration(seconds: 20));

      // Follow HTTP redirects automatically
      if ([301, 302, 307, 308].contains(response.statusCode)) {
        final redirectLocation = response.headers.value(HttpHeaders.locationHeader);
        if (redirectLocation != null) {
          final redirectUri = Uri.parse(redirectLocation);
          return _doGet(redirectUri.hasScheme ? redirectUri : uri.resolve(redirectLocation), userAgent);
        }
      }

      final Map<String, String> headers = {};
      response.headers.forEach((name, values) {
        headers[name.toLowerCase()] = values.join(', ');
      });

      final bodyBytes = await response.fold<List<int>>([], (prev, element) => prev..addAll(element));
      final body = utf8.decode(bodyBytes, allowMalformed: true);

      return (body, headers);
    } finally {
      client.close();
    }
  }
}
