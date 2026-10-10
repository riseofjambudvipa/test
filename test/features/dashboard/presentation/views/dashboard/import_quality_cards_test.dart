import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/features/dashboard/presentation/views/dashboard/import_quality_cards.dart';
import 'package:capstudio/core/downloader/binary_download_models.dart';
import 'package:capstudio/core/utils/native_helper.dart';
import 'package:capstudio/core/whisper/whisper_model.dart';
import '../../../../../helpers/widget_helpers.dart';

void main() {
  testWidgets('ImportQualityCards renders all quality modes and handles taps', (tester) async {
    QualityMode? selected;
    WhisperModel? downloadedModel;

    final hardware = const SystemHardwareInfo(
      ramGB: 16.0,
      cpuCores: 8,
      hasGpu: true,
      gpuInfo: 'NVIDIA GeForce RTX 3080',
    );

    await pumpTestWidget(
      tester,
      SingleChildScrollView(
        child: ImportQualityCards(
          selectedQuality: QualityMode.balanced,
          hardwareInfo: hardware,
          modelExists: const {'tiny': true, 'base': false, 'small': true},
          downloadProgressMap: const {},
          onSelectQuality: (mode) => selected = mode,
          onDownloadModel: (model) => downloadedModel = model,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify quality mode names are present
    expect(find.text(QualityMode.balanced.displayName), findsOneWidget);
    expect(find.text(QualityMode.fast.displayName), findsOneWidget);

    // Tap on Fast card
    await tester.tap(find.text(QualityMode.fast.displayName));
    await tester.pumpAndSettle();

    expect(selected, QualityMode.fast);

    // Tap download button on base model (which is not downloaded)
    final downloadButtons = find.widgetWithText(ElevatedButton, 'Download');
    if (downloadButtons.evaluate().isNotEmpty) {
      await tester.tap(downloadButtons.first);
      await tester.pumpAndSettle();
      expect(downloadedModel, isNotNull);
    }
  });

  testWidgets('ImportQualityCards renders active downloading progress', (tester) async {
    const downloadProgress = BinaryDownloadProgress(
      toolId: 'model_base',
      status: BinaryDownloadStatus.downloading,
      downloadProgress: 0.65,
    );

    await pumpTestWidget(
      tester,
      SingleChildScrollView(
        child: ImportQualityCards(
          selectedQuality: QualityMode.balanced,
          hardwareInfo: null,
          modelExists: const {'base': false},
          downloadProgressMap: const {'base': downloadProgress},
          onSelectQuality: (_) {},
          onDownloadModel: (_) {},
        ),
      ),
    );
    await tester.pump();

    // Verify downloading percent is rendered
    expect(find.text('65%'), findsOneWidget);
  });
}
