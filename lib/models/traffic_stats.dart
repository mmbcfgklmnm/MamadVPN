class TrafficStats {
  final double downloadSpeed; // in bytes per second
  final double uploadSpeed;   // in bytes per second
  final int sessionDownloaded; // in bytes
  final int sessionUploaded;   // in bytes
  final Duration connectedDuration;

  const TrafficStats({
    this.downloadSpeed = 0.0,
    this.uploadSpeed = 0.0,
    this.sessionDownloaded = 0,
    this.sessionUploaded = 0,
    this.connectedDuration = Duration.zero,
  });

  TrafficStats copyWith({
    double? downloadSpeed,
    double? uploadSpeed,
    int? sessionDownloaded,
    int? sessionUploaded,
    Duration? connectedDuration,
  }) {
    return TrafficStats(
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      sessionDownloaded: sessionDownloaded ?? this.sessionDownloaded,
      sessionUploaded: sessionUploaded ?? this.sessionUploaded,
      connectedDuration: connectedDuration ?? this.connectedDuration,
    );
  }
}
