import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../../core/assets/asset_path_service.dart';
import '../../../../core/assets/asset_verification_service.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../../core/utils/platform_utils.dart';
import 'onboarding/tools_setup_step.dart';
import 'onboarding/assets_folder_step.dart';
import 'onboarding/packs_download_step.dart';
import '../../../../l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;

  Future<void> _completeOnboarding() async {
    await SettingsService.instance.setOnboardingComplete();
    if (mounted) {
      context.go('/');
    }
  }

  String _getPlatformBadge() {
    if (kIsWeb) return 'Web Studio';
    if (Platform.isAndroid || Platform.isIOS) return 'Mobile Studio';
    if (Platform.isWindows) return 'Windows Desktop';
    if (Platform.isMacOS) return 'macOS Desktop';
    if (Platform.isLinux) return 'Linux Desktop';
    return 'Desktop Edition';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12.0 : 24.0,
                vertical: isMobile ? 14.0 : 24.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0.0, constraints.maxHeight - (isMobile ? 28.0 : 48.0)),
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 640),
                    padding: EdgeInsets.all(isMobile ? 16.0 : 28.0),
                    decoration: AppTheme.glassDecoration(
                      color: AppTheme.cardBg.withValues(alpha: 0.88),
                      borderRadius: 20,
                      borderOpacity: 0.12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  // Logo Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentOrange.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(Icons.movie_creation_rounded, size: 28, color: AppTheme.accentOrange),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'CapStudio',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryText,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentOrange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.accentOrange.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getPlatformBadge(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentOrange,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            AppLocalizations.of(context)?.onboardingAppTagline ?? '100% Offline Local AI Caption Editor',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fade(duration: 400.ms).slideY(begin: -0.15),
                  const SizedBox(height: 20),

                  // Step Breadcrumbs
                  _buildStepIndicator(),

                  // Onboarding Steps
                  if (_currentStep == 0)
                    _buildStepWelcome(theme)
                  else if (_currentStep == 1)
                    ToolsSetupStep(
                      onContinue: () => setState(() => _currentStep = kDebugMode ? 2 : 3),
                      onSkip: () => setState(() => _currentStep = kDebugMode ? 2 : 3),
                    )
                  else if (_currentStep == 2)
                    AssetsFolderStep(
                      onBack: () => setState(() => _currentStep = 1),
                      onContinue: () => setState(() => _currentStep = 3),
                    )
                  else if (_currentStep == 3)
                    PacksDownloadStep(
                      onBack: () => setState(() => _currentStep = (AssetPathService.instance.isMobile || isLinuxSandboxed || kIsWeb) ? 0 : (kDebugMode ? 2 : 1)),
                      onContinue: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final l10n = AppLocalizations.of(context);
                        try {
                          await ref.read(assetVerificationProvider.notifier).reVerify();
                        } catch (e) {
                          LoggerService.instance.log(LogLevel.error, 'OnboardingScreen', 'Asset verification failed: $e');
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n?.assetVerificationFailed ??
                                    'Asset verification failed. Please ensure assets downloaded properly.'),
                                backgroundColor: AppTheme.accentRed,
                              ),
                            );
                          }
                          return;
                        }
                        if (mounted) {
                          setState(() => _currentStep = 4);
                        }
                      },
                    )
                  else if (_currentStep == 4)
                    _buildStepComplete(theme),
                ],
              ),
            ),
          ),
        ),
      );
    },
  ),
),
);
}

  Widget _buildStepIndicator() {
    final List<(String, int)> steps;
    if (kIsWeb) {
      steps = const [('Welcome', 0), ('Ready', 4)];
    } else if (AssetPathService.instance.isMobile || isLinuxSandboxed) {
      steps = const [('Welcome', 0), ('Content', 3), ('Ready', 4)];
    } else if (!kDebugMode) {
      // In release: assets folder defaults strictly to C:\ without prompting user
      steps = const [
        ('Welcome', 0),
        ('Engines', 1),
        ('Content', 3),
        ('Ready', 4),
      ];
    } else {
      // In developer/debug mode: allow custom storage folder selection
      steps = const [
        ('Welcome', 0),
        ('Engines', 1),
        ('Storage', 2),
        ('Content', 3),
        ('Ready', 4),
      ];
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 450;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(steps.length, (index) {
          final targetStep = steps[index].$2;
          final isCompleted = _currentStep > targetStep;
          final isCurrent = _currentStep == targetStep;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isCurrent ? (isCompact ? 22 : 24) : (isCompact ? 16 : 18),
                height: isCompact ? 16 : 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppTheme.accentOrange
                      : (isCompleted ? AppTheme.accentGreen.withValues(alpha: 0.2) : AppTheme.cardBg),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isCurrent
                        ? AppTheme.accentOrange
                        : (isCompleted ? AppTheme.accentGreen : AppTheme.borderGlass),
                    width: 1,
                  ),
                ),
                child: isCompleted
                    ? Icon(Icons.check, size: isCompact ? 9 : 11, color: AppTheme.accentGreen)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: isCompact ? 8 : 9,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? AppTheme.onAccentText : AppTheme.secondaryText,
                        ),
                      ),
              ),
              if (index < steps.length - 1)
                Container(
                  width: isCompact ? 10 : 14,
                  height: 2,
                  margin: EdgeInsets.symmetric(horizontal: isCompact ? 2 : 3),
                  color: isCompleted ? AppTheme.accentGreen.withValues(alpha: 0.4) : AppTheme.borderGlass,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepWelcome(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('step_welcome'),
      children: [
        Text(
          l10n?.welcomeTitle ?? 'Welcome to CapStudio',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          Icons.security_rounded,
          l10n?.onboardingFeaturePrivacy ?? '100% Privacy & Local AI',
          l10n?.onboardingFeaturePrivacyDesc ?? 'Your files never leave your device. All AI models run locally.',
        ),
        _buildFeatureCard(
          Icons.speed_rounded,
          l10n?.onboardingFeatureGpu ?? 'GPU Accelerated Playback',
          l10n?.onboardingFeatureGpuDesc ?? 'High performance video editing using hardware decoding.',
        ),
        _buildFeatureCard(
          Icons.auto_awesome_rounded,
          l10n?.onboardingFeatureAssets ?? 'Offline Sidecar Assets',
          l10n?.onboardingFeatureAssetsDesc ?? 'Download rich emoji packs once and run completely offline.',
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                if (kIsWeb) {
                  _currentStep = 4;
                } else if (AssetPathService.instance.isMobile) {
                  _currentStep = 3;
                } else if (isLinuxSandboxed) {
                  _currentStep = 3;
                } else {
                  _currentStep = 1;
                }
              });
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(l10n?.btnGetStarted ?? 'Get Started', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: AppTheme.onAccentText,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildStepComplete(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('step_complete'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.accentGreen.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(Icons.check_circle_rounded, size: 52, color: AppTheme.accentGreen),
        ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.bounceOut),
        const SizedBox(height: 16),
        Text(
          l10n?.onboardingReadyTitle ?? "You're Ready to Roll!",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n?.onboardingConfigDetails ?? 'Configuration Details:',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBg.withValues(alpha: 0.4),
            borderRadius: 12,
            borderOpacity: 0.08,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kIsWeb) ...[
                _buildConfigSummary('Execution Environment', 'In-Browser WebAssembly + Web Audio'),
                Divider(color: AppTheme.dividerColor, height: 16),
                _buildConfigSummary('Speech-to-Text Engine', 'Transformers.js (ONNX Runtime Web)'),
                Divider(color: AppTheme.dividerColor, height: 16),
                _buildConfigSummary('Video Subtitle Burning', 'FFmpeg.wasm (SharedArrayBuffer)'),
              ] else if (AssetPathService.instance.isMobile) ...[
                _buildConfigSummary('Execution Mode', 'Mobile On-Device Engine'),
                Divider(color: AppTheme.dividerColor, height: 16),
                _buildConfigSummary(l10n?.configLabelAssetsLocation ?? 'Assets Location', AssetPathService.instance.assetsRoot),
              ] else ...[
                _buildConfigSummary(l10n?.configLabelWhisperCli ?? 'Whisper CLI', (SettingsService.instance.whisperCliPath ?? '').isEmpty ? (l10n?.configValueDemoMode ?? 'Demo Mode (Mock)') : (SettingsService.instance.whisperCliPath ?? '')),
                Divider(color: AppTheme.dividerColor, height: 16),
                _buildConfigSummary(l10n?.configLabelFfmpegCli ?? 'FFmpeg CLI', (SettingsService.instance.ffmpegCliPath ?? '').isEmpty ? (l10n?.configValueSystemPathDefault ?? 'System PATH default') : (SettingsService.instance.ffmpegCliPath ?? '')),
                Divider(color: AppTheme.dividerColor, height: 16),
                _buildConfigSummary(l10n?.configLabelAssetsLocation ?? 'Assets Location', AssetPathService.instance.assetsRoot),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _completeOnboarding,
            icon: const Icon(Icons.rocket_launch_rounded, size: 18),
            label: Text(l10n?.btnLaunchCapStudio ?? 'Launch CapStudio', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: AppTheme.onAccentText,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBgElevated.withValues(alpha: 0.35),
        borderRadius: 12,
        borderOpacity: 0.08,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.accentOrange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryText, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: AppTheme.secondaryText, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSummary(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.mutedText, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.secondaryText),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
