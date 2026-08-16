// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'CapStudio';

  @override
  String get dashboardTitle => '我的项目';

  @override
  String get dashboardSubtitle => '离线 AI 智能字幕制作工具';

  @override
  String get importVideo => '导入视频';

  @override
  String get dragDropText => '将视频文件拖放到此处';

  @override
  String get clickBrowse => '或点击浏览本地文件';

  @override
  String get demoMode => '演示模式';

  @override
  String get demoModeDesc => '加载演示项目以试用字幕样式和编辑功能。';

  @override
  String get warningAssets => '需要恢复资源文件夹';

  @override
  String get warningAssetsDesc => '在应用支持文件夹中未找到内置资源。双击此处以恢复或更改资源目录。';

  @override
  String get deleteProjectTitle => '删除项目';

  @override
  String deleteProjectConfirm(String projectName) {
    return '您确定要永久删除 \"$projectName\" 吗？此操作无法撤销。';
  }

  @override
  String get renameProjectTitle => '重命名项目';

  @override
  String get projectNameLabel => '项目名称';

  @override
  String get btnCancel => '取消';

  @override
  String get btnDelete => '删除';

  @override
  String get btnRename => '重命名';

  @override
  String get btnSave => '保存';

  @override
  String get btnConfirm => '确认';

  @override
  String get btnExport => '导出';

  @override
  String get btnUndo => '撤销';

  @override
  String get btnRedo => '重做';

  @override
  String get statusDraft => '草稿';

  @override
  String get statusCompleted => '已完成';

  @override
  String get createdLabel => '创建时间:';

  @override
  String get durationLabel => '时长:';

  @override
  String get statusLabel => '状态:';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsGeneral => '常规设置';

  @override
  String get settingsTheme => '应用主题';

  @override
  String get themeSystem => '系统默认';

  @override
  String get themeLight => '浅色模式';

  @override
  String get themeDark => '深色模式';

  @override
  String get settingsLanguage => '界面语言';

  @override
  String get settingsTranscription => '语音识别设置';

  @override
  String get settingsWhisperModel => 'Whisper 模型';

  @override
  String get settingsWhisperModelDesc => '选择用于转写的 Whisper 模型。模型越小速度越快，越大越准确。';

  @override
  String get settingsTranscribeLang => '转写语言';

  @override
  String get settingsAutoDetect => '自动检测语言';

  @override
  String get settingsGPU => 'GPU 硬件加速 (CUDA)';

  @override
  String get settingsVAD => 'VAD 语音活动检测阈值';

  @override
  String get settingsExport => '导出设置';

  @override
  String get settingsExportDest => '默认输出目录';

  @override
  String get settingsBrowse => '浏览';

  @override
  String get settingsEmojiPacks => '表情与样式包';

  @override
  String get settingsEmojiPacksDesc => '自定义表情符号渲染样式和字幕相关的资源包。';

  @override
  String get settingsEmojiSearchLang => '表情符号搜索语言';

  @override
  String get settingsBtnManagePacks => '管理表情包';

  @override
  String get systemTitle => '系统信息';

  @override
  String get systemVersion => '版本';

  @override
  String get systemReset => '恢复默认值';

  @override
  String get editorTabCaptions => '字幕编辑';

  @override
  String get editorTabStyles => '字体样式';

  @override
  String get editorTabTrim => '视频裁剪';

  @override
  String get editorTabAudio => '音频特效';

  @override
  String get editorTabTranscription => '重新转写';

  @override
  String get editorTabShortcuts => '快捷键';

  @override
  String get editorTabDebug => '调试面板';

  @override
  String get editorHeaderBack => '返回';

  @override
  String get editorKeyboardShortcuts => '键盘快捷键说明';

  @override
  String get dialogAnalyzing => '正在分析视频...';

  @override
  String get dialogTranscribing => '正在转写音频...';

  @override
  String get dialogExtracting => '正在提取音频...';

  @override
  String get dialogWait => '这可能需要一些时间，请稍候。';

  @override
  String get dialogError => '发生错误';

  @override
  String get dialogImportFailed => '导入视频失败。';

  @override
  String get noProjects => '暂无已创建项目';

  @override
  String get aboutApp => '关于 CapStudio';

  @override
  String get aboutAppDesc => '介绍 CapStudio、致谢和开源许可。';

  @override
  String get aboutAppThanks => '特别感谢使 CapStudio 成为可能的开源项目：';

  @override
  String get btnViewAllLicenses => '查看所有依赖包的开源许可';
}
