part of 'viral_clipping_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Candidate Card & Sub-Widgets (Extension on _ViralClippingPanelState)
// ─────────────────────────────────────────────────────────────────────────────

extension _ViralClipCandidateCards on _ViralClippingPanelState {
  Widget _buildCandidateCard(int rank, ViralClipCandidate candidate, Project project) {
    final l10n = AppLocalizations.of(context);
    final score = candidate.score.round();
    final badgeColor = score >= 80
        ? AppTheme.accentGreen
        : (score >= 60 ? AppTheme.accentOrange : AppTheme.accentOrange.withValues(alpha: 0.7));

    final startFmt = _formatTimestamp(candidate.start);
    final endFmt = _formatTimestamp(candidate.end);
    final isSelected = _selectedForExport[candidate.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.accentOrange.withValues(alpha: 0.08)
            : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? AppTheme.accentOrange.withValues(alpha: 0.5)
              : badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: checkbox + rank/score + timing + category badges ──────
          Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: AppTheme.accentOrange,
                onChanged: (val) => _toggleExportCandidate(candidate.id, val),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#$rank  $score/100',
                  style:
                      TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$startFmt – $endFmt (${candidate.duration.toStringAsFixed(0)}s)',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryText,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (candidate.hasCleanBoundaries) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: AppTheme.accentGreen.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 9, color: AppTheme.accentGreen),
                      const SizedBox(width: 2),
                      Text(
                        l10n?.badgeCleanCut ?? 'CLEAN CUT',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentGreen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (candidate.hookCategory.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: AppTheme.accentCyan.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Text(
                    candidate.hookCategory.toUpperCase(),
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentCyan),
                  ),
                ),
            ],
          ),

          // ── Viral Click-Worthy Title ──────────────────────────────────────
          if (candidate.displayTitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.movie_creation_outlined, size: 14, color: AppTheme.accentOrange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    candidate.displayTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryText,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy_rounded, size: 14, color: AppTheme.mutedText),
                  tooltip: 'Copy Title for Social Media',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: candidate.displayTitle));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied viral title to clipboard: "${candidate.displayTitle}"'),
                        backgroundColor: AppTheme.accentGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],

          // ── Hook keyword badge ────────────────────────────────────────────
          if (candidate.hookText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.accentOrange.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on, size: 11, color: AppTheme.accentOrange),
                      const SizedBox(width: 3),
                      Text(
                        '"${candidate.hookText}"',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentOrange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (candidate.hookInFirstFive) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n?.badgeFirst5s ?? 'FIRST 5s',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentGreen),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (candidate.questionCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.accentCyan.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Text(
                      '${candidate.questionCount}× ?',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentCyan),
                    ),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 8),

          // ── Sub-score bars row ────────────────────────────────────────────
          _buildSubScoreBars(candidate),

          const SizedBox(height: 8),

          // ── Summary text ──────────────────────────────────────────────────
          Text(
            candidate.summary,
            style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // ── AI Virality Reasoning (OpusClip style) ───────────────────────
          if (candidate.viralityReasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardBgElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderGlass),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: AppTheme.accentOrange),
                      const SizedBox(width: 5),
                      Text(
                        'AI VIRALITY ANALYSIS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentOrange,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          candidate.viralityGrade,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final reason in candidate.viralityReasons) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(fontSize: 10, color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(fontSize: 10, color: AppTheme.secondaryText, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // ── Action buttons ────────────────────────────────────────────────
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.play_arrow, size: 14),
                label: Text(l10n?.btnPreview ?? 'Preview', style: const TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryText,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                onPressed: () {
                  ref.read(editorProvider.notifier).setCurrentTime(candidate.start);
                  ref.read(editorProvider.notifier).setIsPlaying(true);
                },
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                icon: const Icon(Icons.crop, size: 13),
                label: Text(l10n?.btnTrim ?? 'Trim',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.8),
                  foregroundColor: AppTheme.onAccentText,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                onPressed: () {
                  ref
                      .read(editorProvider.notifier)
                      .setTrim(candidate.start, candidate.end);
                  ref.read(editorProvider.notifier).setCurrentTime(candidate.start);
                  ref.read(editorProvider.notifier).setIsPlaying(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.projectTrimmedToClip(rank, startFmt, endFmt) ??
                            'Project trimmed to viral clip #$rank ($startFmt - $endFmt)!',
                      ),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_download, size: 13),
                label: Text(l10n?.btnExport ?? 'Export',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: AppTheme.onAccentText,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                onPressed: () =>
                    _showBatchExportSheet(project, singleCandidates: [candidate]),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.fork_right, size: 18),
                tooltip: l10n?.tooltipForkAs916 ?? 'Fork as New 9:16 Short Project',
                color: AppTheme.accentOrange,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
                onPressed: () => _forkProjectFromClip(candidate, rank, project),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// WPM + hookScore + energyScore horizontal mini bars
  Widget _buildSubScoreBars(ViralClipCandidate candidate) {
    final l10n = AppLocalizations.of(context);
    // WPM bar — color-coded
    final wpm = candidate.wordsPerMinute;
    Color wpmColor;
    String wpmLabel;
    double wpmFraction;
    if (wpm >= 120 && wpm <= 170) {
      wpmColor = AppTheme.accentGreen;
      wpmLabel = l10n?.wpmLabelOk(wpm.round()) ?? '${wpm.round()} WPM ✓';
      wpmFraction = ((wpm - 80) / 140).clamp(0.0, 1.0);
    } else if (wpm > 170 && wpm <= 220) {
      wpmColor = AppTheme.accentOrange;
      wpmLabel = l10n?.wpmLabelFast(wpm.round()) ?? '${wpm.round()} WPM FAST';
      wpmFraction = ((wpm - 80) / 220).clamp(0.0, 1.0);
    } else {
      wpmColor = AppTheme.accentRed;
      wpmLabel = l10n?.wpmLabelSlow(wpm.round()) ?? '${wpm.round()} WPM SLOW';
      wpmFraction = ((wpm - 40) / 160).clamp(0.0, 1.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniBar(
                label: 'Hook ${candidate.hookScore.round()}/25',
                fraction: candidate.hookScore / 25.0,
                color: AppTheme.accentOrange,
                icon: Icons.flash_on,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniBar(
                label: 'Story Arc ${candidate.storyArcScore.round()}/25',
                fraction: candidate.storyArcScore / 25.0,
                color: AppTheme.accentCyan,
                icon: Icons.auto_stories,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildMiniBar(
                label: 'Acoustic ${candidate.acousticEnergyScore.round()}/25',
                fraction: candidate.acousticEnergyScore / 25.0,
                color: AppTheme.accentPink,
                icon: Icons.graphic_eq,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniBar(
                label: wpmLabel,
                fraction: wpmFraction,
                color: wpmColor,
                icon: Icons.speed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniBar({
    required String label,
    required double fraction,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppTheme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }

  Future<void> _forkProjectFromClip(
      ViralClipCandidate candidate, int rank, Project project) async {
    // Capture l10n before any async gaps
    final l10n = AppLocalizations.of(context);
    try {
      final forked = SchemaClones.cloneProjectDeep(project);
      forked.id = Isar.autoIncrement;
      forked.projectId =
          'proj_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}';
      forked.name = candidate.displayTitle.isNotEmpty
          ? candidate.displayTitle
          : '${project.name} - Clip #$rank (${candidate.hookCategory})';
      forked.trimStart = candidate.start;
      forked.trimEnd = candidate.end;
      forked.width = 1080;
      forked.height = 1920;
      forked.createdAt = DateTime.now();

      // Retain transcription words that overlap the clip's time range
      forked.words = project.words
          .where((w) =>
              (w.end ?? 0.0) >= candidate.start &&
              (w.start ?? 0.0) <= candidate.end)
          .map(SchemaClones.cloneWord)
          .toList();

      if (IsarService.instance.isInitialized) {
        await IsarService.instance.saveProject(forked);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              l10n?.shortProjectCreated(forked.name) ??
                  'Created 9:16 Short: "${forked.name}"'),
          backgroundColor: AppTheme.accentGreen,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: l10n?.btnOpen ?? 'OPEN',
            textColor: AppTheme.onAccentText,
            onPressed: () {
              ref.read(editorProvider.notifier).setProject(forked);
            },
          ),
        ),
      );
    } catch (e) {
      LoggerService.instance.log(
          LogLevel.error, 'ViralClippingPanel', 'Failed to fork clip project: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              l10n?.errorCreateShortProjectFailed(e.toString()) ??
                  'Failed to create short project: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }
}
