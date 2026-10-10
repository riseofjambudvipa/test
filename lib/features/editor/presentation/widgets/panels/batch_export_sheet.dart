part of 'viral_clipping_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Batch Export Sheet — StatefulWidget so it manages its own async state
// ─────────────────────────────────────────────────────────────────────────────
class BatchExportSheet extends StatefulWidget {
  final List<ViralClipCandidate> candidates;
  final Project project;
  final AspectConversionMode conversionMode;

  const BatchExportSheet({
    super.key,
    required this.candidates,
    required this.project,
    required this.conversionMode,
  });

  @override
  State<BatchExportSheet> createState() => _BatchExportSheetState();
}

class _BatchExportSheetState extends State<BatchExportSheet> {
  String? _outputDir;
  bool _isExporting = false;
  bool _cancelled = false;
  bool _burnCaptions = true;

  // Per-clip export state keyed by candidate id
  late final Map<String, _ClipExportState> _exportStates;

  @override
  void initState() {
    super.initState();
    _exportStates = {
      for (final c in widget.candidates) c.id: _ClipExportState(),
    };
  }

  Future<void> _pickOutputDir() async {
    final result = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose folder to save clips',
    );
    if (result != null) {
      setState(() => _outputDir = result);
    }
  }

  Future<void> _startExport() async {
    if (_outputDir == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n?.errorChooseOutputFolderFirst ??
                'Please choose an output folder first.')),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _cancelled = false;
      for (final s in _exportStates.values) {
        s.status = _ClipExportStatus.idle;
        s.outputPath = null;
        s.errorMessage = null;
      }
    });

    final ffmpegPath = FfmpegLocator.instance.resolve();

    for (final candidate in widget.candidates) {
      if (_cancelled) break;

      setState(() => _exportStates[candidate.id]!.status = _ClipExportStatus.exporting);

      try {
        final outPath = await _exportClip(
          candidate: candidate,
          outputDir: _outputDir!,
          ffmpegPath: ffmpegPath,
        );
        setState(() {
          _exportStates[candidate.id]!.status = _ClipExportStatus.done;
          _exportStates[candidate.id]!.outputPath = outPath;
        });
      } catch (e) {
        LoggerService.instance
            .log(LogLevel.error, '_BatchExportSheet', 'Clip export failed: $e');
        setState(() {
          _exportStates[candidate.id]!.status = _ClipExportStatus.failed;
          _exportStates[candidate.id]!.errorMessage = e.toString();
        });
      }
    }

    setState(() => _isExporting = false);
  }

  /// Extracts a single clip via FFmpeg with the selected aspect-reframing mode and optional subtitles burn-in.
  Future<String> _exportClip({
    required ViralClipCandidate candidate,
    required String outputDir,
    required String ffmpegPath,
  }) async {
    // Build a filesystem-safe filename supporting all Unicode alphabets
    final sanitized = candidate.summary
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    final safeTitle = sanitized.isEmpty
        ? candidate.id
        : sanitized.substring(0, math.min(sanitized.length, 40));
    final filename = 'clip_${candidate.score.round()}_$safeTitle.mp4';
    final outputPath = p.join(outputDir, filename);

    Directory? tempDir;
    try {
      String filterComplex;
      final clipWords = widget.project.words
          .where((w) =>
              (w.end ?? 0.0) > candidate.start &&
              (w.start ?? 0.0) < candidate.end)
          .map((w) {
            final cw = SchemaClones.cloneWord(w);
            final rawStart = (w.start ?? 0.0) - candidate.start;
            final rawEnd = (w.end ?? 0.0) - candidate.start;
            cw.start = math.max(0.0, rawStart);
            cw.end = math.min(candidate.duration, math.max(0.0, rawEnd));
            return cw;
          })
          .toList();

      if (_burnCaptions && clipWords.isNotEmpty) {
        tempDir = await Directory.systemTemp.createTemp('capstudio_clip_sub_');
        final assFile = File(p.join(tempDir.path, 'subtitles.ass'));

        final clipProject = SchemaClones.cloneProjectDeep(widget.project)
          ..width = 1080
          ..height = 1920
          ..duration = candidate.duration
          ..words = clipWords;

        final chunks = CaptionEngine.buildChunks(
          clipWords,
          null,
          0.0,
          candidate.duration,
          widget.project.config.subs.chunkSize,
          widget.project.config.subs.chunkLineMaxLength,
        );

        final assContent = generateAssScript(clipProject, chunks);
        await assFile.writeAsString(assContent);

        final reframeFilter = AspectRatioConverter.buildFilterForMode(
          mode: widget.conversionMode,
          inputWidth: widget.project.width,
          inputHeight: widget.project.height,
          targetWidth: 1080,
          targetHeight: 1920,
          inputStream: '[v_pts]',
          outputStream: '[reframed]',
        );

        final escapedAssPath = escapeAssPath(assFile.path);
        String fontsArg = '';
        try {
          final exporter = FfmpegExporter();
          await exporter.prepareFonts();
          final tempFontsDir = await exporter.prepareTempFontsDir(tempDir.path);
          if (Directory(tempFontsDir).existsSync()) {
            fontsArg = ':fontsdir=\'${escapeAssPath(tempFontsDir)}\'';
          }
        } catch (e) {
          LoggerService.instance.debug('Failed to check fontsDir in viral clipping export: $e');
        }

        filterComplex =
            '[0:v]setpts=PTS-STARTPTS[v_pts]; $reframeFilter; [reframed]subtitles=\'$escapedAssPath\'$fontsArg[out]';
      } else {
        final reframeFilter = AspectRatioConverter.buildFilterForMode(
          mode: widget.conversionMode,
          inputWidth: widget.project.width,
          inputHeight: widget.project.height,
          targetWidth: 1080,
          targetHeight: 1920,
          inputStream: '[v_pts]',
          outputStream: '[out]',
        );
        filterComplex = '[0:v]setpts=PTS-STARTPTS[v_pts]; $reframeFilter';
      }

      // Use input-seeking (-ss before -i) + precise duration (-t)
      final args = [
        '-ss',
        candidate.start.toStringAsFixed(3),
        '-i',
        widget.project.videoPath,
        '-t',
        candidate.duration.toStringAsFixed(3),
        '-filter_complex',
        filterComplex,
        '-map',
        '[out]',
        '-map',
        '0:a?',
        '-c:v',
        'libx264',
        '-preset',
        'fast',
        '-crf',
        '23',
        '-c:a',
        'aac',
        '-b:a',
        '192k',
        '-movflags',
        '+faststart',
        '-y',
        outputPath,
      ];

      final result = await Process.run(ffmpegPath, args);
      if (result.exitCode != 0) {
        final stderr = result.stderr.toString();
        throw Exception(
            'FFmpeg exited ${result.exitCode}: ${stderr.length > 300 ? stderr.substring(0, 300) : stderr}');
      }

      return outputPath;
    } finally {
      if (tempDir != null) {
        try {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        } catch (e) {
          LoggerService.instance.debug('Failed to delete tempDir in viral clipping export: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final doneCount = _exportStates.values
        .where((s) => s.status == _ClipExportStatus.done)
        .length;
    final failCount = _exportStates.values
        .where((s) => s.status == _ClipExportStatus.failed)
        .length;
    final total = widget.candidates.length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.borderGlass,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Icon(Icons.file_download, color: AppTheme.accentOrange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.batchExportSheetTitle(total) ??
                        'BATCH EXPORT $total CLIP${total > 1 ? "S" : ""}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (_isExporting)
                    TextButton(
                      onPressed: () => setState(() => _cancelled = true),
                      child: Text(l10n?.btnCancel ?? 'CANCEL',
                          style: TextStyle(color: AppTheme.accentRed, fontSize: 12)),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Output folder picker
              InkWell(
                onTap: _isExporting ? null : _pickOutputDir,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBgElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _outputDir != null
                          ? AppTheme.accentGreen.withValues(alpha: 0.4)
                          : AppTheme.borderGlass,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_open,
                          size: 18,
                          color: _outputDir != null
                              ? AppTheme.accentGreen
                              : AppTheme.mutedText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _outputDir ??
                              (l10n?.tapToChooseOutputFolder ??
                                  'Tap to choose output folder…'),
                          style: TextStyle(
                            fontSize: 12,
                            color: _outputDir != null
                                ? AppTheme.primaryText
                                : AppTheme.mutedText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_outputDir != null)
                        Icon(Icons.check_circle, size: 16, color: AppTheme.accentGreen),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Burn subtitles toggle
              Material(
                color: AppTheme.cardBgElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.borderGlass),
                ),
                child: SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  dense: true,
                  title: Text(
                    l10n?.burnCaptionsOnClipsLabel ?? 'Burn Dynamic Captions on Clips',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText),
                  ),
                  subtitle: Text(
                    l10n?.burnCaptionsOnClipsDesc ??
                        'Burns styled animated subtitles synchronized to clip audio',
                    style:
                        TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                  ),
                  value: _burnCaptions,
                  activeThumbColor: AppTheme.accentOrange,
                  activeTrackColor: AppTheme.accentOrange.withValues(alpha: 0.5),
                  onChanged: _isExporting
                      ? null
                      : (val) => setState(() => _burnCaptions = val),
                ),
              ),

              const SizedBox(height: 12),

              // Overall progress if exporting
              if (_isExporting || doneCount + failCount > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (doneCount + failCount) / total,
                    minHeight: 6,
                    backgroundColor: AppTheme.borderGlass,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _cancelled
                      ? (l10n?.exportCancelledProgress(doneCount, total) ??
                          'Export cancelled. $doneCount/$total done.')
                      : (l10n?.exportProgressSummary(doneCount, total, failCount) ??
                          '$doneCount/$total exported'
                              '${failCount > 0 ? " · $failCount failed" : ""}'),
                  style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                ),
                const SizedBox(height: 12),
              ],

              // Clip list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.candidates.length,
                  itemBuilder: (_, i) {
                    final c = widget.candidates[i];
                    final state = _exportStates[c.id]!;
                    return _buildClipExportRow(c, state, i + 1);
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Export button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isExporting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.onAccentText))
                      : const Icon(Icons.play_arrow, size: 18),
                  label: Text(
                    _isExporting
                        ? (l10n?.btnExporting ?? 'EXPORTING…')
                        : (doneCount == total && total > 0
                            ? (l10n?.btnExportComplete ?? 'EXPORT COMPLETE ✓')
                            : (l10n?.btnStartExport ?? 'START EXPORT')),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isExporting
                        ? AppTheme.mutedText
                        : (doneCount == total && total > 0
                            ? AppTheme.accentGreen
                            : AppTheme.accentOrange),
                    foregroundColor: AppTheme.onAccentText,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: (_isExporting || (doneCount == total && total > 0))
                      ? null
                      : _startExport,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClipExportRow(
      ViralClipCandidate c, _ClipExportState state, int rank) {
    final startFmt = TimeFormatUtils.formatSecondsToMmSs(c.start, padMinutes: false);
    final endFmt = TimeFormatUtils.formatSecondsToMmSs(c.end, padMinutes: false);

    Widget statusWidget;
    switch (state.status) {
      case _ClipExportStatus.idle:
        statusWidget =
            Icon(Icons.hourglass_empty, size: 18, color: AppTheme.mutedText);
      case _ClipExportStatus.exporting:
        statusWidget = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _ClipExportStatus.done:
        statusWidget =
            Icon(Icons.check_circle, size: 18, color: AppTheme.accentGreen);
      case _ClipExportStatus.failed:
        statusWidget =
            Icon(Icons.error, size: 18, color: AppTheme.accentRed);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: state.status == _ClipExportStatus.done
              ? AppTheme.accentGreen.withValues(alpha: 0.3)
              : state.status == _ClipExportStatus.failed
                  ? AppTheme.accentRed.withValues(alpha: 0.3)
                  : AppTheme.borderGlass,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              statusWidget,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#$rank  ${c.score.round()}/100  ·  $startFmt – $endFmt  (${c.duration.toStringAsFixed(0)}s)',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText),
                    ),
                    if (c.hookText.isNotEmpty)
                      Text(
                        '"${c.hookText}"',
                        style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.accentOrange),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (state.status == _ClipExportStatus.done &&
              state.outputPath != null) ...[
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Text(
                  l10n?.exportClipSavedAt(state.outputPath!) ??
                      '✓ Saved: ${state.outputPath}',
                  style: TextStyle(fontSize: 10, color: AppTheme.accentGreen),
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
          if (state.status == _ClipExportStatus.failed &&
              state.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              '✗ ${state.errorMessage}',
              style: TextStyle(fontSize: 10, color: AppTheme.accentRed),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
