// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'CapStudio';

  @override
  String get dashboardTitle => 'マイプロジェクト';

  @override
  String get dashboardSubtitle => 'オフラインAI字幕スタジオ';

  @override
  String get importVideo => '動画をインポート';

  @override
  String get dragDropText => 'ここに動画ファイルをドラッグ＆ドロップしてください';

  @override
  String get clickBrowse => 'またはクリックしてローカルファイルを参照します';

  @override
  String get demoMode => 'デモモード';

  @override
  String get demoModeDesc => 'デモプロジェクトを読み込んで、スタイルやエディタの機能を試します。';

  @override
  String get warningAssets => 'アセットフォルダの復元が必要';

  @override
  String get warningAssetsDesc =>
      'アプリのサポートフォルダ内に組み込みアセットが見つかりませんでした。ここをダブルクリックして復元するか、アセットディレクトリを変更してください。';

  @override
  String get deleteProjectTitle => 'プロジェクトを削除';

  @override
  String deleteProjectConfirm(String projectName) {
    return '\"$projectName\" を永久に削除してもよろしいですか？この操作は取り消せません。';
  }

  @override
  String get renameProjectTitle => 'プロジェクト名を変更';

  @override
  String get projectNameLabel => 'プロジェクト名';

  @override
  String get btnCancel => 'キャンセル';

  @override
  String get btnDelete => '削除';

  @override
  String get btnRename => '名前変更';

  @override
  String get btnSave => '保存';

  @override
  String get btnConfirm => '確認';

  @override
  String get btnExport => 'エクスポート';

  @override
  String get btnUndo => '元に戻す';

  @override
  String get btnRedo => 'やり直し';

  @override
  String get statusDraft => '下書き';

  @override
  String get statusCompleted => '完了';

  @override
  String get createdLabel => '作成日時:';

  @override
  String get durationLabel => '再生時間:';

  @override
  String get statusLabel => 'ステータス:';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsGeneral => '一般設定';

  @override
  String get settingsTheme => 'アプリのテーマ';

  @override
  String get themeSystem => 'システムデフォルト';

  @override
  String get themeLight => 'ライトモード';

  @override
  String get themeDark => 'ダークモード';

  @override
  String get settingsLanguage => 'UI表示言語';

  @override
  String get settingsTranscription => '文字起こし設定';

  @override
  String get settingsWhisperModel => 'Whisperモデル';

  @override
  String get settingsWhisperModelDesc =>
      '音声認識に使用するモデルを選択します。小さいほど高速で、大きいほど高精度です。';

  @override
  String get settingsTranscribeLang => '文字起こし言語';

  @override
  String get settingsAutoDetect => '言語を自動検出する';

  @override
  String get settingsGPU => 'GPUハードウェアアクセラレーション (CUDA)';

  @override
  String get settingsVAD => 'VAD音声検出閾値';

  @override
  String get settingsExport => 'エクスポート設定';

  @override
  String get settingsExportDest => 'デフォルトの出力先';

  @override
  String get settingsBrowse => '参照';

  @override
  String get settingsEmojiPacks => '絵文字＆スタイルパック';

  @override
  String get settingsEmojiPacksDesc => '絵文字のレンダリングスタイルやアクティブな字幕アセットをカスタマイズします。';

  @override
  String get settingsEmojiSearchLang => '絵文字検索言語';

  @override
  String get settingsBtnManagePacks => '絵文字パックを管理';

  @override
  String get systemTitle => 'システム情報';

  @override
  String get systemVersion => 'バージョン';

  @override
  String get systemReset => '設定をデフォルトに戻す';

  @override
  String get editorTabCaptions => '字幕編集';

  @override
  String get editorTabStyles => 'スタイル';

  @override
  String get editorTabTrim => 'トリミング';

  @override
  String get editorTabAudio => 'オーディオ';

  @override
  String get editorTabTranscription => '文字起こし';

  @override
  String get editorTabShortcuts => 'ショートカット';

  @override
  String get editorTabDebug => 'デバッグ';

  @override
  String get editorHeaderBack => '戻る';

  @override
  String get editorKeyboardShortcuts => 'キーボードショートカット';

  @override
  String get dialogAnalyzing => '動画を分析中...';

  @override
  String get dialogTranscribing => '音声を文字起こし中...';

  @override
  String get dialogExtracting => '音声を抽出中...';

  @override
  String get dialogWait => 'これには少し時間がかかる場合があります。お待ちください。';

  @override
  String get dialogError => 'エラー';

  @override
  String get dialogImportFailed => '動画のインポートに失敗しました。';

  @override
  String get noProjects => '作成されたプロジェクトはありません';

  @override
  String get aboutApp => 'CapStudio について';

  @override
  String get aboutAppDesc => 'CapStudio、クレジット、オープンソースライセンスについて説明します。';

  @override
  String get aboutAppThanks => 'CapStudio を支えるオープンソースプロジェクトに感謝いたします：';

  @override
  String get btnViewAllLicenses => 'すべてのパッケージのライセンスを表示';

  @override
  String get exportBurnIn => '字幕を焼き込んだ動画を書き出し';

  @override
  String get exportTimecodeFormats => 'タイムコード付き字幕フォーマット';

  @override
  String get exportWebEnabled =>
      'クライアント側での動画書き出しが有効です。レンダリングはお使いのブラウザ内でローカルに実行されます。';

  @override
  String get exportWebCaptionOnly =>
      'Web書き出しには現在字幕のみが含まれます。絵文字と効果音はまだ動画に焼き込まれません。完全な結果を得るには、デスクトップまたはモバイルアプリから書き出してください。';

  @override
  String get exportOutputName => '出力動画名';

  @override
  String get exportMode => '書き出しモード';

  @override
  String get exportModeFast => '高速（ネイティブFFmpeg）';

  @override
  String get exportModeFastUnsupported => '高速（ネイティブFFmpeg）⚠️ 非対応';

  @override
  String get exportModeSlow => '低速（1:1プレビューレンダリング）';

  @override
  String get exportTargetFps => 'ターゲットFPS';

  @override
  String get exportFps24 => '24 FPS（映画）';

  @override
  String get exportFps25 => '25 FPS（PAL）';

  @override
  String get exportFps30 => '30 FPS（標準）';

  @override
  String get exportFps50 => '50 FPS';

  @override
  String get exportFps60 => '60 FPS（なめらか）';

  @override
  String get exportFastUnsupported =>
      'この端末では、システムのFFmpegに字幕レンダリングフィルター（libass）がないため高速モードは利用できません。代わりに低速モードが使用されます。';

  @override
  String get exportSlowInfo =>
      'プレビューに表示されたとおりの各フレームをそのままキャプチャします。ピクセル単位で正確な字幕が保証されますが、レンダリングは遅くなります。';

  @override
  String get exportDestDirectory => '保存先フォルダ';

  @override
  String get exportDestBrowser => 'ブラウザのダウンロード場所';

  @override
  String get exportDestAndroid => 'ダウンロードフォルダ（/storage/emulated/0/Download）';

  @override
  String get exportDestIos => 'アプリの書類（書き出し後に共有シート）';

  @override
  String get exportChooseFolder => '出力フォルダを選択';

  @override
  String get exportStartMp4 => 'MP4書き出しを開始';

  @override
  String get exportSrtTitle => 'SubRip字幕（.srt）';

  @override
  String get exportSrtDesc => 'タイムコード付きの汎用標準形式。YouTube、VLC、Premiere Proに対応。';

  @override
  String get exportVttTitle => 'WebVTT字幕（.vtt）';

  @override
  String get exportVttDesc => 'HTML5プレイヤーやオンライン配信で広く使われるWeb向け字幕フォーマット。';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha（.ass）';

  @override
  String get exportAssDesc => 'フォントサイズ、スタイル、余白、インライン強調を埋め込めるプロ仕様のフォーマット。';

  @override
  String get exportTxtTitle => 'プレーンテキストの文字起こし（.txt）';

  @override
  String get exportTxtDesc => 'タイムスタンプの接頭辞付きの行ごとの文字起こし。';

  @override
  String exportSuccess(String type) {
    return '$typeを正常に書き出しました！';
  }

  @override
  String get exportNoLocation => '保存先が選択されていません。ファイルパスを選択してください。';

  @override
  String get exportNoLocationCancelled => '保存先が選択されていません。書き出しをキャンセルしました。';

  @override
  String exportFailed(String error) {
    return '書き出しに失敗しました: $error';
  }

  @override
  String get exportCopySrtTooltip => 'SRTをクリップボードにコピー';

  @override
  String get exportCopiedSrt => 'SRTをクリップボードにコピーしました！';

  @override
  String exportCopyFailedSrt(String error) {
    return 'SRTのコピーに失敗しました: $error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return '$type字幕を書き出し';
  }

  @override
  String get exportVideoDialogTitle => '動画をMP4で書き出し';

  @override
  String get ffmpegRequiredTitle => 'FFmpegが必要です';

  @override
  String get ffmpegRequiredBody =>
      '動画ファイルに字幕を焼き込むには、FFmpegのローカルインストールが必要です。\n\n設定でFFmpegのパスを構成してください。';

  @override
  String get okLabel => 'OK';

  @override
  String get exportWebTitle => '動画を書き出しています（クライアント側）';

  @override
  String exportWebSuccess(String fileName) {
    return '動画を$fileNameとして正常に書き出しました！';
  }

  @override
  String exportWebFailed(String error) {
    return 'レンダリングに失敗しました: $error';
  }

  @override
  String get viralShortsTitle => 'バイラルShortsスタジオ';

  @override
  String get viralShortsSubtitle => '9:16垂直リフレーム、無音ジャンプカット＆AIフック検出';

  @override
  String get viralReframeTitle => '1. 垂直 9:16 リフレーム';

  @override
  String get viralSilenceTitle => '2. 無音削除（ジャンプカット）';

  @override
  String get viralHooksTitle => '3. AIバイラルフック検出';

  @override
  String get btnFindViralMoments => 'バイラルな瞬間を検出';

  @override
  String get btnScanSilences => '無音区間をスキャン';

  @override
  String get btnApplyJumpCuts => 'ジャンプカットを適用';

  @override
  String get editorTabShorts => 'Shorts';

  @override
  String get editorTabClips => 'クリップ';

  @override
  String get captionList => '字幕リスト';

  @override
  String get uncertainLabel => '不確実 (<40%)';

  @override
  String get mediumConfidenceLabel => '中程度の信頼度 (40-60%)';

  @override
  String get jumpToUncertain => '次の不確実な単語にジャンプ';

  @override
  String get noUncertainWords => '不確実な単語は見つかりませんでした。';

  @override
  String get findAndReplace => '検索と置換';

  @override
  String get addWordTitle => '単語を追加';

  @override
  String get editWordTitle => '単語を編集';

  @override
  String get wordTextLabel => '単語テキスト';

  @override
  String get startTimeLabel => '開始時間 (秒)';

  @override
  String get endTimeLabel => '終了時間 (秒)';

  @override
  String get splitChunk => 'チャンクを分割';

  @override
  String get insertLineAfter => '後ろに行を挿入';

  @override
  String get duplicateLine => '行を複製';

  @override
  String get deleteLine => '行を削除';

  @override
  String get chooseSfxTitle => '効果音を選択';

  @override
  String get searchSfxPlaceholder => '効果音を検索...';

  @override
  String get noSfxFound => '効果音が見つかりません';

  @override
  String get emojiSearch => '絵文字検索';

  @override
  String get noEmojisFound => '絵文字が見つかりませんでした。';

  @override
  String get mySavedPresets => '保存したプリセット';

  @override
  String get btnImport => 'インポート';

  @override
  String get btnExportCaps => 'エクスポート';

  @override
  String get btnSaveCurrent => '現在を保存';

  @override
  String get resetToDefault => 'デフォルトに戻す';

  @override
  String get resetConfirmBody => 'すべての字幕スタイルがデフォルトにリセットされます。この操作は取り消せません。';

  @override
  String get btnReset => 'リセット';

  @override
  String get wordHighlightBox => '単語ハイライトボックス';

  @override
  String get wordHighlightBoxDesc => '発話中の単語の背後にカラーカプセル背景を表示';

  @override
  String get maxWordsPerChunk => '字幕チャンクあたりの最大単語数';

  @override
  String get maxCharsPerLine => '字幕1行あたりの最大文字数';

  @override
  String get fontSettings => 'フォント設定';

  @override
  String get colorSettings => 'カラー設定';

  @override
  String get borderSettings => '境界線と影の設定';

  @override
  String get speechToTextTitle => '音声テキスト変換 (文字起こし)';

  @override
  String get speechToTextDesc =>
      'ローカル音声テキスト変換を再実行します。手動による編集やタイミング調整は置き換えられます。';

  @override
  String get useLocalAi => 'ローカルAI文字起こしを使用';

  @override
  String get runOnDeviceDesc => 'このデバイス上で直接音声テキスト変換を実行します';

  @override
  String get offlineDemoModeActive =>
      'オフラインデモモードが有効です。Web版ではローカルWhisper AI文字起こしはサポートされていません。';

  @override
  String get demoModeNote =>
      'デモモードはリアルな字幕トークンを瞬時に生成します。設定不要でスタイル、テンプレート、タイムライン操作のテストに最適です。';

  @override
  String get transcriptionQuality => '文字起こしの品質';

  @override
  String get advancedSettings => '詳細設定';

  @override
  String get cpuThreadsLabel => 'CPUスレッド数';

  @override
  String get vadSensitivity => 'VAD感度';

  @override
  String get translateToEnglish => '字幕を英語に翻訳';

  @override
  String get startTranscriptionBtn => '文字起こしを開始';

  @override
  String get hardwareLocked => 'ハードウェア制限';

  @override
  String get btnDownload => 'ダウンロード';

  @override
  String get welcomeTitle => 'CapStudioへようこそ';

  @override
  String get welcomeSubtitle => '高精度な字幕とバズるショート動画、100%完全オフライン。';

  @override
  String get setupAssetDirTitle => 'アセットディレクトリを選択';

  @override
  String get setupAssetDirDesc => 'モデル、フォント、絵文字パックを保存するディレクトリを選択します。';

  @override
  String get downloadPacksTitle => 'コンテンツパックのダウンロード (任意)';

  @override
  String get downloadPacksDesc => '動画プロジェクト用のアドオンフォントおよび効果音。';

  @override
  String get setupCompleteTitle => 'セットアップ完了';

  @override
  String get setupCompleteDesc => '魅力的な字幕動画を作成する準備が整いました。';

  @override
  String get btnGetStarted => '使ってみる';

  @override
  String get btnNext => '次へ';

  @override
  String get btnSkip => 'スキップ';

  @override
  String get onboardingFeaturePrivacy => '100% プライバシー保護';

  @override
  String get onboardingFeaturePrivacyDesc =>
      'ファイルがデバイス外に送信されることはありません。すべてのAIモデルはローカルで動作します。';

  @override
  String get onboardingFeatureGpu => 'GPU高速再生';

  @override
  String get onboardingFeatureGpuDesc => 'ハードウェアデコードを活用した高性能な動画編集。';

  @override
  String get onboardingFeatureAssets => 'オフラインサイドカーアセット';

  @override
  String get onboardingFeatureAssetsDesc =>
      '豊富な絵文字パックを一度ダウンロードすれば、完全オフラインで利用できます。';

  @override
  String get onboardingReadyTitle => '準備が完了しました！';

  @override
  String get onboardingConfigDetails => '設定の詳細:';

  @override
  String get btnLaunchCapStudio => 'CapStudioを起動';

  @override
  String get assetVerificationFailed =>
      'アセットの検証に失敗しました。アセットが正しくダウンロードされているか確認してください。';

  @override
  String get assetsFolderNotFound => 'アセットフォルダが見つかりません';

  @override
  String get assetsFolderNotFoundDesc =>
      '設定された場所にアセットフォルダが見つかりませんでした。外付けドライブにある場合は接続してください。';

  @override
  String get expectedPathLabel => '予定パス:';

  @override
  String get browseNewLocation => '新しい場所を参照';

  @override
  String get resetToDefaultPath => 'デフォルトのパスに戻す';

  @override
  String get retryVerification => '再検証';

  @override
  String get storagePathFolder => '保存先フォルダ';

  @override
  String get tipWindowsDrive => 'ヒント: Cドライブの容量が少ない場合は、DドライブやEドライブを選択してください。';

  @override
  String get tipGeneralDrive => 'ヒント: システムドライブの空き容量が不足している場合は、外付けドライブを選択できます。';

  @override
  String get confirmLocation => '場所を確定';

  @override
  String get requiredBadge => '必須';

  @override
  String get emojiPacksHeader => '絵文字パック';

  @override
  String get fontPacksHeader => 'フォントパック';

  @override
  String get connectCliTitle => 'ローカルCLIツールの連携';

  @override
  String get connectCliDesc =>
      'CapStudioでローカル文字起こしや動画エクスポートを行うには、whisper.cpp と FFmpeg のバイナリが必要です。';

  @override
  String get skipSetup => '今はセットアップをスキップ';

  @override
  String get btnValidate => '検証';

  @override
  String get autoDetectAndValidate => '自動検出して検証';

  @override
  String get whisperCliPathLabel => 'Whisper CLI 実行ファイルのパス';

  @override
  String get ffmpegCliPathLabel => 'FFmpeg CLI 実行ファイルのパス';

  @override
  String get newProject => '新規プロジェクト';

  @override
  String get searchProjects => 'プロジェクトを検索...';

  @override
  String get filterAll => 'すべて';

  @override
  String get sortByRecent => '最新順';

  @override
  String get sortByDuration => '長さ';

  @override
  String get noMatchingProjects => '一致するプロジェクトが見つかりません';

  @override
  String get btnEdit => '編集';

  @override
  String get btnDuplicate => '複製';

  @override
  String get tooltipEdit => '編集';

  @override
  String get tooltipRename => '名前を変更';

  @override
  String get tooltipDuplicate => '複製';

  @override
  String get tooltipDelete => '削除';

  @override
  String get tooltipTheme => 'テーマ';

  @override
  String get tooltipSettings => '設定';

  @override
  String get selectDemoFormat => 'デモ形式を選択';

  @override
  String get selectDemoDesc =>
      'レイアウト形式を選択して、CapStudioの高精度字幕エンジン、単語単位のアニメーション、音声波形を今すぐプレビューできます。';

  @override
  String get landscapeDemo => '横向きデモ';

  @override
  String get landscapeDemoDesc => 'YouTube、デスクトップ、プレゼンテーションに最適です。';

  @override
  String get portraitDemo => '縦向きデモ';

  @override
  String get portraitDemoDesc => 'TikTok、Shorts、Reels、モバイルに最適です。';

  @override
  String get format16x9 => '16:9 形式';

  @override
  String get format9x16 => '9:16 形式';

  @override
  String get dropVideoHere => 'ここに動画をドロップ';

  @override
  String get dropVideoSupported => 'MP4、MOV、AVI などをサポート';

  @override
  String get statusLocalOffline => 'ローカルオフライン';

  @override
  String get speechModelTitle => '音声認識モデル';

  @override
  String get hardwareUpgradesTitle => 'ハードウェアパフォーマンスのアップグレード';

  @override
  String get showAdvancedPaths => '高度なパス設定を表示';

  @override
  String get hideAdvancedPaths => '高度なパス設定を非表示';

  @override
  String get autoDownload => '自動ダウンロード';

  @override
  String get gpuAcceleratedTranscription => 'GPU高速文字起こし (CUDA)';

  @override
  String get gpuRequiresNvidia => 'CUDA対応のNVIDIA GPUが必要です';

  @override
  String get gpuExportEncoder => 'GPUエクスポートエンコーダー';

  @override
  String get gpuExportEncoderDesc => 'MP4動画エクスポートのハードウェアアクセラレーション';

  @override
  String get defaultLanguage => 'デフォルト言語';

  @override
  String get vadTitle => '音声活動検出 (VAD)';

  @override
  String get vadDesc => '処理中に無音区間をスキップします';

  @override
  String get vadThreshold => 'VADしきい値';

  @override
  String get autoSaveTitle => '自動保存';

  @override
  String get autoSaveDesc => '3秒ごとにプロジェクトの編集内容をデータベースへ自動保存';

  @override
  String get defaultOutputsTitle => 'デフォルトの出力先';

  @override
  String get defaultExportFolder => 'デフォルトのエクスポートフォルダ';

  @override
  String get alwaysAskExportPath => 'エクスポート時に毎回保存先を確認';

  @override
  String get alwaysAskExportPathDesc => 'エクスポートごとに保存先パスを選択します (デスクトップ)';

  @override
  String get performanceTitle => 'パフォーマンス';

  @override
  String get exportCpuThreads => 'エクスポート用CPUスレッド数';

  @override
  String get exportCpuThreadsDesc => 'レンダリングに使用するプロセッサスレッド数 (デバイスごとに安全に自動調整)';

  @override
  String get aboutAppSubtitle => '100%オフライン・プライバシー最優先のAI字幕制作スタジオ';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get openSourceComplianceDesc =>
      'CapStudioは多くのオープンソースライブラリを利用しています。アプリストアの法的要件に準拠するため、すべてのDartパッケージ、推移的依存関係、および完全なライセンス条文を以下にまとめています。';

  @override
  String get visitWebsite => 'ウェブサイトを開く';

  @override
  String get btnContinue => '続ける';

  @override
  String get btnBack => '戻る';

  @override
  String get editTiming => 'タイミング編集';

  @override
  String get wordSettingsTitle => '単語設定';

  @override
  String get emojiSettingsTitle => '絵文字設定';

  @override
  String get changeEmojiTooltip => '絵文字を変更';

  @override
  String get searchEmojisHint => '絵文字を検索...';

  @override
  String emojiPosX(String offset) {
    return '絵文字の位置 (Xオフセット: ${offset}px)';
  }

  @override
  String emojiPosY(String offset) {
    return '絵文字の位置 (Yオフセット: ${offset}px)';
  }

  @override
  String emojiScale(String scale) {
    return '絵文字の倍率 (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return 'アニメーション速度 (${speed}x)';
  }

  @override
  String get emojiStylePack => '絵文字スタイル / パック';

  @override
  String get selectStylePackTooltip => 'スタイルパックを選択';

  @override
  String get selectEmojiTitle => '絵文字を選択';

  @override
  String get stylePackLabel => 'スタイルパック';

  @override
  String get searchHint => '検索...';

  @override
  String get btnCreateProject => 'プロジェクトを作成';

  @override
  String get btnChooseFile => 'ファイルを選択';

  @override
  String get selectSubtitleFile => '字幕ファイルを選択';

  @override
  String get selectTranscriptionQuality => '文字起こしの品質を選択';

  @override
  String get translateToEnglishDesc => '外国語の音声を英語の字幕に直接変換します';

  @override
  String get hardwareSettings => 'ハードウェアとパフォーマンス設定';

  @override
  String get styleTemplatesHeader => 'スタイルテンプレート';

  @override
  String get resetToDefaultStyle => 'デフォルトスタイルに戻す';

  @override
  String get resetStylingTitle => 'スタイルをリセットしますか？';

  @override
  String get resetStylingDesc => 'すべての字幕スタイルがデフォルトにリセットされます。この操作は取り消せません。';

  @override
  String get sizeAndPosition => 'サイズと位置';

  @override
  String get verticalYPos => '垂直Y位置 (%)';

  @override
  String get fontConfigHeader => 'フォント構成';

  @override
  String get fontFamilyLabel => 'フォントファミリー';

  @override
  String get btnImportCustomFont => 'カスタムフォントをインポート (.ttf / .otf)';

  @override
  String get fontWeightLabel => 'フォントの太さ';

  @override
  String get textCaseLabel => '大文字/小文字';

  @override
  String get fontSizeLabel => 'フォントサイズ';

  @override
  String get letterSpacingLabel => '文字間隔';

  @override
  String get lineHeightLabel => '行の高さ';

  @override
  String get onboardingAppTagline => '100%完全オフラインのローカルAI字幕エディタ';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => 'デモモード (模擬)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault => 'システムPATHデフォルト';

  @override
  String get configLabelAssetsLocation => 'アセットの保存場所';

  @override
  String get filePickerAssetsDialogTitle => 'CapStudio アセットフォルダを選択';

  @override
  String errorSelectFolderFailed(String error) {
    return 'フォルダの選択に失敗しました: $error';
  }

  @override
  String errorResetFailed(String error) {
    return 'リセットに失敗しました: $error';
  }

  @override
  String errorVerificationFailed(String error) {
    return '検証に失敗しました: $error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return '次の場所にアセットフォルダが見つかりません: $path';
  }

  @override
  String get dbRecoveredTitle => 'データベースが自動復旧しました';

  @override
  String dbRecoveredBody(String backupPath) {
    return 'データベースのスキーマ不一致または破損が検出されました。データベースはリセットされ、以前のデータは以下にバックアップされました:\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return 'デモ動画の読み込みに失敗しました: $error';
  }

  @override
  String importProgressPercent(int percent) {
    return '$percent% 完了';
  }

  @override
  String get errorInvalidDropFileFormat => '無効なファイル形式です。動画ファイルをドロップしてください。';

  @override
  String get findTextLabel => '検索テキスト';

  @override
  String get replaceWithLabel => '置換テキスト';

  @override
  String findReplaceSuccessCount(int count) {
    return '$count 件を置換しました！';
  }

  @override
  String get btnReplaceAll => 'すべて置換';

  @override
  String errorVideoFileNotFound(String path) {
    return '動画ファイルが見つかりません:\n$path\n動画ファイルを再リンクしてください。';
  }

  @override
  String get errorTranscriptionFailed => '文字起こしに失敗しました。もう一度お試しください。';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return '有効: $quality ($model)';
  }

  @override
  String get badgeRecommended => 'おすすめ';

  @override
  String get languageLabel => '言語';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return '警告: 選択したモデル ($model) は英語専用です。\"$language\" での文字起こしは失敗するか、英語の字幕が生成されます。マルチリンガルモデル (Tiny または Base など) を選択してください。';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      'ヒント: 複数言語が混在している場合、自動検出は推奨されません。話されている言語を明示的に選択すると、はるかに正確な字幕が得られます。';

  @override
  String get detectedHardwareLabel => '検出されたシステムハードウェア:';

  @override
  String hardwareRamSize(String ramGB) {
    return 'RAM容量: $ramGB GB';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'CPU論理コア数: $cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'GPUデバイス: $gpu';
  }

  @override
  String get hardwareDetecting => 'ハードウェア構成を検出中...';

  @override
  String get btnStartReTranscribe => '再文字起こしを開始';

  @override
  String get btnImportSrtVtt => 'SRT/VTT ファイルをインポート';

  @override
  String importedSubtitleWords(int count) {
    return '字幕ファイルから $count 語をインポートしました。';
  }

  @override
  String get errorImportSubtitleFailed =>
      '字幕ファイルのインポートに失敗しました。ファイル形式を確認してください。';

  @override
  String get noProjectLoaded => 'プロジェクトが読み込まれていません';

  @override
  String get badge916Vertical => '9:16 縦向き';

  @override
  String get badge169Landscape => '16:9 横向き';

  @override
  String get reframeTargetCanvas =>
      'ターゲットキャンバス: 1080 × 1920 (TikTok、YouTube Shorts、Instagram Reels)';

  @override
  String get reframeModeLabel => 'リフレームモード:';

  @override
  String get reframeModeBlurPillarbox => 'ブラーピラーボックス (おすすめ)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      '背景動画を拡大してぼかし、9:16画面を埋めながら、中央の動画を鮮明に保ちます。';

  @override
  String get reframeModeCenterCrop => 'センタースマートクロップ';

  @override
  String get reframeModeCenterCropDesc => '左右の端を切り取ることで、9:16画面いっぱいに表示します。';

  @override
  String get reframeModeSplitScreen => '分割画面 / デュアルレイヤー';

  @override
  String get reframeModeSplitScreenDesc =>
      '2つの動画ウィンドウを上下に配置します (リアクション動画やポッドキャストの対談に最適)。';

  @override
  String get btnResetTo169 => '現在 9:16 (16:9 にリセット)';

  @override
  String get btnSetCanvas916 => 'プロジェクトキャンバスを 9:16 に設定';

  @override
  String get silenceRemovalDesc => '不要な間や息継ぎを自動でカットし、動画の視聴維持率を最大化します。';

  @override
  String get silenceAggressivenessLabel => 'カットの積極性:';

  @override
  String silenceNoiseGateLabel(int db) {
    return '無音ノイズゲート: $db dB';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return '最小休止時間: $duration秒';
  }

  @override
  String get btnScanning => 'スキャン中...';

  @override
  String silenceNoneFound(String duration) {
    return '$duration秒を超える無音区間は見つかりませんでした。';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return '$count 箇所の無音を検出しました ($totalSecs秒の無駄時間をカット)！';
  }

  @override
  String errorScanningAudio(String error) {
    return '音声のスキャン中にエラーが発生しました: $error';
  }

  @override
  String jumpCutsApplied(int count) {
    return 'プロジェクトのタイムラインに $count 箇所のジャンプカットを適用しました！';
  }

  @override
  String get viralHooksDesc =>
      '文字起こしから80種以上のバズフック、テンポ (120-170 WPM)、質問、熱量密度、クリップ境界をスキャンします。';

  @override
  String get btnAnalyzingTranscript => '文字起こしを分析中...';

  @override
  String get selectAllLabel => 'すべて選択';

  @override
  String selectedCountOf(int selected, int total) {
    return '$total 件中 $selected 件を選択中';
  }

  @override
  String get btnSelectClipsToBatchExport => '一括エクスポートするクリップを選択';

  @override
  String btnBatchExportCount(int count) {
    return '$count 件のクリップを一括エクスポート';
  }

  @override
  String get viralNoClipsDetected => 'この動画の長さの範囲では、高スコアのバズクリップが検出されませんでした。';

  @override
  String get badgeCleanCut => 'クリーンカット';

  @override
  String get badgeFirst5s => '最初の5秒';

  @override
  String get btnPreview => 'プレビュー';

  @override
  String get btnTrim => 'トリミング';

  @override
  String get tooltipForkAs916 => '新しい 9:16 ショートプロジェクトとして派生';

  @override
  String wpmLabelOk(int wpm) {
    return '$wpm WPM ✓';
  }

  @override
  String wpmLabelFast(int wpm) {
    return '$wpm WPM 速い';
  }

  @override
  String wpmLabelSlow(int wpm) {
    return '$wpm WPM 遅い';
  }

  @override
  String hookScoreLabel(int score) {
    return 'フック度 $score/40';
  }

  @override
  String energyScoreLabel(int score) {
    return '熱量 $score/20';
  }

  @override
  String get filePickerClipsFolderTitle => 'クリップの保存先フォルダを選択';

  @override
  String get errorChooseOutputFolderFirst => '最初に保存先フォルダを選択してください。';

  @override
  String batchExportSheetTitle(int count) {
    return '$count 件のクリップを一括エクスポート';
  }

  @override
  String get tapToChooseOutputFolder => 'タップして保存先フォルダを選択…';

  @override
  String get burnCaptionsOnClipsLabel => 'クリップに動的字幕を焼き付ける';

  @override
  String get burnCaptionsOnClipsDesc => '音声と同期したスタイリッシュなアニメーション字幕を埋め込みます';

  @override
  String exportCancelledProgress(int done, int total) {
    return 'エクスポートをキャンセルしました。$done/$total 完了。';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return '$done/$total 件エクスポート完了 · $failed 件失敗';
  }

  @override
  String get btnExporting => 'エクスポート中…';

  @override
  String get btnExportComplete => 'エクスポート完了 ✓';

  @override
  String get btnStartExport => 'エクスポートを開始';

  @override
  String exportClipSavedAt(String path) {
    return '✓ 保存完了: $path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return 'プロジェクトをバズクリップ #$rank ($start - $end) にトリミングしました！';
  }

  @override
  String shortProjectCreated(String name) {
    return '9:16 ショートプロジェクトを作成しました: \"$name\"';
  }

  @override
  String get btnOpen => '開く';

  @override
  String errorCreateShortProjectFailed(String error) {
    return 'ショートプロジェクトの作成に失敗しました: $error';
  }

  @override
  String get autoDetect => '自動検出';

  @override
  String presetSaved(String name) {
    return 'スタイルプリセット \"$name\" を保存しました！';
  }

  @override
  String get presetDeleted => 'プリセットを削除しました。';

  @override
  String get presetExported => 'スタイルプリセットをエクスポートしました！';

  @override
  String errorPresetExportFailed(String error) {
    return 'プリセットのエクスポートに失敗しました: $error';
  }

  @override
  String get presetImported => 'スタイルプリセットをインポートしました！';

  @override
  String errorPresetImportFailed(String error) {
    return 'プリセットのインポートに失敗しました: $error';
  }

  @override
  String get selectFontFileDialogTitle => 'TTF または OTF フォントファイルを選択';

  @override
  String get fontWeightThin => '極細';

  @override
  String get fontWeightExtraLight => '特薄';

  @override
  String get fontWeightLight => '細字';

  @override
  String get fontWeightNormal => '標準';

  @override
  String get fontWeightMedium => '中字';

  @override
  String get fontWeightSemiBold => '中太';

  @override
  String get fontWeightBold => '太字';

  @override
  String get fontWeightExtraBold => '極太';

  @override
  String get fontWeightBlack => 'ブラック';

  @override
  String get fontCaseNormal => '標準';

  @override
  String get fontCaseUppercase => '大文字';

  @override
  String get fontCaseCapitalize => '先頭のみ大文字';

  @override
  String get strokeStyleThickOutline => '太いアウトライン';

  @override
  String get strokeStyleNoneFlat => 'なし (フラット)';

  @override
  String get shadowStyleSoft => 'ソフトシャドウ';

  @override
  String get shadowStyleNone => 'なし';

  @override
  String get animStyleActivePop => 'アクティブポップ';

  @override
  String get animStyleActiveBounce => 'アクティブバウンス';

  @override
  String get animStyleKineticTilt => 'キネティックティルト';

  @override
  String get animStyleGlowPulse => 'グローパルス';

  @override
  String get animStyleWordReveal => 'ワードリビール';

  @override
  String get animStyleNoneStatic => 'なし (静止)';

  @override
  String fontImportedSuccess(String name) {
    return 'カスタムフォント \"$name\" を正常にインポートして適用しました';
  }

  @override
  String get errorFontImportFailed => 'フォントファイルの読み込みに失敗しました。データが無効です。';

  @override
  String get invalidTimingError =>
      '開始/終了時間が無効です。開始時間は0以上、終了時間は開始時間以上かつ動画の長さ以下である必要があります。';

  @override
  String get projectSavedSuccess => 'プロジェクトを保存しました。';

  @override
  String wordDeletedSuccess(String text) {
    return '単語を削除しました: \"$text\"';
  }

  @override
  String get splitClip => 'クリップを分割';

  @override
  String get removeClip => 'クリップを削除';

  @override
  String get resetToOriginal => '元に戻す';

  @override
  String splitTimelineAt(String time) {
    return '$time秒の位置でタイムラインを分割しました。';
  }

  @override
  String get splitTimelineError => '分割するには再生ヘッドがアクティブな領域内にある必要があります。';

  @override
  String get exclusionToggled => '再生ヘッド下のセグメント除外状態を切り替えました。';

  @override
  String get splitsReset => 'すべてのタイムライン分割と除外をリセットしました。';

  @override
  String get shareVideo => '動画を共有';

  @override
  String get openOutputFolder => '出力先フォルダを開く';

  @override
  String get errorLogCopied => 'エラーログをクリップボードにコピーしました。';

  @override
  String get diagnosticsExported => 'フィルタリングされた診断レポートを共有シートで開きました。';

  @override
  String errorDiagnosticsFailed(String error) {
    return '診断レポートのエクスポートに失敗しました: $error';
  }

  @override
  String logLineCopied(String message) {
    return 'ログ行をクリップボードにコピーしました: \"$message\"';
  }

  @override
  String commandCopied(String command) {
    return 'コピー完了: \"$command\"';
  }

  @override
  String get settingsRestored => '設定をデフォルトに戻しました。';

  @override
  String get gpuEncoderNoneCpu => 'なし (CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => 'VC++ 再頒布可能パッケージをダウンロード';

  @override
  String errorDownloadToolFailed(String error) {
    return 'ツールのダウンロードに失敗しました: $error';
  }

  @override
  String get errorFolderNotAccessible => '選択したフォルダが存在しないか、アクセス権がありません。';

  @override
  String modelDeleted(String name) {
    return 'モデルを削除しました: $name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return 'モデルの削除に失敗しました: $error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return 'モデル $name のダウンロードに失敗しました: $error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return 'フォルダを自動で開けませんでした。パス: $path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return 'パックのダウンロードに失敗しました: $error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return 'パック $name のダウンロードに失敗しました: $error';
  }

  @override
  String get stickersIndexRefreshed => 'カスタムステッカーのインデックスを更新しました！';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return 'アセットフォルダの変更に失敗しました: $error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return 'アセットフォルダの設定に失敗しました: $error';
  }

  @override
  String get warningNoAvx =>
      'AVXサポートが検出されませんでした！互換性のあるwhisper-cli (非AVX) をダウンロードしています...';

  @override
  String get errorAutoDetectWhisper => 'whisper-cli を自動検出できませんでした。手動で参照してください。';

  @override
  String get errorAutoDetectFfmpeg => 'ffmpeg を自動検出できませんでした。手動で参照してください。';

  @override
  String errorToolDownloadFailed(String error) {
    return 'ツールのダウンロードに失敗しました: $error';
  }

  @override
  String get returnToDashboard => 'ダッシュボードに戻る';

  @override
  String errorImportVideoFailed(String error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String get videoRelinkedSuccess => '動画を再リンクしました！';

  @override
  String get errorRelinkVideoFailed => '動画の再リンクに失敗しました。';

  @override
  String get retranscriptionSuccess => '再文字起こしが完了しました！';

  @override
  String get retranscriptionFailed => '再文字起こしに失敗しました。';
}
