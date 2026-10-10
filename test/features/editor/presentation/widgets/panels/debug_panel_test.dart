import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/logger/logger_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/debug_panel.dart';
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
    await SettingsService.instance.init();

    mockIsarService = MockIsarService();
    when(() => mockIsarService.isInitialized).thenReturn(true);
    when(() => mockIsarService.saveProject(any())).thenAnswer((_) async {});
    IsarService.instance = mockIsarService;

    testProject = makeProject(
      projectId: 'proj_debug_123',
      name: 'Debug Test Project',
      videoPath: 'test.mp4',
      duration: 10.0,
      width: 1080,
      height: 1920,
    );

    LoggerService.instance.log(LogLevel.info, 'DebugTest', 'Sample diagnostic log entry');
  });

  testWidgets('DebugPanel renders metrics, search input, filter chips, and log entries', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorProvider.notifier).setProject(testProject);

    await pumpTestWidget(
      tester,
      const DebugPanel(),
      container: container,
    );
    await tester.pumpAndSettle();

    expect(find.text('DIAGNOSTICS & TELEMETRY'), findsOneWidget);
    expect(find.text('SESSION UPTIME'), findsOneWidget);
    expect(find.text('VERBOSE DIAGNOSTIC MODE'), findsOneWidget);
    expect(find.text('CONSOLE FILTERS'), findsOneWidget);

    // Verify filter chips exist
    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('INFO'), findsWidgets);

    // Verify sample log message rendered
    expect(find.text('Sample diagnostic log entry'), findsOneWidget);
  });
}
