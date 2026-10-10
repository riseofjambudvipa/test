import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:capstudio/core/assets/asset_verification_service.dart';
import 'package:capstudio/features/settings/presentation/views/pack_manager_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_helpers.dart';

void main() {
  testWidgets('PackManagerScreen renders title, storage usage, and content sections', (tester) async {
    final mockManifest = AssetManifest(
      version: '2.0',
      packs: [
        const AssetPack(
          id: 'google_noto_emojis_animated',
          name: 'Google Noto Animated Emojis',
          description: 'Smooth animated Google Noto emojis',
          required: true,
          sizeBytes: 120 * 1024 * 1024,
          compressedSizeBytes: 60 * 1024 * 1024,
          downloadUrl: 'https://example.com/noto.zip',
          checksum: 'mocksha',
          version: '1.0',
          fileCount: 500,
          format: 'webp',
          animated: true,
          localFolder: 'google_noto_emojis_animated_pack',
        ),
      ],
      emojis: [],
    );

    const mockVerification = AssetVerificationResult(
      allRequiredPresent: true,
      missing: [],
      installedPackIds: ['google_noto_emojis_animated'],
      hasAnyEmojis: true,
    );

    await pumpTestWidget(
      tester,
      const PackManagerScreen(),
      overrides: [
        assetManifestProvider.overrideWithValue(mockManifest),
        assetVerificationProvider.overrideWith((ref) => AssetVerificationNotifier(mockVerification)),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Manage Content Packs'), findsOneWidget);
    expect(find.text('Total Disk Storage Space Used'), findsOneWidget);
    expect(find.text('EMOJI STYLE PACKS'), findsOneWidget);
    expect(find.text('USER CUSTOM STICKERS'), findsOneWidget);
    expect(find.text('ASSET FOLDER CONFIGURATION'), findsOneWidget);
    expect(find.text('Google Noto Animated Emojis'), findsOneWidget);
  });
}
