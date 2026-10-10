// ignore_for_file: avoid_print
/// CapStudio Test Dashboard Generator
/// Runs: dart run scripts/generate_test_dashboard.dart [output_html_path]
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class SuiteInfo {
  final int id;
  final String path;
  SuiteInfo(this.id, this.path);
}

class TestInfo {
  final int id;
  final int suiteId;
  final String name;
  int startTime = 0;
  String result = 'pending';
  int duration = 0;
  String? errorMessage;
  String? stackTrace;
  final List<String> printOutput = [];
  TestInfo(this.id, this.suiteId, this.name);
}

void main(List<String> args) async {
  final outputPath = args.isNotEmpty
      ? args[0]
      : p.join(Directory.current.path, 'test_dashboard.html');

  final logFile = File(p.join(Directory.current.path, 'flutter_test.log'));
  if (logFile.existsSync()) {
    logFile.deleteSync();
  }

  final consoleBuffer = <String>[];
  void writeOut(String s) {
    stdout.writeln(s);
    consoleBuffer.add(s);
  }

  writeOut('┌────────────────────────────────────────────────────────┐');
  writeOut('│          CapStudio Live Test Suite Runner              │');
  writeOut('└────────────────────────────────────────────────────────┘\n');

  final suites  = <int, SuiteInfo>{};
  final tests   = <int, TestInfo>{};
  final startMs = DateTime.now().millisecondsSinceEpoch;

  int? currentTestId;
  final pendingStderr = <String>[];
  final printedSuites = <int>{};

  final flutterExe = 'flutter';
  final process = await Process.start(
    flutterExe, ['test', '--reporter', 'json'],
    workingDirectory: Directory.current.path,
    runInShell: Platform.isWindows,
  );

  final stderrLines = <String>[];
  process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    if (line.trim().isNotEmpty) {
      stderrLines.add(line);
      if (currentTestId != null && tests.containsKey(currentTestId)) {
        tests[currentTestId]!.printOutput.add(line);
      } else {
        pendingStderr.add(line);
      }
    }
  });

  await for (final line in process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    try {
      final event = jsonDecode(line);
      if (event is! Map<String, dynamic>) continue;
      
      final type  = event['type'] as String? ?? '';
      switch (type) {
        case 'suite':
          final s = event['suite'];
          if (s is Map<String, dynamic>) {
            suites[s['id'] as int] = SuiteInfo(s['id'] as int, s['path'] as String? ?? '');
          }
        case 'testStart':
          final t = event['test'];
          if (t is Map<String, dynamic>) {
            final ti = TestInfo(
              t['id'] as int,
              (t['suiteID'] as int?) ?? -1,
              t['name'] as String? ?? '',
            );
            ti.startTime = event['time'] as int? ?? 0;
            tests[ti.id] = ti;
            currentTestId = ti.id;

            if (pendingStderr.isNotEmpty) {
              ti.printOutput.addAll(pendingStderr);
              pendingStderr.clear();
            }

            if (!ti.name.startsWith('loading ') && ti.name != '(setUpAll)' && ti.name != '(tearDownAll)') {
              final suite = suites[ti.suiteId];
              final suitePath = suite != null ? suite.path : '';
              
              if (suite != null && !printedSuites.contains(ti.suiteId)) {
                printedSuites.add(ti.suiteId);
                writeOut('📂  \x1B[36m$suitePath\x1B[0m');
              }
              
              writeOut('  ├─ 🚀  \x1B[1mRunning:\x1B[0m ${ti.name}');
            }
          }
        case 'testDone':
          final tid = event['testID'] as int;
          if (tests.containsKey(tid)) {
            final ti = tests[tid]!;
            ti.result   = event['result'] as String? ?? 'error';
            ti.duration = (event['time'] as int? ?? 0) - ti.startTime;

            if (!ti.name.startsWith('loading ') && ti.name != '(setUpAll)' && ti.name != '(tearDownAll)') {
              final durStr = ti.duration < 1000 ? '${ti.duration}ms' : '${(ti.duration / 1000).toStringAsFixed(1)}s';

              if (ti.result == 'success') {
                writeOut('  │   └─  \x1B[32m✓ PASS ($durStr)\x1B[0m');
              } else {
                writeOut('  │   └─  \x1B[31m✗ FAIL ($durStr)\x1B[0m');
              }
            }
          }
          if (currentTestId == tid) currentTestId = null;
        case 'error':
          final tid = event['testID'] as int;
          if (tests.containsKey(tid)) {
            final err = event['error'] as String?;
            final st  = event['stackTrace'] as String?;
            tests[tid]!.errorMessage = err;
            if (st != null && st.trim().isNotEmpty) {
              final lines = st.split('\n');
              final truncated = lines.length > 20
                  ? [...lines.take(20), '… (${lines.length - 20} more lines)']
                  : lines;
              tests[tid]!.stackTrace = truncated.join('\n');
            }
          }
        case 'print':
          final tid = event['testID'] as int;
          final msg = event['message'] as String? ?? '';
          if (tests.containsKey(tid) && msg.trim().isNotEmpty) {
            tests[tid]!.printOutput.add(msg);
          }
      }
    } catch (_) {}
  }

  final exitCode = await process.exitCode;
  final totalMs  = DateTime.now().millisecondsSinceEpoch - startMs;

  final realTests = tests.values
      .where((t) =>
          !t.name.startsWith('loading ') &&
          t.name != '(setUpAll)' &&
          t.name != '(tearDownAll)')
      .toList();

  final passed = realTests.where((t) => t.result == 'success').length;
  final failed = realTests.where((t) => t.result != 'success').length;
  final total  = realTests.length;
  final pct    = total > 0 ? (passed / total * 100).toStringAsFixed(1) : '0.0';

  final bySuite = <int, List<TestInfo>>{};
  for (final t in realTests) {
    bySuite.putIfAbsent(t.suiteId, () => []).add(t);
  }

  if (failed > 0) {
    writeOut('\n\x1B[31m==============================================================================\x1B[0m');
    writeOut('\x1B[31m✗ DETAILED POST-MORTEM FOR FAILURES\x1B[0m');
    writeOut('\x1B[31m==============================================================================\x1B[0m');

    for (final t in realTests.where((t) => t.result != 'success')) {
      final suite = suites[t.suiteId];
      final suitePath = suite != null ? suite.path : 'unknown_suite.dart';
      
      var lineNum = '1';
      if (t.stackTrace != null) {
        final match = RegExp(r'_test\.dart:(\d+)').firstMatch(t.stackTrace!);
        if (match != null) {
          lineNum = match.group(1)!;
        }
      }

      final fileUri = 'file:///${Directory.current.absolute.path.replaceAll('\\', '/')}/$suitePath#L$lineNum';

      writeOut('\n✗ [FAIL] $suitePath > ${t.name}');
      writeOut('  📍  \x1B[1mLocation:\x1B[0m \x1B[4m$fileUri\x1B[0m');
      
      if (t.errorMessage != null) {
        writeOut('  ❓  \x1B[1mWhat Went Wrong:\x1B[0m');
        final errLines = t.errorMessage!.split('\n');
        for (final el in errLines) {
          writeOut('     $el');
        }
      }

      if (t.printOutput.isNotEmpty) {
        writeOut('  📋  \x1B[1mCaptured Logs:\x1B[0m');
        for (final logLine in t.printOutput) {
          final upperLine = logLine.toUpperCase();
          String formattedLogLine = logLine;
          
          if (upperLine.contains('[ERROR')) {
            formattedLogLine = logLine.replaceAll(RegExp(r'\[ERROR\s*\]'), '\x1B[1m\x1B[97m\x1B[41m ERROR  \x1B[0m');
          } else if (upperLine.contains('[WARN')) {
            formattedLogLine = logLine.replaceAll(RegExp(r'\[WARN\s*\]'), '\x1B[1m\x1B[30m\x1B[48;5;220m WARN   \x1B[0m');
          } else if (upperLine.contains('[ACTION')) {
            formattedLogLine = logLine.replaceAll(RegExp(r'\[ACTION\s*\]'), '\x1B[1m\x1B[38;5;170m[ACTION ]\x1B[0m');
          } else if (upperLine.contains('[INFO')) {
            formattedLogLine = logLine.replaceAll(RegExp(r'\[INFO\s*\]'), '\x1B[1m\x1B[38;5;39m[INFO   ]\x1B[0m');
          } else if (upperLine.contains('[DEBUG')) {
            formattedLogLine = logLine.replaceAll(RegExp(r'\[DEBUG\s*\]'), '\x1B[1m\x1B[38;5;75m[DEBUG  ]\x1B[0m');
          } else if (upperLine.contains('[TRACE')) {
            formattedLogLine = logLine.replaceAll(RegExp(r'\[TRACE\s*\]'), '\x1B[1m\x1B[38;5;244m[TRACE  ]\x1B[0m');
          }
          
          writeOut('     $formattedLogLine');
        }
      }

      if (t.stackTrace != null) {
        writeOut('  📍  \x1B[1mStack Trace:\x1B[0m');
        final stLines = t.stackTrace!.split('\n');
        for (final sl in stLines) {
          writeOut('     \x1B[90m$sl\x1B[0m');
        }
      }
      writeOut(' ──────────────────────────────────────────────────────────────────────────────');
    }
  }

  final barLen = 16;
  final filledLen = (double.parse(pct) / 100 * barLen).round();
  final emptyLen = barLen - filledLen;
  final barStr = '\x1B[32m${'█' * filledLen}\x1B[0m${' ' * emptyLen}';

  writeOut('\n┌────────────────────────────────────────────────────────┐');
  writeOut('│                   TEST RUN SUMMARY                     │');
  writeOut('├────────────────────────────────────────────────────────┤');
  writeOut('│  Passed Tests :  $passed / $total   [$barStr] $pct%   │');
  writeOut('│  Failed Tests :  $failed                                   │');
  writeOut('│  Suites Run   :  ${bySuite.length} suites                            │');
  writeOut('│  Duration     :  ${(totalMs / 1000).toStringAsFixed(1)}s                                │');
  writeOut('│  Exit Code    :  $exitCode (${exitCode == 0 ? 'SUCCESS' : 'FAILURE'})                          │');
  writeOut('└────────────────────────────────────────────────────────┘\n');

  String stripAnsi(String s) => s.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
  final plainTextLog = consoleBuffer.map(stripAnsi).join('\n');
  await logFile.writeAsString(plainTextLog, encoding: utf8);

  final html = _buildHtml(
    suites: suites, bySuite: bySuite,
    passed: passed, failed: failed, total: total, pct: pct,
    totalMs: totalMs, exitCode: exitCode,
  );

  await File(outputPath).writeAsString(html, encoding: utf8);
  writeOut('Dashboard written: $outputPath');
  writeOut('Log file written: ${logFile.path}');
  exit(exitCode);
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _suiteEmoji(String f) {
  if (f.contains('audio'))    return '🔊';
  if (f.contains('ffmpeg'))   return '📽';
  if (f.contains('whisper'))  return '🎙';
  if (f.contains('emoji'))    return '😀';
  if (f.contains('srt'))      return '📄';
  if (f.contains('caption'))  return '📋';
  if (f.contains('editor'))   return '✏';
  if (f.contains('word'))     return '🖊';
  if (f.contains('isar'))     return '💾';
  if (f.contains('logger'))   return '📝';
  if (f.contains('settings')) return '⚙';
  if (f.contains('waveform')) return '〰';
  if (f.contains('timeline')) return '⏱';
  if (f.contains('widget'))   return '🖥';
  if (f.contains('download')) return '⬇';
  if (f.contains('pack'))     return '📦';
  if (f.contains('dash'))     return '📊';
  if (f.contains('stt'))      return '🧠';
  if (f.contains('relink'))   return '🔗';
  if (f.contains('asset'))    return '🎨';
  if (f.contains('app_dir'))  return '📁';
  if (f.contains('binary'))   return '🔧';
  return '🧪';
}

const _palette = [
  '#3b82f6','#a855f7','#06b6d4','#22c55e',
  '#f97316','#eab308','#ec4899','#6366f1',
  '#14b8a6','#f43f5e','#8b5cf6','#0ea5e9',
];
String _color(int i) => _palette[i % _palette.length];

/// Produce a unique JS-safe ID for each test row (for toggling detail panels)
String _testId(int suiteIdx, int testIdx) => 'td_${suiteIdx}_$testIdx';

String _buildHtml({
  required Map<int, SuiteInfo> suites,
  required Map<int, List<TestInfo>> bySuite,
  required int passed, required int failed, required int total,
  required String pct, required int totalMs, required int exitCode,
}) {
  var totalErrors = 0;
  var totalWarnings = 0;
  var totalActions = 0;
  var totalInfos = 0;
  var totalDebugs = 0;
  var totalTraces = 0;

  final ansiRegex = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
  for (final ts in bySuite.values) {
    for (final t in ts) {
      for (final line in t.printOutput) {
        final cleanLine = line.replaceAll(ansiRegex, '');
        final upperLine = cleanLine.toUpperCase();
        if (upperLine.contains('[ERROR') || upperLine.contains('ERROR:') || upperLine.contains(' ERROR ')) {
          totalErrors++;
        } else if (upperLine.contains('[WARN') || upperLine.contains('WARN:') || upperLine.contains(' WARNING ')) {
          totalWarnings++;
        } else if (upperLine.contains('[ACTION') || upperLine.contains('ACTION:') || upperLine.contains(' ACTION ')) {
          totalActions++;
        } else if (upperLine.contains('[INFO') || upperLine.contains('INFO:') || upperLine.contains(' INFO ')) {
          totalInfos++;
        } else if (upperLine.contains('[DEBUG') || upperLine.contains('DEBUG:') || upperLine.contains(' DEBUG ')) {
          totalDebugs++;
        } else if (upperLine.contains('[TRACE') || upperLine.contains('TRACE:') || upperLine.contains(' TRACE ')) {
          totalTraces++;
        }
      }
    }
  }

  final now      = DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ');
  final ok       = failed == 0;
  final sc       = ok ? '#22c55e' : '#ef4444';
  final slabel   = ok ? 'ALL TESTS PASSED' : '$failed TESTS FAILED';
  final sfill    = ok
      ? 'linear-gradient(90deg,#22c55e,#4ade80)'
      : 'linear-gradient(90deg,#ef4444,#f87171)';
  final sglw     = ok ? 'rgba(34,197,94,.5)' : 'rgba(239,68,68,.5)';

  final sortedIds = bySuite.keys.toList()
    ..sort((a, b) => (suites[a]?.path ?? '').compareTo(suites[b]?.path ?? ''));

  final sections = StringBuffer();
  var idx = 0;
  for (final sid in sortedIds) {
    final ts = bySuite[sid]!;
    if (ts.isEmpty) continue;
    final suite = suites[sid];
    final rawPath = suite?.path ?? 'unknown';
    final fname  = p.basename(rawPath);
    final sp     = ts.where((t) => t.result == 'success').length;
    final sf     = ts.where((t) => t.result != 'success').length;
    final fill   = ts.isEmpty ? 0 : (sp / ts.length * 100).round();
    final clr    = _color(idx);
    final emoji  = _suiteEmoji(fname);

    var suiteErrors = 0;
    var suiteWarnings = 0;
    var suiteActions = 0;
    var suiteInfos = 0;
    var suiteDebugs = 0;
    var suiteTraces = 0;

    final rows = StringBuffer();
    var ti = 0;
    for (final t in ts) {
      final ok2 = t.result == 'success';
      final dur = t.duration < 1000
          ? '${t.duration}ms'
          : '${(t.duration / 1000).toStringAsFixed(1)}s';
      final dn = t.name.contains(': ')
          ? t.name.substring(t.name.indexOf(': ') + 2)
          : t.name;
      final detailId = _testId(idx, ti);

      var testErrors = 0;
      var testWarnings = 0;
      var testActions = 0;
      var testInfos = 0;
      var testDebugs = 0;
      var testTraces = 0;
      
      final ansiRegex = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
      for (final line in t.printOutput) {
        final cleanLine = line.replaceAll(ansiRegex, '');
        final upperLine = cleanLine.toUpperCase();
        if (upperLine.contains('[ERROR') || upperLine.contains('ERROR:') || upperLine.contains(' ERROR ')) {
          testErrors++;
        } else if (upperLine.contains('[WARN') || upperLine.contains('WARN:') || upperLine.contains(' WARNING ')) {
          testWarnings++;
        } else if (upperLine.contains('[ACTION') || upperLine.contains('ACTION:') || upperLine.contains(' ACTION ')) {
          testActions++;
        } else if (upperLine.contains('[INFO') || upperLine.contains('INFO:') || upperLine.contains(' INFO ')) {
          testInfos++;
        } else if (upperLine.contains('[DEBUG') || upperLine.contains('DEBUG:') || upperLine.contains(' DEBUG ')) {
          testDebugs++;
        } else if (upperLine.contains('[TRACE') || upperLine.contains('TRACE:') || upperLine.contains(' TRACE ')) {
          testTraces++;
        }
      }
      suiteErrors += testErrors;
      suiteWarnings += testWarnings;
      suiteActions += testActions;
      suiteInfos += testInfos;
      suiteDebugs += testDebugs;
      suiteTraces += testTraces;

      final rowBadges = StringBuffer();
      if (testErrors > 0) {
        rowBadges.write(' <span class="row-badge r-badge">❌ $testErrors</span>');
      }
      if (testWarnings > 0) {
        rowBadges.write(' <span class="row-badge w-badge">⚠️ $testWarnings</span>');
      }
      if (testActions > 0) {
        rowBadges.write(' <span class="row-badge a-badge">⚙️ $testActions</span>');
      }
      if (testInfos > 0) {
        rowBadges.write(' <span class="row-badge i-badge">ℹ️ $testInfos</span>');
      }
      if (testDebugs > 0) {
        rowBadges.write(' <span class="row-badge d-badge">🐛 $testDebugs</span>');
      }
      if (testTraces > 0) {
        rowBadges.write(' <span class="row-badge t-badge">🔍 $testTraces</span>');
      }

      // Build detail panel content — always shown for every test
      final detailHtml = StringBuffer();

      // Print/log output section
      if (t.printOutput.isNotEmpty) {
        final statsParts = <String>[];
        if (testErrors > 0) statsParts.add('❌ $testErrors');
        if (testWarnings > 0) statsParts.add('⚠️ $testWarnings');
        if (testActions > 0) statsParts.add('$testActions Actions');
        if (testInfos > 0) statsParts.add('$testInfos Infos');
        if (testDebugs > 0) statsParts.add('$testDebugs Debugs');
        if (testTraces > 0) statsParts.add('$testTraces Traces');
        final statsStr = statsParts.join(' • ');

        detailHtml.write('<div class="dl-section">');
        detailHtml.write('<div class="dl-label">📋 Output / Logs ($statsStr)</div>');
        detailHtml.write('<div class="dl-log">');
        for (var line in t.printOutput) {
          final cleanLine = line.replaceAll(ansiRegex, '');
          final upperLine = cleanLine.toUpperCase();
          
          // Color-code based on log level prefix
          String cls = 'log-plain';
          if (upperLine.contains('[ERROR')) {
            cls = 'log-err';
          } else if (upperLine.contains('[WARN')) {
            cls = 'log-warn';
          } else if (upperLine.contains('[ACTION')) {
            cls = 'log-action';
          } else if (upperLine.contains('[INFO')) {
            cls = 'log-info';
          } else if (upperLine.contains('[DEBUG')) {
            cls = 'log-debug';
          } else if (upperLine.contains('[TRACE')) {
            cls = 'log-trace';
          }
          
          detailHtml.write('<div class="log-line $cls">${_esc(cleanLine)}</div>');
        }
        detailHtml.write('</div></div>');
      }

      // Error message section
      if (t.errorMessage != null) {
        detailHtml.write('<div class="dl-section">');
        detailHtml.write('<div class="dl-label">❌ Error</div>');
        detailHtml.write('<div class="dl-err">${_esc(t.errorMessage!)}</div>');
        detailHtml.write('</div>');
      }

      // Stack trace section
      if (t.stackTrace != null) {
        detailHtml.write('<div class="dl-section">');
        detailHtml.write('<div class="dl-label">📍 Stack Trace</div>');
        detailHtml.write('<div class="dl-stack">${_esc(t.stackTrace!)}</div>');
        detailHtml.write('</div>');
      }

      // No output fallback
      if (t.printOutput.isEmpty && t.errorMessage == null && t.stackTrace == null) {
        detailHtml.write('<div class="dl-empty">No output captured — test ran silently ✓</div>');
      }

      rows.write('''
        <div class="tr">
          <div class="ts ${ok2 ? 'p' : 'f'}">${ok2 ? '✓' : '✗'}</div>
          <div class="tn${ok2 ? '' : ' fe'}">${_esc(dn)}${rowBadges.toString()}</div>
          <div class="tr-right">
            <button class="detail-btn" onclick="event.stopPropagation();toggleDetail('$detailId')">▸ Details</button>
            <div class="td">$dur</div>
          </div>
        </div>
        <div class="detail-panel" id="$detailId">${detailHtml.toString()}</div>
      ''');
      ti++;
    }

    final suiteBadges = StringBuffer();
    if (suiteErrors > 0) {
      suiteBadges.write(' <span class="suite-badge r-badge">❌ $suiteErrors</span>');
    }
    if (suiteWarnings > 0) {
      suiteBadges.write(' <span class="suite-badge w-badge">⚠️ $suiteWarnings</span>');
    }
    if (suiteActions > 0) {
      suiteBadges.write(' <span class="suite-badge a-badge">⚙️ $suiteActions</span>');
    }
    if (suiteInfos > 0) {
      suiteBadges.write(' <span class="suite-badge i-badge">ℹ️ $suiteInfos</span>');
    }
    if (suiteDebugs > 0) {
      suiteBadges.write(' <span class="suite-badge d-badge">🐛 $suiteDebugs</span>');
    }
    if (suiteTraces > 0) {
      suiteBadges.write(' <span class="suite-badge t-badge">🔍 $suiteTraces</span>');
    }

    sections.write('''
    <div class="sc" onclick="toggleCard(this)">
      <div class="sh">
        <div class="si" style="background:${clr}22;color:$clr">$emoji</div>
        <div class="stg">
          <div class="sn-row">
            <span class="sn">${_esc(fname)}</span>
            ${suiteBadges.toString()}
          </div>
          <div class="sfp">${_esc(rawPath)}</div>
        </div>
        <div class="ss">
          <div class="sb pa">✓ $sp</div>
          ${sf > 0 ? '<div class="sb fa">✗ $sf</div>' : ''}
        </div>
        <div class="eb">▾</div>
      </div>
      <div class="st"><div class="sf2" style="width:$fill%;background:${sf == 0 ? '#22c55e' : '#ef4444'}"></div></div>
      <div class="tl">$rows</div>
    </div>
    ''');
    idx++;
  }

  return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>CapStudio — Test Dashboard</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
<style>
:root{--bg:#0b0d12;--card:#111520;--glass:rgba(255,255,255,.04);--border:rgba(255,255,255,.07);
--text:#f1f5f9;--muted:#64748b;--dim:#334155}
*{margin:0;padding:0;box-sizing:border-box}
body{background:var(--bg);color:var(--text);font-family:'Inter',sans-serif;min-height:100vh}
body::before{content:'';position:fixed;top:-200px;left:-200px;width:600px;height:600px;
background:radial-gradient(circle,rgba(59,130,246,.06),transparent 70%);pointer-events:none;z-index:0}
body::after{content:'';position:fixed;bottom:-200px;right:-200px;width:700px;height:700px;
background:radial-gradient(circle,rgba(168,85,247,.05),transparent 70%);pointer-events:none;z-index:0}
.page{position:relative;z-index:1;max-width:1200px;margin:0 auto;padding:48px 24px 80px}
.hdr{margin-bottom:40px}.htop{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:16px;margin-bottom:8px}
.lr{display:flex;align-items:center;gap:12px}
.li{width:44px;height:44px;background:linear-gradient(135deg,#3b82f6,#a855f7);border-radius:12px;
display:flex;align-items:center;justify-content:center;font-size:22px;box-shadow:0 4px 20px rgba(59,130,246,.4)}
.lt h1{font-size:22px;font-weight:800;letter-spacing:-.4px;
background:linear-gradient(135deg,#f1f5f9,#94a3b8);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.lt span{font-size:12px;color:var(--muted)}
.badge{display:flex;align-items:center;gap:8px;padding:6px 14px;border-radius:100px;
font-size:12px;font-weight:700;background:${ok ? 'rgba(34,197,94,.12)' : 'rgba(239,68,68,.12)'};
border:1px solid ${ok ? 'rgba(34,197,94,.25)' : 'rgba(239,68,68,.25)'};color:$sc}
.dot{width:7px;height:7px;border-radius:50%;background:$sc;box-shadow:0 0 8px $sc;animation:pulse 2s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
.meta{color:var(--muted);font-size:13px;margin-top:4px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:16px;margin-bottom:32px}
.card{background:var(--card);border:1px solid var(--border);border-radius:18px;padding:20px;
display:flex;flex-direction:column;gap:6px;transition:transform .2s,box-shadow .2s;position:relative;overflow:hidden}
.card::before{content:'';position:absolute;top:0;left:0;right:0;height:2px;border-radius:18px 18px 0 0}
.card:hover{transform:translateY(-2px);box-shadow:0 8px 32px rgba(0,0,0,.3)}
.g::before{background:linear-gradient(90deg,#22c55e,#4ade80)}
.r::before{background:linear-gradient(90deg,#ef4444,#f87171)}
.b::before{background:linear-gradient(90deg,#3b82f6,#60a5fa)}
.pu::before{background:linear-gradient(90deg,#a855f7,#c084fc)}
.y::before{background:linear-gradient(90deg,#eab308,#facc15)}
.lbl{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:1px;color:var(--muted)}
.val{font-size:34px;font-weight:800;line-height:1;letter-spacing:-1px;font-family:'JetBrains Mono',monospace}
.g .val{color:#22c55e}.r .val{color:#ef4444}.b .val{color:#3b82f6}.pu .val{color:#a855f7}.y .val{color:#eab308}
.sub{font-size:12px;color:var(--muted)}
.pbox{background:var(--card);border:1px solid var(--border);border-radius:18px;padding:22px 24px;margin-bottom:32px}
.prow{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px}
.prow span:first-child{font-size:13px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.8px}
.pct{font-size:13px;font-weight:700;color:$sc;font-family:'JetBrains Mono',monospace}
.track{width:100%;height:8px;background:var(--glass);border-radius:100px;overflow:hidden}
.fill{height:100%;border-radius:100px;background:$sfill;box-shadow:0 0 12px $sglw;transition:width 1s ease}
.stitle{font-size:13px;font-weight:700;text-transform:uppercase;letter-spacing:1.2px;
color:var(--muted);margin-bottom:14px;display:flex;align-items:center;gap:10px}
.stitle::after{content:'';flex:1;height:1px;background:var(--border)}
.eabtn{background:var(--glass);border:1px solid var(--border);color:var(--muted);
font-size:12px;font-weight:600;padding:6px 14px;border-radius:100px;cursor:pointer;
transition:all .2s;font-family:'Inter',sans-serif;margin-bottom:14px}
.eabtn:hover{border-color:rgba(255,255,255,.15);color:var(--text)}
.sgrid{display:flex;flex-direction:column;gap:10px;margin-bottom:40px}
.sc{background:var(--card);border:1px solid var(--border);border-radius:16px;overflow:hidden;cursor:pointer;transition:border-color .2s}
.sc:hover{border-color:rgba(255,255,255,.12)}
.sh{display:flex;align-items:center;gap:14px;padding:14px 18px}
.si{width:34px;height:34px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0}
.stg{flex:1;min-width:0}
.sn-row{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.sn{font-size:13px;font-weight:600;color:var(--text);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sfp{font-size:10px;color:var(--muted);font-family:'JetBrains Mono',monospace;margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.row-badge{font-size:9px;font-weight:700;padding:1px 5px;border-radius:4px;margin-left:6px;font-family:'JetBrains Mono',monospace;display:inline-flex;align-items:center;vertical-align:middle}
.suite-badge{font-size:10px;font-weight:700;padding:2px 7px;border-radius:6px;font-family:'JetBrains Mono',monospace;display:inline-flex;align-items:center;gap:3px;vertical-align:middle}
.r-badge{background:rgba(239,68,68,0.12);color:#ef4444;border:1px solid rgba(239,68,68,0.25)}
.w-badge{background:rgba(234,179,8,0.12);color:#eab308;border:1px solid rgba(234,179,8,0.25)}
.ss{display:flex;align-items:center;gap:8px;flex-shrink:0}
.sb{font-size:12px;font-weight:600;font-family:'JetBrains Mono',monospace;padding:3px 10px;border-radius:100px}
.pa{background:rgba(34,197,94,.12);color:#22c55e}.fa{background:rgba(239,68,68,.12);color:#ef4444}
.eb{font-size:14px;color:var(--dim);transition:transform .2s;flex-shrink:0}
.sc.open .eb{transform:rotate(180deg)}
.st{height:3px;background:var(--glass);margin:0 18px}
.sf2{height:100%;transition:width .8s ease}
.tl{display:none;flex-direction:column;gap:0;padding:8px 14px 14px}
.sc.open .tl{display:flex}
/* Test row */
.tr{display:flex;align-items:center;gap:10px;padding:6px 10px;border-radius:6px;transition:background .15s}
.tr:hover{background:var(--glass)}
.ts{width:18px;height:18px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:10px;flex-shrink:0}
.ts.p{background:rgba(34,197,94,.12);color:#22c55e}.ts.f{background:rgba(239,68,68,.12);color:#ef4444}
.tn{display:flex;align-items:center;flex-wrap:wrap;flex:1;font-size:12px;color:#94a3b8;line-height:1.5;word-break:break-word}
.tn.fe{color:#ef4444}
.tr-right{display:flex;align-items:center;gap:8px;flex-shrink:0}
.td{font-size:11px;color:var(--dim);font-family:'JetBrains Mono',monospace;white-space:nowrap}
/* Detail toggle button */
.detail-btn{background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.1);
color:var(--muted);font-size:10px;font-weight:600;padding:2px 8px;border-radius:4px;
cursor:pointer;font-family:'JetBrains Mono',monospace;transition:all .15s;white-space:nowrap}
.detail-btn:hover{background:rgba(255,255,255,.09);color:var(--text);border-color:rgba(255,255,255,.2)}
.detail-btn.open{color:#60a5fa;border-color:rgba(96,165,250,.3);background:rgba(96,165,250,.08)}
/* Detail panel */
.detail-panel{display:none;flex-direction:column;gap:8px;
margin:0 10px 8px 38px;padding:10px 12px;
background:rgba(0,0,0,.3);border-radius:8px;border:1px solid rgba(255,255,255,.06)}
.detail-panel.open{display:flex}
.dl-section{display:flex;flex-direction:column;gap:4px}
.dl-label{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.8px;color:var(--muted);margin-bottom:2px}
/* Log output lines */
.dl-log{display:flex;flex-direction:column;gap:1px;max-height:300px;overflow-y:auto;
font-size:11px;font-family:'JetBrains Mono',monospace;
background:rgba(0,0,0,.25);border-radius:6px;padding:8px 10px;border:1px solid rgba(255,255,255,.04)}
.log-line{line-height:1.5;white-space:pre-wrap;word-break:break-all;padding:1px 0}
.log-info{color:#60a5fa}
.log-err{color:#f87171;font-weight:500}
.log-warn{color:#fbbf24}
.log-action{color:#a78bfa}
.log-debug{color:#64748b}
.log-trace{color:#475569}
.log-plain{color:#94a3b8}
/* Error text */
.dl-err{font-size:11px;font-family:'JetBrains Mono',monospace;color:#f87171;
background:rgba(239,68,68,.07);border-left:2px solid #ef4444;padding:8px 12px;
border-radius:4px;white-space:pre-wrap;word-break:break-all}
/* Stack trace */
.dl-stack{font-size:10px;font-family:'JetBrains Mono',monospace;color:#64748b;
background:rgba(0,0,0,.3);border-left:2px solid rgba(100,116,139,.3);padding:8px 12px;
border-radius:4px;white-space:pre-wrap;word-break:break-all;max-height:200px;overflow-y:auto}
/* No output placeholder */
.dl-empty{font-size:11px;color:var(--dim);font-family:'JetBrains Mono',monospace;
padding:6px 4px;font-style:italic}
footer{text-align:center;color:var(--dim);font-size:12px;margin-top:60px;padding-top:24px;border-top:1px solid var(--border)}
.log-stats-grid{display:flex;flex-wrap:wrap;gap:12px;margin-top:12px}
.log-stat-item{display:flex;align-items:center;gap:8px;padding:6px 14px;border-radius:100px;
font-size:12px;font-weight:600;background:rgba(255,255,255,.03);border:1px solid var(--border);color:var(--muted)}
.log-stat-item strong{color:var(--text);font-family:'JetBrains Mono',monospace;font-size:13px}
.log-stat-dot{width:6px;height:6px;border-radius:50%;background:var(--muted)}
.log-stat-item.err{border-color:rgba(239,68,68,.25);background:rgba(239,68,68,.05)}
.log-stat-item.err .log-stat-dot{background:#ef4444;box-shadow:0 0 6px #ef4444}
.log-stat-item.err strong{color:#f87171}
.log-stat-item.warn{border-color:rgba(234,179,8,.25);background:rgba(234,179,8,.05)}
.log-stat-item.warn .log-stat-dot{background:#eab308;box-shadow:0 0 6px #eab308}
.log-stat-item.warn strong{color:#fbbf24}
.log-stat-item.action{border-color:rgba(168,85,247,.25);background:rgba(168,85,247,.05)}
.log-stat-item.action .log-stat-dot{background:#a855f7;box-shadow:0 0 6px #a855f7}
.log-stat-item.action strong{color:#a78bfa}
.log-stat-item.info{border-color:rgba(59,130,246,.25);background:rgba(59,130,246,.05)}
.log-stat-item.info .log-stat-dot{background:#3b82f6;box-shadow:0 0 6px #3b82f6}
.log-stat-item.info strong{color:#60a5fa}
.log-stat-item.debug{border-color:rgba(100,116,139,.25);background:rgba(100,116,139,.05)}
.log-stat-item.debug .log-stat-dot{background:#64748b;box-shadow:0 0 6px #64748b}
.log-stat-item.debug strong{color:#94a3b8}
.log-stat-item.trace{border-color:rgba(71,85,105,.25);background:rgba(71,85,105,.05)}
.log-stat-item.trace .log-stat-dot{background:#475569;box-shadow:0 0 6px #475569}
.log-stat-item.trace strong{color:#64748b}
</style>
</head>
<body>
<div class="page">
  <div class="hdr">
    <div class="htop">
      <div class="lr">
        <div class="li">🎬</div>
        <div class="lt"><h1>CapStudio Test Suite</h1><span>Local AI Caption Studio · Live Test Dashboard</span></div>
      </div>
      <div class="badge"><div class="dot"></div>$slabel</div>
    </div>
    <div class="meta">Generated $now · $passed/$total tests · ${(totalMs/1000).toStringAsFixed(1)}s · exit $exitCode</div>
  </div>

  <div class="grid">
    <div class="card g"><div class="lbl">Passed Tests</div><div class="val">$passed</div><div class="sub">$pct% pass rate</div></div>
    <div class="card r"><div class="lbl">Failed Tests</div><div class="val">$failed</div><div class="sub">${failed == 0 ? 'No failures' : 'Fix required'}</div></div>
    <div class="card b"><div class="lbl">Total Tests</div><div class="val">$total</div><div class="sub">${sortedIds.length} suites</div></div>
    <div class="card pu"><div class="lbl">Duration</div><div class="val">${(totalMs/1000).toStringAsFixed(0)}s</div><div class="sub">${total > 0 ? (totalMs/total).round() : 0}ms avg/test</div></div>
    <div class="card y"><div class="lbl">Exit Code</div><div class="val">$exitCode</div><div class="sub">${exitCode == 0 ? 'Success' : 'Failure'}</div></div>
  </div>

  <div class="pbox">
    <div class="prow"><span>Overall Pass Rate</span><span class="pct">$passed / $total — $pct%</span></div>
    <div class="track"><div class="fill" id="mainFill" style="width:0%"></div></div>
  </div>

  <div class="pbox" style="margin-top:-16px; margin-bottom:32px;">
    <div class="prow" style="margin-bottom:8px;">
      <span>Captured Log Statistics</span>
      <span class="pct" style="color:var(--muted); font-size:11px; text-transform:none; font-family:sans-serif;">Total events across all tests</span>
    </div>
    <div class="log-stats-grid">
      <div class="log-stat-item err"><span class="log-stat-dot"></span><strong>$totalErrors</strong> Errors</div>
      <div class="log-stat-item warn"><span class="log-stat-dot"></span><strong>$totalWarnings</strong> Warnings</div>
      <div class="log-stat-item action"><span class="log-stat-dot"></span><strong>$totalActions</strong> Actions</div>
      <div class="log-stat-item info"><span class="log-stat-dot"></span><strong>$totalInfos</strong> Infos</div>
      <div class="log-stat-item debug"><span class="log-stat-dot"></span><strong>$totalDebugs</strong> Debugs</div>
      <div class="log-stat-item trace"><span class="log-stat-dot"></span><strong>$totalTraces</strong> Traces</div>
    </div>
  </div>

  <div class="stitle">🧪 Test Suites (${sortedIds.length})</div>
  <button class="eabtn" onclick="toggleAll()">⊕ Expand All Suites</button>
  <div class="sgrid">$sections</div>

  <footer>
    <strong>CapStudio Test Dashboard</strong> — Real data from <code>flutter test --reporter json</code><br>
    <span style="margin-top:6px;display:block">$now · $passed/$total · exit $exitCode</span>
  </footer>
</div>
<script>
  setTimeout(() => { document.getElementById('mainFill').style.width = '$pct%'; }, 200);
  function toggleCard(c) { c.classList.toggle('open'); }
  let allOpen = false;
  function toggleAll() {
    allOpen = !allOpen;
    document.querySelectorAll('.sc').forEach(c => c.classList.toggle('open', allOpen));
    document.querySelector('.eabtn').textContent = allOpen ? '⊖ Collapse All' : '⊕ Expand All Suites';
  }
  function toggleDetail(id) {
    const panel = document.getElementById(id);
    if (!panel) return;
    panel.classList.toggle('open');
    // Toggle the button text/style
    const btn = panel.previousElementSibling
      ? panel.previousElementSibling.querySelector('.detail-btn')
      : null;
    if (btn) {
      btn.classList.toggle('open');
      btn.textContent = panel.classList.contains('open') ? '▾ Details' : '▸ Details';
    }
  }
</script>
</body>
</html>''';
}
