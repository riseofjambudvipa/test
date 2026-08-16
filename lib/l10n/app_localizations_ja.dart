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
}
