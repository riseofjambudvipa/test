import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/settings/settings_service.dart';
import '../core/assets/asset_path_service.dart';
import '../features/dashboard/presentation/views/dashboard_screen.dart';
import '../features/editor/presentation/views/editor_screen.dart';
import '../features/onboarding/presentation/views/onboarding_screen.dart';
import '../features/onboarding/presentation/views/assets_folder_recovery_screen.dart';
import '../features/settings/presentation/views/settings_screen.dart';
import '../features/settings/presentation/views/pack_manager_screen.dart';
import '../features/settings/presentation/views/settings/about_app_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.accentOrange, size: 64),
            const SizedBox(height: 16),
            Text(
              '404 - Page Not Found',
              style: TextStyle(color: AppTheme.primaryText, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The path "${state.uri.path}" could not be resolved.',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: AppTheme.onAccentText,
              ),
              onPressed: () => GoRouter.of(context).go('/'),
              child: Text(
                AppLocalizations.of(context)?.returnToDashboard ??
                    'Return to Dashboard',
              ),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      final onboarded = SettingsService.instance.onboardingComplete;
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';
      final isGoingToRecovery = state.matchedLocation == '/onboarding/recover-assets';
      
      if (!onboarded) {
        if (isGoingToOnboarding) return null;
        return '/onboarding';
      }

      // Desktop only: check if asset root directory exists on disk.
      // If not, redirect to recovery screen.
      if (AssetPathService.instance.isDesktop) {
        final exists = AssetPathService.instance.assetsRootExists;
        if (!exists && !isGoingToRecovery) {
          return '/onboarding/recover-assets';
        }
      }
      
      if (isGoingToOnboarding) {
        return '/';
      }
      if (isGoingToRecovery) {
        final exists = AssetPathService.instance.assetsRootExists;
        if (exists) return '/';
        return null;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/recover-assets',
        builder: (context, state) => const AssetsFolderRecoveryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/packs',
        builder: (context, state) => const PackManagerScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const AboutAppScreen(),
      ),
      GoRoute(
        path: '/editor/:projectId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'];
          if (projectId == null || projectId.isEmpty) {
            return Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: Text(
                  'Error: Project ID is missing or invalid.',
                  style: TextStyle(color: AppTheme.primaryText, fontSize: 16),
                ),
              ),
            );
          }
          return EditorScreen(projectId: projectId);
        },
      ),
    ],
  );
});
