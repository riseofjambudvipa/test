import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import '../../test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = null;
    await Isar.initializeIsarCore(download: true);
  });

  registerTestEnvironment(
    initialPreferences: {
      'db_schema_version': 0,
    },
    silenceLogs: true,
  );

  Project createTestProject(String projectId, String name, DateTime createdAt) {
    return Project()
      ..projectId = projectId
      ..name = name
      ..videoPath = 'video_$projectId.mp4'
      ..duration = 15.5
      ..width = 1080
      ..height = 1920
      ..createdAt = createdAt
      ..trimStart = 0.0
      ..trimEnd = 15.5
      ..status = 'draft'
      ..config = (ProjectConfigSchema()
        ..name = 'default'
        ..style = (StyleConfigSchema()
          ..fontFamily = 'Montserrat'
          ..fontWeight = '800'
          ..textTransform = 'uppercase'
          ..color = '#ffffff'
          ..fontSize = 24.0
          ..top = 70.0)
        ..highlightStyle = (HighlightStyleSchema()
          ..mainColor = '#f97316'
          ..secondColor = '#06b6d4'
          ..thirdColor = '#22c55e')
        ..subs = (SubtitleConfigSchema()
          ..chunkSize = 2
          ..chunkLineMaxLength = 20)
        ..animation = 'pop'
        ..shadow = 'soft'
        ..stroke = 'none')
      ..words = [
        WordSchema()
          ..wordId = 'w1_$projectId'
          ..text = 'Hello'
          ..start = 1.0
          ..end = 1.5
          ..type = 'word'
          ..confidence = 0.95,
        WordSchema()
          ..wordId = 'w2_$projectId'
          ..text = 'World'
          ..start = 1.6
          ..end = 2.0
          ..type = 'word'
          ..confidence = 0.88,
      ];
  }

  group('IsarService Complete Database Integration Tests', () {
    test('throws StateError when accessing db getter before initialization', () {
      final isarService = IsarService.instance;
      // Ensure we are in closed uninitialized state
      try {
        if (isarService.isInitialized) {
          isarService.close();
        }
      } catch (_) {}

      expect(() => isarService.db, throwsStateError);
    });

    test('initializes database, runs schema verification, and migrates successfully', () async {
      final isarService = IsarService.instance;
      try {
        if (isarService.isInitialized) {
          await isarService.close();
        }
      } catch (_) {}

      expect(isarService.isInitialized, isFalse);
      await isarService.init();
      expect(isarService.isInitialized, isTrue);
      expect(SettingsService.instance.dbSchemaVersion, 1);
    });

    test('IsarService double initialization is idempotent and does not throw', () async {
      final isarService = IsarService.instance;
      try {
        if (isarService.isInitialized) {
          await isarService.close();
        }
      } catch (_) {}

      expect(isarService.isInitialized, isFalse);
      
      // Initialize once
      await isarService.init();
      expect(isarService.isInitialized, isTrue);
      
      // Initialize again
      await expectLater(isarService.init(), completes);
      expect(isarService.isInitialized, isTrue);
    });

    test('supports full CRUD cycle (Create, Read, Update, Delete) on project models', () async {
      final isarService = IsarService.instance;
      await isarService.init();

      const testId = 'proj_crud_999';
      final initialProject = createTestProject(testId, 'CRUD Test Project', DateTime.now());

      // 1. Create (Insert)
      await isarService.saveProject(initialProject);

      // 2. Read (Query)
      final retrieved = await isarService.getProject(testId);
      expect(retrieved, isNotNull);
      expect(retrieved!.projectId, testId);
      expect(retrieved.name, 'CRUD Test Project');
      expect(retrieved.words.length, 2);
      expect(retrieved.words[0].text, 'Hello');
      expect(retrieved.words[1].text, 'World');

      // 3. Update — clone the retrieved project before modifying (never mutate Isar objects in-place)
      final updatedWords = List<WordSchema>.from(retrieved.words)
        ..add(
          WordSchema()
            ..wordId = 'w3_extra'
            ..text = 'Added'
            ..start = 2.1
            ..end = 2.5
            ..type = 'word'
            ..confidence = 1.0,
        );
      final cloned = Project()
        ..id = retrieved.id
        ..projectId = retrieved.projectId
        ..name = 'Updated Project Name'
        ..videoPath = retrieved.videoPath
        ..duration = retrieved.duration
        ..width = retrieved.width
        ..height = retrieved.height
        ..createdAt = retrieved.createdAt
        ..trimStart = retrieved.trimStart
        ..trimEnd = retrieved.trimEnd
        ..status = retrieved.status
        ..thumbnailPath = retrieved.thumbnailPath
        ..config = retrieved.config
        ..words = updatedWords
        ..segments = retrieved.segments;
      await isarService.saveProject(cloned);

      final updated = await isarService.getProject(testId);
      expect(updated, isNotNull);
      expect(updated!.name, 'Updated Project Name');
      expect(updated.words.length, 3);
      expect(updated.words[2].text, 'Added');

      // 4. Delete
      await isarService.deleteProject(retrieved.id);

      final queryAfterDelete = await isarService.getProject(testId);
      expect(queryAfterDelete, isNull);

      // Delete non-existent ID does not throw
      await isarService.deleteProject(999999);
    });

    test('queries all projects sorted by createdAt descending', () async {
      final isarService = IsarService.instance;
      await isarService.init();

      // Clear existing database records to have a clean slate for sorting assertions
      final existing = await isarService.getAllProjects();
      for (final p in existing) {
        await isarService.deleteProject(p.id);
      }

      final now = DateTime.now();
      final pOld = createTestProject('old_id', 'Old Project', now.subtract(const Duration(hours: 2)));
      final pMid = createTestProject('mid_id', 'Mid Project', now.subtract(const Duration(hours: 1)));
      final pNew = createTestProject('new_id', 'New Project', now);

      // Save in out-of-order sequence
      await isarService.saveProject(pMid);
      await isarService.saveProject(pOld);
      await isarService.saveProject(pNew);

      // Fetch all projects
      final list = await isarService.getAllProjects();
      expect(list.length, 3);

      // Assert precise sorting order: newest first, oldest last
      expect(list[0].projectId, 'new_id');
      expect(list[1].projectId, 'mid_id');
      expect(list[2].projectId, 'old_id');
    });

    test('auto-recovers and opens a fresh database when the database file is corrupted', () async {
      final isarService = IsarService.instance;
      
      // 1. Ensure we start closed
      if (isarService.isInitialized) {
        await isarService.close();
      }

      // 2. Write completely invalid garbage bytes to the database file path to simulate corruption
      // We write 100KB of garbage to guarantee that the MDBX engine detects the file format violation and fails.
      final dbDir = AppDirs.support;
      final dbFile = File(p.join(dbDir, 'capstudio_db.isar'));
      dbFile.parent.createSync(recursive: true);
      final garbageBytes = List<int>.generate(100 * 1024, (i) => i % 256);
      dbFile.writeAsBytesSync(garbageBytes);

      expect(dbFile.existsSync(), isTrue);

      // 3. Trigger database initialization (which will fail to open the garbage file and trigger auto-recovery)
      await isarService.init();

      // 4. Verify database opened successfully anyway
      expect(isarService.isInitialized, isTrue);
      expect(isarService.db.isOpen, isTrue);

      // 5. Verify backup was created and corrupted file was deleted/moved
      expect(isarService.lastAutoRecoveredBackupPath, isNotNull);
      final backupFile = File(isarService.lastAutoRecoveredBackupPath!);
      expect(backupFile.existsSync(), isTrue);
      expect(backupFile.readAsBytesSync(), garbageBytes);

      // 6. Verify we can still perform CRUD operations on the fresh database
      final testProj = createTestProject('recovered_proj_1', 'Recovered Project', DateTime.now());
      await isarService.saveProject(testProj);
      final retrieved = await isarService.getProject('recovered_proj_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Recovered Project');
    });
  });
}
