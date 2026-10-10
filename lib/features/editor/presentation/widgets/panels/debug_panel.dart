import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/utils/share_service.dart';
import '../../../../../core/assets/asset_path_service.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../controllers/editor_controller.dart';

class DebugPanel extends ConsumerStatefulWidget {
  const DebugPanel({super.key});

  @override
  ConsumerState<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends ConsumerState<DebugPanel> {
  String _logSearchQuery = '';
  LogLevel? _selectedLogLevelFilter;
  final _logSearchController = TextEditingController();
  
  // Storage stats & periodic refresh state
  Timer? _statsTimer;
  Map<String, dynamic> _logStats = {};
  String _lastStatsSignature = '';
  bool _verboseMode = false;
  bool _showMetrics = true;
  bool _initializedMetricsCollapse = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Periodically refresh stats (every 2.5 seconds) to track real-time memory & storage growth
    _statsTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) _loadStats();
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _logSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await LoggerService.instance.getLogStats();
    if (!mounted) return;
    // FIX (perf): the 2.5s refresh timer used to setState unconditionally,
    // rebuilding the entire ~500-entry log ListView every tick even when
    // nothing changed. Skip the rebuild when the stats are identical.
    final buffer = StringBuffer();
    stats.forEach((k, v) => buffer.write('$k=$v;'));
    final signature = buffer.toString();
    if (signature == _lastStatsSignature) return;
    _lastStatsSignature = signature;
    setState(() {
      _logStats = stats;
      final minLevelName = stats['minimumLevel'] as String?;
      if (minLevelName != null) {
        _verboseMode = minLevelName == 'trace';
      }
    });
  }

  void _toggleVerboseMode(bool enabled) {
    setState(() {
      _verboseMode = enabled;
    });
    final level = enabled ? LogLevel.trace : LogLevel.info;
    LoggerService.instance.setMinimumLevel(level);
    SettingsService.instance.setLogMinimumLevel(level.name);
    _loadStats();
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBgElevated,
        borderRadius: 10,
        borderOpacity: 0.06,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryText,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 8,
              color: AppTheme.mutedText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDialogLogFilterChip(String label, LogLevel? level) {
    final isSelected = _selectedLogLevelFilter == level;
    Color chipColor = AppTheme.secondaryText;
    if (level == LogLevel.trace || level == LogLevel.debug) chipColor = AppTheme.accentPink;
    if (level == LogLevel.error) chipColor = AppTheme.accentRed;
    if (level == LogLevel.warning) chipColor = AppTheme.accentOrange;
    if (level == LogLevel.action) chipColor = AppTheme.accentCyan;
    if (level == LogLevel.info) chipColor = AppTheme.accentGreen;

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        selected: isSelected,
        selectedColor: chipColor.withValues(alpha: 0.15),
        checkmarkColor: chipColor,
        backgroundColor: AppTheme.cardBgElevated,
        labelStyle: TextStyle(
          color: isSelected ? chipColor : AppTheme.secondaryText,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedLogLevelFilter = level;
            });
          }
        },
      ),
    );
  }

  Widget _buildLogItemRow(LogEntry entry) {
    Color indicatorColor = AppTheme.secondaryText;
    IconData levelIcon = Icons.notes_rounded;
    
    switch (entry.level) {
      case LogLevel.trace:
      case LogLevel.debug:
        indicatorColor = AppTheme.accentPink;
        levelIcon = Icons.bug_report_outlined;
        break;
      case LogLevel.info:
        indicatorColor = AppTheme.accentGreen;
        levelIcon = Icons.info_outline_rounded;
        break;
      case LogLevel.action:
        indicatorColor = AppTheme.accentCyan;
        levelIcon = Icons.touch_app_outlined;
        break;
      case LogLevel.warning:
        indicatorColor = AppTheme.accentOrange;
        levelIcon = Icons.warning_amber_rounded;
        break;
      case LogLevel.error:
        indicatorColor = AppTheme.accentRed;
        levelIcon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.1),
        borderRadius: 6,
        borderOpacity: 0.05,
      ).copyWith(
        border: Border(
          left: BorderSide(color: indicatorColor, width: 3.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level Icon & Timestamp
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
              child: Icon(levelIcon, size: 12, color: indicatorColor.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 8),
            // Log Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '[${entry.formattedTime}]',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: AppTheme.glassDecoration(
                              color: indicatorColor.withValues(alpha: 0.08),
                              borderRadius: 4,
                              borderOpacity: 0.1,
                            ),
                            child: Text(
                              entry.source.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: indicatorColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      entry.message,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        height: 1.35,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    if (entry.stackTrace != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: AppTheme.glassDecoration(
                          color: AppTheme.cardBgElevated,
                          borderRadius: 4,
                          borderOpacity: 0.05,
                        ),
                        child: SelectableText(
                          entry.stackTrace!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Copy Log Line Action Button
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 12, color: AppTheme.mutedText),
              tooltip: 'Copy entry line',
              splashRadius: 16,
              onPressed: () async {
                final l10n = AppLocalizations.of(context);
                await Clipboard.setData(ClipboardData(text: entry.toString()));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.logLineCopied(entry.message) ??
                            'Copied log line to clipboard: "${entry.message}"',
                      ),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final hasProject = ref.watch(editorProvider.select((s) => s.project != null));
    if (!hasProject) return const SizedBox.shrink();

    if (!_initializedMetricsCollapse) {
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      final isCompactWidth = MediaQuery.of(context).size.width < 600;
      if (isLandscape && isCompactWidth) {
        _showMetrics = false;
      }
      _initializedMetricsCollapse = true;
    }

    final uptimeSeconds = _logStats['uptimeSeconds'] as int? ?? 0;
    final totalSizeKB = _logStats['totalSizeKB'] as int? ?? 0;
    final totalFiles = _logStats['totalFiles'] as int? ?? 0;
    final memoryLogCount = _logStats['memoryLogCount'] as int? ?? 0;

    final uptimeText = uptimeSeconds >= 60
        ? '${uptimeSeconds ~/ 60}m ${uptimeSeconds % 60}s'
        : '${uptimeSeconds}s';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Telemetry and Metrics Section Header
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final useVerticalLayout = constraints.maxWidth < 500;

                            final titleRow = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'DIAGNOSTICS & TELEMETRY',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.secondaryText,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(
                                    _showMetrics ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: AppTheme.secondaryText,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showMetrics = !_showMetrics;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  splashRadius: 16,
                                ),
                              ],
                            );

                            final actionButtons = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 TextButton.icon(
                                   icon: Icon(Icons.download_rounded, size: 12, color: AppTheme.accentCyan),
                                   label: Text('EXPORT', style: TextStyle(fontSize: 10, color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
                                   onPressed: () async {
                                     try {
                                       final l10n = AppLocalizations.of(context);
                                       final rawEntries = LoggerService.instance.logsNotifier.value;
                                       var filteredEntries = rawEntries;
                                       
                                       if (_selectedLogLevelFilter != null) {
                                         filteredEntries = filteredEntries.where((e) {
                                           if (_selectedLogLevelFilter == LogLevel.trace) {
                                             return e.level == LogLevel.trace || e.level == LogLevel.debug;
                                           }
                                           return e.level == _selectedLogLevelFilter;
                                         }).toList();
                                       }
                                       
                                       if (_logSearchQuery.isNotEmpty) {
                                         filteredEntries = filteredEntries.where((e) => 
                                           e.source.toLowerCase().contains(_logSearchQuery) ||
                                           e.message.toLowerCase().contains(_logSearchQuery)
                                         ).toList();
                                       }

                                       final buffer = StringBuffer();
                                       buffer.writeln('=== CapStudio Diagnostic Report (Filtered) ===');
                                       buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
                                       final activeFilterName = _selectedLogLevelFilter?.name.toUpperCase() ?? 'ALL';
                                       buffer.writeln('Active Filter: $activeFilterName');
                                       if (_logSearchQuery.isNotEmpty) {
                                         buffer.writeln('Search Query: "$_logSearchQuery"');
                                       }
                                       buffer.writeln('Entries: ${filteredEntries.length}');
                                       buffer.writeln('');
                                       
                                       for (final entry in filteredEntries) {
                                         final timeStr = entry.timestamp.toIso8601String().substring(11, 23);
                                         final lvlStr = entry.level.name.toUpperCase().padRight(7);
                                         buffer.writeln('[$timeStr] [$lvlStr] [${entry.source}] ${entry.message}');
                                       }
                                       
                                       final logs = buffer.toString();

                                       if (logs.isNotEmpty) {
                                         if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                                           // Write to a temporary file and share via system share sheet
                                           final tempDir = AssetPathService.instance.tempDir;
                                           final tempFile = File(p.join(tempDir, 'diagnostics_report.txt'));
                                           await tempFile.writeAsString(logs, flush: true);
 
                                           final shared = await ShareService.shareFile(tempFile.path, mimeType: 'text/plain');
                                           if (shared && context.mounted) {
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(
                                                 content: Text(
                                                   l10n?.diagnosticsExported ??
                                                       'Filtered diagnostic report opened in share sheet.',
                                                 ),
                                                 backgroundColor: AppTheme.accentGreen,
                                               ),
                                             );
                                           }
                                         } else {
                                           // On desktop/web, copy to clipboard safely with a truncation safeguard
                                           String safeLogs = logs;
                                           bool wasTruncated = false;
                                           const maxBytes = 150 * 1024; // 150 KB safety limit
                                           if (logs.length > maxBytes) {
                                             safeLogs = '... [TRUNCATED FOR CLIPBOARD SAFETY] ...\n${logs.substring(logs.length - maxBytes)}';
                                             wasTruncated = true;
                                           }
 
                                           await Clipboard.setData(ClipboardData(text: safeLogs));
                                           if (context.mounted) {
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(
                                                 content: Text(wasTruncated
                                                     ? 'Filtered diagnostics report (recent logs) copied to clipboard.'
                                                     : 'Filtered diagnostics report copied to clipboard.'),
                                                 backgroundColor: AppTheme.accentGreen,
                                               ),
                                             );
                                           }
                                         }
                                       }
                                     } catch (e) {
                                        if (context.mounted) {
                                          final l10n = AppLocalizations.of(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n?.errorDiagnosticsFailed(e.toString()) ??
                                                    'Failed to export diagnostics report: $e',
                                              ),
                                              backgroundColor: AppTheme.accentRed,
                                            ),
                                          );
                                        }
                                     }
                                   },
                                 ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  icon: Icon(Icons.delete_outline, size: 12, color: AppTheme.accentRed),
                                  label: Text(AppLocalizations.of(context)?.btnReset ?? 'CLEAR', style: TextStyle(fontSize: 10, color: AppTheme.accentRed, fontWeight: FontWeight.bold)),
                                  onPressed: () async {
                                    // FIX (audit): the list is driven by the
                                    // logsNotifier stream, so the extra
                                    // setState was a redundant full rebuild.
                                    await LoggerService.instance.clear();
                                  },
                                ),
                              ],
                            );

                            if (useVerticalLayout) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      titleRow,
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: actionButtons,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                titleRow,
                                actionButtons,
                              ],
                            );
                          },
                        ),

                        if (_showMetrics) ...[
                          const SizedBox(height: 8),
                          // Diagnostic cards wrap
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cardWidth = constraints.maxWidth < 320
                                  ? (constraints.maxWidth - 10) / 2
                                  : (constraints.maxWidth - 20) / 3;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: _buildMetricCard(
                                      icon: Icons.timer_outlined,
                                      title: 'SESSION UPTIME',
                                      value: uptimeText,
                                      subtitle: 'Active session',
                                      color: AppTheme.accentCyan,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _buildMetricCard(
                                      icon: Icons.storage_rounded,
                                      title: 'PERSISTENT LOGS',
                                      value: '$totalSizeKB KB',
                                      subtitle: '$totalFiles file(s)',
                                      color: AppTheme.accentOrange,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _buildMetricCard(
                                      icon: Icons.memory_rounded,
                                      title: 'BUFFER COUNTER',
                                      value: '$memoryLogCount/500',
                                      subtitle: 'Ring capacity',
                                      color: AppTheme.accentGreen,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: AppTheme.glassDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.02),
                              borderRadius: 12,
                              borderOpacity: 0.08,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.developer_mode_rounded, size: 14, color: AppTheme.accentOrange),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'VERBOSE DIAGNOSTIC MODE',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryText,
                                                letterSpacing: 0.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Track deep micro-interactions, state updates, coordinates, and engine timings. Intended for technical diagnostics.',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          color: AppTheme.secondaryText,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Switch(
                                  value: _verboseMode,
                                  activeThumbColor: AppTheme.accentOrange,
                                  activeTrackColor: AppTheme.accentOrange.withValues(alpha: 0.3),
                                  inactiveThumbColor: AppTheme.mutedText,
                                  inactiveTrackColor: AppTheme.dividerColor,
                                  onChanged: _toggleVerboseMode,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Console Filters Header
                        Text(
                          'CONSOLE FILTERS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryText,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextField(
                          controller: _logSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search console logs by source, keyword, or message...',
                            hintStyle: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                            prefixIcon: Icon(Icons.search, size: 14, color: AppTheme.mutedText),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.borderGlass),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                            ),
                            suffixIcon: _logSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 14, color: AppTheme.mutedText),
                                    onPressed: () {
                                      setState(() {
                                        _logSearchQuery = '';
                                        _logSearchController.clear();
                                      });
                                    },
                                  )
                                : null,
                          ),
                          style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                          onChanged: (val) {
                            setState(() {
                              _logSearchQuery = val.trim().toLowerCase();
                            });
                          },
                        ),
                        const SizedBox(height: 8),

                        SizedBox(
                          height: 28,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildDialogLogFilterChip('ALL', null),
                              if (_verboseMode) _buildDialogLogFilterChip('DEBUG/TRACE', LogLevel.trace),
                              _buildDialogLogFilterChip('ACTIONS', LogLevel.action),
                              _buildDialogLogFilterChip('INFO', LogLevel.info),
                              _buildDialogLogFilterChip('WARNINGS', LogLevel.warning),
                              _buildDialogLogFilterChip('ERRORS', LogLevel.error),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'LIVE SYSTEM DIAGNOSTIC CONSOLE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryText,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: ValueListenableBuilder<List<LogEntry>>(
                    valueListenable: LoggerService.instance.logsNotifier,
                    builder: (context, logEntries, child) {
                      var filteredLogs = logEntries;
                      if (_selectedLogLevelFilter != null) {
                        filteredLogs = filteredLogs.where((e) {
                          if (_selectedLogLevelFilter == LogLevel.trace) {
                            return e.level == LogLevel.trace || e.level == LogLevel.debug;
                          }
                          return e.level == _selectedLogLevelFilter;
                        }).toList();
                      }
                      if (_logSearchQuery.isNotEmpty) {
                        filteredLogs = filteredLogs.where((e) => 
                          e.source.toLowerCase().contains(_logSearchQuery) ||
                          e.message.toLowerCase().contains(_logSearchQuery)
                        ).toList();
                      }

                      if (filteredLogs.isEmpty) {
                        return Center(
                          child: Text(
                            'No matching console entries recorded.',
                            style: TextStyle(color: AppTheme.mutedText, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        );
                      }

                      return Container(
                        decoration: AppTheme.glassDecoration(
                          color: AppTheme.cardBg.withValues(alpha: 0.1),
                          borderRadius: 10,
                          borderOpacity: 0.05,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            return _buildLogItemRow(filteredLogs[index]);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
