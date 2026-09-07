import 'dart:async';
import 'dart:io';
import '../models/server_node.dart';

class PingService {
  /// Measure TCP handshake latency to the server host and port
  static Future<int> tcpPing(String host, int port, {Duration timeout = const Duration(seconds: 4)}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      stopwatch.stop();
      await socket.close();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      return -1; // Timed out or unreachable
    }
  }

  /// Ping a single server node and update its ping and lastTested fields
  static Future<int> pingNode(ServerNode node, {Duration timeout = const Duration(seconds: 4)}) async {
    final latency = await tcpPing(node.address, node.port, timeout: timeout);
    node.ping = latency;
    node.lastTested = DateTime.now();
    return latency;
  }

  /// Concurrent batch ping with a pool limit (e.g. 10 simultaneous connections)
  static Future<void> batchPing(
    List<ServerNode> nodes, {
    int concurrency = 8,
    Duration timeout = const Duration(seconds: 4),
    void Function(ServerNode node, int ping)? onProgress,
  }) async {
    final queue = List<ServerNode>.from(nodes);
    final List<Future<void>> workers = [];

    for (int i = 0; i < concurrency; i++) {
      workers.add(() async {
        while (queue.isNotEmpty) {
          final node = queue.removeLast();
          final ping = await pingNode(node, timeout: timeout);
          if (onProgress != null) {
            onProgress(node, ping);
          }
        }
      }());
    }

    await Future.wait(workers);
  }

  /// Finds the server node with the lowest positive ping
  static ServerNode? findBestNode(List<ServerNode> nodes) {
    ServerNode? best;
    int lowestPing = 999999;

    for (final node in nodes) {
      if (node.ping != null && node.ping! > 0 && node.ping! < lowestPing) {
        lowestPing = node.ping!;
        best = node;
      }
    }
    return best;
  }
}
