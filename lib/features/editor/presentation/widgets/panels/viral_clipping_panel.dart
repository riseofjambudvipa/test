import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';
import '../../../../exporter/data/ffmpeg_exporter.dart';
import '../../../../../core/database/isar_service.dart';
import '../../../../../core/database/schemas/project.dart';
import '../../../../../core/ffmpeg/ffmpeg_locator.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/utils/schema_clones.dart';
import '../../../../../core/video/silence_detector.dart';
import '../../../../../core/video/viral_clip_models.dart';
import '../../../../../core/video/viral_hook_detector.dart';
import '../../../../exporter/data/ass_script_builder.dart';
import '../../../domain/caption_engine.dart';
import '../../controllers/editor_controller.dart';
import '../../controllers/editor_state.dart';
import '../../../../../core/utils/time_format_utils.dart';
import '../../../../../core/audio/waveform_service.dart';
import '../../../../../l10n/app_localizations.dart';

part 'batch_export_sheet.dart';
part 'viral_clipping_candidate_cards.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Per-clip export state
// ─────────────────────────────────────────────────────────────────────────────
enum _ClipExportStatus { idle, exporting, done, failed }

class _ClipExportState {
  _ClipExportStatus status = _ClipExportStatus.idle;
  String? outputPath;
  String? errorMessage;
}

// ─────────────────────────────────────────────────────────────────────────────
// ViralClippingPanel
// ─────────────────────────────────────────────────────────────────────────────
class ViralClippingPanel extends ConsumerStatefulWidget {
  const ViralClippingPanel({super.key});

  @override
  ConsumerState<ViralClippingPanel> createState() => _ViralClippingPanelState();
}

class _ViralClippingPanelState extends ConsumerState<ViralClippingPanel> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  AspectConversionMode _conversionMode = AspectConversionMode.blurPillarbox;
  SilenceAggressiveness _aggressiveness = SilenceAggressiveness.balanced;
  double _noiseThreshold = -35.0;
  double _minSilenceDuration = 0.4;
  bool _isDetectingSilence = false;
  List<SilenceSegment>? _detectedSilences;
  String? _silenceStatusMessage;

  // Viral hook candidates
  bool _isAnalyzingHooks = false;
  List<ViralClipCandidate>? _hookCandidates;
  final double _minClipDuration = 20.0;
  final double _maxClipDuration = 60.0;

  // Batch export selection — keyed by candidate id
  final Map<String, bool> _selectedForExport = {};

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.watch(themeProvider);
    final state = ref.watch(editorProvider);
    final project = state.project;

    if (project == null) {
      return Center(child: Text(AppLocalizations.of(context)?.noProjectLoaded ?? 'No project loaded'));
    }

    final isVertical = project.height > project.width;
    final l10n = AppLocalizations.of(context);

    // Empty-state: no transcription words means AI features cannot produce results
    if (project.words.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 20),
            _buildReframingSection(l10n, project, isVertical),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: AppTheme.glassDecoration(
                color: AppTheme.cardBg.withValues(alpha: 0.5),
                borderRadius: 14,
                borderOpacity: 0.1,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.subtitles_off_outlined,
                        size: 32, color: AppTheme.accentOrange),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Transcription Required',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Transcribe your video first to unlock AI viral clip '
                    'detection, silence removal, and hook analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.mic, size: 16),
                      label: const Text(
                        'GO TO TRANSCRIPTION',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: AppTheme.onAccentText,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => ref
                          .read(editorProvider.notifier)
                          .setActiveTab(EditorTab.transcription),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n),
          const SizedBox(height: 20),
          _buildReframingSection(l10n, project, isVertical),
          const SizedBox(height: 20),
          _buildSilenceRemovalSection(l10n, project),
          const SizedBox(height: 20),
          _buildViralHooksSection(l10n, project),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.6),
        borderRadius: 12,
        borderOpacity: 0.12,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.auto_awesome, color: AppTheme.accentOrange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.viralShortsTitle ?? 'VIRAL SHORTS STUDIO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.viralShortsSubtitle ??
                      '9:16 Vertical Reframe, Silence Jump-Cuts & AI Hook Detector',
                  style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reframing ───────────────────────────────────────────────────────────────

  Widget _buildReframingSection(AppLocalizations? l10n, Project project, bool isVertical) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.4),
        borderRadius: 12,
        borderOpacity: 0.08,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.viralReframeTitle ?? '1. VERTICAL 9:16 REFRAME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: AppTheme.accentOrange,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isVertical
                      ? AppTheme.accentGreen.withValues(alpha: 0.2)
                      : AppTheme.accentOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isVertical
                      ? (l10n?.badge916Vertical ?? '9:16 VERTICAL')
                      : (l10n?.badge169Landscape ?? '16:9 LANDSCAPE'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isVertical ? AppTheme.accentGreen : AppTheme.accentOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.reframeTargetCanvas ??
                'Target canvas: 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)',
            style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.reframeModeLabel ?? 'Reframe Mode:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
          ),
          const SizedBox(height: 8),
          _buildModeTile(
            mode: AspectConversionMode.blurPillarbox,
            title: l10n?.reframeModeBlurPillarbox ?? 'Blur Pillarbox (Recommended)',
            description: l10n?.reframeModeBlurPillarboxDesc ??
                'Scales & blurs video in the background to fill 9:16, keeping the centered video crisp.',
            icon: Icons.blur_on,
          ),
          const SizedBox(height: 6),
          _buildModeTile(
            mode: AspectConversionMode.centerCrop,
            title: l10n?.reframeModeCenterCrop ?? 'Center Smart Crop',
            description: l10n?.reframeModeCenterCropDesc ??
                'Fills the full 9:16 screen by cropping the left and right edges.',
            icon: Icons.crop_portrait,
          ),
          const SizedBox(height: 6),
          _buildModeTile(
            mode: AspectConversionMode.splitScreen,
            title: l10n?.reframeModeSplitScreen ?? 'Split Screen / Dual Layer',
            description: l10n?.reframeModeSplitScreenDesc ??
                'Stacks two video windows vertically (ideal for reactions and podcast dialogue).',
            icon: Icons.view_agenda_outlined,
          ),
          const SizedBox(height: 6),
          _buildModeTile(
            mode: AspectConversionMode.smartFaceTrack,
            title: 'AI Smart Face Track (OpusClip)',
            description:
                'Intelligent rule-of-thirds upper-body focal framing. Keeps the speaker face and eyes perfectly framed in 9:16.',
            icon: Icons.face_retouching_natural_rounded,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.aspect_ratio, size: 16),
              label: Text(
                isVertical
                    ? (l10n?.btnResetTo169 ?? 'CURRENTLY 9:16 (RESET TO 16:9)')
                    : (l10n?.btnSetCanvas916 ?? 'SET PROJECT CANVAS TO 9:16'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: AppTheme.onAccentText,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (isVertical) {
                  ref.read(editorProvider.notifier).updateDimensions(1920, 1080);
                } else {
                  ref.read(editorProvider.notifier).updateDimensions(1080, 1920);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTile({
    required AspectConversionMode mode,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _conversionMode == mode;
    return InkWell(
      onTap: () => setState(() => _conversionMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentOrange.withValues(alpha: 0.12)
              : AppTheme.cardBgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentOrange.withValues(alpha: 0.5)
                : AppTheme.borderGlass,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppTheme.accentOrange : AppTheme.mutedText),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.accentOrange : AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(fontSize: 10, color: AppTheme.secondaryText)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, size: 16, color: AppTheme.accentOrange),
          ],
        ),
      ),
    );
  }

  // ── Silence Removal ─────────────────────────────────────────────────────────

  Widget _buildSilenceRemovalSection(AppLocalizations? l10n, Project project) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.4),
        borderRadius: 12,
        borderOpacity: 0.08,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.viralSilenceTitle ?? '2. SILENCE REMOVAL (JUMP-CUTS)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: AppTheme.accentOrange,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n?.silenceRemovalDesc ??
                'Automatically cuts out dead pauses and breathing gaps to maximize video retention.',
            style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.silenceAggressivenessLabel ?? 'Cut Aggressiveness:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: SilenceAggressiveness.values.map((agg) {
              final isSel = _aggressiveness == agg;
              return ChoiceChip(
                label: Text(agg.label, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                selected: isSel,
                selectedColor: AppTheme.accentOrange.withValues(alpha: 0.25),
                backgroundColor: AppTheme.cardBgElevated,
                side: BorderSide(
                  color: isSel ? AppTheme.accentOrange : AppTheme.borderGlass,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _aggressiveness = agg;
                      _noiseThreshold = agg.noiseThreshold;
                      _minSilenceDuration = agg.minSilenceDuration;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            l10n?.silenceNoiseGateLabel(_noiseThreshold.toInt()) ??
                'Silence Noise Gate: ${_noiseThreshold.toInt()} dB',
            style: TextStyle(fontSize: 11, color: AppTheme.primaryText),
          ),
          Slider(
            value: _noiseThreshold,
            min: -50.0,
            max: -20.0,
            divisions: 30,
            activeColor: AppTheme.accentOrange,
            onChanged: (val) => setState(() => _noiseThreshold = val),
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.silenceMinPauseLabel(_minSilenceDuration.toStringAsFixed(2)) ??
                'Min Pause Duration: ${_minSilenceDuration.toStringAsFixed(2)}s',
            style: TextStyle(fontSize: 11, color: AppTheme.primaryText),
          ),
          Slider(
            value: _minSilenceDuration,
            min: 0.1,
            max: 2.0,
            divisions: 19,
            activeColor: AppTheme.accentOrange,
            onChanged: (val) => setState(() => _minSilenceDuration = val),
          ),
          const SizedBox(height: 8),
          if (_silenceStatusMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cardBgElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _silenceStatusMessage!,
                style: TextStyle(fontSize: 11, color: AppTheme.accentGreen),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: _isDetectingSilence
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search, size: 16),
                  label: Text(
                    _isDetectingSilence
                        ? (l10n?.btnScanning ?? 'SCANNING...')
                        : (l10n?.btnScanSilences ?? 'SCAN FOR SILENCES'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentOrange,
                    side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.5)),
                  ),
                  onPressed: _isDetectingSilence ? null : () => _runSilenceDetection(project),
                ),
              ),
              if (_detectedSilences != null && _detectedSilences!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.content_cut, size: 16),
                    label: Text(l10n?.btnApplyJumpCuts ?? 'APPLY JUMP-CUTS',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: AppTheme.onAccentText,
                    ),
                    onPressed: () => _applyJumpCuts(project),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runSilenceDetection(Project project) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isDetectingSilence = true;
      _silenceStatusMessage = null;
    });

    try {
      final detector = SilenceDetector();
      final silences = await detector.detectSilence(
        videoPath: project.videoPath,
        noiseThreshold: _noiseThreshold,
        durationThreshold: _minSilenceDuration,
        words: project.words,
        totalDuration: project.duration,
      );

      final totalSilence = silences.fold<double>(0.0, (acc, s) => acc + s.duration);

      setState(() {
        _isDetectingSilence = false;
        _detectedSilences = silences;
        _silenceStatusMessage = silences.isEmpty
            ? (l10n?.silenceNoneFound(_minSilenceDuration.toString()) ??
                'No silence gaps found exceeding ${_minSilenceDuration}s.')
            : (l10n?.silenceFoundCount(
                    silences.length, totalSilence.toStringAsFixed(1)) ??
                'Found ${silences.length} silences (${totalSilence.toStringAsFixed(1)}s dead air saved)!');
      });
    } catch (e) {
      LoggerService.instance
          .log(LogLevel.error, 'ViralClippingPanel', 'Silence detection failed: $e');
      setState(() {
        _isDetectingSilence = false;
        _silenceStatusMessage = l10n?.errorScanningAudio(e.toString()) ?? 'Error scanning audio: $e';
      });
    }
  }

  void _applyJumpCuts(Project project) {
    if (_detectedSilences == null || _detectedSilences!.isEmpty) return;

    final controller = ref.read(editorProvider.notifier);
    final totalDuration = project.duration;
    final activeSegments = SilenceDetector().generateActiveSegments(
      silenceSegments: _detectedSilences!,
      totalDuration: totalDuration,
    );

    final newSegments = activeSegments
        .map((s) => VideoSegmentSchema()
          ..start = s.start
          ..end = s.end
          ..isDeleted = false)
        .toList();

    controller.applySegments(newSegments);

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.jumpCutsApplied(activeSegments.length) ??
              'Applied ${activeSegments.length} jump-cuts to project timeline!',
        ),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  // ── Viral Hooks Section ─────────────────────────────────────────────────────

  Widget _buildViralHooksSection(AppLocalizations? l10n, Project project) {
    final hasResults = _hookCandidates != null && _hookCandidates!.isNotEmpty;
    final selectedCount = _selectedForExport.values.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.4),
        borderRadius: 12,
        borderOpacity: 0.08,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.viralHooksTitle ?? '3. AI VIRAL HOOK DETECTOR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: AppTheme.accentOrange,
                ),
              ),
              if (_hookCandidates != null)
                Text(
                  '${_hookCandidates!.length} MOMENTS',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n?.viralHooksDesc ??
                'Scans transcription words for 80+ viral hooks, pacing (120–170 WPM), questions, energy density & clip boundaries.',
            style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: AppTheme.mutedText),
              const SizedBox(width: 6),
              Text(
                'Clip duration range: ${_minClipDuration.toInt()}–${_maxClipDuration.toInt()}s',
                style: TextStyle(fontSize: 10, color: AppTheme.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isAnalyzingHooks
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onAccentText))
                  : const Icon(Icons.bolt, size: 16),
              label: Text(
                _isAnalyzingHooks
                    ? (l10n?.btnAnalyzingTranscript ?? 'ANALYZING TRANSCRIPT...')
                    : (l10n?.btnFindViralMoments ?? 'FIND VIRAL MOMENTS'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: AppTheme.onAccentText,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isAnalyzingHooks ? null : () => _analyzeHooks(project),
            ),
          ),

          // ── Candidate cards ────────────────────────────────────────────────
          if (hasResults) ...[
            const SizedBox(height: 14),
            // Select-all row
            Row(
              children: [
                Checkbox(
                  value: selectedCount == _hookCandidates!.length,
                  tristate: selectedCount > 0 && selectedCount < _hookCandidates!.length,
                  activeColor: AppTheme.accentOrange,
                  onChanged: (val) => setState(() {
                    for (final c in _hookCandidates!) {
                      _selectedForExport[c.id] = val ?? false;
                    }
                  }),
                ),
                Text(
                  l10n?.selectAllLabel ?? 'Select All',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryText),
                ),
                const Spacer(),
                Text(
                  l10n?.selectedCountOf(selectedCount, _hookCandidates!.length) ??
                      '$selectedCount of ${_hookCandidates!.length} selected',
                  style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                ),
              ],
            ),
            ..._hookCandidates!.asMap().entries.map((entry) {
              final idx = entry.key;
              final candidate = entry.value;
              return _buildCandidateCard(idx + 1, candidate, project);
            }),

            // ── Batch Export Button ──────────────────────────────────────────
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.file_download, size: 16),
                label: Text(
                  selectedCount == 0
                      ? (l10n?.btnSelectClipsToBatchExport ?? 'SELECT CLIPS TO BATCH EXPORT')
                      : (l10n?.btnBatchExportCount(selectedCount) ??
                          'BATCH EXPORT $selectedCount CLIP(S)'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedCount == 0
                      ? AppTheme.cardBg
                      : AppTheme.accentOrange,
                  foregroundColor: selectedCount == 0
                      ? AppTheme.mutedText
                      : AppTheme.onAccentText,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: selectedCount == 0
                    ? null
                    : () => _showBatchExportSheet(project),
              ),
            ),
          ] else if (_hookCandidates != null && _hookCandidates!.isEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n?.viralNoClipsDetected ??
                    'No high-scoring viral clips detected in this video duration range.',
                style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _analyzeHooks(Project project) async {
    setState(() => _isAnalyzingHooks = true);

    try {
      // 1. Extract audio waveform amplitudes for hardware-accurate acoustic energy scoring
      List<double>? amplitudes;
      try {
        final ffmpegPath = FfmpegLocator.instance.resolve();
        amplitudes = await WaveformService.instance.extractWaveform(
          videoPath: project.videoPath,
          ffmpegPath: ffmpegPath,
          sampleCount: 1000,
        );
      } catch (e) {
        LoggerService.instance.log(
            LogLevel.warning, 'ViralClippingPanel', 'Waveform extraction for hook detection fallback: $e');
      }

      final detector = ViralHookDetector();
      final candidates = detector.detectHooks(
        words: project.words.toList(),
        amplitudes: amplitudes,
        totalDuration: project.duration,
        minDuration: _minClipDuration,
        maxDuration: _maxClipDuration,
      );

      // Initialise export-selection map (all deselected by default)
      final newSelection = <String, bool>{};
      for (final c in candidates) {
        newSelection[c.id] = false;
      }

      setState(() {
        _isAnalyzingHooks = false;
        _hookCandidates = candidates;
        _selectedForExport
          ..clear()
          ..addAll(newSelection);
      });
    } catch (e) {
      LoggerService.instance
          .log(LogLevel.error, 'ViralClippingPanel', 'Hook detection failed: $e');
      setState(() => _isAnalyzingHooks = false);
    }
  }

  void _toggleExportCandidate(String candidateId, bool? val) {
    setState(() => _selectedForExport[candidateId] = val ?? false);
  }

  // ── Batch Export Sheet ──────────────────────────────────────────────────────

  void _showBatchExportSheet(Project project, {List<ViralClipCandidate>? singleCandidates}) {
    final selected = singleCandidates ??
        (_hookCandidates ?? [])
            .where((c) => _selectedForExport[c.id] == true)
            .toList();

    if (selected.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BatchExportSheet(
        candidates: selected,
        project: project,
        conversionMode: _conversionMode,
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _formatTimestamp(double seconds) {
    return TimeFormatUtils.formatSecondsToMmSs(seconds, padMinutes: false);
  }
}
