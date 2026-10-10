import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/features/exporter/presentation/widgets/export_progress_sheet.dart';
import 'package:capstudio/core/video/viral_clip_models.dart';
import 'package:capstudio/core/audio/audio_mastering_models.dart';
import '../../../../helpers/project_fixture.dart';
import '../../../../helpers/widget_helpers.dart';

void main() {
  testWidgets('ExportProgressSheet renders elapsed time, eta, and cancel button', (tester) async {
    final project = makeProject(
      projectId: 'proj_export_test',
      name: 'Export Test Video',
      videoPath: 'test.mp4',
      duration: 10.0,
      width: 1080,
      height: 1920,
    );

    await pumpTestWidget(
      tester,
      ExportProgressSheet(
        project: project,
        outputFilePath: 'output.mp4',
        ffmpegPath: 'ffmpeg',
      ),
    );
    await tester.pump();

    expect(find.text('Elapsed Time'), findsOneWidget);
    expect(find.text('Estimated Remaining (ETA)'), findsOneWidget);
    expect(find.text('Cancel Export'), findsOneWidget);

    // Tap Cancel Export button
    await tester.tap(find.text('Cancel Export'));
    await tester.pump();
  });

  testWidgets('ExportProgressSheet initializes with conversionMode', (tester) async {
    final project = makeProject(
      projectId: 'proj_export_reframe_test',
      name: 'Reframe Export Test Video',
      videoPath: 'test.mp4',
      duration: 10.0,
      width: 1920,
      height: 1080,
    );

    await pumpTestWidget(
      tester,
      ExportProgressSheet(
        project: project,
        outputFilePath: 'output_reframe.mp4',
        ffmpegPath: 'ffmpeg',
        conversionMode: AspectConversionMode.centerCrop,
      ),
    );
    await tester.pump();

    expect(find.text('Elapsed Time'), findsOneWidget);
    expect(find.text('Cancel Export'), findsOneWidget);

    await tester.tap(find.text('Cancel Export'));
    await tester.pump();
  });

  testWidgets('ExportProgressSheet initializes with AudioMasteringConfig', (tester) async {
    final project = makeProject(
      projectId: 'proj_export_mastering_test',
      name: 'Mastering Export Test Video',
      videoPath: 'test.mp4',
      duration: 10.0,
      width: 1080,
      height: 1920,
    );

    await pumpTestWidget(
      tester,
      ExportProgressSheet(
        project: project,
        outputFilePath: 'output_mastered.mp4',
        ffmpegPath: 'ffmpeg',
        enableStudioSound: true,
        audioMastering: const AudioMasteringConfig(
          enableStudioSound: true,
          platform: AudioMasteringPlatform.socialShorts,
          enableDeEsser: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Elapsed Time'), findsOneWidget);
    expect(find.text('Cancel Export'), findsOneWidget);

    await tester.tap(find.text('Cancel Export'));
    await tester.pump();
  });
}
