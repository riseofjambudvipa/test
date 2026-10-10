import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:collection/collection.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_provider.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/logger/logger_service.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/asset_warning_banner.dart';
import '../../../../core/utils/app_dirs.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/utils/premium_blur_dialog.dart';

import 'dashboard/welcome_hero.dart';
import 'dashboard/delete_confirm_dialog.dart';
import 'dashboard/project_card.dart';
import 'dashboard/import_sheet.dart';
import 'dashboard/demo_selector_dialog.dart';
import 'dashboard/bundle_import_helper.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isDragOver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final backupPath = IsarService.instance.lastAutoRecoveredBackupPath;
        if (backupPath != null) {
          IsarService.instance.lastAutoRecoveredBackupPath = null; // Clear so it only shows once
          final l10n = AppLocalizations.of(context);
          showDialog<void>(
            context: context,
            builder: (context) => PremiumBlurDialog(
              maxWidth: 450,
              glowColor: AppTheme.accentOrange,
              glowOpacity: 0.1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.dbRecoveredTitle ?? 'Database Automatically Recovered',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.dbRecoveredBody(backupPath) ?? 'A database schema mismatch or corruption was detected. '
                    'The database was reset, and your previous data was backed up to:\n\n$backupPath',
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n?.okLabel ?? 'OK', style: TextStyle(color: AppTheme.secondaryText)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showImportDialog(String filePath, {required bool isDemo}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ImportVideoDialog(filePath: filePath, isDemo: isDemo),
    );
  }

  Future<void> _pickVideoFile({required bool isDemo}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.video,
    );

    if (!mounted) return;

    if (result != null && result.files.single.path != null) {
      _showImportDialog(result.files.single.path!, isDemo: isDemo);
    }
  }

  Future<void> _startDemoMode(bool isLandscape) async {
    final l10n = AppLocalizations.of(context);
    try {
      unawaited(showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.accentOrange),
          ),
        ),
      ));
      
      final demoPath = await _prepareDemoVideo(isLandscape);
      
      if (mounted) {
        Navigator.pop(context); // Close the loading dialog
        _showImportDialog(demoPath, isDemo: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.errorDemoLoadFailed(e.toString()) ?? 'Failed to load demo video: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<String> _prepareDemoVideo(bool isLandscape) async {
    final folder = isLandscape ? 'landscape' : 'portrait';

    if (kIsWeb) {
      return 'assets/demo/$folder/demo.mp4';
    }

    // Clean up legacy files from AppDirs.support (user system root) to keep it pristine
    final legacyFiles = [
      p.join(AppDirs.support, 'demo_landscape.mp4'),
      p.join(AppDirs.support, 'demo_landscape_subtitles.srt'),
      p.join(AppDirs.support, 'demo_portrait.mp4'),
      p.join(AppDirs.support, 'demo_portrait_subtitles.srt'),
      p.join(AppDirs.support, 'demo.mp4'),
    ];
    for (final path in legacyFiles) {
      try {
        final f = File(path);
        if (f.existsSync()) {
          f.deleteSync();
        }
      } catch (e) {
        LoggerService.instance.debug('Failed to delete legacy demo file $path: $e');
      }
    }

    // Organise demo files under AppDirs.assets/demo/landscape/ and AppDirs.assets/demo/portrait/
    final targetDir = p.join(AppDirs.assets, 'demo', folder);
    final targetPath = p.join(targetDir, 'demo.mp4');
    final targetFile = File(targetPath);
    if (!await targetFile.exists()) {
      final byteData = await rootBundle.load('assets/demo/$folder/demo.mp4');
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
    }

    final srtPath = p.join(targetDir, 'demo_subtitles.srt');
    final srtFile = File(srtPath);
    if (!await srtFile.exists()) {
      try {
        final byteData = await rootBundle.load('assets/demo/$folder/demo_subtitles.srt');
        await srtFile.parent.create(recursive: true);
        await srtFile.writeAsBytes(
          byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
          flush: true,
        );
      } catch (e) {
        // Safe warning, mock fallback will run in editor
        LoggerService.instance.log(LogLevel.warning, 'Dashboard', 'Failed to prepare demo subtitles: $e');
      }
    }

    return targetPath;
  }

  void _showDemoSelectorDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => DemoSelectorDialog(
        onSelectDemo: (isLandscape) => _startDemoMode(isLandscape),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      dashboardProvider.select((s) => s.errorMessage),
      (prev, next) {
        if (next != null && next.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      },
    );

    final state = ref.watch(dashboardProvider);
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);

    final mainContent = LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isSmallHeight = constraints.maxHeight < 550;
        final padding = (isMobile || isSmallHeight) ? 16.0 : 32.0;

        return Stack(
          children: [
            // Glowing Ambient background gradients
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: GlowingBackgroundPainter(
                    primaryGlow: theme.accentOrange,
                    secondaryGlow: theme.accentCyan,
                    devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                  ),
                ),
              ),
            ),
            // Background layout
            Padding(
              padding: EdgeInsets.all(padding),
              child: CustomScrollView(
                slivers: [
                  // Asset status banner (required warnings or optional pack discovery)
                  const SliverToBoxAdapter(
                    child: AssetWarningBanner(),
                  ),
                  // Header Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side: Title and Offline status badge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'CapStudio',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: isMobile ? 18 : 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.accentOrange,
                                  letterSpacing: isMobile ? 1.0 : 2.0,
                                ),
                              ),
                              SizedBox(width: isMobile ? 6 : 10),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: 2),
                                decoration: AppTheme.glassDecoration(
                                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                                  borderRadius: 4,
                                  borderOpacity: 0.3,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: isMobile ? 4 : 6),
                                    Text(
                                      l10n?.statusLocalOffline ?? 'LOCAL OFFLINE',
                                      style: TextStyle(
                                        color: AppTheme.accentGreen,
                                        fontSize: isMobile ? 8 : 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Right side: Theme and Settings buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Light / Dark mode toggle
                              Container(
                                width: 36,
                                height: 36,
                                decoration: AppTheme.glassDecoration(
                                  color: AppTheme.cardBg,
                                  borderRadius: 10,
                                  borderOpacity: 0.08,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 18,
                                  icon: Icon(
                                    theme.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                                    color: AppTheme.accentOrange,
                                  ),
                                  tooltip: theme.isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                                  onPressed: () {
                                    ref.read(themeProvider.notifier).toggleBrightness();
                                  },
                                ),
                              ),
                              SizedBox(width: isMobile ? 6 : 8),
                              // Small Theme Palette Icon Button
                              Container(
                                width: 36,
                                height: 36,
                                decoration: AppTheme.glassDecoration(
                                  color: AppTheme.cardBg,
                                  borderRadius: 10,
                                  borderOpacity: 0.08,
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                  ),
                                  child: PopupMenuButton<ThemePalette>(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 160),
                                    iconSize: 18,
                                    icon: Icon(Icons.palette_outlined, color: AppTheme.accentOrange),
                                    tooltip: l10n?.tooltipTheme ?? 'Theme Palette',
                                    offset: const Offset(0, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: AppTheme.borderGlass),
                                    ),
                                    color: AppTheme.cardBg,
                                    onSelected: (val) {
                                      ref.read(themeProvider.notifier).setPalette(val);
                                      LoggerService.instance.log(LogLevel.action, 'Dashboard', 'Global theme palette changed to: ${val.name}');
                                    },
                                    itemBuilder: (context) => ThemePalette.values
                                        .map(
                                          (p) {
                                            final pData = AppThemeData.getThemeFor(palette: p, isDark: theme.isDark);
                                            final isSelected = theme.activePalette == p;
                                            return PopupMenuItem(
                                              value: p,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [pData.accentPrimary, pData.accentSecondary],
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      p.displayName,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                        color: isSelected ? AppTheme.accentOrange : AppTheme.primaryText,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    Icon(Icons.check, size: 14, color: AppTheme.accentOrange),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                              SizedBox(width: isMobile ? 6 : 8),
                              // Small Settings Icon Button
                              Container(
                                width: 36,
                                height: 36,
                                decoration: AppTheme.glassDecoration(
                                  color: AppTheme.cardBg,
                                  borderRadius: 10,
                                  borderOpacity: 0.08,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 18,
                                  icon: Icon(Icons.settings_outlined, color: AppTheme.accentOrange),
                                  onPressed: () {
                                    context.push('/settings');
                                  },
                                  tooltip: l10n?.tooltipSettings ?? 'Settings',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 4)),
                  if (!isSmallHeight) ...[
                    SliverToBoxAdapter(
                      child: Text(
                        l10n?.dashboardSubtitle ??
                            'Professional local-first caption editor and subtitle export suite.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: isMobile ? 20 : 32),
                    ),
                  ] else ...[
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 6),
                    ),
                  ],

                  // Main Dashboard Body slivers
                  ..._buildSliverBody(state, isMobile, isSmallHeight),
                ],
              ),
            ),

            // Glassmorphic Full-Screen Progress Overlay for Imports
            if (state.isLoading)
              Container(
                color: AppTheme.isLight ? Colors.black54 : Colors.black87,
                child: Center(
                  child: Container(
                    width: isMobile ? constraints.maxWidth - 48 : 380,
                    padding: EdgeInsets.all(isMobile ? 24 : 32),
                    decoration: AppTheme.glassDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: 16,
                      borderOpacity: 0.12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppTheme.accentOrange),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          state.importStatusText,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: state.importProgress,
                          color: AppTheme.accentOrange,
                          backgroundColor: AppTheme.dividerColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)?.importProgressPercent((state.importProgress * 100).toInt())
                              ?? '${(state.importProgress * 100).toInt()}% Completed',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_isDragOver)
              Positioned.fill(
                child: Container(
                  color: AppTheme.isLight ? Colors.black54 : Colors.black87,
                  child: Center(
                    child: Container(
                      width: 320,
                      height: 200,
                      decoration: AppTheme.glassDecoration(
                        color: AppTheme.cardBg.withValues(alpha: 0.5),
                        borderRadius: 16,
                        borderOpacity: 0.0,
                        glowColor: AppTheme.accentOrange,
                        glowOpacity: 0.12,
                      ).copyWith(
                        border: Border.all(
                          color: AppTheme.accentOrange,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 64, color: AppTheme.accentOrange),
                          const SizedBox(height: 16),
                          Text(
                            l10n?.dropVideoHere ?? 'DROP VIDEO HERE',
                            style: TextStyle(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n?.dropVideoSupported ?? 'Supports MP4, MOV, AVI, etc.',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );

    return Scaffold(
      body: (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
          ? mainContent
          : DropTarget(
              onDragDone: (details) {
                setState(() => _isDragOver = false);
                if (details.files.isNotEmpty) {
                  final bundleFile = details.files.firstWhereOrNull((f) {
                    final ext = p.extension(f.path).toLowerCase();
                    return ext == '.capstudio' || ext == '.json';
                  });
                  if (bundleFile != null) {
                    ref.read(dashboardProvider.notifier).importProjectBundle(filePath: bundleFile.path).then((proj) {
                      if (proj != null && context.mounted) {
                        context.go('/editor/${proj.projectId}');
                      }
                    });
                    return;
                  }

                  final videoFile = details.files.firstWhereOrNull((f) {
                    final ext = p.extension(f.path).toLowerCase();
                    return ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'].contains(ext);
                  });
                  if (videoFile != null) {
                    _showImportDialog(videoFile.path, isDemo: false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)?.errorInvalidDropFileFormat
                              ?? 'Invalid file format. Please drop a video file or .capstudio bundle.',
                        ),
                        backgroundColor: AppTheme.accentRed,
                      ),
                    );
                  }
                }
              },
              onDragEntered: (details) => setState(() => _isDragOver = true),
              onDragExited: (details) => setState(() => _isDragOver = false),
              child: mainContent,
            ),
    );
  }

  /// Builds the body slivers for the dashboard.
  List<Widget> _buildSliverBody(DashboardState state, bool isMobile, bool isSmallHeight) {
    final l10n = AppLocalizations.of(context);
    final importVideoTitle = l10n?.importVideo.toUpperCase() ?? 'IMPORT NEW VIDEO';
    final dragDropText = l10n?.dragDropText ?? 'Drag and drop your video file here';
    final demoModeTitle = l10n?.demoMode ?? 'DEMO MODE';
    final demoModeDesc = l10n?.demoModeDesc ?? 'Load a demo project to try out styling and editor features.';
    final dashboardTitle = (l10n?.dashboardTitle ?? 'My Projects').toUpperCase();

    if (isMobile) {
      return [
        // Stacked Import and Demo Cards
        SliverToBoxAdapter(
          child: _maybeAnimate(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HoverableImportCard(
                  title: importVideoTitle,
                  subtitle: dragDropText,
                  icon: Icons.video_library_outlined,
                  onTap: state.isLoading ? () {} : () => _pickVideoFile(isDemo: false),
                ),
                const SizedBox(height: 10),
                HoverableImportCard(
                  title: demoModeTitle,
                  subtitle: demoModeDesc,
                  icon: Icons.bolt_outlined,
                  onTap: state.isLoading ? () {} : () => _showDemoSelectorDialog(),
                ),
              ],
            ),
            beginY: 0.1,
            duration: const Duration(milliseconds: 400),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: isSmallHeight ? 12 : 20),
        ),
        // Recent Projects Header
        SliverToBoxAdapter(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dashboardTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppTheme.primaryText,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => pickAndImportProjectBundle(context, ref),
                icon: Icon(Icons.file_upload_outlined, size: 14, color: AppTheme.accentOrange),
                label: Text(
                  'IMPORT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.accentOrange,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                  backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(60, 28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 12),
        ),
        // Projects List
        state.projects.isEmpty
            ? const SliverToBoxAdapter(
                child: WelcomeHero(),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final project = state.projects[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _maybeAnimate(
                        SizedBox(
                          height: 140,
                          child: HoverableProjectCard(
                            project: project,
                            onEdit: () => context.go('/editor/${project.projectId}'),
                            onRename: () => _showRenameDialog(project),
                            onDelete: () => _showDeleteConfirm(project),
                          ),
                        ),
                        delay: Duration(milliseconds: index * 50),
                        beginX: 0.05,
                      ),
                    );
                  },
                  childCount: state.projects.length,
                ),
              ),
      ];
    } else {
      return [
        // Side-by-side Import and Demo Cards
        SliverToBoxAdapter(
          child: _maybeAnimate(
            Row(
              children: [
                Expanded(
                  child: HoverableImportCard(
                    title: importVideoTitle,
                    subtitle: dragDropText,
                    icon: Icons.video_library_outlined,
                    onTap: state.isLoading ? () {} : () => _pickVideoFile(isDemo: false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: HoverableImportCard(
                    title: demoModeTitle,
                    subtitle: demoModeDesc,
                    icon: Icons.bolt_outlined,
                    onTap: state.isLoading ? () {} : () => _showDemoSelectorDialog(),
                  ),
                ),
              ],
            ),
            beginY: 0.1,
            duration: const Duration(milliseconds: 400),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: isSmallHeight ? 16 : 32),
        ),
        // Recent Projects Header
        SliverToBoxAdapter(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dashboardTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppTheme.primaryText,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => pickAndImportProjectBundle(context, ref),
                icon: Icon(Icons.file_upload_outlined, size: 16, color: AppTheme.accentOrange),
                label: Text(
                  'IMPORT (.capstudio)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.accentOrange,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                  backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: isSmallHeight ? 8 : 16),
        ),
        // Projects Grid
        state.projects.isEmpty
            ? const SliverToBoxAdapter(
                child: WelcomeHero(),
              )
            : SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: isSmallHeight ? 115 : 140,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final project = state.projects[index];
                    return _maybeAnimate(
                      HoverableProjectCard(
                        project: project,
                        onEdit: () => context.go('/editor/${project.projectId}'),
                        onRename: () => _showRenameDialog(project),
                        onDelete: () => _showDeleteConfirm(project),
                      ),
                      delay: Duration(milliseconds: index * 50),
                      beginY: 0.08,
                    );
                  },
                  childCount: state.projects.length,
                ),
              ),
      ];
    }
  }

  void _showRenameDialog(Project project) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return RenameProjectDialog(project: project, ref: ref);
      },
    );
  }

  void _showDeleteConfirm(Project project) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return DeleteConfirmDialog(
          project: project,
          onDelete: () {
            ref.read(dashboardProvider.notifier).deleteProject(project.projectId);
          },
        );
      },
    );
  }

  Widget _maybeAnimate(
    Widget child, {
    Duration? delay,
    Duration duration = const Duration(milliseconds: 300),
    double beginX = 0.0,
    double beginY = 0.0,
  }) {
    return child;
  }
}
