// lib/core/audio/waveform_web_helper_web.dart
// ignore_for_file: uri_does_not_exist, avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:web_audio' as web_audio;
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:js_util' as js_util;

Future<List<double>> extractWaveformWeb(String videoPath, int sampleCount) async {
  // videoPath is a Blob URL (e.g. blob:http...)
  // 1. Fetch the bytes from the Blob URL using HttpRequest
  final request = await html.HttpRequest.request(videoPath, responseType: 'arraybuffer');
  final ByteBuffer buffer = request.response as ByteBuffer;

  // 2. Determine duration from a temporary VideoElement to allocate the correct context size
  double duration = 10.0; // Reasonable fallback duration (seconds)
  html.VideoElement? videoEl;
  try {
    videoEl = html.VideoElement()..src = videoPath;
    await videoEl.onLoadedMetadata.first.timeout(const Duration(seconds: 2));
    duration = videoEl.duration.toDouble();
  } catch (_) {
    // Keep fallback
  } finally {
    if (videoEl != null) {
      videoEl.src = '';
      try {
        videoEl.load();
      } catch (_) {}
    }
  }

  // Downsample sample rate dynamically for long videos to prevent browser memory exhaustion
  final int sampleRate = duration > 300.0 ? 8000 : 44100;
  final contextSamples = (duration * sampleRate).toInt().clamp(sampleRate, sampleRate * 3600 * 5); // Max 5 hours safety limit

  // 3. Decode using Web Audio API OfflineAudioContext with dynamic sample size
  final audioCtx = web_audio.OfflineAudioContext(1, contextSamples, sampleRate);
  
  // decodeAudioData is asynchronous and returns a Future
  final audioBuffer = await audioCtx.decodeAudioData(buffer);
  
  final floatData = audioBuffer.getChannelData(0); // Float32List

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
