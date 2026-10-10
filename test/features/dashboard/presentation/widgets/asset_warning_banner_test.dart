import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/assets/asset_verification_service.dart';
import 'package:capstudio/features/dashboard/presentation/widgets/asset_warning_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    required AssetVerificationResult verificationResult,
    bool dismissed = false,
  }) {
    return ProviderScope(
      overrides: [
        assetVerificationProvider.overrideWith((ref) => AssetVerificationNotifier(verificationResult, ref)),
        optionalAssetBannerDismissedProvider.overrideWith((ref) => dismissed),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: AssetWarningBanner(),
        ),
      ),
    );
  }

  group('AssetWarningBanner Tests', () {
    testWidgets('renders nothing when all assets are installed', (tester) async {
      const allGood = AssetVerificationResult(
        allRequiredPresent: true,
        missing: [],
        installedPackIds: ['googleNonAnimated', 'openmoji'],
        hasAnyEmojis: true,
      );

      await tester.pumpWidget(buildTestWidget(verificationResult: allGood));
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Emoji Packs Available'), findsNothing);
      expect(find.text('Required Assets Missing'), findsNothing);
    });

    testWidgets('renders urgent warning when required assets are missing', (tester) async {
      const requiredMissing = AssetVerificationResult(
        allRequiredPresent: false,
        missing: [
          MissingAsset(
            packId: 'font_roboto',
            packName: 'Roboto Font',
            isRequired: true,
            userMessage: 'Roboto Font required',
          ),
        ],
        installedPackIds: [],
        hasAnyEmojis: false,
      );

      await tester.pumpWidget(buildTestWidget(verificationResult: requiredMissing));
      await tester.pumpAndSettle();

      expect(find.text('Required Assets Missing'), findsOneWidget);
      expect(find.textContaining('Roboto Font'), findsOneWidget);
      expect(find.text('Install Now'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      // Dismiss button is not shown for urgent required warnings
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('renders discovery alert when optional emoji packs are missing', (tester) async {
      const optionalMissing = AssetVerificationResult(
        allRequiredPresent: true,
        missing: [
          MissingAsset(
            packId: 'openmoji',
            packName: 'OpenMoji',
            isRequired: false,
            userMessage: 'OpenMoji not installed',
          ),
          MissingAsset(
            packId: 'microsoftAnimated',
            packName: 'FluentUI Animated',
            isRequired: false,
            userMessage: 'FluentUI Animated not installed',
          ),
        ],
        installedPackIds: ['googleNonAnimated'],
        hasAnyEmojis: true,
      );

      await tester.pumpWidget(buildTestWidget(verificationResult: optionalMissing));
      await tester.pumpAndSettle();

      expect(find.text('Emoji Packs Available'), findsOneWidget);
      expect(find.textContaining('2 optional emoji packs can be installed'), findsOneWidget);
      expect(find.text('Manage Packs'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);
      // Dismiss button should be present
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('renders nothing when optional banner is dismissed', (tester) async {
      const optionalMissing = AssetVerificationResult(
        allRequiredPresent: true,
        missing: [
          MissingAsset(
            packId: 'openmoji',
            packName: 'OpenMoji',
            isRequired: false,
            userMessage: 'OpenMoji not installed',
          ),
        ],
        installedPackIds: [],
        hasAnyEmojis: false,
      );

      await tester.pumpWidget(buildTestWidget(
        verificationResult: optionalMissing,
        dismissed: true,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Emoji Packs Available'), findsNothing);
    });
  });
}
