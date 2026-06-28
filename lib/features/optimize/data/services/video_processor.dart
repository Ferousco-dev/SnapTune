import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/statistics.dart';
import 'package:path_provider/path_provider.dart';

// ─── Metadata ─────────────────────────────────────────────────────────────────

class VideoMetadata {
  final String videoCodec;
  final String audioCodec;
  final int width;
  final int height;
  final double fps;
  final bool isVfr;
  final int videoBitrateBps;
  final int audioBitrateBps;
  final int audioSampleRate;
  final int audioChannels;
  final double durationSecs;
  final int fileSizeBytes;

  const VideoMetadata({
    required this.videoCodec,
    required this.audioCodec,
    required this.width,
    required this.height,
    required this.fps,
    required this.isVfr,
    required this.videoBitrateBps,
    required this.audioBitrateBps,
    required this.audioSampleRate,
    required this.audioChannels,
    required this.durationSecs,
    required this.fileSizeBytes,
  });

  int get longestSide => width >= height ? width : height;

  // True if video has an audio track at all
  bool get hasAudio => audioCodec.isNotEmpty;

  // WhatsApp re-encodes if any of these are false
  bool get videoCodecOk => videoCodec == 'h264';
  // No audio track = nothing to check; aac = OK
  bool get audioCodecOk => !hasAudio || audioCodec == 'aac';
  bool get resolutionOk => longestSide <= 1280;
  bool get fpsOk => fps <= 60.0 && !isVfr;
  // 0 = undetectable (common on WhatsApp-received files) — treat as OK
  bool get videoBitrateOk => videoBitrateBps == 0 || videoBitrateBps <= 1_800_000;
  bool get audioBitrateOk =>
      !hasAudio || audioBitrateBps == 0 || audioBitrateBps <= 160_000;
  // 0 = undetectable — treat as OK
  bool get audioSampleRateOk =>
      !hasAudio ||
      audioSampleRate == 0 ||
      audioSampleRate == 44100 ||
      audioSampleRate == 48000;

  bool get isWhatsAppReady =>
      videoCodecOk &&
      audioCodecOk &&
      resolutionOk &&
      fpsOk &&
      videoBitrateOk &&
      audioBitrateOk &&
      audioSampleRateOk &&
      durationSecs <= 29.0;
}

// ─── Optimization plan ────────────────────────────────────────────────────────

class OptimizationPlan {
  final bool bypass;
  final int targetWidth;
  final int targetHeight;
  final int targetFps;
  final int targetVideoBitrateBps;
  final bool reEncodeVideo;
  final bool reEncodeAudio;
  final bool needsSplit;
  final List<String> reasons;

  const OptimizationPlan({
    required this.bypass,
    required this.targetWidth,
    required this.targetHeight,
    required this.targetFps,
    required this.targetVideoBitrateBps,
    required this.reEncodeVideo,
    required this.reEncodeAudio,
    required this.needsSplit,
    required this.reasons,
  });
}

// ─── Decision engine ──────────────────────────────────────────────────────────

class _WhatsAppOptimizer {
  // Targets sit just below WhatsApp's re-encode thresholds (observed behavior)
  static const int _maxLongSide = 1280;
  static const int _targetVideoBps = 1_500_000; // 1.5 Mbps
  static const int _maxFps = 60;
  static const int _defaultFps = 30; // fallback when source fps undetectable

  OptimizationPlan analyze(VideoMetadata m) {
    if (m.isWhatsAppReady) {
      return OptimizationPlan(
        bypass: true,
        targetWidth: m.width,
        targetHeight: m.height,
        targetFps: m.fps > 0 ? m.fps.round().clamp(1, _maxFps) : _defaultFps,
        targetVideoBitrateBps: m.videoBitrateBps,
        reEncodeVideo: false,
        reEncodeAudio: false,
        needsSplit: false,
        reasons: const ['Already WhatsApp-ready — no processing needed'],
      );
    }

    final reasons = <String>[];

    // Resolution: scale longest side to ≤1280, preserve aspect ratio
    int tW = m.width;
    int tH = m.height;
    if (m.longestSide > _maxLongSide) {
      if (m.width >= m.height) {
        tW = _maxLongSide;
        tH = ((m.height * _maxLongSide) / m.width).round();
      } else {
        tH = _maxLongSide;
        tW = ((m.width * _maxLongSide) / m.height).round();
      }
      // H.264 requires even dimensions
      if (tW % 2 != 0) tW++;
      if (tH % 2 != 0) tH++;
      reasons.add('Resize ${m.width}×${m.height} → $tW×$tH');
    }

    // FPS: preserve source up to 60fps; fall back to 30fps if undetectable
    int tFps = m.fps > 0
        ? m.fps.round().clamp(1, _maxFps)
        : _defaultFps;
    if (m.fps > _maxFps) {
      reasons.add('Reduce fps ${m.fps.toStringAsFixed(1)} → $_maxFps');
    }
    if (m.isVfr) {
      reasons.add('Convert variable frame rate to CFR');
    }

    // Bitrate cap
    int tBps = m.videoBitrateBps;
    if (m.videoBitrateBps > _targetVideoBps) {
      tBps = _targetVideoBps;
      reasons.add(
          'Reduce video bitrate ${(m.videoBitrateBps / 1000).round()} kbps'
          ' → ${(_targetVideoBps / 1000).round()} kbps');
    }

    // Video needs re-encoding?
    final reEncodeVideo = !m.videoCodecOk ||
        m.longestSide > _maxLongSide ||
        m.fps > _maxFps ||
        m.isVfr ||
        m.videoBitrateBps > _targetVideoBps;

    // Audio needs re-encoding? (skip entirely if no audio stream)
    final reEncodeAudio = m.hasAudio &&
        (!m.audioCodecOk || !m.audioBitrateOk || !m.audioSampleRateOk);
    if (reEncodeAudio) {
      reasons.add(
          'Re-encode audio: ${m.audioCodec} → AAC 128 kbps 44.1 kHz');
    }

    // Split for WhatsApp Status
    final needsSplit = m.durationSecs > 29.0;
    if (needsSplit) {
      final clips = (m.durationSecs / 29).ceil();
      reasons.add(
          'Split ${m.durationSecs.toStringAsFixed(1)}s into $clips × 29s clips');
    }

    if (!reEncodeVideo && !reEncodeAudio && !needsSplit) {
      return OptimizationPlan(
        bypass: true,
        targetWidth: m.width,
        targetHeight: m.height,
        targetFps: tFps,
        targetVideoBitrateBps: tBps,
        reEncodeVideo: false,
        reEncodeAudio: false,
        needsSplit: false,
        reasons: const ['No changes required'],
      );
    }

    return OptimizationPlan(
      bypass: false,
      targetWidth: tW,
      targetHeight: tH,
      targetFps: tFps,
      targetVideoBitrateBps: tBps,
      reEncodeVideo: reEncodeVideo,
      reEncodeAudio: reEncodeAudio,
      needsSplit: needsSplit,
      reasons: reasons,
    );
  }
}

// ─── Result ───────────────────────────────────────────────────────────────────

class VideoProcessResult {
  final List<String> outputPaths;
  final bool bypassed;
  final int originalSizeBytes;
  final int outputSizeBytes;
  final VideoMetadata? metadata;
  final List<String> appliedChanges;

  const VideoProcessResult({
    required this.outputPaths,
    required this.bypassed,
    required this.originalSizeBytes,
    required this.outputSizeBytes,
    this.metadata,
    this.appliedChanges = const [],
  });
}

// ─── Processor ────────────────────────────────────────────────────────────────

class VideoProcessor {
  final _optimizer = _WhatsAppOptimizer();

  Future<VideoProcessResult> process({
    required String inputPath,
    void Function(double progress)? onProgress,
  }) async {
    final originalSize = await _fileSizeOf(inputPath);
    onProgress?.call(0.05);

    final meta = await _probe(inputPath);
    onProgress?.call(0.12);

    if (meta == null) {
      return _passthrough(inputPath, originalSize);
    }

    final plan = _optimizer.analyze(meta);

    if (plan.bypass) {
      return VideoProcessResult(
        outputPaths: [inputPath],
        bypassed: true,
        originalSizeBytes: originalSize,
        outputSizeBytes: originalSize,
        metadata: meta,
        appliedChanges: plan.reasons,
      );
    }

    final tmpDir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final transcodedPath = '${tmpDir.path}/snaptune_$stamp.mp4';

    final ok = await _transcode(
      inputPath: inputPath,
      outputPath: transcodedPath,
      plan: plan,
      meta: meta,
      onProgress: (p) => onProgress?.call(0.12 + p * 0.68),
    );

    if (!ok || !File(transcodedPath).existsSync()) {
      return _passthrough(inputPath, originalSize, meta: meta);
    }

    onProgress?.call(0.80);

    List<String> finalPaths;
    if (plan.needsSplit) {
      finalPaths = await _split(
        inputPath: transcodedPath,
        durationSecs: meta.durationSecs,
        tmpDir: tmpDir.path,
        stamp: stamp,
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
      metadata: meta,
      appliedChanges: plan.reasons,
    );
  }

  // ─── Probe ──────────────────────────────────────────────────────────────────

  Future<VideoMetadata?> _probe(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      if (info == null) return null;

      final streams = info.getStreams();
      if (streams.isEmpty) return null;

      dynamic videoStream;
      dynamic audioStream;
      for (final s in streams) {
        if (s.getType() == 'video') videoStream ??= s;
        if (s.getType() == 'audio') audioStream ??= s;
      }
      if (videoStream == null) return null;

      final vProps = videoStream.getAllProperties() as Map?;
      final aProps = audioStream?.getAllProperties() as Map?;

      final rFps = vProps?['r_frame_rate'] as String?;
      final avgFps = vProps?['avg_frame_rate'] as String?;
      final fps = _parseFrac(avgFps ?? rFps ?? '30/1');
      // Only flag VFR when the difference is >5% — avoids false positives on
      // WhatsApp-received files where metadata has minor rounding differences
      final rFpsVal = _parseFrac(rFps ?? '0');
      final avgFpsVal = _parseFrac(avgFps ?? '0');
      final isVfr = rFpsVal > 0 &&
          avgFpsVal > 0 &&
          (rFpsVal - avgFpsVal).abs() / rFpsVal > 0.05;

      // Stream-level bitrate is more accurate; fall back to container / estimate
      final vBps = int.tryParse(videoStream.getBitrate() ?? '0') ?? 0;
      final aBps = int.tryParse(audioStream?.getBitrate() ?? '0') ?? 0;
      final containerBps = int.tryParse(info.getBitrate() ?? '0') ?? 0;
      final effectiveVBps = vBps > 0
          ? vBps
          : (containerBps > aBps ? containerBps - aBps : containerBps);

      final meta = VideoMetadata(
        videoCodec: videoStream.getCodec() ?? '',
        audioCodec: audioStream?.getCodec() ?? '',
        width: videoStream.getWidth() ?? 0,
        height: videoStream.getHeight() ?? 0,
        fps: fps,
        isVfr: isVfr,
        videoBitrateBps: effectiveVBps,
        audioBitrateBps: aBps,
        audioSampleRate:
            int.tryParse(aProps?['sample_rate']?.toString() ?? '0') ?? 0,
        audioChannels:
            int.tryParse(aProps?['channels']?.toString() ?? '0') ?? 0,
        durationSecs:
            double.tryParse(info.getDuration() ?? '0') ?? 0.0,
        fileSizeBytes: await _fileSizeOf(path),
      );
      debugPrint('[VP] probe: codec=${meta.videoCodec}/${meta.audioCodec} '
          '${meta.width}x${meta.height} fps=${meta.fps.toStringAsFixed(2)} '
          'isVfr=${meta.isVfr} vbr=${meta.videoBitrateBps} abr=${meta.audioBitrateBps} '
          'sr=${meta.audioSampleRate} dur=${meta.durationSecs.toStringAsFixed(1)}s '
          'ready=${meta.isWhatsAppReady}');
      return meta;
    } catch (e) {
      debugPrint('[VP] probe failed: $e');
      return null;
    }
  }

  // ─── Transcode ──────────────────────────────────────────────────────────────

  Future<bool> _transcode({
    required String inputPath,
    required String outputPath,
    required OptimizationPlan plan,
    required VideoMetadata meta,
    void Function(double)? onProgress,
  }) async {
    final parts = <String>['-i "$inputPath"'];

    // Video stream
    if (plan.reEncodeVideo) {
      final vf = _buildVf(plan, meta);
      parts.addAll([
        '-c:v libx264',
        '-profile:v baseline',
        '-level:v 3.0',
        '-pix_fmt yuv420p',
        '-preset fast',
        '-crf 23',
        '-maxrate ${(plan.targetVideoBitrateBps / 1000).round()}k',
        '-bufsize ${(plan.targetVideoBitrateBps * 2 / 1000).round()}k',
        '-g ${plan.targetFps}',
        '-keyint_min ${plan.targetFps ~/ 2}',
        if (vf.isNotEmpty) '-vf "$vf"',
        // 29.97fps matches WhatsApp's internal target (verified from PureStatus/ClearStatus)
        '-r 29.97',
      ]);
    } else {
      parts.add('-c:v copy');
    }

    // Audio stream
    if (plan.reEncodeAudio) {
      parts.addAll([
        '-c:a aac',
        '-b:a 128k',
        '-ar 44100',
        '-ac 2',
      ]);
    } else if (!meta.hasAudio) {
      parts.add('-an');
    } else {
      parts.add('-c:a copy');
    }

    parts.addAll([
      '-movflags +faststart',
      '-map_metadata -1',
      '-threads 0',
      '-f mp4',
      '-y "$outputPath"',
    ]);

    final cmd = parts.join(' ');
    debugPrint('[VP] cmd: $cmd');
    final session = await FFmpegKit.executeAsync(
      cmd,
      null,
      null,
      (Statistics stats) {
        if (meta.durationSecs > 0 && onProgress != null) {
          final pct = (stats.getTime() / 1000.0) / meta.durationSecs;
          onProgress(pct.clamp(0.0, 1.0));
        }
      },
    );

    final rc = await session.getReturnCode();
    final ok = ReturnCode.isSuccess(rc);
    debugPrint('[VP] transcode: ${ok ? "OK" : "FAILED"} rc=$rc');
    if (!ok) {
      final logs = await session.getAllLogsAsString();
      debugPrint('[VP] ffmpeg logs:\n$logs');
    }
    return ok;
  }

  // ─── VF filter ──────────────────────────────────────────────────────────────

  String _buildVf(OptimizationPlan plan, VideoMetadata meta) {
    final filters = <String>[];

    if (meta.longestSide > 1280) {
      // Use pre-computed even dimensions from the plan (avoids complex FFmpeg expressions)
      filters.add('scale=${plan.targetWidth}:${plan.targetHeight}');
    }

    // Cap at 60fps (WhatsApp limit) or convert VFR; don't touch CFR ≤60fps
    if (meta.fps > 60 || meta.isVfr) {
      filters.add('fps=fps=${plan.targetFps}');
    }

    return filters.join(',');
  }

  // ─── Split ──────────────────────────────────────────────────────────────────

  Future<List<String>> _split({
    required String inputPath,
    required double durationSecs,
    required String tmpDir,
    required int stamp,
  }) async {
    const clipSecs = 29;
    final count = (durationSecs / clipSecs).ceil();
    final outputs = <String>[];

    for (int i = 0; i < count; i++) {
      final start = i * clipSecs;
      final outPath = '$tmpDir/snaptune_status_${stamp}_${i + 1}.mp4';

      // -ss before -i = fast GOP-aligned seek; -c copy avoids re-encode
      final cmd = '-ss $start -t $clipSecs '
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

  // ─── Helpers ────────────────────────────────────────────────────────────────

  VideoProcessResult _passthrough(String path, int size, {VideoMetadata? meta}) {
    return VideoProcessResult(
      outputPaths: [path],
      bypassed: true,
      originalSizeBytes: size,
      outputSizeBytes: size,
      metadata: meta,
    );
  }

  Future<int> _fileSizeOf(String path) async {
    try {
      return await File(path).length();
    } catch (_) {
      return 0;
    }
  }

  double _parseFrac(String frac) {
    final parts = frac.split('/');
    if (parts.length == 2) {
      final n = double.tryParse(parts[0]) ?? 0;
      final d = double.tryParse(parts[1]) ?? 1;
      return d > 0 ? n / d : 30.0;
    }
    return double.tryParse(frac) ?? 30.0;
  }
}
