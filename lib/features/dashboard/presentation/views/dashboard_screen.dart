import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
                    'Database Automatically Recovered',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A database schema mismatch or corruption was detected. '
                    'The database was reset, and your previous data was backed up to:\n\n$backupPath',
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK', style: TextStyle(color: AppTheme.secondaryText)),
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
            content: Text('Failed to load demo video: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<String> _prepareDemoVideo(bool isLandscape) async {
    final folder = isLandscape ? 'landscape' : 'protrait';

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
      } catch (_) {}
    }

    // Organise demo files under AppDirs.assets/demo/landscape/ and AppDirs.assets/demo/protrait/
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
      builder: (context) {
        return PremiumBlurDialog(
          maxWidth: 580,
          borderOpacity: 0.08,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECT DEMO FORMAT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a layout format to preview CapStudio\'s high-fidelity caption engine, live word-level animations, and audio waveforms instantly.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.secondaryText,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildDemoCard(
                      context: context,
                      title: 'Landscape Demo',
                      subtitle: 'Perfect for YouTube, desktop & presentations.',
                      aspectRatio: '16:9 Format',
                      icon: Icons.desktop_windows_outlined,
                      gradientColor: AppTheme.accentCyan,
                      onTap: () {
                        Navigator.pop(context);
                        _startDemoMode(true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDemoCard(
                      context: context,
                      title: 'Portrait Demo',
                      subtitle: 'Ideal for TikTok, Shorts, Reels & mobile.',
                      aspectRatio: '9:16 Format',
                      icon: Icons.phone_android_outlined,
                      gradientColor: AppTheme.accentOrange,
                      onTap: () {
                        Navigator.pop(context);
                        _startDemoMode(false);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String aspectRatio,
    required IconData icon,
    required Color gradientColor,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 500;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: GlassContainer(
        padding: EdgeInsets.all(isNarrow ? 12 : 20),
        borderRadius: 12,
        borderOpacity: 0.12,
        glowColor: gradientColor,
        glowOpacity: 0.04,
        color: Colors.white.withValues(alpha: 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isNarrow ? 8 : 10),
              decoration: AppTheme.glassDecoration(
                color: gradientColor.withValues(alpha: 0.1),
                borderRadius: 24,
                borderOpacity: 0.15,
              ),
              child: Icon(icon, color: gradientColor, size: isNarrow ? 20 : 28),
            ),
            SizedBox(height: isNarrow ? 10 : 16),
            Text(
              title,
              style: TextStyle(
                fontSize: isNarrow ? 12 : 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isNarrow ? 10 : 12,
                color: AppTheme.mutedText,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isNarrow ? 10 : 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: AppTheme.glassDecoration(
                color: gradientColor.withValues(alpha: 0.15),
                borderRadius: 4,
                borderOpacity: 0.2,
              ),
              child: Text(
                aspectRatio,
                style: TextStyle(
                  fontSize: isNarrow ? 8 : 10,
                  fontWeight: FontWeight.bold,
                  color: gradientColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final theme = ref.watch(themeProvider);

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
                  // Warning Banner if required assets are missing
                  const SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AssetWarningBanner(),
                        SizedBox(height: 12),
                      ],
                    ),
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
                                      'LOCAL OFFLINE',
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
                              // Small Theme Icon Button
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
                                  child: PopupMenuButton<ThemeType>(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 150),
                                    iconSize: 18,
                                    icon: Icon(Icons.palette_outlined, color: AppTheme.accentOrange),
                                    tooltip: 'Theme',
                                    offset: const Offset(0, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    color: AppTheme.cardBg,
                                    onSelected: (val) {
                                      ref.read(themeProvider.notifier).setTheme(val);
                                      LoggerService.instance.log(LogLevel.action, 'Dashboard', 'Global dynamic theme changed to: ${val.name}');
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: ThemeType.obsidianAmber, child: Text('Deep Obsidian', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                      PopupMenuItem(value: ThemeType.neonCyberpunk, child: Text('Neon Cyberpunk', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                      PopupMenuItem(value: ThemeType.obsidianEmerald, child: Text('Obsidian Emerald', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                      PopupMenuItem(value: ThemeType.royalAmethyst, child: Text('Royal Amethyst', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                      PopupMenuItem(value: ThemeType.sunsetSunrise, child: Text('Sunset Sunrise', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                    ],
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
                                  tooltip: 'Settings',
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
                color: Colors.black87,
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
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(state.importProgress * 100).toInt()}% Completed',
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
                  color: Colors.black.withValues(alpha: 0.85),
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
                            'DROP VIDEO HERE',
                            style: TextStyle(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Supports MP4, MOV, AVI, etc.',
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
                  final videoFile = details.files.firstWhereOrNull((f) {
                    final ext = p.extension(f.path).toLowerCase();
                    return ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'].contains(ext);
                  });
                  if (videoFile != null) {
                    _showImportDialog(videoFile.path, isDemo: false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid file format. Please drop a video file.'),
                        backgroundColor: Colors.redAccent,
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
    final l10n = AppLocalizations.of(context)!;
    if (isMobile) {
      return [
        // Stacked Import and Demo Cards
        SliverToBoxAdapter(
          child: _maybeAnimate(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HoverableImportCard(
                  title: l10n.importVideo.toUpperCase(),
                  subtitle: l10n.dragDropText,
                  icon: Icons.video_library_outlined,
                  onTap: state.isLoading ? () {} : () => _pickVideoFile(isDemo: false),
                ),
                const SizedBox(height: 10),
                HoverableImportCard(
                  title: l10n.demoMode,
                  subtitle: l10n.demoModeDesc,
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
          child: Text(
            l10n.dashboardTitle.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
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
                    title: l10n.importVideo.toUpperCase(),
                    subtitle: l10n.dragDropText,
                    icon: Icons.video_library_outlined,
                    onTap: state.isLoading ? () {} : () => _pickVideoFile(isDemo: false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: HoverableImportCard(
                    title: l10n.demoMode,
                    subtitle: l10n.demoModeDesc,
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
          child: Text(
            l10n.dashboardTitle.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
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
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return child;
    }
    var animated = child.animate(delay: delay);
    if (beginX != 0.0) {
      animated = animated.fade(duration: duration).slideX(begin: beginX, end: 0, curve: Curves.easeOutCubic);
    } else if (beginY != 0.0) {
      animated = animated.fade(duration: duration).slideY(begin: beginY, end: 0, curve: Curves.easeOutCubic);
    } else {
      animated = animated.fade(duration: duration);
    }
    return animated;
  }
}
