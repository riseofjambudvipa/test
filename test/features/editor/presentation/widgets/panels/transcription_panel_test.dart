import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/transcription_panel.dart';
import '../../../../../helpers/project_fixture.dart';
import '../../../../../helpers/widget_helpers.dart';

class MockIsarService extends Mock implements IsarService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Project testProject;
  late MockIsarService mockIsarService;

  setUpAll(() {
    registerFallbackValue(Project());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('capstudio_transcribe_test_');
    addTearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });
    AppDirs.setSupportPathForTesting(tempDir.path);
    await AppDirs.init();
    await SettingsService.instance.init();
    await SettingsService.instance.setWhisperModelPath('assets/models/ggml-tiny.bin');

    mockIsarService = MockIsarService();
    when(() => mockIsarService.isInitialized).thenReturn(true);
    when(() => mockIsarService.saveProject(any())).thenAnswer((_) async {});
    IsarService.instance = mockIsarService;

    testProject = makeProject(
      projectId: 'proj_transcribe_123',
      name: 'Transcribe Test Project',
      videoPath: 'test.mp4',
      duration: 15.0,
      width: 1080,
      height: 1920,
    );
  });

  testWidgets('TranscriptionPanel renders quality selector, language dropdown, translate toggle, and action buttons', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorProvider.notifier).setProject(testProject);

    await pumpTestWidget(
      tester,
      const TranscriptionPanel(),
      container: container,
    );
    await tester.pumpAndSettle();

    expect(find.text('SELECT TRANSCRIPTION QUALITY'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Translate captions to English'), findsOneWidget);
    expect(find.text('AI POST-PROCESSING'), findsOneWidget);
    expect(find.text('Auto-Add Magic Emojis'), findsOneWidget);
    expect(find.text('Auto-Add Magic SFX'), findsOneWidget);
    expect(find.text('START RE-TRANSCRIBE'), findsOneWidget);
    expect(find.text('IMPORT SRT/VTT FILE'), findsOneWidget);
  });
}
