import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart' hide AssetManifest;
import 'app/theme.dart';
import 'app/theme_provider.dart';
import 'app/routes.dart';
import 'core/database/isar_service.dart';
import 'core/logger/logger_service.dart';
import 'core/assets/asset_manifest.dart';
import 'core/assets/asset_verification_service.dart';
import 'core/audio/audio_service.dart';
import 'core/utils/platform_utils.dart';
import 'core/whisper/whisper_mobile_service.dart';
import 'features/editor/presentation/controllers/editor_controller.dart';
import 'app/initialization_error_app.dart';
import 'core/initialization/app_initializer.dart';
import 'core/utils/premium_blur_dialog.dart';
import 'l10n/app_localizations.dart';
import 'app/locale_provider.dart';

void main() {
  // Wrap entire app in crash-capture zone
  runZonedGuarded(() async {
    Future<void> boot() async {
      try {
        final initResult = await AppInitializer.boot();

        runApp(
          ProviderScope(
            overrides: [
              assetManifestProvider.overrideWithValue(initResult.manifest),
              assetVerificationProvider.overrideWith((ref) => AssetVerificationNotifier(initResult.verification, ref)),
            ],
            child: const CapStudioApp(),
          ),
        );
      } catch (error, stackTrace) {
        // Log to advanced logger if initialized, otherwise fallback to debugPrint
        if (LoggerService.instance.isInitialized) {
          LoggerService.instance.logCrash(error, stackTrace, context: AppInitializer.initContext);
        } else {
          debugPrint('CRITICAL: Fatal initialization error: $error\n$stackTrace');
        }

        runApp(
          InitializationErrorApp(
            error: LoggerService.instance.scrubPii(error.toString()),
            stackTrace: LoggerService.instance.scrubPii(stackTrace.toString()),
            onRetry: () {
              try {
                IsarService.instance.close();
              } catch (e) {
                debugPrint('Failed to close IsarService on retry: $e');
              }
              try {
                LoggerService.instance.dispose();
              } catch (e) {
                debugPrint('Failed to dispose LoggerService on retry: $e');
              }
              boot();
            },
          ),
        );
      }
    }

    await boot();
  }, (error, stackTrace) {
    // Catch ALL unhandled async exceptions in the entire app
    if (LoggerService.instance.isInitialized) {
      LoggerService.instance.logCrash(error, stackTrace, context: 'runZonedGuarded');
    } else {
      debugPrint('CRITICAL: Unhandled async exception in runZonedGuarded: $error\n$stackTrace');
    }
  });
}

class CapStudioApp extends ConsumerStatefulWidget {
  const CapStudioApp({super.key});

  @override
  ConsumerState<CapStudioApp> createState() => _CapStudioAppState();
}

class _CapStudioAppState extends ConsumerState<CapStudioApp> with WindowListener, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (isDesktop) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (isMobile) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        // Free whisper model when app goes to background only if not actively transcribing
        if (!WhisperMobileService.instance.isTranscribing) {
          try {
            WhisperMobileService.instance.freeModel();
          } catch (e) {
            LoggerService.instance.log(LogLevel.warning, 'Lifecycle', 'Failed to free Whisper model: $e');
          }
        }
      }
    }
  }

  @override
  Future<void> onWindowClose() async {
    final project = ref.read(editorProvider).project;
    final hasUnsaved = ref.read(editorProvider).hasUnsavedChanges;
    final context = navigatorKey.currentContext;

    // Always ask for confirmation if a project is loaded in the editor
    if (project != null && context != null && context.mounted) {
      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) => PremiumBlurDialog(
          maxWidth: 400,
          glowColor: hasUnsaved ? AppTheme.accentRed : AppTheme.accentOrange,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasUnsaved ? 'Unsaved Changes' : 'Close CapStudio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hasUnsaved 
                    ? 'You have unsaved changes. Are you sure you want to close CapStudio?'
                    : 'Are you sure you want to close CapStudio? Any active project edit session will end.',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('CANCEL', style: TextStyle(color: AppTheme.secondaryText)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasUnsaved ? AppTheme.accentRed : AppTheme.accentOrange,
                      foregroundColor: AppTheme.onAccentText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(hasUnsaved ? 'CLOSE ANYWAY' : 'CLOSE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (shouldClose == true) {
        await _cleanTeardownAndExit();
      }
    } else {
      if (project != null && hasUnsaved) {
        LoggerService.instance.log(
          LogLevel.warning,
          'Lifecycle',
          'onWindowClose called with unsaved changes, but context is null or unmounted. Forcing exit and discarding changes.',
        );
      }
      await _cleanTeardownAndExit();
    }
  }

  Future<void> _cleanTeardownAndExit() async {
    // Teardown is sequenced in two phases to prevent services that log internally
    // (AudioService, IsarService) from writing to the LoggerService after its
    // IOSinks have been closed, which causes "Bad state: StreamSink is bound to a stream".
    //
    // Phase 1: Shut down services that may write logs (parallel, 150ms budget).
    // Phase 2: Dispose the logger last so it captures all Phase-1 log lines.
    try {
      await Future.wait([
        // Stop all active audio players (AudioService logs internally)
        AudioService.instance.stopAll(),
        // Close Isar to release database file locks cleanly
        IsarService.instance.close().catchError((Object e) {
          LoggerService.instance.debug('Teardown IsarService close error: $e');
        }),
      ]).timeout(
        const Duration(milliseconds: 150),
        onTimeout: () => [],
      );
    } catch (e) {
      LoggerService.instance.debug('Teardown Phase 1 exception: $e');
    }

    // Phase 2: Flush and close log files — must happen AFTER all other services.
    try {
      await LoggerService.instance.dispose().timeout(
        const Duration(milliseconds: 100),
        onTimeout: () {},
      );
    } catch (_) {
      // Silently swallow as LoggerService is already disposed
    }

    if (kIsWeb) {
      return;
    } else if (Platform.isAndroid || Platform.isIOS) {
      await SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the themeProvider to rebuild the router with the latest dynamic styles
    final currentTheme = ref.watch(themeProvider);
    final router = ref.watch(goRouterProvider);
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'CapStudio',
      themeMode: currentTheme.isLight ? ThemeMode.light : ThemeMode.dark,
      theme: currentTheme.theme,
      darkTheme: currentTheme.darkTheme,
      locale: currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
    );
  }
}

/// Custom scroll behavior to prevent automatic framework-level scrollbar wrapping
/// on desktop platforms, which triggers random "ScrollController has no ScrollPosition attached" crashes.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
