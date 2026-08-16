import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../../core/assets/asset_path_service.dart';
import '../../../../core/assets/asset_verification_service.dart';
import '../../../../core/utils/platform_utils.dart';
import 'onboarding/tools_setup_step.dart';
import 'onboarding/assets_folder_step.dart';
import 'onboarding/packs_download_step.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: AppTheme.glassDecoration(
                color: AppTheme.cardBg.withValues(alpha: 0.8),
                borderRadius: 16,
                borderOpacity: 0.08,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie_creation_outlined, size: 36, color: AppTheme.accentOrange),
                      const SizedBox(width: 12),
                      Text(
                        'CapStudio',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 500.ms).slideY(begin: -0.2),
                  const SizedBox(height: 8),
                  Text(
                    '100% Offline Local AI Caption Editor',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryText),
                  ),
                  const SizedBox(height: 32),

                  // Onboarding Steps
                  if (_currentStep == 0)
                    _buildStepWelcome(theme)
                  else if (_currentStep == 1)
                    ToolsSetupStep(
                      onContinue: () => setState(() => _currentStep = 2),
                      onSkip: () => setState(() => _currentStep = 2),
                    )
                  else if (_currentStep == 2)
                    AssetsFolderStep(
                      onBack: () => setState(() => _currentStep = 1),
                      onContinue: () => setState(() => _currentStep = 3),
                    )
                  else if (_currentStep == 3)
                    PacksDownloadStep(
                      onBack: () => setState(() => _currentStep = 2),
                      onContinue: () async {
                        await ref.read(assetVerificationProvider.notifier).reVerify();
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
      ),
    );
  }

  Widget _buildStepWelcome(ThemeData theme) {
    return Column(
      key: const ValueKey('step_welcome'),
      children: [
        Text(
          'Welcome to CapStudio',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _buildFeatureRow(Icons.privacy_tip_outlined, '100% Privacy', 'Your files never leave your device. All AI models run locally.'),
        _buildFeatureRow(Icons.bolt, 'GPU Accelerated Playback', 'High performance video editing using hardware decoding.'),
        _buildFeatureRow(Icons.download_for_offline_outlined, 'Offline Sidecar Assets', 'Download rich emoji packs once and run completely offline.'),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (AssetPathService.instance.isMobile) {
                _currentStep = 3; // Skip tools & folder picker on mobile, go to download
              } else if (isLinuxSandboxed) {
                // In Linux sandbox, binaries and assets folder are handled by system
                _currentStep = 3;
              } else {
                _currentStep = 1;
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildStepComplete(ThemeData theme) {
    return Column(
      key: const ValueKey('step_complete'),
      children: [
        Icon(Icons.check_circle_outline, size: 64, color: AppTheme.accentGreen)
            .animate()
            .scale(delay: 100.ms, duration: 400.ms, curve: Curves.bounceOut),
        const SizedBox(height: 16),
        Text(
          "You're Ready to Roll!",
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'Configuration Details:',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBg.withValues(alpha: 0.25),
            borderRadius: 8,
            borderOpacity: 0.06,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!AssetPathService.instance.isMobile) ...[
                _buildConfigSummary('Whisper CLI', (SettingsService.instance.whisperCliPath ?? '').isEmpty ? 'Demo Mode (Mock)' : (SettingsService.instance.whisperCliPath ?? '')),
                const Divider(color: Colors.white10, height: 16),
                _buildConfigSummary('FFmpeg CLI', (SettingsService.instance.ffmpegCliPath ?? '').isEmpty ? 'System PATH default' : (SettingsService.instance.ffmpegCliPath ?? '')),
                const Divider(color: Colors.white10, height: 16),
              ],
              _buildConfigSummary('Assets Location', AssetPathService.instance.assetsRoot),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _completeOnboarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Launch CapStudio', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.accentOrange),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
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
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
