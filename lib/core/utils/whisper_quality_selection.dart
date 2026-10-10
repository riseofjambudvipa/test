import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../whisper/whisper_model.dart';
import '../downloader/binary_downloader_service.dart';
import '../settings/settings_service.dart';
import '../logger/logger_service.dart';
import '../assets/asset_path_service.dart';
import 'native_helper.dart';

/// FIX (Issue #8, CapStudio 1.0 audit — the largest duplication found in the
/// whole codebase): hardware detection, model-existence checking, download
/// progress tracking, and quality-to-model resolution previously existed as
/// two independent, near-verbatim copies of ~8 methods across
/// `import_sheet.dart` (`_ImportVideoDialogState`) and
/// `transcription_panel.dart` (`_TranscriptionPanelState`). Issue #7 (the
/// broken `modelNameEn`) depended on this exact duplicated code, and was a
/// live example of the duplication already causing a bug to exist in two
/// places instead of one.
///
/// This mixin provides the state and logic under new, unambiguous names;
/// each consuming file's `_buildQualityCards()` widget-building code
/// (deliberately styled a little differently per screen — a modal dialog
/// vs. an embedded panel — and intentionally NOT touched by this fix) is
/// updated to read from these instead of its own local fields.
///
/// Where the two original implementations had small behavioral drift
/// (`transcription_panel.dart`'s versions cleared `modelExists` before
/// rebuilding it and re-verified from disk after a download completed;
/// `import_sheet.dart`'s versions didn't), this mixin standardizes on the
/// more defensive behavior for both, since there's no reason import's flow
/// should be less careful than retranscribe's.
mixin WhisperQualitySelectionMixin<T extends StatefulWidget> on State<T> {
  /// The currently active transcription language code (e.g. 'auto', 'en',
  /// 'hi'). The consuming widget supplies this so the mixin doesn't need to
  /// know where language selection state actually lives; call
  /// [updateModelForSelectedQuality] again after the user changes language.
  String get selectedLanguageForQualityPicker;

  SystemHardwareInfo? hardwareInfo;
  QualityMode selectedQuality = QualityMode.balanced;
  bool isQualitySelectorExpanded = false;

  WhisperModel? selectedModel;
  final Map<String, bool> modelExists = {};
  final Map<String, BinaryDownloadProgress?> downloadProgressMap = {};
  final Map<String, StreamSubscription<BinaryDownloadProgress>?> _qualityPickerSubscriptions = {};

  /// Call from initState().
  void initWhisperQualitySelection() {
    loadModelSettings();
    listenToModelDownloads();
    detectHardwareAndSetDefaultQuality();
  }

  /// Call from dispose().
  void disposeWhisperQualitySelection() {
    for (final sub in _qualityPickerSubscriptions.values) {
      sub?.cancel();
    }
  }

  Future<void> detectHardwareAndSetDefaultQuality() async {
    final info = await detectSystemHardware();
    if (!mounted) return;

    setState(() {
      hardwareInfo = info;
      final whisperModelName = SettingsService.instance.whisperModelName;
      if (whisperModelName != null) {
        final loadedQuality = mapModelNameToQualityMode(whisperModelName);
        if (loadedQuality.isSupported(info)) {
          selectedQuality = loadedQuality;
        } else {
          selectedQuality = getRecommendedQualityMode(info);
        }
      } else {
        selectedQuality = getRecommendedQualityMode(info);
      }
      updateModelForSelectedQuality();
    });
  }

  QualityMode mapModelNameToQualityMode(String name) {
    return QualityMode.values.firstWhere(
      (m) => m.modelName == name || m.modelNameEn == name,
      orElse: () => QualityMode.balanced,
    );
  }

  QualityMode getRecommendedQualityMode(SystemHardwareInfo info) {
    return QualityMode.getRecommended(info);
  }

  void updateModelForSelectedQuality() {
    final modelName = selectedQuality.modelName;
    selectedModel = kWhisperModels.firstWhere((m) => m.name == modelName, orElse: () => kWhisperModels.first);
  }

  Future<void> loadModelSettings() async {
    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        modelExists.clear();
        for (final model in kWhisperModels) {
          modelExists[model.name] = false;
        }
        updateModelForSelectedQuality();
      });
      return;
    }

    final Map<String, bool> tempExists = {};
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    for (final model in kWhisperModels) {
      final modelPath = AssetPathService.instance.resolveModelPath(model.name);
      tempExists[model.name] = isTest ? File(modelPath).existsSync() : await File(modelPath).exists();
    }

    if (!mounted) return;
    setState(() {
      modelExists.clear();
      modelExists.addAll(tempExists);
      updateModelForSelectedQuality();
    });
  }

  void listenToModelDownloads() {
    for (final model in kWhisperModels) {
      final toolId = 'model_${model.name}';
      _qualityPickerSubscriptions[model.name] = BinaryDownloaderService.instance
          .stream(toolId)
          .listen((progress) async {
        try {
          if (!mounted) return;
          setState(() {
            downloadProgressMap[model.name] = progress;
            if (progress.status == BinaryDownloadStatus.complete) {
              modelExists[model.name] = true;
            }
          });
          // FIX (audit, active-model hijack): only promote the completed
          // model to the ACTIVE model when it matches the user's current
          // selection in this picker. Previously ANY completed download
          // (e.g. "base" downloaded from another screen) silently switched
          // the active model away from "small" mid-work.
          if (progress.status == BinaryDownloadStatus.complete &&
              selectedModel?.name == model.name) {
            final modelPath = AssetPathService.instance.resolveModelPath(model.name);
            await SettingsService.instance.setWhisperModelPath(modelPath);
            await SettingsService.instance.setWhisperModelName(model.name);
            await loadModelSettings();
          }
        } catch (e) {
          // FIX (audit): an exception inside the stream callback previously
          // propagated on the stream's error zone.
          LoggerService.instance.log(LogLevel.error, 'WhisperQualitySelection',
              'Model download stream handler failed: $e');
        }
      });
    }
  }

  Future<void> downloadWhisperModel(WhisperModel model, {required String logTag}) async {
    setState(() {
      downloadProgressMap[model.name] = BinaryDownloadProgress(
        toolId: 'model_${model.name}',
        status: BinaryDownloadStatus.downloading,
        downloadProgress: 0.0,
      );
    });
    try {
      await BinaryDownloaderService.instance.downloadWhisperModel(model.name);
      await loadModelSettings();
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, logTag, 'Model download failed: $e');
      // ROBUSTNESS FIX (found in second-pass review): the original code in
      // both import_sheet.dart and transcription_panel.dart logged the
      // failure but left downloadProgressMap showing 'downloading' at 0%
      // forever, since the completion handler in listenToModelDownloads()
      // only fires on a genuine stream event, not on a caught exception
      // here. A user hitting a network error or a full disk would see a
      // permanently frozen progress bar with no way to tell the download
      // had actually stopped. Explicitly set a 'failed' status so the UI
      // can show a clear retry state instead.
      if (!mounted) return;
      setState(() {
        downloadProgressMap[model.name] = BinaryDownloadProgress(
          toolId: 'model_${model.name}',
          status: BinaryDownloadStatus.failed,
          error: e.toString(),
        );
      });
    }
  }
}
