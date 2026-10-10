import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/logger/logger_service.dart';
import '../../test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  registerTestEnvironment(silenceLogs: true);

  late LoggerService logger;

  setUp(() {
    logger = LoggerService.instance;
  });

  group('LoggerService Tests', () {
    test('should initialize files and directories correctly under AppDirs', () {
      expect(logger.logDirectory, isNotNull);
      expect(logger.logFilePath, isNotNull);
      expect(File(logger.logFilePath!).existsSync(), isTrue);

      final jsonLogPath = logger.logFilePath!.replaceAll('.log', '.jsonl');
      expect(File(jsonLogPath).existsSync(), isTrue);
    });

    test('should log and filter entries by level correctly', () async {
      logger.setMinimumLevel(LogLevel.warning);
      
      // Clear memory buffer
      await logger.clear();
      
      logger.log(LogLevel.info, 'TestSource', 'Info message (filtered)');
      logger.log(LogLevel.warning, 'TestSource', 'Warning message (logged)');
      logger.log(LogLevel.error, 'TestSource', 'Error message (logged)');

      final logs = logger.logs;
      // Info should be skipped due to minimum warning filter, warning and error retained
      expect(logs.length, 2);
      expect(logs[0].level, LogLevel.error);
      expect(logs[1].level, LogLevel.warning);
      expect(logs[1].message, 'Warning message (logged)');
    });

    test('LogEntry toString and toJson formatters work correctly', () {
      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.action,
        source: 'UI',
        message: 'Tap button',
        stackTrace: 'custom_stack',
      );

      final text = entry.toString();
      expect(text, contains('[ACTION ] [UI] Tap button'));
      expect(text, contains('STACK: custom_stack'));

      final jsonText = entry.toJson();
      expect(jsonText, contains('"level":"action"'));
      expect(jsonText, contains('"source":"UI"'));
      expect(jsonText, contains('"msg":"Tap button"'));
      expect(jsonText, contains('"stack":"custom_stack"'));
    });

    test('should enforce memory log ring buffer maximum limit of 500 logs', () async {
      logger.setMinimumLevel(LogLevel.trace);
      await logger.clear();

      // Log 600 items
      for (int i = 0; i < 600; i++) {
        logger.log(LogLevel.trace, 'Source', 'Log number $i');
      }

      // Memory logs must be capped at max limit
      expect(logger.logs.length, 500);
      
      // The oldest ones should be popped out, so the last memory log (oldest remaining) should be "Log number 100"
      expect(logger.logs.last.message, 'Log number 100');
      expect(logger.logs.first.message, 'Log number 599');
    });

    test('Performance timers should capture execution duration accurately', () async {
      logger.startTimer('heavy_op');
      await Future.delayed(const Duration(milliseconds: 100));
      final duration = logger.stopTimer('heavy_op');

      expect(duration, isNotNull);
      expect(duration.inMilliseconds, greaterThanOrEqualTo(90));
    });

    test('should sort logs in descending chronological order (newest first)', () async {
      logger.setMinimumLevel(LogLevel.trace);
      await logger.clear();

      logger.log(LogLevel.info, 'Source', 'First logged (oldest)');
      await Future.delayed(const Duration(milliseconds: 1));
      logger.log(LogLevel.info, 'Source', 'Second logged');
      await Future.delayed(const Duration(milliseconds: 1));
      logger.log(LogLevel.info, 'Source', 'Third logged (newest)');

      final logs = logger.logs;
      expect(logs.length, 4);
      expect(logs[0].message, 'Third logged (newest)');
      expect(logs[1].message, 'Second logged');
      expect(logs[2].message, 'First logged (oldest)');
      expect(logs[3].message, contains('In-memory logs cleared by user'));
      
      expect(logs[0].timestamp.isAfter(logs[1].timestamp), isTrue);
      expect(logs[1].timestamp.isAfter(logs[2].timestamp), isTrue);
    });

    test('colorize generates correct ANSI escapes for all LogLevels', () {
      final now = DateTime.now();
      
      for (final level in LogLevel.values) {
        final entry = LogEntry(
          timestamp: now,
          level: level,
          source: 'Test',
          message: 'Color test for ${level.name}',
          stackTrace: level == LogLevel.error ? 'DummyStack' : null,
        );

        final colored = logger.colorize(entry);
        expect(colored, contains('Color test for ${level.name}'));
        expect(colored, contains('[Test]'));
        
        switch (level) {
          case LogLevel.trace:
            expect(colored, contains('\x1B[1m\x1B[38;5;244m[TRACE  ]\x1B[0m'));
            break;
          case LogLevel.debug:
            expect(colored, contains('\x1B[1m\x1B[38;5;75m[DEBUG  ]\x1B[0m'));
            break;
          case LogLevel.info:
            expect(colored, contains('\x1B[1m\x1B[38;5;39m[INFO   ]\x1B[0m'));
            break;
          case LogLevel.action:
            expect(colored, contains('\x1B[1m\x1B[38;5;170m[ACTION ]\x1B[0m'));
            break;
          case LogLevel.warning:
            expect(colored, contains('\x1B[1m\x1B[30m\x1B[48;5;220m WARN   \x1B[0m'));
            break;
          case LogLevel.error:
            expect(colored, contains('\x1B[1m\x1B[97m\x1B[41m ERROR  \x1B[0m'));
            expect(colored, contains('DummyStack'));
            break;
        }
      }
    });

    test('scrubPii removes username and user profile paths from strings', () {
      final username = Platform.environment['USERNAME'] ?? Platform.environment['USER'];
      final homeDir = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];

      if (username != null && username.length > 2) {
        final scrubbed = logger.scrubPii('Error occurred for user $username at runtime');
        expect(scrubbed, contains('<USER>'));
        expect(scrubbed, isNot(contains(username)));
      }

      if (homeDir != null && homeDir.isNotEmpty) {
        final scrubbed = logger.scrubPii('Failed to open file at $homeDir/project.json');
        expect(scrubbed, contains('<USER_HOME>'));
        expect(scrubbed, isNot(contains(homeDir)));
      }
    });
  });
}
