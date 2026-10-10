import 'dart:math' as math;
import '../database/schemas/word.dart';
import 'viral_clip_models.dart';
import '../logger/logger_service.dart';
import '../plugins/plugin_manager_service.dart';
import 'package:uuid/uuid.dart';

class ViralHookDetector {
  // ────────────────────────────────────────────────────────────────────────────
  // 50+ real viral hook patterns across six engagement categories
  // ────────────────────────────────────────────────────────────────────────────
  static const Map<String, List<String>> _categorizedHooks = {
    'Curiosity Gap': [
      // English
      'what if i told you',
      'did you know that',
      'did you know',
      'have you ever wondered',
      'have you ever',
      'the reason why',
      'here is why',
      'here\'s why',
      'this is why',
      'why does',
      'why do most',
      // Spanish
      'sabías que',
      'sabias que',
      'te has preguntado',
      'por qué la mayoría',
      'esta es la razón',
      'esta es la razon',
      // Hindi / Hinglish
      'kya aap jante hain',
      'kya aap jaante ho',
      'kya aapko pata hai',
      'kya aapko pata tha',
      'ye kyu hota hai',
      'asli wajah',
      // French
      'saviez-vous que',
      'le saviez-vous',
      'vous êtes-vous déjà demandé',
      'voici pourquoi',
      // Arabic
      'هل تعلم أن',
      'هل تعلم',
      'لماذا يحدث',
      'السبب الحقيقي',
    ],
    'Action / Urgency': [
      // English
      'stop doing this',
      'stop doing',
      'never do this again',
      'never do this',
      'you need to stop',
      'you have to stop',
      'most people don\'t know',
      'most people dont know',
      'nobody tells you',
      'they don\'t want you to know',
      'they dont want you to know',
      'you\'re doing it wrong',
      'you are doing it wrong',
      'biggest mistake',
      'common mistake',
      // Spanish
      'deja de hacer esto',
      'nunca hagas esto',
      'tienes que parar',
      'la mayoría no sabe',
      'el mayor error',
      'error común',
      // Hindi / Hinglish
      'ye galti mat karna',
      'ye karna band karo',
      'sabse badi galti',
      'koi nahi batata',
      'har koi galat karta hai',
      // French
      'arrêtez de faire ça',
      'ne faites plus jamais',
      'la plus grande erreur',
      'personne ne vous dit',
      // Arabic
      'توقف عن فعل هذا',
      'لا تفعل هذا أبدا',
      'أكبر خطأ',
      'لا أحد يخبرك',
    ],
    'Value Promise': [
      // English
      'in the next',
      'by the end of this',
      'after watching this',
      'i went from',
      'how i made',
      'how i went from',
      'the secret to',
      'the key to',
      'step by step',
      'step-by-step',
      'here\'s how',
      'here is how',
      'how to',
      // Spanish
      'al final de este',
      'después de ver esto',
      'el secreto para',
      'cómo pasé de',
      'paso a paso',
      'así es como',
      // Hindi / Hinglish
      'is video ke baad',
      'step by step',
      'kaise karein',
      'secret trick',
      'sirf 2 minute mein',
      'seekho kaise',
      // French
      'à la fin de cette',
      'après avoir vu ça',
      'le secret pour',
      'étape par étape',
      'comment faire',
      // Arabic
      'في هذا الفيديو',
      'السر الحقيقي',
      'خطوة بخطوة',
      'كيف تصنع',
    ],
    'Controversy / Emotion': [
      // English
      'i was wrong about',
      'i can\'t believe',
      'i cant believe',
      'this changed everything',
      'this changed my life',
      'the truth about',
      'the real reason',
      'warning:',
      'be careful',
      'this is dangerous',
      'nobody talks about',
      'no one talks about',
      // Spanish
      'estaba equivocado sobre',
      'no puedo creer',
      'esto cambió todo',
      'esto cambió mi vida',
      'la verdad sobre',
      'nadie habla de',
      // Hindi / Hinglish
      'sach sun kar',
      'mujhe vishwas nahi hua',
      'isne sab badal diya',
      'asli sachai',
      'koi baat nahi karta',
      // French
      'j\'avais tort',
      'je n\'arrive pas à croire',
      'cela a tout changé',
      'la vérité sur',
      'personne n\'en parle',
      // Arabic
      'كنت مخطئا بشأن',
      'لا أستطيع تصديق',
      'هذا غير كل شيء',
      'الحقيقة حول',
    ],
    'Social Proof': [
      // English
      'went viral',
      'millions of people',
      'everyone is doing',
      'everyone is talking about',
      'trending right now',
      'gone viral',
      // Spanish
      'se volvió viral',
      'millones de personas',
      'todo el mundo habla de',
      'en tendencia',
      // Hindi / Hinglish
      'viral ho gaya',
      'lakho logo ne',
      'sab log baat kar rahe',
      'trending hai',
      // French
      'devenu viral',
      'des millions de personnes',
      'tout le monde en parle',
    ],
    'Numbers / Lists': [
      'number one reason',
      'number 1 reason',
      '3 things',
      '5 ways',
      '5 things',
      '10x',
      'top 3',
      'top 5',
      'top 10',
      '3 steps',
      '5 steps',
      '3 razones',
      '5 formas',
      '3 baatein',
      '5 tareeqe',
      '3 choses',
      '5 façons',
    ],
    'Pattern Interrupt': [
      // English
      'watch till the end',
      'watch to the end',
      'stay till the end',
      'this trick',
      'game changer',
      'life changing',
      'life-changing',
      'you won\'t believe',
      'you wont believe',
      'jaw dropping',
      'jaw-dropping',
      'mind blowing',
      'mind-blowing',
      'unbelievable',
      'incredible',
      'insane',
      'shocking',
      'never seen before',
      'nobody told me',
      'no one told me',
      'secret weapon',
      'hidden',
      'finally revealed',
      'exposed',
      'they lied about',
      'the real truth',
      // Spanish
      'mira hasta el final',
      'no te vas a creer',
      'increíble',
      'nadie me dijo',
      'por fin revelado',
      // Hindi / Hinglish
      'last tak dekhna',
      'end tak dekho',
      'ye trick dekho',
      'hosh ud jayenge',
      'kisi ne nahi bataya',
      // French
      'regardez jusqu\'à la fin',
      'vous n\'allez pas croire',
      'incroyable',
      'du jamais vu',
      // Arabic
      'شاهد حتى النهاية',
      'لن تصدق',
      'شيء لا يصدق',
    ],
  };

  static final List<String> _hookKeywords = [
    for (final list in _categorizedHooks.values) ...list,
  ];

  static const List<String> _narrativeOpeners = [
    'imagine', 'it started', 'first time', 'one day', 'originally', 'at the beginning',
    'so here', 'years ago', 'when i was', 'every day', 'think about', 'look at',
    'pehle', 'shuruat', 'ek bar', 'imaginons', 'au début', 'au debut', 'imagina', 'al principio',
  ];

  static const List<String> _narrativeTensions = [
    'but then', 'however', 'suddenly', 'the problem', 'disaster', 'failed', 'wrong',
    'crisis', 'unexpectedly', 'nobody expected', 'turning point', 'struggle', 'shockingly',
    'worst part', 'obstacle', 'hit a wall', 'went wrong', 'big mistake', 'danger',
    'par tab', 'lekin', 'mushkil', 'mais alors', 'le problème', 'pero entonces', 'el problema',
  ];

  static const List<String> _narrativeResolutions = [
    'finally', 'the result', 'in the end', 'that is why', 'now i know', 'turned out',
    'solution', 'takeaway', 'lesson', 'transformed', 'changed everything', 'success',
    'how to fix', 'the answer', 'worth it', 'unlocked', 'mastered',
    'aakhirkar', 'natija', 'samadhan', 'finalement', 'la solution', 'finalmente', 'el resultado',
  ];

  final _uuid = const Uuid();

  /// Identifies high-retention viral clip candidates using sentence and thought
  /// boundaries, hook keyword detection, acoustic energy profiling, narrative story arcs,
  /// speech pacing (WPM), and NMS deduplication.
  List<ViralClipCandidate> detectHooks({
    required List<WordSchema> words,
    List<double>? amplitudes,
    double totalDuration = 0.0,
    double minDuration = 20.0,
    double maxDuration = 60.0,
  }) {
    LoggerService.instance.log(
        LogLevel.info, 'ViralHookDetector', 'Starting hook detection on ${words.length} words');

    if (words.isEmpty) return [];

    final transcriptDuration = (words.last.end ?? words.last.start ?? 0.0) - (words.first.start ?? 0.0);
    final effectiveTotalDuration = totalDuration > 0 ? totalDuration : transcriptDuration;
    final effectiveMinDuration = (effectiveTotalDuration > 0 && effectiveTotalDuration < minDuration)
        ? math.max(3.0, effectiveTotalDuration * 0.4)
        : minDuration;
    final effectiveMaxDuration = (effectiveTotalDuration > 0 && effectiveTotalDuration < maxDuration)
        ? effectiveTotalDuration
        : maxDuration;

    // Pre-calculate natural sentence boundaries:
    // A word ends a thought if it has terminal punctuation (., !, ?) or is followed
    // by a natural pause (>= 0.35s).
    final isBoundary = List<bool>.filled(words.length, false);
    for (int i = 0; i < words.length; i++) {
      final text = (words[i].text ?? '').trim();
      final endsWithPunct = text.endsWith('.') || text.endsWith('!') || text.endsWith('?');
      if (endsWithPunct || i == words.length - 1) {
        isBoundary[i] = true;
      } else {
        final currentEnd = words[i].end ?? (words[i].start ?? 0.0);
        final nextStart = words[i + 1].start ?? currentEnd;
        if (nextStart - currentEnd >= 0.35) {
          isBoundary[i] = true;
        }
      }
    }

    // Candidate starting indices:
    // Prefer start of sentences or hook keywords.
    final startIndices = <int>{0};
    for (int i = 0; i < words.length - 1; i++) {
      if (isBoundary[i]) {
        startIndices.add(i + 1);
      }
    }

    // Also scan for hook keyword starts anywhere in the transcript
    final fullTextLower = words.map((w) => (w.text ?? '').toLowerCase()).toList();
    for (int i = 0; i < words.length; i++) {
      final joinedWindow = fullTextLower.skip(i).take(6).join(' ');
      for (final hook in _hookKeywords) {
        if (joinedWindow.startsWith(hook)) {
          startIndices.add(i);
          break;
        }
      }
    }

    // Scan for acoustic energy peaks across audio waveform to detect emotional climaxes
    if (amplitudes != null && amplitudes.isNotEmpty && totalDuration > 0) {
      double sumAmp = 0.0;
      for (final a in amplitudes) {
        sumAmp += a;
      }
      final avgAmp = sumAmp / amplitudes.length;
      final peakThreshold = math.max(0.25, avgAmp * 1.4);

      for (int i = 0; i < amplitudes.length; i += 5) {
        if (amplitudes[i] >= peakThreshold) {
          final peakTime = (i / amplitudes.length) * totalDuration;
          for (int w = 0; w < words.length; w++) {
            final wStart = words[w].start ?? 0.0;
            if (wStart <= peakTime && (peakTime - wStart) <= 5.0) {
              if (w == 0 || isBoundary[w - 1]) {
                startIndices.add(w);
                break;
              }
            }
          }
        }
      }
    }

    final rawCandidates = <ViralClipCandidate>[];
    final sortedStartIndices = startIndices.toList()..sort();

    for (final startIdx in sortedStartIndices) {
      if (startIdx >= words.length) continue;
      final startWord = words[startIdx];
      final clipStart = startWord.start ?? 0.0;

      int? bestBoundaryIdx;

      for (int i = startIdx; i < words.length; i++) {
        final endWord = words[i];
        final clipEnd = endWord.end ?? ((endWord.start ?? clipStart) + 0.1);
        final duration = clipEnd - clipStart;

        if (duration > effectiveMaxDuration) {
          // If we reached past max duration, check if we found any boundary before it
          break;
        }

        if (duration >= effectiveMinDuration) {
          if (isBoundary[i] || i == words.length - 1) {
            final candidateWords = words.sublist(startIdx, i + 1);
            final candidate = _evaluateCandidate(
              candidateWords,
              hasCleanBoundaries: isBoundary[i],
              amplitudes: amplitudes,
              totalDuration: totalDuration,
            );
            if (candidate != null) {
              rawCandidates.add(candidate);
              bestBoundaryIdx = i;
            }
          }
        }
      }

      // If no sentence boundary fell inside [effectiveMinDuration, effectiveMaxDuration],
      // take the maximum words fitting under effectiveMaxDuration as fallback.
      if (bestBoundaryIdx == null) {
        int lastFittingIdx = startIdx;
        for (int i = startIdx; i < words.length; i++) {
          final clipEnd = words[i].end ?? (words[i].start ?? clipStart);
          if (clipEnd - clipStart > effectiveMaxDuration) break;
          lastFittingIdx = i;
        }
        final dur = (words[lastFittingIdx].end ?? clipStart) - clipStart;
        if (dur >= effectiveMinDuration && lastFittingIdx > startIdx) {
          final candidateWords = words.sublist(startIdx, lastFittingIdx + 1);
          final candidate = _evaluateCandidate(
            candidateWords,
            hasCleanBoundaries: false,
            amplitudes: amplitudes,
            totalDuration: totalDuration,
          );
          if (candidate != null) {
            rawCandidates.add(candidate);
          }
        }
      }
    }

    // Sort raw candidates by score descending
    rawCandidates.sort((a, b) => b.score.compareTo(a.score));

    // Non-Maximum Suppression (NMS): filter out heavily overlapping candidates (> 60% overlap)
    final List<ViralClipCandidate> finalCandidates = [];
    for (final candidate in rawCandidates) {
      bool isOverlapping = false;
      for (final existing in finalCandidates) {
        final overlapStart = math.max(candidate.start, existing.start);
        final overlapEnd = math.min(candidate.end, existing.end);
        final overlap = math.max(0.0, overlapEnd - overlapStart);
        final minDur = math.min(candidate.duration, existing.duration);

        if (minDur > 0 && (overlap / minDur) > 0.60) {
          isOverlapping = true;
          break;
        }
      }
      if (!isOverlapping) {
        finalCandidates.add(candidate);
      }
    }

    LoggerService.instance.log(
        LogLevel.info, 'ViralHookDetector', 'Generated ${finalCandidates.length} candidates after NMS deduplication');

    return finalCandidates;
  }

  /// Calculates acoustic audio energy (0–25) using normalized waveform amplitudes.
  /// Analyzes root-mean-square (RMS) presence, dynamic contrast (speech cadence/variance),
  /// and dynamic peak punchiness.
  double calculateAcousticEnergy(
    double clipStart,
    double clipEnd,
    List<double>? amplitudes,
    double totalDuration,
  ) {
    if (amplitudes == null || amplitudes.isEmpty || totalDuration <= 0) {
      return 12.5; // neutral baseline when waveform has not been sampled
    }

    final startRatio = (clipStart / totalDuration).clamp(0.0, 1.0);
    final endRatio = (clipEnd / totalDuration).clamp(0.0, 1.0);

    final startIdx = (startRatio * amplitudes.length).floor().clamp(0, amplitudes.length - 1);
    final endIdx = (endRatio * amplitudes.length).ceil().clamp(startIdx + 1, amplitudes.length);

    final slice = amplitudes.sublist(startIdx, endIdx);
    if (slice.isEmpty) return 12.5;

    // 1. RMS Volume Presence (0.0 to 1.0)
    double sumSq = 0.0;
    double peak = 0.0;
    double sum = 0.0;
    for (final a in slice) {
      sumSq += a * a;
      sum += a;
      if (a > peak) peak = a;
    }
    final rms = math.sqrt(sumSq / slice.length);
    final mean = sum / slice.length;

    // 2. Dynamic Contrast (standard deviation: cadence & vocal modulation vs monotone flat audio)
    double varSum = 0.0;
    for (final a in slice) {
      final diff = a - mean;
      varSum += diff * diff;
    }
    final stdDev = math.sqrt(varSum / slice.length);

    // 3. Peak punchiness: dynamic bursts of speech/enthusiasm above baseline
    final punchiness = (peak - mean).clamp(0.0, 1.0);

    // RMS presence (up to 10 points): sweet spot around 0.25 - 0.70 normalized RMS
    final rmsScore = (rms * 15.0).clamp(0.0, 10.0);
    // Animated vocal contrast (up to 8 points)
    final varScore = (stdDev * 35.0).clamp(0.0, 8.0);
    // Burst punchiness (up to 7 points)
    final punchScore = (punchiness * 12.0).clamp(0.0, 7.0);

    return (rmsScore + varScore + punchScore).clamp(0.0, 25.0);
  }

  /// Evaluates 3-act narrative story arc structure:
  /// Act 1 (Opening 0–35%): Inciting Incident / Hook
  /// Act 2 (Middle 25–80%): Conflict / Tension / Obstacle
  /// Act 3 (Closing 65–100%): Payoff / Resolution / Transformation
  double calculateStoryArcScore(List<WordSchema> words) {
    if (words.length < 3) return 0.0;
    final start = words.first.start ?? 0.0;
    final end = words.last.end ?? (words.last.start ?? 0.0) + 0.1;
    final dur = end - start;
    if (dur <= 0) return 0.0;

    final act1Threshold = start + (dur * 0.35);
    final act2Start = start + (dur * 0.25);
    final act2End = start + (dur * 0.80);
    final act3Threshold = start + (dur * 0.65);

    final act1Words = words.where((w) => (w.start ?? start) <= act1Threshold);
    final act2Words = words.where((w) => (w.start ?? start) >= act2Start && (w.end ?? start) <= act2End);
    final act3Words = words.where((w) => (w.end ?? start) >= act3Threshold);

    final act1Text = act1Words.map((w) => (w.text ?? '').toLowerCase()).join(' ');
    final act2Text = act2Words.map((w) => (w.text ?? '').toLowerCase()).join(' ');
    final act3Text = act3Words.map((w) => (w.text ?? '').toLowerCase()).join(' ');

    double score = 0.0;

    // Act 1 check: Hook or narrative opening
    bool hasAct1Opener = false;
    for (final o in _narrativeOpeners) {
      if (act1Text.contains(o)) {
        hasAct1Opener = true;
        break;
      }
    }
    if (!hasAct1Opener) {
      for (final h in _hookKeywords) {
        if (act1Text.contains(h)) {
          hasAct1Opener = true;
          break;
        }
      }
    }
    if (hasAct1Opener) score += 9.0;

    // Act 2 check: Tension or Conflict
    bool hasAct2Tension = false;
    for (final t in _narrativeTensions) {
      if (act2Text.contains(t)) {
        hasAct2Tension = true;
        break;
      }
    }
    if (hasAct2Tension) score += 8.0;

    // Act 3 check: Payoff or Resolution
    bool hasAct3Payoff = false;
    for (final r in _narrativeResolutions) {
      if (act3Text.contains(r)) {
        hasAct3Payoff = true;
        break;
      }
    }
    if (hasAct3Payoff) score += 8.0;

    return score.clamp(0.0, 25.0);
  }

  static const Set<String> _stopWords = {
    'a', 'an', 'the', 'and', 'or', 'but', 'if', 'because', 'as', 'what',
    'which', 'this', 'that', 'these', 'those', 'then', 'so', 'than', 'such',
    'both', 'through', 'about', 'for', 'is', 'of', 'while', 'during', 'to',
    'with', 'at', 'by', 'from', 'in', 'into', 'on', 'onto', 'off', 'out',
    'over', 'under', 'again', 'further', 'once', 'here', 'there', 'when',
    'where', 'why', 'how', 'all', 'any', 'each', 'few', 'more',
    'most', 'other', 'some', 'no', 'nor', 'not', 'only', 'own', 'same',
    'too', 'very', 'can', 'will', 'just', 'should', 'now',
    'i', 'me', 'my', 'we', 'our', 'you', 'your', 'he', 'him', 'his', 'she',
    'her', 'it', 'its', 'they', 'them', 'their', 'words', 'word', 'like',
  };

  static String _extractTopic(List<WordSchema> words) {
    final counts = <String, int>{};
    for (final w in words) {
      final raw = (w.text ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (raw.length > 2 && !_stopWords.contains(raw)) {
        counts[raw] = (counts[raw] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return 'This';
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return _toTitleCase(sorted.first.key);
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return '';
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Generates a viral, high-CTR headline for the clip candidate.
  static String generateViralTitle(
    List<WordSchema> words, {
    String? detectedHook,
    String? detectedCategory,
  }) {
    final topic = _extractTopic(words);

    switch (detectedCategory) {
      case 'Curiosity Gap':
        return 'The Truth About $topic';
      case 'Action / Urgency':
        return 'Stop Making This $topic Mistake';
      case 'Value Promise':
        return 'How To Master $topic';
      case 'Pattern Interrupt':
        return 'This $topic Trick Changes Everything';
      case 'Secret / Insider':
        return 'The Untold Secret To $topic';
      case 'Listicle / Framework':
        return 'Top Ways To Level Up $topic';
      default:
        // 1. If first sentence is an opening question, use that question as the high-CTR title
        final firstSentenceWords = <String>[];
        for (int i = 0; i < words.length && i < 15; i++) {
          final t = (words[i].text ?? '').trim();
          firstSentenceWords.add(t);
          if (t.endsWith('?') || t.endsWith('!') || t.endsWith('.')) break;
        }
        final firstSentence = firstSentenceWords.join(' ').trim();
        if (firstSentence.endsWith('?') && firstSentenceWords.length >= 3 && firstSentenceWords.length <= 12) {
          return _toTitleCase(firstSentence);
        }
        if (detectedHook != null && detectedHook.isNotEmpty) {
          return _toTitleCase(detectedHook);
        }
        if (firstSentenceWords.length >= 4 && firstSentenceWords.length <= 10) {
          final cleanSentence = firstSentence.replaceAll(RegExp(r'[.!?,]'), '').trim();
          if (cleanSentence.isNotEmpty) {
            return _toTitleCase(cleanSentence);
          }
        }
        final text = words.take(5).map((w) => w.text ?? '').join(' ').trim();
        return text.isNotEmpty ? _toTitleCase(text) : 'Viral Clip';
    }
  }

  ViralClipCandidate? _evaluateCandidate(
    List<WordSchema> words, {
    bool hasCleanBoundaries = false,
    List<double>? amplitudes,
    double totalDuration = 0.0,
  }) {
    if (words.isEmpty) return null;

    final start = words.first.start ?? 0.0;
    final end = words.last.end ?? (words.last.start ?? 0.0) + 0.1;
    final duration = end - start;
    if (duration <= 0) return null;

    // ── Build full text ──────────────────────────────────────────────────────
    final textSegments = words.map((w) => w.text ?? '').where((t) => t.isNotEmpty).toList();
    final fullText = textSegments.join(' ');
    final lowerText = fullText.toLowerCase();

    // ── 1. WPM velocity scoring (optimal viral sweet spot 120–170 WPM) ────────
    final wordCount = textSegments.length;
    final wpm = (wordCount / duration) * 60.0;

    double wpmScore;
    if (wpm >= 120 && wpm <= 170) {
      wpmScore = 15.0; // optimal viral range
    } else if (wpm > 170 && wpm <= 200) {
      wpmScore = 10.0; // fast-paced
    } else if (wpm >= 100 && wpm < 120) {
      wpmScore = 8.0; // moderate
    } else if (wpm > 200) {
      wpmScore = 5.0; // too rushed
    } else {
      wpmScore = 3.0; // slow pacing
    }

    // ── 2. Hook keyword detection and categorization ─────────────────────────
    double hookScore = 0.0;
    String detectedHook = '';
    String detectedCategory = 'General Engagement';
    bool hookInFirstFive = false;

    final firstFiveWords = words.where((w) => (w.start ?? start) - start <= 5.0);
    final firstFiveText = firstFiveWords.map((w) => w.text ?? '').join(' ').toLowerCase();

    for (final entry in _categorizedHooks.entries) {
      final category = entry.key;
      for (final hook in entry.value) {
        if (lowerText.contains(hook)) {
          hookScore += (hookScore < 20.0) ? 20.0 : 10.0;
          if (detectedHook.isEmpty) {
            detectedHook = hook;
            detectedCategory = category;
          }
          if (!hookInFirstFive && firstFiveText.contains(hook)) {
            hookInFirstFive = true;
          }
        }
      }
    }

    // Check active custom creator pack & plugin hooks
    try {
      final customHooks = PluginManagerService.instance.getActiveCustomHooks();
      for (final ch in customHooks) {
        final reg = RegExp(ch.pattern, caseSensitive: false);
        if (reg.hasMatch(lowerText)) {
          hookScore += (hookScore < 20.0) ? ch.weight : (ch.weight * 0.5);
          if (detectedHook.isEmpty) {
            detectedHook = ch.tag.replaceAll('_', ' ').toUpperCase();
            detectedCategory = 'Creator Pack: ${ch.tag}';
          }
          if (!hookInFirstFive && reg.hasMatch(firstFiveText)) {
            hookInFirstFive = true;
          }
        }
      }
    } catch (_) {}

    hookScore = hookScore.clamp(0.0, 25.0);

    // ── 3. Acoustic Energy Profiling (0–25) ──────────────────────────────────
    final acousticEnergyScore = calculateAcousticEnergy(start, end, amplitudes, totalDuration);

    // ── 4. Narrative 3-Act Story Arc Scoring (0–25) ──────────────────────────
    final storyArcScore = calculateStoryArcScore(words);

    // ── 5. Question mark density (0–10) ──────────────────────────────────────
    final questionCount = '?'.allMatches(fullText).length;
    final questionScore = (questionCount * 5.0).clamp(0.0, 10.0);

    // ── 6. Sentence boundary scoring (0–8) ───────────────────────────────────
    double structureScore = hasCleanBoundaries ? 8.0 : 0.0;
    final trimmed = fullText.trim();
    if (!hasCleanBoundaries) {
      if (trimmed.endsWith('.') || trimmed.endsWith('!') || trimmed.endsWith('?')) {
        structureScore += 4.0;
      }
      final firstChar = trimmed.isNotEmpty ? trimmed[0] : '';
      if (firstChar.isNotEmpty && firstChar == firstChar.toUpperCase() && firstChar != firstChar.toLowerCase()) {
        structureScore += 4.0;
      }
    }

    // ── 7. Duration sweet spot (0–7) ─────────────────────────────────────────
    double durationScore = 0.0;
    if (duration >= 30.0 && duration <= 45.0) {
      durationScore = 7.0;
    } else if (duration >= 20.0 && duration < 30.0) {
      durationScore = 5.0;
    } else if (duration > 45.0 && duration <= 60.0) {
      durationScore = 3.0;
    } else if (duration >= 5.0 && duration < 20.0) {
      durationScore = 4.0;
    }

    // ── Composite score (0–100) ──────────────────────────────────────────────
    double total = hookScore                         // up to 25
        + (hookInFirstFive ? 15.0 : 0.0)             // +15 bonus if hook in first 5s
        + acousticEnergyScore                        // up to 25
        + storyArcScore                              // up to 25
        + wpmScore                                   // up to 15
        + questionScore                              // up to 10
        + structureScore                             // up to 8
        + durationScore;                             // up to 7
    // Theoretical raw max = 130 -> normalized to 100
    total = ((total / 130.0) * 100.0).clamp(0.0, 100.0);

    final summary = fullText.length > 80 ? '${fullText.substring(0, 77)}...' : fullText;

    // ── 8. Generate Viral Title ──────────────────────────────────────────────
    final viralTitle = generateViralTitle(
      words,
      detectedHook: detectedHook,
      detectedCategory: detectedCategory,
    );

    // ── 9. Generate OpusClip-style AI virality reasoning breakdown ───────────
    final reasons = <String>[];
    if (detectedHook.isNotEmpty) {
      if (hookInFirstFive) {
        reasons.add('High-impact "$detectedCategory" hook in opening 5s: "$detectedHook"');
      } else {
        reasons.add('Engaging "$detectedCategory" hook: "$detectedHook"');
      }
    }
    if (storyArcScore >= 16.0) {
      reasons.add('Complete 3-Act narrative structure (Hook -> Conflict -> Payoff) maximizes viewer retention');
    } else if (storyArcScore >= 8.0) {
      reasons.add('Strong narrative tension sustains curiosity');
    }
    if (acousticEnergyScore >= 16.0) {
      reasons.add('Dynamic acoustic energy & vocal punch prevent mid-video drop-off');
    } else if (acousticEnergyScore >= 10.0) {
      reasons.add('Consistent vocal presence and clear delivery');
    }
    if (wpm >= 130.0 && wpm <= 175.0) {
      reasons.add('Optimal viral pacing at ${wpm.round()} WPM maintains high retention');
    } else if (wpm > 175.0) {
      reasons.add('Fast-paced kinetic delivery (${wpm.round()} WPM) ideal for short attention spans');
    } else {
      reasons.add('Clear, measured articulation at ${wpm.round()} WPM');
    }
    if (questionCount > 0) {
      reasons.add('$questionCount provocative question${questionCount > 1 ? "s" : ""} drive comment section debate');
    }
    if (hasCleanBoundaries) {
      reasons.add('Clean narrative boundary starting and ending on complete sentence thoughts');
    }
    if (duration >= 30.0 && duration <= 45.0) {
      reasons.add('Sweet-spot duration (${duration.round()}s) optimized for TikTok/Reels algorithm completion rates');
    }

    return ViralClipCandidate(
      id: _uuid.v4(),
      start: start,
      end: end,
      duration: duration,
      score: total,
      hookText: detectedHook,
      hookCategory: detectedCategory,
      summary: summary,
      wordCount: wordCount,
      wordsPerMinute: wpm,
      hookScore: hookScore,
      energyScore: (acousticEnergyScore * 0.8).clamp(0.0, 20.0),
      wpmScore: wpmScore,
      hookInFirstFive: hookInFirstFive,
      questionCount: questionCount,
      hasCleanBoundaries: hasCleanBoundaries,
      viralityReasons: reasons,
      viralTitle: viralTitle,
      acousticEnergyScore: acousticEnergyScore,
      storyArcScore: storyArcScore,
    );
  }
}

