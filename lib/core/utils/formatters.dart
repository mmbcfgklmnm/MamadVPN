import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Formatters {
  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    final num = bytes / pow(1024, i);
    return '${num.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static String formatSpeed(double bytesPerSec, [int decimals = 1]) {
    if (bytesPerSec <= 0) return '0 KB/s';
    const suffixes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var i = (log(bytesPerSec) / log(1024)).floor();
    if (i <= 0) {
      return '${bytesPerSec.toStringAsFixed(0)} B/s';
    }
    if (i >= suffixes.length) i = suffixes.length - 1;
    final num = bytesPerSec / pow(1024, i);
    return '${num.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  static Color getPingColor(int? pingMs) {
    if (pingMs == null) return AppColors.pingTimeout;
    if (pingMs < 0) return AppColors.pingTimeout;
    if (pingMs < 150) return AppColors.pingGood;
    if (pingMs < 350) return AppColors.pingMedium;
    return AppColors.pingBad;
  }

  static String formatPing(int? pingMs) {
    if (pingMs == null) return '--';
    if (pingMs < 0) return 'Timeout';
    return '$pingMs ms';
  }

  static String getCountryFlag(String countryCode) {
    if (countryCode.length != 2) return '🌐';
    final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}
