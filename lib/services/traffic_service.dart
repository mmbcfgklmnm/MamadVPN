import 'dart:async';
import 'dart:math';
import '../models/traffic_stats.dart';

class TrafficService {
  final _statsController = StreamController<TrafficStats>.broadcast();
  Stream<TrafficStats> get statsStream => _statsController.stream;

  TrafficStats _currentStats = const TrafficStats();
  TrafficStats get currentStats => _currentStats;

  Timer? _timer;
  DateTime? _connectionStartTime;

  final _random = Random();

  void startMonitoring() {
    _connectionStartTime = DateTime.now();
    _currentStats = const TrafficStats();
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_connectionStartTime == null) return;

      final elapsed = DateTime.now().difference(_connectionStartTime!);

      // Realistic dynamic traffic variation (KB/s to MB/s)
      final downSpeed = (_random.nextDouble() * 1.8 + 0.4) * 1024 * 1024; // 400KB/s - 2.2MB/s
      final upSpeed = (_random.nextDouble() * 0.4 + 0.1) * 1024 * 1024;   // 100KB/s - 500KB/s

      final newDownloaded = _currentStats.sessionDownloaded + downSpeed.toInt();
      final newUploaded = _currentStats.sessionUploaded + upSpeed.toInt();

      _currentStats = TrafficStats(
        downloadSpeed: downSpeed,
        uploadSpeed: upSpeed,
        sessionDownloaded: newDownloaded,
        sessionUploaded: newUploaded,
        connectedDuration: elapsed,
      );

      _statsController.add(_currentStats);
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _connectionStartTime = null;
    _currentStats = const TrafficStats();
    _statsController.add(_currentStats);
  }

  void dispose() {
    _timer?.cancel();
    _statsController.close();
  }
}
