import 'package:flutter_test/flutter_test.dart';
import 'package:mamadvpn/core/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    test('Format bytes to human-readable strings', () {
      expect(Formatters.formatBytes(500), '500.0 B');
      expect(Formatters.formatBytes(1024), '1.0 KB');
      expect(Formatters.formatBytes(1048576), '1.0 MB');
      expect(Formatters.formatBytes(1073741824), '1.0 GB');
    });

    test('Format connection duration', () {
      const dur = Duration(hours: 1, minutes: 23, seconds: 45);
      expect(Formatters.formatDuration(dur), '01:23:45');
    });

    test('Format ping latency strings', () {
      expect(Formatters.formatPing(45), '45 ms');
      expect(Formatters.formatPing(-1), 'Timeout');
      expect(Formatters.formatPing(null), '--');
    });
  });
}
