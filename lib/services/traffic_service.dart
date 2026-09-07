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

  /// Query Sing-Box Clash API on 127.0.0.1:9090 for real byte counters
  Future<(double, double, int, int)> _fetchRealTelemetry() async {
    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 800);

    try {
      final request = await client.getUrl(Uri.parse('http://127.0.0.1:9090/connections'));
      final response = await request.close().timeout(const Duration(milliseconds: 800));

      if (response.statusCode == 200) {
        final bodyBytes = await response.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
        final bodyString = utf8.decode(bodyBytes);
        final Map<String, dynamic> data = jsonDecode(bodyString);

        final totalDown = (data['downloadTotal'] as num?)?.toInt() ?? 0;
        final totalUp = (data['uploadTotal'] as num?)?.toInt() ?? 0;

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
    } catch (_) {
      // Core not running or idle: true speed is 0
    } finally {
      client.close();
    }

    return (0.0, 0.0, _lastTotalDownload, _lastTotalUpload);
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
