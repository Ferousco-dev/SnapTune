import 'dart:io';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/statistics.dart';
import 'package:path_provider/path_provider.dart';

class VideoProbeResult {
  final String codec;
  final int width;
  final int height;
  final double fps;
  final int bitrateBps;
  final double durationSecs;
  final bool isVfr;

  const VideoProbeResult({
    required this.codec,
    required this.width,
    required this.height,
    required this.fps,
    required this.bitrateBps,
    required this.durationSecs,
    required this.isVfr,
  });

  // A video is WhatsApp-ready when WhatsApp won't need to touch it.
  // Constraints: H.264, ≤1080p wide side, ≤2Mbps, ≤29s, CFR.
  bool get isWhatsAppReady =>
      codec == 'h264' &&
      width <= 1080 &&
      height <= 1920 &&
      bitrateBps <= 2_000_000 &&
      durationSecs <= 29.0 &&
      !isVfr;
}

class VideoProcessResult {
  final List<String> outputPaths;
  final bool bypassed;
  final int originalSizeBytes;
  final int outputSizeBytes;

  const VideoProcessResult({
    required this.outputPaths,
    required this.bypassed,
    required this.originalSizeBytes,
    required this.outputSizeBytes,
  });
}

class VideoProcessor {
  Future<VideoProcessResult> process({
    required String inputPath,
    void Function(double progress)? onProgress,
  }) async {
    final originalSize = await File(inputPath).length();
    final probe = await _probe(inputPath);

    // Can't probe → pass through as-is
    if (probe == null) {
      return VideoProcessResult(
        outputPaths: [inputPath],
        bypassed: true,
        originalSizeBytes: originalSize,
        outputSizeBytes: originalSize,
      );
    }

    // Already WhatsApp-ready and short enough → bypass entirely
    if (probe.isWhatsAppReady) {
      return VideoProcessResult(
        outputPaths: [inputPath],
        bypassed: true,
        originalSizeBytes: originalSize,
        outputSizeBytes: originalSize,
      );
    }

    final tmpDir = await getTemporaryDirectory();
    final transcodedPath = '${tmpDir.path}/snaptune_tc.mp4';

    onProgress?.call(0.05);

    final ok = await _transcode(
      inputPath: inputPath,
      outputPath: transcodedPath,
      totalDurationSecs: probe.durationSecs,
      onProgress: (p) => onProgress?.call(0.05 + p * 0.75),
    );

    // Transcode failed → fall back to original
    if (!ok || !File(transcodedPath).existsSync()) {
      return VideoProcessResult(
        outputPaths: [inputPath],
        bypassed: true,
        originalSizeBytes: originalSize,
        outputSizeBytes: originalSize,
      );
    }

    onProgress?.call(0.80);

    // Split into 29-second chunks if needed
    List<String> finalPaths;
    if (probe.durationSecs > 29.0) {
      finalPaths = await _split(
        inputPath: transcodedPath,
        totalDurationSecs: probe.durationSecs,
        tmpDir: tmpDir.path,
      );
      if (finalPaths.isEmpty) finalPaths = [transcodedPath];
    } else {
      finalPaths = [transcodedPath];
    }

    onProgress?.call(1.0);

    final outputSize = finalPaths.fold<int>(
      0,
      (sum, p) => sum + (File(p).existsSync() ? File(p).lengthSync() : 0),
    );

    return VideoProcessResult(
      outputPaths: finalPaths,
      bypassed: false,
      originalSizeBytes: originalSize,
      outputSizeBytes: outputSize,
    );
  }

  Future<VideoProbeResult?> _probe(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      if (info == null) return null;

      final streams = info.getStreams();
      if (streams.isEmpty) return null;
      final video = streams.firstWhere(
        (s) => s.getType() == 'video',
        orElse: () => streams.first,
      );

      final codec = video.getCodec() ?? '';
      final width = video.getWidth() ?? 0;
      final height = video.getHeight() ?? 0;
      final bitrate = int.tryParse(info.getBitrate() ?? '0') ?? 0;
      final duration = double.tryParse(info.getDuration() ?? '0') ?? 0.0;

      // Detect VFR: r_frame_rate != avg_frame_rate
      final props = video.getAllProperties();
      final rFps = props?['r_frame_rate'] as String?;
      final avgFps = props?['avg_frame_rate'] as String?;
      final fps = _parseFraction(avgFps ?? rFps ?? '30/1');
      final isVfr = rFps != null && avgFps != null && rFps != avgFps;

      return VideoProbeResult(
        codec: codec,
        width: width,
        height: height,
        fps: fps,
        bitrateBps: bitrate,
        durationSecs: duration,
        isVfr: isVfr,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _transcode({
    required String inputPath,
    required String outputPath,
    required double totalDurationSecs,
    void Function(double)? onProgress,
  }) async {
    // Scale to 1080x1920 (9:16) maintaining aspect ratio with letterbox/pillarbox padding.
    // fps=fps=30 inside -vf converts VFR to CFR before libx264 sees the frames.
    const vf = 'scale=1080:1920:force_original_aspect_ratio=decrease,'
        'pad=1080:1920:(ow-iw)/2:(oh-ih)/2,'
        'fps=fps=30';

    final cmd = [
      '-i "$inputPath"',
      '-c:v libx264',
      '-profile:v high -level:v 4.1',
      '-preset fast',
      '-crf 23',
      '-vf "$vf"',
      '-vsync cfr',
      '-c:a aac -b:a 128k -ar 44100',
      '-movflags +faststart',
      '-map_metadata -1',
      '-y "$outputPath"',
    ].join(' ');

    final session = await FFmpegKit.executeAsync(
      cmd,
      null,
      null,
      (Statistics stats) {
        if (totalDurationSecs > 0 && onProgress != null) {
          final pct = (stats.getTime() / 1000.0) / totalDurationSecs;
          onProgress(pct.clamp(0.0, 1.0));
        }
      },
    );

    final rc = await session.getReturnCode();
    return ReturnCode.isSuccess(rc);
  }

  Future<List<String>> _split({
    required String inputPath,
    required double totalDurationSecs,
    required String tmpDir,
  }) async {
    const chunkSecs = 29;
    final count = (totalDurationSecs / chunkSecs).ceil();
    final outputs = <String>[];

    for (int i = 0; i < count; i++) {
      final start = i * chunkSecs;
      final outPath = '$tmpDir/snaptune_status_${i + 1}.mp4';

      // -ss before -i = fast GOP-aligned seek; -c copy = no re-encode
      final cmd = '-ss $start -t $chunkSecs '
          '-i "$inputPath" '
          '-c copy '
          '-avoid_negative_ts make_zero '
          '-y "$outPath"';

      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (ReturnCode.isSuccess(rc) && File(outPath).existsSync()) {
        outputs.add(outPath);
      }
    }

    return outputs;
  }

  double _parseFraction(String fraction) {
    final parts = fraction.split('/');
    if (parts.length == 2) {
      final n = double.tryParse(parts[0]) ?? 0;
      final d = double.tryParse(parts[1]) ?? 1;
      return d > 0 ? n / d : 0;
    }
    return double.tryParse(fraction) ?? 30.0;
  }
}
