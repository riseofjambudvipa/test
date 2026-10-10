import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

class AudioSynthesizer {
  static List<int> generateWavBytes(int numSamples, int sampleRate, double Function(double t) synthFunc) {
    const numChannels = 1;
    const bitsPerSample = 16;
    final subchunk2Size = numSamples * numChannels * (bitsPerSample ~/ 8);
    final chunkSize = 36 + subchunk2Size;
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);

    final wavBuffer = Uint8List(44 + numSamples * 2);
    final byteData = ByteData.sublistView(wavBuffer);

    // RIFF header
    wavBuffer.setRange(0, 4, utf8.encode('RIFF'));
    
    // ChunkSize (4 bytes, offset 4)
    byteData.setUint32(4, chunkSize, Endian.little);

    // WAVEfmt
    wavBuffer.setRange(8, 16, utf8.encode('WAVEfmt '));

    // Subchunk1Size (16) (4 bytes, offset 16)
    byteData.setUint32(16, 16, Endian.little);

    // AudioFormat (1 = PCM) (2 bytes, offset 20)
    byteData.setUint16(20, 1, Endian.little);

    // NumChannels (1) (2 bytes, offset 22)
    byteData.setUint16(22, numChannels, Endian.little);

    // SampleRate (4 bytes, offset 24)
    byteData.setUint32(24, sampleRate, Endian.little);

    // ByteRate (4 bytes, offset 28)
    byteData.setUint32(28, byteRate, Endian.little);

    // BlockAlign (2 bytes, offset 32)
    byteData.setUint16(32, blockAlign, Endian.little);

    // BitsPerSample (16) (2 bytes, offset 34)
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // data
    wavBuffer.setRange(36, 40, utf8.encode('data'));

    // Subchunk2Size (4 bytes, offset 40)
    byteData.setUint32(40, subchunk2Size, Endian.little);

    // PCM samples (offset 44)
    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final raw = synthFunc(t);
      // FIX (audit): NaN.round() throws; guard so a misbehaving generator
      // can't crash synthesis. NaN.clamp() also yields NaN in Dart.
      final val = raw.isNaN ? 0.0 : raw.clamp(-1.0, 1.0);
      final sampleVal = (val * 32767).round();
      byteData.setInt16(offset, sampleVal, Endian.little);
      offset += 2;
    }

    return wavBuffer;
  }

  static List<int> generateWhooshFast(int sr) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sr * 0.35).round(), sr,
      (t) {
        final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 12);
        final freq = 800 + (1 - t / 0.35) * 1200;
        return math.sin(2 * math.pi * freq * t) * 0.5 * env +
               (rng.nextDouble() - 0.5) * 0.3 * env;
      },
    );
  }

  static List<int> generateWhooshSlow(int sr) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sr * 0.7).round(), sr,
      (t) {
        final d = 0.7;
        final env = t < 0.1 ? t / 0.1 : math.exp(-(t - 0.1) * 4);
        final freq = 400 + (1 - t / d) * 800;
        return math.sin(2 * math.pi * freq * t) * 0.4 * env +
               (rng.nextDouble() - 0.5) * 0.25 * env;
      },
    );
  }

  static List<int> generateSwipe(int sr, bool leftToRight) => generateWavBytes(
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

  static List<int> generateSweepUp(int sr) => generateWavBytes(
    (sr * 0.5).round(), sr,
    (t) {
      final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 5);
      final freq = 200 + t / 0.5 * 2000;
      return (math.sin(2 * math.pi * freq * t) * 0.4 +
              math.sin(2 * math.pi * freq * 2 * t) * 0.15) * env;
    },
  );

  static List<int> generateSweepDown(int sr) => generateWavBytes(
    (sr * 0.5).round(), sr,
    (t) {
      final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 5);
      final freq = 2200 - t / 0.5 * 2000;
      return (math.sin(2 * math.pi * freq * t) * 0.4 +
              math.sin(2 * math.pi * freq * 2 * t) * 0.15) * env;
    },
  );

  static List<int> generatePop(int sampleRate) {
    final duration = 0.15;
    final numSamples = (duration * sampleRate).toInt();
    double phase = 0.0;
    return generateWavBytes(numSamples, sampleRate, (t) {
      final progress = t / duration;
      final freq = 1800.0 * math.exp(-12.0 * progress);
      phase += 2.0 * math.pi * freq / sampleRate;
      final envelope = math.exp(-18.0 * t);
      return math.sin(phase) * envelope * 0.8;
    });
  }

  static List<int> generatePopDeep(int sr) => generateWavBytes(
    (sr * 0.3).round(), sr,
    (t) {
      final env = math.exp(-t * 20);
      final freq = 120 - t * 80;
      return math.sin(2 * math.pi * freq.clamp(20, 200) * t) * env;
    },
  );

  static List<int> generateBoom(int sr) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sr * 0.8).round(), sr,
      (t) {
        final env = t < 0.01 ? t / 0.01 : math.exp(-(t - 0.01) * 6);
        final noise = (rng.nextDouble() - 0.5);
        final sub = math.sin(2 * math.pi * 60 * t);
        return (noise * 0.6 + sub * 0.4) * env;
      },
    );
  }

  static List<int> generateThud(int sr) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sr * 0.4).round(), sr,
      (t) {
        final env = math.exp(-t * 15);
        final freq = 80 - t * 40;
        return (math.sin(2 * math.pi * freq.clamp(20, 100) * t) * 0.7 +
                (rng.nextDouble() - 0.5) * 0.3) * env;
      },
    );
  }

  static List<int> generatePunch(int sr) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sr * 0.2).round(), sr,
      (t) {
        final env = math.exp(-t * 25);
        return ((rng.nextDouble() - 0.5) * 0.8 +
                math.sin(2 * math.pi * 150 * t) * 0.2) * env;
      },
    );
  }

  static List<int> generateStamp(int sr) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sr * 0.25).round(), sr,
      (t) {
        final env = t < 0.005 ? 1.0 : math.exp(-(t - 0.005) * 30);
        return ((rng.nextDouble() - 0.5) * 0.9 +
                math.sin(2 * math.pi * 200 * t) * 0.1) * env;
      },
    );
  }

  static List<int> generateBell(int sampleRate) {
    final duration = 1.0;
    final numSamples = (duration * sampleRate).toInt();
    return generateWavBytes(numSamples, sampleRate, (t) {
      final envelope = math.exp(-3.5 * t);
      return (math.sin(2.0 * math.pi * 987.77 * t) + 0.45 * math.sin(2.0 * math.pi * 1480.0 * t)) * envelope * 0.5;
    });
  }

  static List<int> generateChime(int sampleRate) {
    final duration = 1.2;
    final numSamples = (duration * sampleRate).toInt();
    return generateWavBytes(numSamples, sampleRate, (t) {
      final envelope = math.exp(-2.2 * t);
      final vibrato = 1.0 + 0.03 * math.sin(2.0 * math.pi * 7.5 * t);
      return (math.sin(2.0 * math.pi * 1320.0 * vibrato * t) + 0.35 * math.sin(2.0 * math.pi * 1760.0 * t)) * envelope * 0.4;
    });
  }

  static List<int> generateBlip(int sampleRate) {
    final duration = 0.1;
    final numSamples = (duration * sampleRate).toInt();
    return generateWavBytes(numSamples, sampleRate, (t) {
      final progress = t / duration;
      final envelope = math.sin(math.pi * progress);
      final fundamental = math.sin(2.0 * math.pi * 2400.0 * t);
      final overtone = 0.3 * math.sin(2.0 * math.pi * 3600.0 * t);
      return (fundamental + overtone) * envelope * 0.55;
    });
  }

  static List<int> generateDing(int sr) => generateWavBytes(
    (sr * 0.8).round(), sr,
    (t) {
      final env = math.exp(-t * 4);
      return (math.sin(2 * math.pi * 880 * t) * 0.6 +
              math.sin(2 * math.pi * 1760 * t) * 0.3 +
              math.sin(2 * math.pi * 2640 * t) * 0.1) * env;
    },
  );

  static List<int> generatePing(int sr) => generateWavBytes(
    (sr * 0.5).round(), sr,
    (t) {
      final env = math.exp(-t * 6);
      return (math.sin(2 * math.pi * 1200 * t) * 0.7 +
              math.sin(2 * math.pi * 2400 * t) * 0.3) * env;
    },
  );

  static List<int> generateDrop(int sr) => generateWavBytes(
    (sr * 0.3).round(), sr,
    (t) {
      final env = math.exp(-t * 12);
      final freq = 2000 - t / 0.3 * 1500;
      return math.sin(2 * math.pi * freq.clamp(500, 2000) * t) * env * 0.6;
    },
  );

  static List<int> generateBoing(int sampleRate) {
    final duration = 0.5;
    final numSamples = (duration * sampleRate).toInt();
    double phase = 0.0;
    return generateWavBytes(numSamples, sampleRate, (t) {
      final freqMod = math.sin(2.0 * math.pi * 8.0 * t) * 200.0 * math.exp(-4.0 * t);
      final freq = 400.0 + freqMod;
      phase += 2.0 * math.pi * freq / sampleRate;
      final envelope = math.exp(-5.0 * t);
      return math.sin(phase) * envelope * 0.65;
    });
  }

  static List<int> generateBounce(int sr) => generateWavBytes(
    (sr * 0.4).round(), sr,
    (t) {
      final env = math.exp(-t * 8);
      final bounceCycle = (t * 15) % 1.0;
      final freq = 200 + (1 - bounceCycle) * 300;
      return math.sin(2 * math.pi * freq * t) * env * 0.6;
    },
  );

  static List<int> generateSqueak(int sr) => generateWavBytes(
    (sr * 0.25).round(), sr,
    (t) {
      final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 10);
      final freq = 1200 + math.sin(2 * math.pi * 8 * t) * 400;
      return math.sin(2 * math.pi * freq * t) * env * 0.5;
    },
  );

  static List<int> generateCoin(int sr) => generateWavBytes(
    (sr * 0.4).round(), sr,
    (t) {
      final env = math.exp(-t * 8);
      return (math.sin(2 * math.pi * 1046 * t) * 0.5 +
              math.sin(2 * math.pi * 1318 * t) * 0.3 +
              math.sin(2 * math.pi * 1568 * t) * 0.2) * env;
    },
  );

  static List<int> generateSparkle(int sr) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sr * 0.5).round(), sr,
      (t) {
        final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 5);
        final base = 1800 + math.sin(2 * math.pi * 15 * t) * 600;
        final noise = (rng.nextDouble() - 0.5) * 0.1;
        return (math.sin(2 * math.pi * base * t) * 0.5 + noise) * env;
      },
    );
  }

  static List<int> generateGlitch(int sr) {
    final rng = math.Random(42);
    final seededRng = math.Random(1337);
    return generateWavBytes(
      (sr * 0.3).round(), sr,
      (t) {
        final env = math.exp(-t * 8);
        final freq = (seededRng.nextDouble() * 2000 + 200) * (1 + (t * 10).floor() * 0.3);
        return (math.sin(2 * math.pi * freq * t) * 0.4 +
                (rng.nextDouble() - 0.5) * 0.5) * env;
      },
    );
  }

  static List<int> generateRise(int sr) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sr * 1.5).round(), sr,
      (t) {
        final d = 1.5;
        final env = t < 0.1 ? t / 0.1 : (t > 1.3 ? (d - t) / 0.2 : 1.0);
        final freq = 100 + (t / d) * 800;
        return (math.sin(2 * math.pi * freq * t) * 0.3 +
                math.sin(2 * math.pi * freq * 2 * t) * 0.2 +
                (rng.nextDouble() - 0.5) * 0.1) * env.clamp(0.0, 1.0);
      },
    );
  }

  static List<int> generateTension(int sr) => generateWavBytes(
    (sr * 1.0).round(), sr,
    (t) {
      final env = t < 0.2 ? t / 0.2 : (t > 0.8 ? (1.0 - t) / 0.2 : 1.0);
      return (math.sin(2 * math.pi * 220 * t) * 0.4 +
              math.sin(2 * math.pi * 221 * t) * 0.4) * env.clamp(0.0, 1.0);
    },
  );

  static List<int> generateBassDrop(int sr) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sr * 0.6).round(), sr,
      (t) {
        final env = t < 0.01 ? t / 0.01 : math.exp(-(t - 0.01) * 4);
        final freq = 60 + t * 20;
        return (math.sin(2 * math.pi * freq * t) * 0.8 +
                (rng.nextDouble() - 0.5) * 0.2) * env;
      },
    );
  }

  static List<int> generateReverse(int sr) {
    final fwd = generateWhooshFast(sr);
    final header = fwd.sublist(0, 44);
    final samples = fwd.sublist(44);
    final len = samples.length;
    
    final rev = Uint8List(len);
    int revIdx = 0;
    final startIdx = len % 2 == 0 ? len - 2 : len - 3;
    for (int i = startIdx; i >= 0; i -= 2) {
      rev[revIdx++] = samples[i];
      rev[revIdx++] = samples[i + 1];
    }
    
    final combined = Uint8List(44 + len);
    combined.setRange(0, 44, header);
    combined.setRange(44, 44 + len, rev);
    return combined;
  }

  static List<int> generateEcho(int sampleRate) {
    final duration = 0.6;
    final numSamples = (duration * sampleRate).toInt();
    double phase = 0.0;
    return generateWavBytes(numSamples, sampleRate, (t) {
      final progress = t / duration;
      final freq = 200.0 + 1000.0 * progress * progress;
      phase += 2.0 * math.pi * freq / sampleRate;
      final envelope = math.sin(math.pi * progress);
      final echo1 = t > 0.15 ? math.sin(phase - 0.15 * 2.0 * math.pi * 600) * 0.25 * math.exp(-(t - 0.15) * 6) : 0.0;
      final echo2 = t > 0.30 ? math.sin(phase - 0.30 * 2.0 * math.pi * 600) * 0.10 * math.exp(-(t - 0.30) * 8) : 0.0;
      return (math.sin(phase) * envelope * 0.45 + echo1 + echo2).clamp(-1.0, 1.0);
    });
  }

  static List<int> generateWhoosh(int sampleRate) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sampleRate * 0.5).round(), sampleRate,
      (t) {
        final d = 0.5;
        final env = t < 0.08 ? t / 0.08 : math.exp(-(t - 0.08) * 7);
        final freq = 900.0 - (t / d) * 550.0;
        final tonal = math.sin(2 * math.pi * freq * t) * 0.35;
        final noise = (rng.nextDouble() - 0.5) * 0.45;
        return (tonal + noise) * env;
      },
    );
  }

  static List<int> generateSweep(int sampleRate) {
    final duration = 0.9;
    final numSamples = (duration * sampleRate).toInt();
    double phase1 = 0.0;
    double phase2 = 0.0;
    return generateWavBytes(numSamples, sampleRate, (t) {
      final progress = t / duration;
      final freq1 = 120.0 + 2280.0 * progress * progress;
      final vibrato = 1.0 + 0.02 * math.sin(2 * math.pi * 6 * t);
      final freq2 = freq1 * 1.5 * vibrato;
      phase1 += 2.0 * math.pi * freq1 / sampleRate;
      phase2 += 2.0 * math.pi * freq2 / sampleRate;
      final env = progress < 0.1
          ? progress / 0.1
          : (progress > 0.85 ? (1.0 - progress) / 0.15 : 1.0);
      return (math.sin(phase1) * 0.45 + math.sin(phase2) * 0.2) * env.clamp(0.0, 1.0);
    });
  }

  static List<int> generateTapeStop(int sr) => generateWavBytes(
    (sr * 0.8).round(), sr,
    (t) {
      final d = 0.8;
      final env = math.exp(-t * 3);
      final freq = 440 * math.pow(0.1, t / d);
      return math.sin(2 * math.pi * freq.clamp(20, 440) * t) * env * 0.5;
    },
  );

  static List<int> generateLevelUp(int sr) => generateWavBytes(
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

  static List<int> generateFail(int sr) => generateWavBytes(
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

  static List<int> generateCorrect(int sr) => generateWavBytes(
    (sr * 0.5).round(), sr,
    (t) {
      final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 6);
      return (math.sin(2 * math.pi * 880 * t) * 0.5 +
              math.sin(2 * math.pi * 1109 * t) * 0.5) * env;
    },
  );

  static List<int> generateWrong(int sr) => generateWavBytes(
    (sr * 0.4).round(), sr,
    (t) {
      final env = t < 0.02 ? t / 0.02 : math.exp(-(t - 0.02) * 8);
      return (math.sin(2 * math.pi * 196 * t) * 0.5 +
              math.sin(2 * math.pi * 185 * t) * 0.5) * env;
    },
  );

  static List<int> generatePowerUp(int sr) => generateWavBytes(
    (sr * 0.7).round(), sr,
    (t) {
      final d = 0.7;
      final env = t < 0.1 ? t / 0.1 : (t > 0.5 ? (d - t) / 0.2 : 1.0);
      final freq = 200 + (t / d) * 1600;
      return (math.sin(2 * math.pi * freq * t) * 0.5 +
              math.sin(2 * math.pi * freq * 2 * t) * 0.2) * env.clamp(0.0, 1.0);
    },
  );

  static List<int> generateGameOver(int sr) => generateWavBytes(
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

  static List<int> generateSwishFuturistic(int sr) => generateWavBytes(
    (sr * 0.4).round(), sr,
    (t) {
      final env = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 8);
      final fm = math.sin(2 * math.pi * 35 * t) * 300;
      final freq = 1200.0 - t * 800.0 + fm;
      return math.sin(2 * math.pi * freq * t) * 0.4 * env;
    },
  );

  static List<int> generateSparkleMagical(int sr) => generateWavBytes(
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

  static List<int> generateCymbalSwell(int sr) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sr * 1.0).round(), sr,
      (t) {
        final env = t < 0.75 ? math.pow(t / 0.75, 3.0) : math.exp(-(t - 0.75) * 12);
        final noise = (rng.nextDouble() - 0.5);
        return noise * env * 0.55;
      },
    );
  }

  static List<int> generateLaserShot(int sr) => generateWavBytes(
    (sr * 0.2).round(), sr,
    (t) {
      final env = math.exp(-t * 15);
      final freq = 2800.0 * math.exp(-18.0 * t) + 150.0;
      return math.sin(2 * math.pi * freq * t) * env * 0.7;
    },
  );

  static List<int> generateHeavyImpact(int sr) {
    final rng = math.Random(42);
    return generateWavBytes(
      (sr * 0.5).round(), sr,
      (t) {
        final punchEnv = math.exp(-t * 30);
        final subEnv = math.exp(-t * 8);
        final punchNoise = (rng.nextDouble() - 0.5) * punchEnv * 0.7;
        final subBass = math.sin(2 * math.pi * 55 * t) * subEnv * 0.4;
        return punchNoise + subBass;
      },
    );
  }

  static List<int> generateSynthChime(int sr) => generateWavBytes(
    (sr * 0.7).round(), sr,
    (t) {
      final env = math.exp(-t * 4.5);
      final mod = math.sin(2 * math.pi * 220 * t) * 4.0 * math.exp(-t * 6);
      final car = math.sin(2 * math.pi * 659.25 * t + mod);
      return car * env * 0.5;
    },
  );
}
