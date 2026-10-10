// lib/core/audio/waveform_web_helper_web.dart
import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import '../video/video_web_helper.dart';

Future<List<double>> extractWaveformWeb(String videoPath, int sampleCount) async {
  // videoPath is a Blob URL (e.g. blob:http...) or asset path
  final resolved = resolveWebVideoUrl(videoPath);
  // 1. Fetch the bytes from the URL using standard HTTP client (compatible with JS and Wasm)
  final response = await http.get(Uri.parse(resolved));
  final bytes = response.bodyBytes;

  // 2. Determine duration from a temporary VideoElement to allocate the correct context size
  double duration = 10.0; // Reasonable fallback duration (seconds)
  web.HTMLVideoElement? videoEl;
  try {
    videoEl = web.document.createElement('video') as web.HTMLVideoElement;
    videoEl.src = resolved;
    final completer = Completer<void>();
    videoEl.onloadedmetadata = ((web.Event event) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    videoEl.onerror = ((web.Event event) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    await completer.future.timeout(const Duration(seconds: 2));
    if (videoEl.duration.isFinite && videoEl.duration > 0) {
      duration = videoEl.duration.toDouble();
    }
  } catch (_) {
    // Keep fallback
  } finally {
    if (videoEl != null) {
      videoEl.src = '';
      try {
        videoEl.load();
      } catch (e) {
        debugPrint('videoEl.load() cleanup error on web: $e');
      }
    }
  }

  // Downsample sample rate dynamically for long videos to prevent browser memory exhaustion
  final int sampleRate = duration > 300.0 ? 8000 : 44100;
  final contextSamples = (duration * sampleRate).toInt().clamp(sampleRate, sampleRate * 3600 * 5); // Max 5 hours safety limit

  // 3. Decode using Web Audio API OfflineAudioContext with dynamic sample size
  final audioCtx = web.OfflineAudioContext(
    web.OfflineAudioContextOptions(
      numberOfChannels: 1,
      length: contextSamples,
      sampleRate: sampleRate.toDouble(),
    ),
  );
  
  final audioBuffer = await audioCtx.decodeAudioData(bytes.buffer.toJS).toDart;
  final floatData = audioBuffer.getChannelData(0).toDart;

  final totalSamples = floatData.length;
  if (totalSamples <= 0) {
    return List.generate(sampleCount, (_) => 0.0);
  }
  
  final chunkSize = totalSamples ~/ sampleCount;
  final amplitudes = <double>[];

  for (int i = 0; i < sampleCount; i++) {
    double sumSquares = 0;
    final int start = (i * chunkSize).toInt();
    final int end = (start + chunkSize).clamp(0, totalSamples).toInt();
    int count = 0;
    for (int j = start; j < end; j++) {
      final sample = floatData[j];
      sumSquares += sample * sample;
      count++;
    }
    amplitudes.add(count > 0 ? math.sqrt(sumSquares / count) : 0.0);
  }

  final maxAmp = amplitudes.isEmpty ? 0.0 : amplitudes.reduce(math.max);
  return maxAmp > 0 ? amplitudes.map((a) => a / maxAmp).toList() : amplitudes;
}

