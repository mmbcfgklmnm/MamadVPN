class Subscription {
  final String id;
  String name;
  String url;
  DateTime updatedAt;
  int autoUpdateIntervalHours;
  int nodeCount;
  int uploadBytes;
  int downloadBytes;
  int totalBytes; // 0 means unlimited
  DateTime? expireDate;

  Subscription({
    required this.id,
    required this.name,
    required this.url,
    required this.updatedAt,
    this.autoUpdateIntervalHours = 24,
    this.nodeCount = 0,
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.totalBytes = 0,
    this.expireDate,
  });

  int get usedBytes => uploadBytes + downloadBytes;
  int get remainingBytes => (totalBytes > 0 && totalBytes >= usedBytes) ? (totalBytes - usedBytes) : 0;
  double get usagePercent => totalBytes > 0 ? (usedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'updatedAt': updatedAt.toIso8601String(),
      'autoUpdateIntervalHours': autoUpdateIntervalHours,
      'nodeCount': nodeCount,
      'uploadBytes': uploadBytes,
      'downloadBytes': downloadBytes,
      'totalBytes': totalBytes,
      'expireDate': expireDate?.toIso8601String(),
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Subscription',
      url: json['url'] ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      autoUpdateIntervalHours: json['autoUpdateIntervalHours'] ?? 24,
      nodeCount: json['nodeCount'] ?? 0,
      uploadBytes: json['uploadBytes'] ?? 0,
      downloadBytes: json['downloadBytes'] ?? 0,
      totalBytes: json['totalBytes'] ?? 0,
      expireDate: json['expireDate'] != null ? DateTime.tryParse(json['expireDate']) : null,
    );
  }
}
