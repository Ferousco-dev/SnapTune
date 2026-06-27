class OptimizationRecord {
  final String id;
  final int timestampMs;
  final String presetId;
  final String presetName;
  final String filename;
  final int originalSizeBytes;
  final int outputSizeBytes;
  final bool isVideo;
  final String? savedOutputPath;
  final int clipCount;

  const OptimizationRecord({
    required this.id,
    required this.timestampMs,
    required this.presetId,
    required this.presetName,
    required this.filename,
    required this.originalSizeBytes,
    required this.outputSizeBytes,
    required this.isVideo,
    this.savedOutputPath,
    this.clipCount = 1,
  });

  int get savingsBytes => (originalSizeBytes - outputSizeBytes).clamp(0, originalSizeBytes);
  double get savingsPct =>
      originalSizeBytes > 0 ? savingsBytes / originalSizeBytes * 100 : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestampMs': timestampMs,
        'presetId': presetId,
        'presetName': presetName,
        'filename': filename,
        'originalSizeBytes': originalSizeBytes,
        'outputSizeBytes': outputSizeBytes,
        'isVideo': isVideo,
        'savedOutputPath': savedOutputPath,
        'clipCount': clipCount,
      };

  factory OptimizationRecord.fromJson(Map<String, dynamic> j) =>
      OptimizationRecord(
        id: j['id'] as String,
        timestampMs: j['timestampMs'] as int,
        presetId: j['presetId'] as String,
        presetName: j['presetName'] as String,
        filename: j['filename'] as String,
        originalSizeBytes: j['originalSizeBytes'] as int,
        outputSizeBytes: j['outputSizeBytes'] as int,
        isVideo: j['isVideo'] as bool,
        savedOutputPath: j['savedOutputPath'] as String?,
        clipCount: (j['clipCount'] as int?) ?? 1,
      );
}
