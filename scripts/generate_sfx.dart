// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as p;

void main() async {
  print('=== CapStudio Sound Effects Pre-Baker & Generator ===');
  
  // Dynamically resolve project root (from CWD or script directory)
  Directory projectRootDir = Directory.current;
  if (!File(p.join(projectRootDir.path, 'pubspec.yaml')).existsSync()) {
    final scriptDir = File(Platform.script.toFilePath()).parent;
    var searchDir = scriptDir;
    bool found = false;
    for (int i = 0; i < 5; i++) {
      if (File(p.join(searchDir.path, 'pubspec.yaml')).existsSync()) {
        projectRootDir = searchDir;
        found = true;
        break;
      }
      searchDir = searchDir.parent;
    }
    if (!found) {
      print('ERROR: Could not locate pubspec.yaml. Please run from within the CapStudio repository.');
      exit(1);
    }
  }

  final sfxDir = Directory(p.join(projectRootDir.path, 'assets', 'sfx'));
  if (!sfxDir.existsSync()) {
    sfxDir.createSync(recursive: true);
    print('Created directory: ${sfxDir.path}');
  }

  final sampleRate = 22050;
  final Map<String, List<int> Function(int)> generators = {
    // ── Whoosh family ────────────────────────────────────────────
    'whoosh_fast':  _generateWhooshFast,
    'whoosh_slow':  _generateWhooshSlow,
    'whoosh':       _generateWhoosh,       // unique: mid-speed air turbulence whoosh
    // ── Swipe & Sweep family ─────────────────────────────────────
    'swipe_left':   (sr) => _generateSwipe(sr, true),
    'swipe_right':  (sr) => _generateSwipe(sr, false),
    'sweep_up':     _generateSweepUp,
    'sweep_down':   _generateSweepDown,
    'sweep':        _generateSweep,        // unique: sine sweep with harmonic shimmer
    'echo':         _generateEcho,         // unique: delay echo effect
    // ── Impact family ────────────────────────────────────────────
    'pop':          _generatePop,
    'pop_deep':     _generatePopDeep,
    'boom':         _generateBoom,
    'thud':         _generateThud,
    'punch':        _generatePunch,
    'stamp':        _generateStamp,
    // ── Tonal / Bell family ────────────────────────────────────────
    'bell':         _generateBell,
    'chime':        _generateChime,
    'blip':         _generateBlip,
    'ding':         _generateDing,
    'ping':         _generatePing,
    // ── Quirky / Fun family ────────────────────────────────────────
    'drop':         _generateDrop,
    'boing':        _generateBoing,
    'bounce':       _generateBounce,
    'squeak':       _generateSqueak,
    'coin':         _generateCoin,
    'sparkle':      _generateSparkle,
    'glitch':       _generateGlitch,
    // ── Cinematic / Mood family ──────────────────────────────────
    'rise':         _generateRise,
    'tension':      _generateTension,
    'drop_bass':    _generateBassDrop,
    'reverse':      (_) => _generateReverse(sampleRate),
    'tape_stop':    _generateTapeStop,
    // ── Game / UI family ───────────────────────────────────────────
    'level_up':     _generateLevelUp,
    'fail':         _generateFail,
    'correct':      _generateCorrect,
    'wrong':        _generateWrong,
    'power_up':     _generatePowerUp,
    'game_over':    _generateGameOver,
    // ── Premium SFX ───────────────────────────────────────────────
    'swish_futuristic': _generateSwishFuturistic,
    'sparkle_magical':  _generateSparkleMagical,
    'cymbal_swell':     _generateCymbalSwell,
    'laser_shot':       _generateLaserShot,
    'heavy_impact':     _generateHeavyImpact,
    'synth_chime':      _generateSynthChime,
  };

  print('Generating ${generators.length} high-fidelity sound effects into: ${sfxDir.path}...\n');

  int count = 0;
  for (final entry in generators.entries) {
    final sfxId = entry.key;
    final file = File(p.join(sfxDir.path, '$sfxId.wav'));
    
    print('  [GEN] $sfxId.wav...');
    final bytes = entry.value(sampleRate);
    await file.writeAsBytes(bytes);
    
    final kb = (bytes.length / 1024).toStringAsFixed(1);
    print('        -> Completed ($kb KB)');
    count++;
  }

  // All sounds are uniquely synthesized — no aliases or copies needed.
  
  print('\nSuccessfully pre-baked $count sound effects in assets/sfx!');
}

// --- WAV Synthesis Algorithms ---

List<int> _generateWavBytes(int numSamples, int sampleRate, double Function(double t) synthFunc) {
  final numChannels = 1;
  final bitsPerSample = 16;
  final subchunk2Size = numSamples * numChannels * (bitsPerSample ~/ 8);
  final chunkSize = 36 + subchunk2Size;
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);

  final bytes = <int>[];
  bytes.addAll(utf8.encode('RIFF'));
  
  // ChunkSize
  bytes.add(chunkSize & 0xFF);
  bytes.add((chunkSize >> 8) & 0xFF);
  bytes.add((chunkSize >> 16) & 0xFF);
  bytes.add((chunkSize >> 24) & 0xFF);
  
  bytes.addAll(utf8.encode('WAVEfmt '));
  
  // Subchunk1Size (16)
  bytes.add(16); bytes.add(0); bytes.add(0); bytes.add(0);
  // AudioFormat (1 = PCM)
  bytes.add(1); bytes.add(0);
  // NumChannels (1)
  bytes.add(numChannels); bytes.add(0);
  // SampleRate
  bytes.add(sampleRate & 0xFF);
  bytes.add((sampleRate >> 8) & 0xFF);
  bytes.add((sampleRate >> 16) & 0xFF);
  bytes.add((sampleRate >> 24) & 0xFF);
  // ByteRate
  bytes.add(byteRate & 0xFF);
  bytes.add((byteRate >> 8) & 0xFF);
  bytes.add((byteRate >> 16) & 0xFF);
  bytes.add((byteRate >> 24) & 0xFF);
  // BlockAlign
  bytes.add(blockAlign); bytes.add(0);
  // BitsPerSample (16)
  bytes.add(bitsPerSample); bytes.add(0);
  
  bytes.addAll(utf8.encode('data'));
  
  // Subchunk2Size
  bytes.add(subchunk2Size & 0xFF);
  bytes.add((subchunk2Size >> 8) & 0xFF);
  bytes.add((subchunk2Size >> 16) & 0xFF);
  bytes.add((subchunk2Size >> 24) & 0xFF);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final val = synthFunc(t);
    final sampleVal = (val.clamp(-1.0, 1.0) * 32767).round();
    bytes.add(sampleVal & 0xFF);
    bytes.add((sampleVal >> 8) & 0xFF);
  }

  return bytes;
}

List<int> _generateWhooshFast(int sr) => _generateWavBytes(
  (sr * 0.35).round(), sr,
  (t) {
    final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 12);
    final freq = 800 + (1 - t / 0.35) * 1200;
    return math.sin(2 * math.pi * freq * t) * 0.5 * env +
           (math.Random().nextDouble() - 0.5) * 0.3 * env;
  },
);

List<int> _generateWhooshSlow(int sr) => _generateWavBytes(
  (sr * 0.7).round(), sr,
  (t) {
    final d = 0.7;
    final env = t < 0.1 ? t / 0.1 : math.exp(-(t - 0.1) * 4);
    final freq = 400 + (1 - t / d) * 800;
    return math.sin(2 * math.pi * freq * t) * 0.4 * env +
           (math.Random().nextDouble() - 0.5) * 0.25 * env;
  },
);

List<int> _generateSwipe(int sr, bool leftToRight) => _generateWavBytes(
  (sr * 0.25).round(), sr,
  (t) {
    final d = 0.25;
    final env = math.exp(-t * 8);
    final base = leftToRight ? 600.0 : 1200.0;
    final target = leftToRight ? 1200.0 : 600.0;
    final freq = base + (target - base) * (t / d);
    return math.sin(2 * math.pi * freq * t) * 0.5 * env;
  },
);

List<int> _generateSweepUp(int sr) => _generateWavBytes(
  (sr * 0.5).round(), sr,
  (t) {
    final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 5);
    final freq = 200 + t / 0.5 * 2000;
    return (math.sin(2 * math.pi * freq * t) * 0.4 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.15) * env;
  },
);

List<int> _generateSweepDown(int sr) => _generateWavBytes(
  (sr * 0.5).round(), sr,
  (t) {
    final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 5);
    final freq = 2200 - t / 0.5 * 2000;
    return (math.sin(2 * math.pi * freq * t) * 0.4 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.15) * env;
  },
);

List<int> _generatePop(int sampleRate) {
  final duration = 0.15;
  final numSamples = (duration * sampleRate).toInt();
  double phase = 0.0;
  return _generateWavBytes(numSamples, sampleRate, (t) {
    final progress = t / duration;
    final freq = 1800.0 * math.exp(-12.0 * progress);
    phase += 2.0 * math.pi * freq / sampleRate;
    final envelope = math.exp(-18.0 * t);
    return math.sin(phase) * envelope * 0.8;
  });
}

List<int> _generatePopDeep(int sr) => _generateWavBytes(
  (sr * 0.3).round(), sr,
  (t) {
    final env = math.exp(-t * 20);
    final freq = 120 - t * 80;
    return math.sin(2 * math.pi * freq.clamp(20, 200) * t) * env;
  },
);

List<int> _generateBoom(int sr) => _generateWavBytes(
  (sr * 0.8).round(), sr,
  (t) {
    final env = t < 0.01 ? t / 0.01 : math.exp(-(t - 0.01) * 6);
    final noise = (math.Random().nextDouble() - 0.5);
    final sub = math.sin(2 * math.pi * 60 * t);
    return (noise * 0.6 + sub * 0.4) * env;
  },
);

List<int> _generateThud(int sr) => _generateWavBytes(
  (sr * 0.4).round(), sr,
  (t) {
    final env = math.exp(-t * 15);
    final freq = 80 - t * 40;
    return (math.sin(2 * math.pi * freq.clamp(20, 100) * t) * 0.7 +
            (math.Random().nextDouble() - 0.5) * 0.3) * env;
  },
);

List<int> _generatePunch(int sr) => _generateWavBytes(
  (sr * 0.2).round(), sr,
  (t) {
    final env = math.exp(-t * 25);
    return ((math.Random().nextDouble() - 0.5) * 0.8 +
            math.sin(2 * math.pi * 150 * t) * 0.2) * env;
  },
);

List<int> _generateStamp(int sr) => _generateWavBytes(
  (sr * 0.25).round(), sr,
  (t) {
    final env = t < 0.005 ? 1.0 : math.exp(-(t - 0.005) * 30);
    return ((math.Random().nextDouble() - 0.5) * 0.9 +
            math.sin(2 * math.pi * 200 * t) * 0.1) * env;
  },
);

List<int> _generateBell(int sampleRate) {
  final duration = 1.0;
  final numSamples = (duration * sampleRate).toInt();
  return _generateWavBytes(numSamples, sampleRate, (t) {
    final envelope = math.exp(-3.5 * t);
    return (math.sin(2.0 * math.pi * 987.77 * t) + 0.45 * math.sin(2.0 * math.pi * 1480.0 * t)) * envelope * 0.5;
  });
}

List<int> _generateChime(int sampleRate) {
  final duration = 1.2;
  final numSamples = (duration * sampleRate).toInt();
  return _generateWavBytes(numSamples, sampleRate, (t) {
    final envelope = math.exp(-2.2 * t);
    final vibrato = 1.0 + 0.03 * math.sin(2.0 * math.pi * 7.5 * t);
    return (math.sin(2.0 * math.pi * 1320.0 * vibrato * t) + 0.35 * math.sin(2.0 * math.pi * 1760.0 * t)) * envelope * 0.4;
  });
}

List<int> _generateBlip(int sampleRate) {
  final duration = 0.1;
  final numSamples = (duration * sampleRate).toInt();
  return _generateWavBytes(numSamples, sampleRate, (t) {
    final progress = t / duration;
    final envelope = math.sin(math.pi * progress);
    final fundamental = math.sin(2.0 * math.pi * 2400.0 * t);
    final overtone = 0.3 * math.sin(2.0 * math.pi * 3600.0 * t);
    return (fundamental + overtone) * envelope * 0.55;
  });
}

List<int> _generateDing(int sr) => _generateWavBytes(
  (sr * 0.8).round(), sr,
  (t) {
    final env = math.exp(-t * 4);
    return (math.sin(2 * math.pi * 880 * t) * 0.6 +
            math.sin(2 * math.pi * 1760 * t) * 0.3 +
            math.sin(2 * math.pi * 2640 * t) * 0.1) * env;
  },
);

List<int> _generatePing(int sr) => _generateWavBytes(
  (sr * 0.5).round(), sr,
  (t) {
    final env = math.exp(-t * 6);
    return (math.sin(2 * math.pi * 1200 * t) * 0.7 +
            math.sin(2 * math.pi * 2400 * t) * 0.3) * env;
  },
);

List<int> _generateDrop(int sr) => _generateWavBytes(
  (sr * 0.3).round(), sr,
  (t) {
    final env = math.exp(-t * 12);
    final freq = 2000 - t / 0.3 * 1500;
    return math.sin(2 * math.pi * freq.clamp(500, 2000) * t) * env * 0.6;
  },
);

List<int> _generateBoing(int sampleRate) {
  final duration = 0.5;
  final numSamples = (duration * sampleRate).toInt();
  double phase = 0.0;
  return _generateWavBytes(numSamples, sampleRate, (t) {
    final freqMod = math.sin(2.0 * math.pi * 8.0 * t) * 200.0 * math.exp(-4.0 * t);
    final freq = 400.0 + freqMod;
    phase += 2.0 * math.pi * freq / sampleRate;
    final envelope = math.exp(-5.0 * t);
    return math.sin(phase) * envelope * 0.65;
  });
}

List<int> _generateBounce(int sr) => _generateWavBytes(
  (sr * 0.4).round(), sr,
  (t) {
    final env = math.exp(-t * 8);
    final bounceCycle = (t * 15) % 1.0;
    final freq = 200 + (1 - bounceCycle) * 300;
    return math.sin(2 * math.pi * freq * t) * env * 0.6;
  },
);

List<int> _generateSqueak(int sr) => _generateWavBytes(
  (sr * 0.25).round(), sr,
  (t) {
    final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 10);
    final freq = 1200 + math.sin(2 * math.pi * 8 * t) * 400;
    return math.sin(2 * math.pi * freq * t) * env * 0.5;
  },
);

List<int> _generateCoin(int sr) => _generateWavBytes(
  (sr * 0.4).round(), sr,
  (t) {
    final env = math.exp(-t * 8);
    return (math.sin(2 * math.pi * 1046 * t) * 0.5 +
            math.sin(2 * math.pi * 1318 * t) * 0.3 +
            math.sin(2 * math.pi * 1568 * t) * 0.2) * env;
  },
);

List<int> _generateSparkle(int sr) => _generateWavBytes(
  (sr * 0.5).round(), sr,
  (t) {
    final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 5);
    final base = 1800 + math.sin(2 * math.pi * 15 * t) * 600;
    final noise = (math.Random().nextDouble() - 0.5) * 0.1;
    return (math.sin(2 * math.pi * base * t) * 0.5 + noise) * env;
  },
);

List<int> _generateGlitch(int sr) => _generateWavBytes(
  (sr * 0.3).round(), sr,
  (t) {
    final env = math.exp(-t * 8);
    final rng = math.Random(42);
    final freq = (rng.nextDouble() * 2000 + 200) * (1 + (t * 10).floor() * 0.3);
    return (math.sin(2 * math.pi * freq * t) * 0.4 +
            (math.Random().nextDouble() - 0.5) * 0.5) * env;
  },
);

List<int> _generateRise(int sr) => _generateWavBytes(
  (sr * 1.5).round(), sr,
  (t) {
    final d = 1.5;
    final env = t < 0.1 ? t / 0.1 : (t > 1.3 ? (d - t) / 0.2 : 1.0);
    final freq = 100 + (t / d) * 800;
    return (math.sin(2 * math.pi * freq * t) * 0.3 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.2 +
            (math.Random().nextDouble() - 0.5) * 0.1) * env.clamp(0.0, 1.0);
  },
);

List<int> _generateTension(int sr) => _generateWavBytes(
  (sr * 1.0).round(), sr,
  (t) {
    final env = t < 0.2 ? t / 0.2 : (t > 0.8 ? (1.0 - t) / 0.2 : 1.0);
    return (math.sin(2 * math.pi * 220 * t) * 0.4 +
            math.sin(2 * math.pi * 221 * t) * 0.4) * env.clamp(0.0, 1.0);
  },
);

List<int> _generateBassDrop(int sr) => _generateWavBytes(
  (sr * 0.6).round(), sr,
  (t) {
    final env = t < 0.01 ? t / 0.01 : math.exp(-(t - 0.01) * 4);
    final freq = 60 + t * 20;
    return (math.sin(2 * math.pi * freq * t) * 0.8 +
            (math.Random().nextDouble() - 0.5) * 0.2) * env;
  },
);

List<int> _generateReverse(int sr) {
  final fwd = _generateWhooshFast(sr);
  final header = fwd.sublist(0, 44);
  final samples = fwd.sublist(44);
  final rev = <int>[];
  final len = samples.length;
  final startIdx = len % 2 == 0 ? len - 2 : len - 3;
  for (int i = startIdx; i >= 0; i -= 2) {
    rev.add(samples[i]);
    rev.add(samples[i + 1]);
  }
  return [...header, ...rev];
}

// Renamed from _generateSweep — this is the echo/delay-style upward sweep
List<int> _generateEcho(int sampleRate) {
  final duration = 0.6;
  final numSamples = (duration * sampleRate).toInt();
  double phase = 0.0;
  return _generateWavBytes(numSamples, sampleRate, (t) {
    final progress = t / duration;
    final freq = 200.0 + 1000.0 * progress * progress;
    phase += 2.0 * math.pi * freq / sampleRate;
    final envelope = math.sin(math.pi * progress);
    // Simulated echo: two decaying repeats at 0.15s and 0.30s offsets
    final echo1 = t > 0.15 ? math.sin(phase - 0.15 * 2.0 * math.pi * 600) * 0.25 * math.exp(-(t - 0.15) * 6) : 0.0;
    final echo2 = t > 0.30 ? math.sin(phase - 0.30 * 2.0 * math.pi * 600) * 0.10 * math.exp(-(t - 0.30) * 8) : 0.0;
    return (math.sin(phase) * envelope * 0.45 + echo1 + echo2).clamp(-1.0, 1.0);
  });
}

// Unique mid-speed whoosh — air turbulence burst, distinct from fast/slow variants
List<int> _generateWhoosh(int sampleRate) => _generateWavBytes(
  (sampleRate * 0.5).round(), sampleRate,
  (t) {
    final d = 0.5;
    // Bell-shaped envelope: ramps up then fades
    final env = t < 0.08 ? t / 0.08 : math.exp(-(t - 0.08) * 7);
    // Freq descends from 900 → 350 Hz (mid-range, not as extreme as fast/slow)
    final freq = 900.0 - (t / d) * 550.0;
    // Mix tonal sine + broadband noise for air texture
    final tonal = math.sin(2 * math.pi * freq * t) * 0.35;
    final noise = (math.Random().nextDouble() - 0.5) * 0.45;
    return (tonal + noise) * env;
  },
);

// Unique sweep — wide-band harmonic sine sweep with shimmer overtone
// Clearly distinct from sweep_up (short/sharp) and sweep_down (short/sharp)
List<int> _generateSweep(int sampleRate) {
  final duration = 0.9;
  final numSamples = (duration * sampleRate).toInt();
  double phase1 = 0.0;
  double phase2 = 0.0;
  return _generateWavBytes(numSamples, sampleRate, (t) {
    final progress = t / duration;
    // Fundamental sweeps 120 → 2400 Hz with quadratic acceleration
    final freq1 = 120.0 + 2280.0 * progress * progress;
    // Shimmer overtone sweeps at 1.5x with slight vibrato
    final vibrato = 1.0 + 0.02 * math.sin(2 * math.pi * 6 * t);
    final freq2 = freq1 * 1.5 * vibrato;
    phase1 += 2.0 * math.pi * freq1 / sampleRate;
    phase2 += 2.0 * math.pi * freq2 / sampleRate;
    // Smooth fade-in / fade-out envelope
    final env = progress < 0.1
        ? progress / 0.1
        : (progress > 0.85 ? (1.0 - progress) / 0.15 : 1.0);
    return (math.sin(phase1) * 0.45 + math.sin(phase2) * 0.2) * env.clamp(0.0, 1.0);
  });
}

List<int> _generateTapeStop(int sr) => _generateWavBytes(
  (sr * 0.8).round(), sr,
  (t) {
    final d = 0.8;
    final env = math.exp(-t * 3);
    final freq = 440 * math.pow(0.1, t / d);
    return math.sin(2 * math.pi * freq.clamp(20, 440) * t) * env * 0.5;
  },
);

List<int> _generateLevelUp(int sr) => _generateWavBytes(
  (sr * 0.8).round(), sr,
  (t) {
    final notes = [523.0, 659.0, 784.0, 1047.0];
    final noteLen = 0.2;
    final noteIdx = (t / noteLen).floor().clamp(0, notes.length - 1);
    final freq = notes[noteIdx];
    final localT = t - noteIdx * noteLen;
    final env = localT < 0.05 ? localT / 0.05 : math.exp(-(localT - 0.05) * 8);
    return (math.sin(2 * math.pi * freq * t) * 0.6 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.3) * env;
  },
);

List<int> _generateFail(int sr) => _generateWavBytes(
  (sr * 1.2).round(), sr,
  (t) {
    final notes = [392.0, 349.0, 311.0, 261.0];
    final noteLen = 0.3;
    final noteIdx = (t / noteLen).floor().clamp(0, notes.length - 1);
    final freq = notes[noteIdx];
    final localT = t - noteIdx * noteLen;
    final env = localT < 0.05 ? localT / 0.05 : math.exp(-(localT - 0.05) * 3);
    return (math.sin(2 * math.pi * freq * t) * 0.5 +
            math.sin(2 * math.pi * freq * 1.5 * t) * 0.3) * env;
  },
);

List<int> _generateCorrect(int sr) => _generateWavBytes(
  (sr * 0.5).round(), sr,
  (t) {
    final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 6);
    return (math.sin(2 * math.pi * 880 * t) * 0.5 +
            math.sin(2 * math.pi * 1109 * t) * 0.5) * env;
  },
);

List<int> _generateWrong(int sr) => _generateWavBytes(
  (sr * 0.4).round(), sr,
  (t) {
    final env = t < 0.02 ? t / 0.02 : math.exp(-(t - 0.02) * 8);
    return (math.sin(2 * math.pi * 196 * t) * 0.5 +
            math.sin(2 * math.pi * 185 * t) * 0.5) * env;
  },
);

List<int> _generatePowerUp(int sr) => _generateWavBytes(
  (sr * 0.7).round(), sr,
  (t) {
    final d = 0.7;
    final env = t < 0.1 ? t / 0.1 : (t > 0.5 ? (d - t) / 0.2 : 1.0);
    final freq = 200 + (t / d) * 1600;
    return (math.sin(2 * math.pi * freq * t) * 0.5 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.2) * env.clamp(0.0, 1.0);
  },
);

List<int> _generateGameOver(int sr) => _generateWavBytes(
  (sr * 1.5).round(), sr,
  (t) {
    final notes = [523.0, 494.0, 466.0, 392.0];
    final noteLen = 0.375;
    final noteIdx = (t / noteLen).floor().clamp(0, notes.length - 1);
    final freq = notes[noteIdx];
    final localT = t - noteIdx * noteLen;
    final env = localT < 0.03 ? localT / 0.03 : math.exp(-(localT - 0.03) * 5);
    return math.sin(2 * math.pi * freq * t) * 0.7 * env;
  },
);

// ── Premium SFX Generators ────────────────────────────────────────────────────

List<int> _generateSwishFuturistic(int sr) => _generateWavBytes(
  (sr * 0.4).round(), sr,
  (t) {
    final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 8);
    final fm = math.sin(2 * math.pi * 35 * t) * 300;
    final freq = 1200.0 - t * 800.0 + fm;
    return math.sin(2 * math.pi * freq * t) * 0.4 * env;
  },
);

List<int> _generateSparkleMagical(int sr) => _generateWavBytes(
  (sr * 0.6).round(), sr,
  (t) {
    final env = math.exp(-t * 5);
    final signal = math.sin(2 * math.pi * 1500 * t) * 0.3 +
                   math.sin(2 * math.pi * 2300 * t) * 0.25 +
                   math.sin(2 * math.pi * 3100 * t) * 0.2;
    final shimmer = 1.0 + 0.15 * math.sin(2 * math.pi * 45 * t);
    return signal * env * shimmer * 0.5;
  },
);

List<int> _generateCymbalSwell(int sr) => _generateWavBytes(
  (sr * 1.0).round(), sr,
  (t) {
    final env = t < 0.75 ? math.pow(t / 0.75, 3.0) : math.exp(-(t - 0.75) * 12);
    final noise = (math.Random().nextDouble() - 0.5);
    return noise * (env as double) * 0.55;
  },
);

List<int> _generateLaserShot(int sr) => _generateWavBytes(
  (sr * 0.2).round(), sr,
  (t) {
    final env = math.exp(-t * 15);
    final freq = 2800.0 * math.exp(-18.0 * t) + 150.0;
    return math.sin(2 * math.pi * freq * t) * env * 0.7;
  },
);

List<int> _generateHeavyImpact(int sr) => _generateWavBytes(
  (sr * 0.5).round(), sr,
  (t) {
    final punchEnv = math.exp(-t * 30);
    final subEnv   = math.exp(-t * 8);
    final punchNoise = (math.Random().nextDouble() - 0.5) * punchEnv * 0.7;
    final subBass    = math.sin(2 * math.pi * 55 * t) * subEnv * 0.4;
    return punchNoise + subBass;
  },
);

List<int> _generateSynthChime(int sr) => _generateWavBytes(
  (sr * 0.7).round(), sr,
  (t) {
    final env = math.exp(-t * 4.5);
    final mod = math.sin(2 * math.pi * 220 * t) * 4.0 * math.exp(-t * 6);
    final car = math.sin(2 * math.pi * 659.25 * t + mod);
    return car * env * 0.5;
  },
);
