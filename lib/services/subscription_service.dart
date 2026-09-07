import 'package:http/http.dart' as http;
import '../models/server_node.dart';
import '../models/subscription.dart';
import 'config_parser.dart';

class SubscriptionFetchResult {
  final Subscription subscription;
  final List<ServerNode> nodes;

  SubscriptionFetchResult({required this.subscription, required this.nodes});
}

class SubscriptionService {
  final http.Client _client;

  SubscriptionService([http.Client? client]) : _client = client ?? http.Client();

  /// Fetch remote subscription and extract nodes and quota headers
  Future<SubscriptionFetchResult> fetchSubscription({
    required String id,
    required String name,
    required String url,
    int? intervalHours,
  }) async {
    final uri = Uri.parse(url.trim());
    final response = await _client.get(
      uri,
      headers: {
        'User-Agent': 'v2rayNG/1.8.5 (MamadVPN)',
        'Accept': '*/*',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch subscription: HTTP ${response.statusCode}');
    }

    // Parse subscription user-info header (upload, download, total, expire)
    int upload = 0;
    int download = 0;
    int total = 0;
    DateTime? expire;

    final userInfoHeader = response.headers['subscription-userinfo'];
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

    // Parse nodes from the response body
    final nodes = ConfigParser.parseMultiple(response.body, subscriptionId: id);

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
}
