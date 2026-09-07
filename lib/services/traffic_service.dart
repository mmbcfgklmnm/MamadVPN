import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/traffic_stats.dart';

class TrafficService {
  final _statsController = StreamController<TrafficStats>.broadcast();
  Stream<TrafficStats> get statsStream => _statsController.stream;

  TrafficStats _currentStats = const TrafficStats();
  TrafficStats get currentStats => _currentStats;

  Timer? _timer;
  DateTime? _connectionStartTime;

  int _lastTotalDownload = 0;
  int _lastTotalUpload = 0;
  DateTime? _lastPollTime;

  void startMonitoring() {
    _connectionStartTime = DateTime.now();
    _currentStats = const TrafficStats();
    _lastTotalDownload = 0;
    _lastTotalUpload = 0;
    _lastPollTime = null;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_connectionStartTime == null) return;

      final elapsed = DateTime.now().difference(_connectionStartTime!);
      final (realDownSpeed, realUpSpeed, realTotalDown, realTotalUp) = await _fetchRealTelemetry();

      _currentStats = TrafficStats(
        downloadSpeed: realDownSpeed,
        uploadSpeed: realUpSpeed,
        sessionDownloaded: realTotalDown,
        sessionUploaded: realTotalUp,
        connectedDuration: elapsed,
      );

      _statsController.add(_currentStats);
    });
  }

  /// Query Sing-Box Clash API on 127.0.0.1:9090 or Xray Stats API on 127.0.0.1:10085
  Future<(double, double, int, int)> _fetchRealTelemetry() async {
    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 600);

    try {
      final request = await client.getUrl(Uri.parse('http://127.0.0.1:9090/connections'));
      final response = await request.close().timeout(const Duration(milliseconds: 600));

      if (response.statusCode == 200) {
        final bodyBytes = await response.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
        final bodyString = utf8.decode(bodyBytes);
        final Map<String, dynamic> data = jsonDecode(bodyString);

        final totalDown = (data['downloadTotal'] as num?)?.toInt() ?? 0;
        final totalUp = (data['uploadTotal'] as num?)?.toInt() ?? 0;

        return _calculateSpeed(totalDown, totalUp);
      }
    } catch (_) {
      // Sing-box not active, try Xray statsquery below
    } finally {
      client.close();
    }

    try {
      final res = await Process.run('xray.exe', ['api', 'statsquery', '--server=127.0.0.1:10085']);
      if (res.exitCode == 0 && res.stdout.toString().isNotEmpty) {
        final data = jsonDecode(res.stdout.toString());
        final statList = data['stat'] as List<dynamic>?;
        int totalDown = 0;
        int totalUp = 0;
        if (statList != null) {
          for (final item in statList) {
            final name = item['name']?.toString() ?? '';
            final val = (item['value'] as num?)?.toInt() ?? 0;
            if (name.contains('proxy-in') && name.contains('downlink')) totalDown += val;
            if (name.contains('proxy-in') && name.contains('uplink')) totalUp += val;
          }
        }
        return _calculateSpeed(totalDown, totalUp);
      }
    } catch (_) {}

    return (0.0, 0.0, _lastTotalDownload, _lastTotalUpload);
  }

  (double, double, int, int) _calculateSpeed(int totalDown, int totalUp) {
    final now = DateTime.now();
    double downSpeed = 0.0;
    double upSpeed = 0.0;

    if (_lastPollTime != null) {
      final seconds = now.difference(_lastPollTime!).inMilliseconds / 1000.0;
      if (seconds > 0) {
        final diffDown = totalDown - _lastTotalDownload;
        final diffUp = totalUp - _lastTotalUpload;
        downSpeed = (diffDown > 0 ? diffDown / seconds : 0.0);
        upSpeed = (diffUp > 0 ? diffUp / seconds : 0.0);
      }
    }

    _lastTotalDownload = totalDown;
    _lastTotalUpload = totalUp;
    _lastPollTime = now;

    return (downSpeed, upSpeed, totalDown, totalUp);
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _connectionStartTime = null;
    _lastTotalDownload = 0;
    _lastTotalUpload = 0;
    _lastPollTime = null;
    _currentStats = const TrafficStats();
    _statsController.add(_currentStats);
  }

  void dispose() {
    _timer?.cancel();
    _statsController.close();
  }
}
