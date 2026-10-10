import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import '../utils/app_dirs.dart';

/// Log severity levels (ordered by importance)
enum LogLevel {
  trace,   // Extremely verbose: method entry/exit, variable dumps
  debug,   // Developer diagnostics: state changes, intermediate values
  info,    // Normal operations: startup, config loaded, transcription complete
  action,  // User-initiated actions: button taps, file imports, exports
  warning, // Recoverable issues: missing font, slow transcription, retry
  error,   // Failures: crash, file I/O error, codec failure, unhandled exception
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String source;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
    this.stackTrace,
    this.metadata,
  });

  String get formattedTime {
    final t = timestamp.toLocal();
    return '${t.hour.toString().padLeft(2, '0')}:'
           '${t.minute.toString().padLeft(2, '0')}:'
           '${t.second.toString().padLeft(2, '0')}.'
           '${t.millisecond.toString().padLeft(3, '0')}';
  }

  String get formattedDate {
    final t = timestamp.toLocal();
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    final lvl = level.name.toUpperCase().padRight(7);
    final base = '[$formattedTime] [$lvl] [$source] $message';
    if (stackTrace != null) {
      return '$base\n  STACK: $stackTrace';
    }
    return base;
  }

  /// Structured JSON format for machine-parseable logs
  String toJson() {
    final map = <String, dynamic>{
      'ts': timestamp.toUtc().toIso8601String(),
      'level': level.name,
      'source': source,
      'msg': message,
    };
    if (stackTrace != null) map['stack'] = stackTrace;
    if (metadata != null) map['meta'] = metadata;
    return jsonEncode(map);
  }
}

/// Professional-grade logging service with:
/// - Daily log rotation (7-day retention)
/// - Crash/stack trace capture
/// - Performance timing helpers
/// - Session-based log files
/// - Structured JSON output alongside human-readable format
/// - Configurable log level filtering
/// - In-memory ring buffer for UI display
class LoggerService {
  LoggerService._internal();
  static LoggerService _instance = LoggerService._internal();
  static LoggerService get instance => _instance;

  @visibleForTesting
  static set instance(LoggerService newInstance) {
    _instance = newInstance;
  }

  /// Reset the singleton instance for testing purposes to avoid singleton pollution.
  static void resetForTesting() {
    _instance._notifyTimer?.cancel();
    _instance._notifyTimer = null;
    _instance = LoggerService._internal();
  }

  /// If false, logs will not be printed to the console via debugPrint.
  /// Defaults to false in a testing environment, true otherwise.
  bool enableConsoleOutput = true;

  // ── Configuration ───────────────────────────────────────────────────────
  static const int _maxMemoryLogs = 500;
  static const int _maxLogRetentionDays = 7;
  LogLevel _minimumLevel = kDebugMode ? LogLevel.trace : LogLevel.info;

  // ── State ───────────────────────────────────────────────────────────────
  final QueueList<LogEntry> _logs = QueueList<LogEntry>();
  final ValueNotifier<List<LogEntry>> _logsNotifier = ValueNotifier<List<LogEntry>>([]);
  ValueListenable<List<LogEntry>> get logsNotifier => _logsNotifier;
  Timer? _notifyTimer;
  bool _needsNotify = false;
  
  File? _logFile;
  File? _jsonLogFile;
  IOSink? _fileSink;
  IOSink? _jsonSink;
  bool _initialized = false;
  /// Counter to batch file size check queries on the main thread (performance)
  int _logWriteCount = 0;
  /// True once dispose() starts — all subsequent log() calls become no-ops
  /// for file I/O to prevent writing to a closed/closing IOSink.
  bool _disposing = false;

  // Buffers to hold logs during active async file rotation (Finding 25)
  final List<LogEntry> _fileRotationBuffer = [];
  final List<LogEntry> _jsonRotationBuffer = [];
  bool _rotatingFile = false;
  bool _rotatingJson = false;
  bool _fileSinkBound = false;
  bool _jsonSinkBound = false;
  String? _logDir;
  String _sessionId = '';
  final Stopwatch _sessionTimer = Stopwatch();
  final Map<String, Stopwatch> _perfTimers = {};

  List<LogEntry> get logs => List.unmodifiable(_logs.toList().reversed);
  String? get logFilePath => _logFile?.path;
  String? get logDirectory => _logDir;
  Duration get sessionUptime => _sessionTimer.elapsed;
  bool get isDisposing => _disposing;
  bool get isInitialized => _initialized;

  /// Set minimum log level at runtime (e.g., from Settings screen)
  void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
    info('Logger', 'Minimum log level set to: ${level.name}');
  }

  /// Initialize the logger with daily rotation and session tracking
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _sessionTimer.start();

    // Generate unique session ID (timestamp-based)
    // Generate unique session ID (timestamp-based + random suffix to avoid collision, Finding 27)
    final now = DateTime.now();
    final randomSuffix = math.Random().nextInt(10000).toString().padLeft(4, '0');
    _sessionId = '${now.year}${now.month.toString().padLeft(2, '0')}'
                 '${now.day.toString().padLeft(2, '0')}_'
                 '${now.hour.toString().padLeft(2, '0')}'
                 '${now.minute.toString().padLeft(2, '0')}'
                 '${now.second.toString().padLeft(2, '0')}_$randomSuffix';

    try {
      if (kIsWeb) {
        log(LogLevel.info, 'Logger', 'Console-only logger initialized for Web. Session: $_sessionId');
        return;
      }
      // Use AppDirs to get the correct single-level path:
      // AppData\Roaming\CapStudio\logs\ (not Documents\capstudio\logs)
      _logDir = AppDirs.logs;
      final logDirObj = Directory(_logDir!);
      if (!logDirObj.existsSync()) {
        logDirObj.createSync(recursive: true);
      }

      // Daily log file (human-readable)
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _logFile = File(p.join(_logDir!, 'capstudio_$dateStr.log'));
      _fileSink = _logFile!.openWrite(mode: FileMode.writeOnlyAppend);

      // JSON log file (machine-parseable, for crash reporting / analytics)
      _jsonLogFile = File(p.join(_logDir!, 'capstudio_$dateStr.jsonl'));
      _jsonSink = _jsonLogFile!.openWrite(mode: FileMode.writeOnlyAppend);

      // Log session start header
      _fileSink!.writeln('\n${'═' * 80}');
      _fileSink!.writeln('SESSION START: $_sessionId');
      _fileSink!.writeln('Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      _fileSink!.writeln('Dart: ${Platform.version}');
      _fileSink!.writeln('${'═' * 80}\n');

      // Rotate old log files
      _rotateOldLogs(logDirObj);

      log(LogLevel.info, 'Logger', 'Advanced logger initialized. Session: $_sessionId, Path: ${_logFile!.path}');
    } catch (e) {
      debugPrint('Failed to initialize persistent file logger: $e');
    }
  }

  /// Scrubs personally identifiable information (PII) such as OS usernames
  /// and home directory paths from the provided [input] string.
  String scrubPii(String input) {
    if (kIsWeb) return input;
    var result = input;
    try {
      final homeDir = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (homeDir != null && homeDir.isNotEmpty) {
        final escapedHome = RegExp.escape(homeDir);
        result = result.replaceAll(RegExp(escapedHome, caseSensitive: false), '<USER_HOME>');
        final normalizedHome = homeDir.replaceAll('\\', '/');
        if (normalizedHome != homeDir) {
          final escapedNormalized = RegExp.escape(normalizedHome);
          result = result.replaceAll(RegExp(escapedNormalized, caseSensitive: false), '<USER_HOME>');
        }
      }
      final username = Platform.environment['USERNAME'] ?? Platform.environment['USER'];
      if (username != null && username.isNotEmpty && username.length > 2) {
        final escapedUser = RegExp.escape(username);
        result = result.replaceAll(RegExp(escapedUser, caseSensitive: false), '<USER>');
      }
    } catch (e) {
      debugPrint('Error in scrubPii: $e');
    }
    return result;
  }

  String _scrubPii(String input) => scrubPii(input);

  Map<String, dynamic>? _scrubMetadata(Map<String, dynamic>? meta) {
    if (meta == null) return null;
    return meta.map((key, value) {
      if (value is String) {
        return MapEntry(key, _scrubPii(value));
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _scrubMetadata(value) ?? {});
      } else if (value is List) {
        return MapEntry(key, value.map((e) => e is String ? _scrubPii(e) : e).toList());
      }
      return MapEntry(key, value);
    });
  }

  /// Core logging method
  void log(LogLevel level, String source, String message, {
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    // Filter by minimum level
    if (level.index < _minimumLevel.index) return;

    final scrubbedMessage = _scrubPii(message);
    final scrubbedStackTrace = stackTrace != null 
        ? _scrubPii(stackTrace.toString().split('\n').take(10).join('\n'))
        : null;
    final scrubbedMetadata = _scrubMetadata(metadata);

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      source: source,
      message: scrubbedMessage,
      stackTrace: scrubbedStackTrace,
      metadata: scrubbedMetadata,
    );

    // In-memory ring buffer using QueueList for O(1) operations
    _logs.add(entry);
    if (_logs.length > _maxMemoryLogs) {
      _logs.removeFirst();
    }

    // Notify UI listeners with throttled updates (150ms debounce) to prevent jank
    _scheduleNotify();

    // Console output
    if (enableConsoleOutput) {
      debugPrint(_colorize(entry));
    }

    // Persistent file I/O
    _writeToLogFile(entry);
  }

  void _scheduleNotify() {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      _notifyListeners();
      return;
    }

    if (_notifyTimer != null) {
      _needsNotify = true;
      return;
    }

    _notifyListeners();

    _notifyTimer = Timer(const Duration(milliseconds: 150), () {
      _notifyTimer = null;
      if (_needsNotify) {
        _needsNotify = false;
        _scheduleNotify();
      }
    });
  }

  void _notifyListeners() {
    if (_disposing) return;
    
    // UI expects newest logs first (index 0 is newest)
    final snapshot = _logs.toList().reversed.toList();

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle ||
        SchedulerBinding.instance.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      _logsNotifier.value = snapshot;
    } else {
      scheduleMicrotask(() {
        _logsNotifier.value = snapshot;
      });
    }
  }

  // ── Convenience methods ─────────────────────────────────────────────────

  void trace(String source, String message, {Map<String, dynamic>? meta}) =>
      log(LogLevel.trace, source, message, metadata: meta);

  void debug(String messageOrSource, [String? message, Map<String, dynamic>? meta]) {
    if (message != null) {
      log(LogLevel.debug, messageOrSource, message, metadata: meta);
    } else {
      log(LogLevel.debug, 'App', messageOrSource, metadata: meta);
    }
  }

  void info(String source, String message, {Map<String, dynamic>? meta}) =>
      log(LogLevel.info, source, message, metadata: meta);

  void action(String source, String message, {Map<String, dynamic>? meta}) =>
      log(LogLevel.action, source, message, metadata: meta);

  void warning(String source, String message, {Map<String, dynamic>? meta}) =>
      log(LogLevel.warning, source, message, metadata: meta);

  void error(String source, String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, source, '$message${error != null ? ' | Error: $error' : ''}',
          stackTrace: stackTrace);

  // ── Performance Timing ──────────────────────────────────────────────────

  /// Start a named performance timer
  void startTimer(String name) {
    _perfTimers[name] = Stopwatch()..start();
    trace('Perf', 'Timer "$name" started');
  }

  /// Stop a named timer and log the elapsed time
  Duration stopTimer(String name) {
    final timer = _perfTimers.remove(name);
    if (timer == null) {
      warning('Perf', 'Timer "$name" not found');
      return Duration.zero;
    }
    timer.stop();
    final elapsed = timer.elapsed;
    info('Perf', 'Timer "$name" completed in ${elapsed.inMilliseconds}ms',
        meta: {'timer': name, 'ms': elapsed.inMilliseconds});
    return elapsed;
  }

  /// Measure an async operation and log the elapsed time
  Future<T> measure<T>(String name, Future<T> Function() operation) async {
    startTimer(name);
    try {
      final result = await operation();
      stopTimer(name);
      return result;
    } catch (e, st) {
      stopTimer(name);
      error('Perf', 'Operation "$name" failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Crash Capture ───────────────────────────────────────────────────────

  /// Log an unhandled exception with full stack trace
  void logCrash(Object exception, StackTrace stackTrace, {String? context}) {
    final msg = context != null
        ? 'UNHANDLED CRASH in $context: $exception'
        : 'UNHANDLED CRASH: $exception';
    log(LogLevel.error, 'CRASH', msg, stackTrace: stackTrace, metadata: {
      'type': exception.runtimeType.toString(),
      'session': _sessionId,
      'uptime_sec': sessionUptime.inSeconds,
    });

    // Force flush to disk immediately on crash.
    // Guard with _disposing to prevent re-entrant crashes when the sink is
    // in an intermediate "draining" state, which itself throws "StreamSink is
    // bound to a stream" → re-enters FlutterError.onError → infinite loop.
    if (!_disposing) {
      _safeFlush();
    }
  }

  /// Log a Flutter framework error (from FlutterError.onError)
  void logFlutterError(FlutterErrorDetails details) {
    final exceptionStr = details.exceptionAsString();
    final isOverflow = exceptionStr.contains('overflowed') || 
                       exceptionStr.contains('RenderFlex') ||
                       exceptionStr.contains('A RenderFlex overflowed');

    if (isOverflow) {
      log(
        LogLevel.warning,
        details.library ?? 'Render',
        'Visual layout overflow (non-fatal): $exceptionStr',
        stackTrace: details.stack,
      );
      return;
    }

    logCrash(
      details.exception,
      details.stack ?? StackTrace.current,
      context: details.library ?? 'Flutter',
    );
  }

  // ── File I/O ────────────────────────────────────────────────────────────

  void _writeToLogFile(LogEntry entry) {
    // Do not attempt any I/O once the sinks are being torn down.
    if (_disposing) return;

    try {
      _logWriteCount++;
      if (_logWriteCount % 100 == 0) {
        // Prevent disk exhaustion by rotating logs when they exceed 10MB (CAT-22).
        // NOTE: sink.close() is async, so we schedule the rotation asynchronously
        // to avoid leaving the sink in the "bound" intermediate state.
        if (!_rotatingFile && !_fileSinkBound && _logFile != null && _logFile!.existsSync()) {
          try {
            if (_logFile!.lengthSync() > 10 * 1024 * 1024) {
              _rotatingFile = true;
              _rotateFileSink();
            }
          } catch (e) {
            debugPrint('Failed to rotate human-readable logs: $e');
          }
        }

        if (!_rotatingJson && !_jsonSinkBound && _jsonLogFile != null && _jsonLogFile!.existsSync()) {
          try {
            if (_jsonLogFile!.lengthSync() > 10 * 1024 * 1024) {
              _rotatingJson = true;
              _rotateJsonSink();
            }
          } catch (e) {
            debugPrint('Failed to rotate JSON logs: $e');
          }
        }
      }

      if (_rotatingFile || _fileSinkBound) {
        if (_fileRotationBuffer.length < 500) {
          _fileRotationBuffer.add(entry);
        }
      } else {
        try {
          _fileSink?.writeln(entry.toString());
        } catch (e) {
          debugPrint('Error writing to file sink: $e');
        }
      }

      if (_rotatingJson || _jsonSinkBound) {
        if (_jsonRotationBuffer.length < 500) {
          _jsonRotationBuffer.add(entry);
        }
      } else {
        try {
          _jsonSink?.writeln(entry.toJson());
        } catch (e) {
          debugPrint('Error writing to JSON sink: $e');
        }
      }
    } catch (e) {
      debugPrint('Error writing to log file: $e');
    }
  }

  /// Rotate the human-readable log sink asynchronously to avoid
  /// the "StreamSink is bound to a stream" error from synchronous close().
  Future<void> _rotateFileSink() async {
    final oldSink = _fileSink;
    _fileSink = null; // Prevent further writes to old sink immediately
    _fileSinkBound = true;
    try {
      await oldSink?.flush();
      await oldSink?.close();
      final backupPath = '${_logFile!.path}.bak';
      final backupFile = File(backupPath);
      if (backupFile.existsSync()) backupFile.deleteSync();
      _logFile!.renameSync(backupPath);
      if (!_disposing) {
        _fileSink = _logFile!.openWrite(mode: FileMode.writeOnly);
        _fileSink!.writeln('=== LOG AUTO-ROTATION (Exceeded 10MB) ===');
        // Write any logs that buffered during the async rotation window (Finding 25)
        for (final entry in _fileRotationBuffer) {
          _fileSink!.writeln(entry.toString());
        }
      }
    } catch (e) {
      debugPrint('Failed to rotate human-readable log sink: $e');
    } finally {
      _fileRotationBuffer.clear();
      _fileSinkBound = false;
      _rotatingFile = false;
    }
  }

  /// Rotate the JSON log sink asynchronously.
  Future<void> _rotateJsonSink() async {
    final oldSink = _jsonSink;
    _jsonSink = null;
    _jsonSinkBound = true;
    try {
      await oldSink?.flush();
      await oldSink?.close();
      final backupPath = '${_jsonLogFile!.path}.bak';
      final backupFile = File(backupPath);
      if (backupFile.existsSync()) backupFile.deleteSync();
      _jsonLogFile!.renameSync(backupPath);
      if (!_disposing) {
        _jsonSink = _jsonLogFile!.openWrite(mode: FileMode.writeOnly);
        // Write buffered JSON entries
        for (final entry in _jsonRotationBuffer) {
          _jsonSink!.writeln(entry.toJson());
        }
      }
    } catch (e) {
      debugPrint('Failed to rotate JSON log sink: $e');
    } finally {
      _jsonRotationBuffer.clear();
      _jsonSinkBound = false;
      _rotatingJson = false;
    }
  }

  /// Safely flush sinks without causing "StreamSink is bound to a stream" on subsequent writes.
  Future<void> _safeFlush() async {
    if (_disposing) return;
    await Future.wait([_safeFlushFile(), _safeFlushJson()]);
  }

  Future<void> _safeFlushFile() async {
    if (_fileSinkBound || _fileSink == null) return;
    _fileSinkBound = true;
    try {
      await _fileSink!.flush();
    } catch (e) {
      debugPrint('Error flushing file sink: $e');
    } finally {
      _fileSinkBound = false;
      if (!_disposing && _fileSink != null) {
        try {
          for (final entry in _fileRotationBuffer) {
            _fileSink!.writeln(entry.toString());
          }
        } catch (e) {
          debugPrint('Error writing buffered logs after flush: $e');
        }
      }
      _fileRotationBuffer.clear();
    }
  }

  Future<void> _safeFlushJson() async {
    if (_jsonSinkBound || _jsonSink == null) return;
    _jsonSinkBound = true;
    try {
      await _jsonSink!.flush();
    } catch (e) {
      debugPrint('Error flushing JSON sink: $e');
    } finally {
      _jsonSinkBound = false;
      if (!_disposing && _jsonSink != null) {
        try {
          for (final entry in _jsonRotationBuffer) {
            _jsonSink!.writeln(entry.toJson());
          }
        } catch (e) {
          debugPrint('Error writing buffered JSON after flush: $e');
        }
      }
      _jsonRotationBuffer.clear();
    }
  }

  /// Delete log files older than retention period
  void _rotateOldLogs(Directory logDir) {
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: _maxLogRetentionDays));
      for (final file in logDir.listSync()) {
        if (file is File) {
          final stat = file.statSync();
          if (stat.modified.isBefore(cutoff)) {
            file.deleteSync();
            log(LogLevel.debug, 'Logger', 'Rotated old log: ${p.basename(file.path)}');
          }
        }
      }
    } catch (e) {
      debugPrint('Log rotation error: $e');
    }
  }

  // ── Log Management ──────────────────────────────────────────────────────

  Future<void> clear() async {
    _logs.clear();
    _logsNotifier.value = [];
    
    try {
      await _safeFlushFile();
      log(LogLevel.info, 'Logger', 'In-memory logs cleared by user. Persistent file retained.');
    } catch (e) {
      debugPrint('Failed to clear logs: $e');
    }
  }

  /// Export all persistent logs as a single string for sharing / bug reports
  Future<String?> exportLogs() async {
    try {
      if (_logDir == null) return null;
      
      final logDir = Directory(_logDir!);
      if (!logDir.existsSync()) return null;

      final buffer = StringBuffer();
      buffer.writeln('=== CapStudio Debug Report ===');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('Session: $_sessionId');
      buffer.writeln('Uptime: ${sessionUptime.inSeconds}s');
      buffer.writeln('Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      buffer.writeln('');

      // Collect all log files sorted by date, and cap to the last 3 files to prevent OOM (Finding 26)
      final logFiles = logDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      final filesToExport = logFiles.length > 3
          ? logFiles.sublist(logFiles.length - 3)
          : logFiles;

      for (final file in filesToExport) {
        buffer.writeln('--- ${p.basename(file.path)} ---');
        buffer.writeln(await file.readAsString());
        buffer.writeln('');
      }

      return buffer.toString();
    } catch (e) {
      error('Logger', 'Failed to export logs', error: e);
      return null;
    }
  }

  /// Get log file sizes for display in settings
  Future<Map<String, dynamic>> getLogStats() async {
    if (_logDir == null) return {'totalFiles': 0, 'totalSizeKB': 0};
    
    try {
      final logDir = Directory(_logDir!);
      if (!logDir.existsSync()) return {'totalFiles': 0, 'totalSizeKB': 0};

      final files = logDir.listSync().whereType<File>().toList();
      int totalSize = 0;
      for (final f in files) {
        totalSize += f.lengthSync();
      }
      return {
        'totalFiles': files.length,
        'totalSizeKB': (totalSize / 1024).round(),
        'sessionId': _sessionId,
        'uptimeSeconds': sessionUptime.inSeconds,
        'memoryLogCount': _logs.length,
        'minimumLevel': _minimumLevel.name,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Flush all buffered writes to disk (call before app exit).
  /// Sets [_disposing] before the final log write so that any concurrent
  /// log() calls (e.g. from parallel Future.wait teardown steps) are
  /// silently dropped instead of writing to a closing/closed IOSink.
  Future<void> dispose() async {
    if (_disposing) return; // Guard against double-dispose
    // Write the final session-end line BEFORE setting the flag.
    log(LogLevel.info, 'Logger', 'Session ending. Uptime: ${sessionUptime.inSeconds}s');
    _sessionTimer.stop();

    // Set flag AFTER the final log write — any log() calls from this point
    // (e.g. from AudioService.stopAll() running in parallel) will be dropped.
    _disposing = true;

    _notifyTimer?.cancel();
    _notifyTimer = null;

    // Capture references and null them out to prevent concurrent _writeToLogFile
    // from using the sinks while we are flushing/closing them.
    final fileSink = _fileSink;
    final jsonSink = _jsonSink;
    _fileSink = null;
    _jsonSink = null;

    try {
      await fileSink?.flush();
      await jsonSink?.flush();
      await fileSink?.close();
      await jsonSink?.close();
    } catch (e) {
      debugPrint('Error closing log sinks: $e');
    }
  }

  @visibleForTesting
  String colorize(LogEntry entry) => _colorize(entry);

  String _colorize(LogEntry entry) {
    const reset = '\x1B[0m';
    const gray = '\x1B[90m';
    
    final sourceStr = '\x1B[1m\x1B[38;5;114m[${entry.source}]\x1B[0m';
    final timeStr = '$gray[${entry.formattedTime}]$reset';

    String lvlStr;
    String msgColor;

    switch (entry.level) {
      case LogLevel.trace:
        lvlStr = '\x1B[1m\x1B[38;5;244m[TRACE  ]\x1B[0m';
        msgColor = '\x1B[90m';
        break;
      case LogLevel.debug:
        lvlStr = '\x1B[1m\x1B[38;5;75m[DEBUG  ]\x1B[0m';
        msgColor = '\x1B[38;5;75m';
        break;
      case LogLevel.info:
        lvlStr = '\x1B[1m\x1B[38;5;39m[INFO   ]\x1B[0m';
        msgColor = '\x1B[38;5;39m';
        break;
      case LogLevel.action:
        lvlStr = '\x1B[1m\x1B[38;5;170m[ACTION ]\x1B[0m';
        msgColor = '\x1B[38;5;170m';
        break;
      case LogLevel.warning:
        lvlStr = '\x1B[1m\x1B[30m\x1B[48;5;220m WARN   \x1B[0m';
        msgColor = '\x1B[33m';
        break;
      case LogLevel.error:
        lvlStr = '\x1B[1m\x1B[97m\x1B[41m ERROR  \x1B[0m';
        msgColor = '\x1B[31m';
        break;
    }

    final base = '$timeStr $lvlStr $sourceStr $msgColor${entry.message}$reset';

    if (entry.stackTrace != null) {
      final indentedStack = entry.stackTrace!
          .split('\n')
          .map((line) => '     \x1B[90m$line\x1B[0m')
          .join('\n');
      return '$base\n$indentedStack';
    }
    return base;
  }
}
