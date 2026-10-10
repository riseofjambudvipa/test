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

  @override
  String get exportBurnIn => '烧录字幕视频导出';

  @override
  String get exportTimecodeFormats => '时间码字幕格式';

  @override
  String get exportWebEnabled => '客户端视频导出已启用。渲染将在您的浏览器中本地运行。';

  @override
  String get exportWebCaptionOnly =>
      'Web 导出目前仅包含字幕——表情符号和音效尚未烧录到视频中。请使用桌面端或移动端应用导出以获得完整效果。';

  @override
  String get exportOutputName => '输出视频名称';

  @override
  String get exportMode => '导出模式';

  @override
  String get exportModeFast => '快速（原生 FFmpeg）';

  @override
  String get exportModeFastUnsupported => '快速（原生 FFmpeg）⚠️ 不支持';

  @override
  String get exportModeSlow => '慢速（1:1 预览渲染）';

  @override
  String get exportTargetFps => '目标帧率';

  @override
  String get exportFps24 => '24 FPS（电影）';

  @override
  String get exportFps25 => '25 FPS（PAL）';

  @override
  String get exportFps30 => '30 FPS（标准）';

  @override
  String get exportFps50 => '50 FPS';

  @override
  String get exportFps60 => '60 FPS（流畅）';

  @override
  String get exportFastUnsupported =>
      '此设备不支持快速模式，因为系统 FFmpeg 版本缺少字幕渲染滤镜（libass）。将改用慢速模式。';

  @override
  String get exportSlowInfo => '逐帧捕获预览中显示的画面。这能保证像素级精确的字幕，但渲染速度较慢。';

  @override
  String get exportDestDirectory => '目标文件夹';

  @override
  String get exportDestBrowser => '浏览器下载位置';

  @override
  String get exportDestAndroid => '下载文件夹（/storage/emulated/0/Download）';

  @override
  String get exportDestIos => '应用文稿（导出后显示共享面板）';

  @override
  String get exportChooseFolder => '选择输出文件夹';

  @override
  String get exportStartMp4 => '开始导出 MP4';

  @override
  String get exportSrtTitle => 'SubRip 字幕（.srt）';

  @override
  String get exportSrtDesc => '带时间码的通用标准格式。兼容 YouTube、VLC 和 Premiere Pro。';

  @override
  String get exportVttTitle => 'WebVTT 字幕（.vtt）';

  @override
  String get exportVttDesc => '面向 Web 优化的字幕格式，广泛用于 HTML5 播放器和在线流媒体。';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha（.ass）';

  @override
  String get exportAssDesc => '专业格式，可嵌入字体大小、样式、边距和内联高亮。';

  @override
  String get exportTxtTitle => '纯文本转写（.txt）';

  @override
  String get exportTxtDesc => '带时间戳前缀标记的逐行转写文本。';

  @override
  String exportSuccess(String type) {
    return '$type 导出成功！';
  }

  @override
  String get exportNoLocation => '未选择保存位置。请选择文件路径。';

  @override
  String get exportNoLocationCancelled => '未选择保存位置。导出已取消。';

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get exportCopySrtTooltip => '复制 SRT 到剪贴板';

  @override
  String get exportCopiedSrt => 'SRT 已复制到剪贴板！';

  @override
  String exportCopyFailedSrt(String error) {
    return '复制 SRT 失败：$error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return '导出 $type 字幕';
  }

  @override
  String get exportVideoDialogTitle => '导出 MP4 视频';

  @override
  String get ffmpegRequiredTitle => '需要 FFmpeg';

  @override
  String get ffmpegRequiredBody =>
      '要将字幕烧录到视频文件中，需要本地安装 FFmpeg。\n\n请在设置中配置 FFmpeg 路径。';

  @override
  String get okLabel => '确定';

  @override
  String get exportWebTitle => '正在导出视频（客户端）';

  @override
  String exportWebSuccess(String fileName) {
    return '视频已成功导出为 $fileName！';
  }

  @override
  String exportWebFailed(String error) {
    return '渲染失败：$error';
  }

  @override
  String get viralShortsTitle => '爆款短视频工作室';

  @override
  String get viralShortsSubtitle => '9:16竖屏重构、静音跳剪与AI爆点挂钩检测';

  @override
  String get viralReframeTitle => '1. 竖屏 9:16 画幅重构';

  @override
  String get viralSilenceTitle => '2. 静音消除（跳剪）';

  @override
  String get viralHooksTitle => '3. AI 爆款吸睛点检测';

  @override
  String get btnFindViralMoments => '寻找爆款片段';

  @override
  String get btnScanSilences => '扫描静音片段';

  @override
  String get btnApplyJumpCuts => '应用跳剪';

  @override
  String get editorTabShorts => '短视频';

  @override
  String get editorTabClips => '片段';

  @override
  String get captionList => '字幕列表';

  @override
  String get uncertainLabel => '低置信度 (<40%)';

  @override
  String get mediumConfidenceLabel => '中等置信度 (40-60%)';

  @override
  String get jumpToUncertain => '跳转到下一个不确定词';

  @override
  String get noUncertainWords => '未发现不确定词语。';

  @override
  String get findAndReplace => '查找与替换';

  @override
  String get addWordTitle => '添加词语';

  @override
  String get editWordTitle => '编辑词语';

  @override
  String get wordTextLabel => '词语文本';

  @override
  String get startTimeLabel => '开始时间 (秒)';

  @override
  String get endTimeLabel => '结束时间 (秒)';

  @override
  String get splitChunk => '拆分字幕块';

  @override
  String get insertLineAfter => '在后方插入行';

  @override
  String get duplicateLine => '复制行';

  @override
  String get deleteLine => '删除行';

  @override
  String get chooseSfxTitle => '选择音效';

  @override
  String get searchSfxPlaceholder => '搜索音效...';

  @override
  String get noSfxFound => '未找到音效';

  @override
  String get emojiSearch => '表情搜索';

  @override
  String get noEmojisFound => '未找到表情。';

  @override
  String get mySavedPresets => '我的预设';

  @override
  String get btnImport => '导入';

  @override
  String get btnExportCaps => '导出';

  @override
  String get btnSaveCurrent => '保存当前样式';

  @override
  String get resetToDefault => '恢复默认';

  @override
  String get resetConfirmBody => '这将把所有字幕样式重置为默认值。此操作无法撤销。';

  @override
  String get btnReset => '重置';

  @override
  String get wordHighlightBox => '单词高亮底色块';

  @override
  String get wordHighlightBoxDesc => '当前发音词语背后的彩色胶囊背景';

  @override
  String get maxWordsPerChunk => '每块字幕最大词数';

  @override
  String get maxCharsPerLine => '每行字幕最大字符数';

  @override
  String get fontSettings => '字体设置';

  @override
  String get colorSettings => '颜色设置';

  @override
  String get borderSettings => '描边与阴影设置';

  @override
  String get speechToTextTitle => '语音转文字转录';

  @override
  String get speechToTextDesc => '重新运行本地语音转文字转录。任何手动编辑或时间偏移都将被替换。';

  @override
  String get useLocalAi => '使用本地 AI 转录';

  @override
  String get runOnDeviceDesc => '直接在此设备上运行语音转文字';

  @override
  String get offlineDemoModeActive => '离线演示模式已激活。网页端不支持本地 Whisper AI 转录。';

  @override
  String get demoModeNote => '演示模式可立即生成高保真的转录标记。无需任何配置即可完美测试样式、模板和时间轴操作。';

  @override
  String get transcriptionQuality => '转录质量';

  @override
  String get advancedSettings => '高级设置';

  @override
  String get cpuThreadsLabel => 'CPU 线程数';

  @override
  String get vadSensitivity => 'VAD 灵敏度';

  @override
  String get translateToEnglish => '将字幕翻译为英语';

  @override
  String get startTranscriptionBtn => '开始转录';

  @override
  String get hardwareLocked => '硬件已锁定';

  @override
  String get btnDownload => '下载';

  @override
  String get welcomeTitle => '欢迎使用 CapStudio';

  @override
  String get welcomeSubtitle => '高精度字幕与爆款短视频，100% 本地离线运行。';

  @override
  String get setupAssetDirTitle => '选择资源目录';

  @override
  String get setupAssetDirDesc => '选择用于存储模型、字体和表情包的目录。';

  @override
  String get downloadPacksTitle => '下载内容包 (可选)';

  @override
  String get downloadPacksDesc => '适用于视频项目的可选字体与音效。';

  @override
  String get setupCompleteTitle => '设置完成';

  @override
  String get setupCompleteDesc => '您已准备好制作令人惊艳的字幕视频。';

  @override
  String get btnGetStarted => '开始使用';

  @override
  String get btnNext => '下一步';

  @override
  String get btnSkip => '跳过';

  @override
  String get onboardingFeaturePrivacy => '100% 隐私保护';

  @override
  String get onboardingFeaturePrivacyDesc => '您的文件绝不离开本地设备。所有 AI 模型完全在本地运行。';

  @override
  String get onboardingFeatureGpu => 'GPU 硬件加速播放';

  @override
  String get onboardingFeatureGpuDesc => '利用硬件解码实现高性能视频剪辑。';

  @override
  String get onboardingFeatureAssets => '离线本地资源包';

  @override
  String get onboardingFeatureAssetsDesc => '一次下载丰富的表情包，随时随地完全离线使用。';

  @override
  String get onboardingReadyTitle => '一切就绪，开始创作！';

  @override
  String get onboardingConfigDetails => '配置详情：';

  @override
  String get btnLaunchCapStudio => '启动 CapStudio';

  @override
  String get assetVerificationFailed => '资源验证失败。请确保资源已完整下载。';

  @override
  String get assetsFolderNotFound => '未找到资源文件夹';

  @override
  String get assetsFolderNotFoundDesc =>
      'CapStudio 无法在配置的位置找到资源文件夹。如果该文件夹位于外部驱动器上，请连接该驱动器。';

  @override
  String get expectedPathLabel => '预期路径：';

  @override
  String get browseNewLocation => '浏览新位置';

  @override
  String get resetToDefaultPath => '重置为默认路径';

  @override
  String get retryVerification => '重新验证';

  @override
  String get storagePathFolder => '存储路径文件夹';

  @override
  String get tipWindowsDrive => '提示：如果 C 盘空间较小，请选择 D 盘或 E 盘以获取更多存储空间。';

  @override
  String get tipGeneralDrive => '提示：如果系统盘已满，您可以选择外部驱动器路径。';

  @override
  String get confirmLocation => '确认位置';

  @override
  String get requiredBadge => '必选';

  @override
  String get emojiPacksHeader => '表情包';

  @override
  String get fontPacksHeader => '字体包';

  @override
  String get connectCliTitle => '连接本地 CLI 工具';

  @override
  String get connectCliDesc =>
      'CapStudio 需要 whisper.cpp 和 FFmpeg 二进制文件来执行本地转录和视频导出。';

  @override
  String get skipSetup => '暂时跳过设置';

  @override
  String get btnValidate => '校验';

  @override
  String get autoDetectAndValidate => '自动检测并校验';

  @override
  String get whisperCliPathLabel => 'Whisper CLI 可执行文件路径';

  @override
  String get ffmpegCliPathLabel => 'FFmpeg CLI 可执行文件路径';

  @override
  String get newProject => '新建项目';

  @override
  String get searchProjects => '搜索项目...';

  @override
  String get filterAll => '全部';

  @override
  String get sortByRecent => '最近使用';

  @override
  String get sortByDuration => '时长';

  @override
  String get noMatchingProjects => '没有匹配您搜索条件的项目';

  @override
  String get btnEdit => '编辑';

  @override
  String get btnDuplicate => '创建副本';

  @override
  String get tooltipEdit => '编辑';

  @override
  String get tooltipRename => '重命名';

  @override
  String get tooltipDuplicate => '创建副本';

  @override
  String get tooltipDelete => '删除';

  @override
  String get tooltipTheme => '主题';

  @override
  String get tooltipSettings => '设置';

  @override
  String get selectDemoFormat => '选择演示格式';

  @override
  String get selectDemoDesc => '选择版式以即时预览 CapStudio 的高保真字幕引擎、实时逐字动画和音频波形。';

  @override
  String get landscapeDemo => '横版演示';

  @override
  String get landscapeDemoDesc => '适合 YouTube、桌面端及演示文稿。';

  @override
  String get portraitDemo => '竖版演示';

  @override
  String get portraitDemoDesc => '适合 TikTok、Shorts、Reels 及移动端设备。';

  @override
  String get format16x9 => '16:9 格式';

  @override
  String get format9x16 => '9:16 格式';

  @override
  String get dropVideoHere => '将视频拖放到此处';

  @override
  String get dropVideoSupported => '支持 MP4、MOV、AVI 等格式';

  @override
  String get statusLocalOffline => '本地离线';

  @override
  String get speechModelTitle => '语音识别模型';

  @override
  String get hardwareUpgradesTitle => '硬件性能升级';

  @override
  String get showAdvancedPaths => '显示高级路径配置';

  @override
  String get hideAdvancedPaths => '隐藏高级路径配置';

  @override
  String get autoDownload => '自动下载';

  @override
  String get gpuAcceleratedTranscription => 'GPU 加速转录 (CUDA)';

  @override
  String get gpuRequiresNvidia => '需要兼容 CUDA 的 NVIDIA GPU';

  @override
  String get gpuExportEncoder => 'GPU 导出编码器';

  @override
  String get gpuExportEncoderDesc => 'MP4 视频导出的硬件加速';

  @override
  String get defaultLanguage => '默认语言';

  @override
  String get vadTitle => '语音活动检测 (VAD)';

  @override
  String get vadDesc => '处理过程中跳过静音片段';

  @override
  String get vadThreshold => 'VAD 阈值';

  @override
  String get autoSaveTitle => '自动保存';

  @override
  String get autoSaveDesc => '每 3 秒自动将项目更改保存到数据库';

  @override
  String get defaultOutputsTitle => '默认输出';

  @override
  String get defaultExportFolder => '默认导出文件夹';

  @override
  String get alwaysAskExportPath => '每次导出时询问路径';

  @override
  String get alwaysAskExportPathDesc => '每次导出时弹出路径选择窗口 (桌面版)';

  @override
  String get performanceTitle => '性能';

  @override
  String get exportCpuThreads => '导出 CPU 线程数';

  @override
  String get exportCpuThreadsDesc => '用于渲染的处理线程数 (根据设备安全自动调整)';

  @override
  String get aboutAppSubtitle => '100% 离线、隐私优先的 AI 字幕制作工作室';

  @override
  String get openSourceLicenses => '开源许可协议';

  @override
  String get openSourceComplianceDesc =>
      'CapStudio 依赖许多其他开源库。为遵守应用商店的法律合规要求，下方汇总了所有 Dart 软件包、传递依赖项及其完整许可文本的清单。';

  @override
  String get visitWebsite => '访问网站';

  @override
  String get btnContinue => '继续';

  @override
  String get btnBack => '返回';

  @override
  String get editTiming => '调整时间';

  @override
  String get wordSettingsTitle => '词语设置';

  @override
  String get emojiSettingsTitle => '表情符号设置';

  @override
  String get changeEmojiTooltip => '更改表情';

  @override
  String get searchEmojisHint => '搜索表情...';

  @override
  String emojiPosX(String offset) {
    return '表情位置 (X轴偏移: ${offset}px)';
  }

  @override
  String emojiPosY(String offset) {
    return '表情位置 (Y轴偏移: ${offset}px)';
  }

  @override
  String emojiScale(String scale) {
    return '表情缩放 (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return '动画速度 (${speed}x)';
  }

  @override
  String get emojiStylePack => '表情风格 / 图集';

  @override
  String get selectStylePackTooltip => '选择风格图集';

  @override
  String get selectEmojiTitle => '选择表情';

  @override
  String get stylePackLabel => '风格图集';

  @override
  String get searchHint => '搜索...';

  @override
  String get btnCreateProject => '创建项目';

  @override
  String get btnChooseFile => '选择文件';

  @override
  String get selectSubtitleFile => '选择字幕文件';

  @override
  String get selectTranscriptionQuality => '选择转录质量';

  @override
  String get translateToEnglishDesc => '将外语语音直接转换为英文字幕';

  @override
  String get hardwareSettings => '硬件与性能设置';

  @override
  String get styleTemplatesHeader => '样式模板';

  @override
  String get resetToDefaultStyle => '重置为默认样式';

  @override
  String get resetStylingTitle => '重置样式？';

  @override
  String get resetStylingDesc => '这将把所有字幕样式重置为默认设置。此操作无法撤销。';

  @override
  String get sizeAndPosition => '尺寸与位置';

  @override
  String get verticalYPos => '垂直 Y 轴位置 (%)';

  @override
  String get fontConfigHeader => '字体配置';

  @override
  String get fontFamilyLabel => '字体名称';

  @override
  String get btnImportCustomFont => '导入自定义字体 (.ttf / .otf)';

  @override
  String get fontWeightLabel => '字重';

  @override
  String get textCaseLabel => '字母大小写';

  @override
  String get fontSizeLabel => '字体大小';

  @override
  String get letterSpacingLabel => '字符间距';

  @override
  String get lineHeightLabel => '行高';

  @override
  String get onboardingAppTagline => '100% 离线本地 AI 字幕编辑器';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => '演示模式 (模拟)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault => '系统 PATH 默认值';

  @override
  String get configLabelAssetsLocation => '资源存放位置';

  @override
  String get filePickerAssetsDialogTitle => '选择 CapStudio 资源文件夹';

  @override
  String errorSelectFolderFailed(String error) {
    return '选择文件夹失败：$error';
  }

  @override
  String errorResetFailed(String error) {
    return '重置失败：$error';
  }

  @override
  String errorVerificationFailed(String error) {
    return '验证失败：$error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return '仍然无法在以下位置找到资源文件夹：$path';
  }

  @override
  String get dbRecoveredTitle => '数据库已自动恢复';

  @override
  String dbRecoveredBody(String backupPath) {
    return '检测到数据库架构不匹配或损坏。数据库已重置，您之前的数据已备份至：\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return '加载演示视频失败：$error';
  }

  @override
  String importProgressPercent(int percent) {
    return '已完成 $percent%';
  }

  @override
  String get errorInvalidDropFileFormat => '无效的文件格式。请拖放视频文件。';

  @override
  String get findTextLabel => '查找文本';

  @override
  String get replaceWithLabel => '替换为';

  @override
  String findReplaceSuccessCount(int count) {
    return '已替换 $count 处！';
  }

  @override
  String get btnReplaceAll => '全部替换';

  @override
  String errorVideoFileNotFound(String path) {
    return '未找到视频文件：\n$path\n请重新关联该视频文件。';
  }

  @override
  String get errorTranscriptionFailed => '转录失败。请重试。';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return '当前使用：$quality ($model)';
  }

  @override
  String get badgeRecommended => '推荐';

  @override
  String get languageLabel => '语言';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return '警告：所选模型 ($model) 仅支持英语。以 \"$language\" 进行转录将失败或生成英文字幕。请选择多语言模型 (如 Tiny 或 Base)。';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      '提示：对于混合语言，不建议使用自动检测。明确选择所说的语言将提供更准确的字幕。';

  @override
  String get detectedHardwareLabel => '检测到的系统硬件：';

  @override
  String hardwareRamSize(String ramGB) {
    return '内存大小：$ramGB GB';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'CPU 逻辑核心数：$cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'GPU 设备：$gpu';
  }

  @override
  String get hardwareDetecting => '正在检测硬件配置...';

  @override
  String get btnStartReTranscribe => '开始重新转录';

  @override
  String get btnImportSrtVtt => '导入 SRT/VTT 文件';

  @override
  String importedSubtitleWords(int count) {
    return '已从字幕文件中导入 $count 个词语。';
  }

  @override
  String get errorImportSubtitleFailed => '导入字幕文件失败。请检查文件格式。';

  @override
  String get noProjectLoaded => '未加载任何项目';

  @override
  String get badge916Vertical => '9:16 竖版';

  @override
  String get badge169Landscape => '16:9 横版';

  @override
  String get reframeTargetCanvas =>
      '目标画布：1080 × 1920 (TikTok、YouTube Shorts、Instagram Reels)';

  @override
  String get reframeModeLabel => '画面重构模式：';

  @override
  String get reframeModeBlurPillarbox => '模糊填充边栏 (推荐)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      '在背景中缩放并模糊视频以填满 9:16 画布，同时保持居中画面的清晰度。';

  @override
  String get reframeModeCenterCrop => '智能中心裁剪';

  @override
  String get reframeModeCenterCropDesc => '通过裁剪左右两侧边缘填满整个 9:16 画面。';

  @override
  String get reframeModeSplitScreen => '分屏 / 双层画面';

  @override
  String get reframeModeSplitScreenDesc => '垂直堆叠两个视频窗口 (非常适合反应视频和播客对话)。';

  @override
  String get btnResetTo169 => '当前为 9:16 (重置为 16:9)';

  @override
  String get btnSetCanvas916 => '将项目画布设为 9:16';

  @override
  String get silenceRemovalDesc => '自动剪掉停顿与呼吸空隙，最大程度提升视频留存率。';

  @override
  String get silenceAggressivenessLabel => '剪辑激进度：';

  @override
  String silenceNoiseGateLabel(int db) {
    return '静音噪声门限：$db dB';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return '最小停顿时间：$duration秒';
  }

  @override
  String get btnScanning => '正在扫描...';

  @override
  String silenceNoneFound(String duration) {
    return '未发现超过 $duration 秒的静音片段。';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return '发现 $count 处静音 (节省了 $totalSecs 秒无声时间)！';
  }

  @override
  String errorScanningAudio(String error) {
    return '扫描音频时出错：$error';
  }

  @override
  String jumpCutsApplied(int count) {
    return '已在项目时间轴上应用 $count 处跳剪！';
  }

  @override
  String get viralHooksDesc =>
      '扫描转录词语以检测 80+ 种爆款钩子、语速 (120-170 WPM)、提问、情绪密度及精彩片段边界。';

  @override
  String get btnAnalyzingTranscript => '正在分析转录内容...';

  @override
  String get selectAllLabel => '全选';

  @override
  String selectedCountOf(int selected, int total) {
    return '已选择 $total 项中的 $selected 项';
  }

  @override
  String get btnSelectClipsToBatchExport => '选择要批量导出的片段';

  @override
  String btnBatchExportCount(int count) {
    return '批量导出 $count 个片段';
  }

  @override
  String get viralNoClipsDetected => '在此视频时长范围内未检测到高分爆款片段。';

  @override
  String get badgeCleanCut => '无缝剪切';

  @override
  String get badgeFirst5s => '黄金前5秒';

  @override
  String get btnPreview => '预览';

  @override
  String get btnTrim => '裁剪';

  @override
  String get tooltipForkAs916 => '派生为新的 9:16 短视频项目';

  @override
  String wpmLabelOk(int wpm) {
    return '$wpm WPM ✓';
  }

  @override
  String wpmLabelFast(int wpm) {
    return '$wpm WPM 偏快';
  }

  @override
  String wpmLabelSlow(int wpm) {
    return '$wpm WPM 偏慢';
  }

  @override
  String hookScoreLabel(int score) {
    return '吸睛度 $score/40';
  }

  @override
  String energyScoreLabel(int score) {
    return '感染力 $score/20';
  }

  @override
  String get filePickerClipsFolderTitle => '选择保存片段的文件夹';

  @override
  String get errorChooseOutputFolderFirst => '请先选择输出文件夹。';

  @override
  String batchExportSheetTitle(int count) {
    return '批量导出 $count 个片段';
  }

  @override
  String get tapToChooseOutputFolder => '点击选择输出文件夹…';

  @override
  String get burnCaptionsOnClipsLabel => '将动态字幕烧录到片段中';

  @override
  String get burnCaptionsOnClipsDesc => '烧录与片段音频同步的样式化动态字幕';

  @override
  String exportCancelledProgress(int done, int total) {
    return '导出已取消。已完成 $done/$total。';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return '已导出 $done/$total · 失败 $failed';
  }

  @override
  String get btnExporting => '正在导出…';

  @override
  String get btnExportComplete => '导出完成 ✓';

  @override
  String get btnStartExport => '开始导出';

  @override
  String exportClipSavedAt(String path) {
    return '✓ 已保存：$path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return '项目已裁剪至爆款片段 #$rank ($start - $end)！';
  }

  @override
  String shortProjectCreated(String name) {
    return '已创建 9:16 短视频项目：\"$name\"';
  }

  @override
  String get btnOpen => '打开';

  @override
  String errorCreateShortProjectFailed(String error) {
    return '创建短视频项目失败：$error';
  }

  @override
  String get autoDetect => '自动检测';

  @override
  String presetSaved(String name) {
    return '样式预设 \"$name\" 保存成功！';
  }

  @override
  String get presetDeleted => '预设删除成功。';

  @override
  String get presetExported => '样式预设导出成功！';

  @override
  String errorPresetExportFailed(String error) {
    return '导出预设失败：$error';
  }

  @override
  String get presetImported => '样式预设导入成功！';

  @override
  String errorPresetImportFailed(String error) {
    return '导入预设失败：$error';
  }

  @override
  String get selectFontFileDialogTitle => '选择 TTF 或 OTF 字体文件';

  @override
  String get fontWeightThin => '极细';

  @override
  String get fontWeightExtraLight => '特细';

  @override
  String get fontWeightLight => '细体';

  @override
  String get fontWeightNormal => '常规';

  @override
  String get fontWeightMedium => '中等';

  @override
  String get fontWeightSemiBold => '半粗';

  @override
  String get fontWeightBold => '粗体';

  @override
  String get fontWeightExtraBold => '特粗';

  @override
  String get fontWeightBlack => '黑体/极粗';

  @override
  String get fontCaseNormal => '正常';

  @override
  String get fontCaseUppercase => '大写';

  @override
  String get fontCaseCapitalize => '首字母大写';

  @override
  String get strokeStyleThickOutline => '粗描边';

  @override
  String get strokeStyleNoneFlat => '无 (扁平)';

  @override
  String get shadowStyleSoft => '柔和阴影';

  @override
  String get shadowStyleNone => '无';

  @override
  String get animStyleActivePop => '发音跳动 (Pop)';

  @override
  String get animStyleActiveBounce => '发音弹跳 (Bounce Jump)';

  @override
  String get animStyleKineticTilt => '动态倾斜弹动 (Kinetic Tilt)';

  @override
  String get animStyleGlowPulse => '发光脉冲 (Glow Pulse)';

  @override
  String get animStyleWordReveal => '逐字显现 (Word Reveal)';

  @override
  String get animStyleNoneStatic => '无 (静态)';

  @override
  String fontImportedSuccess(String name) {
    return '已成功导入并应用自定义字体：\"$name\"';
  }

  @override
  String get errorFontImportFailed => '加载字体文件失败。数据无效。';

  @override
  String get invalidTimingError =>
      '起止时间无效。开始时间必须 >= 0，且结束时间必须 >= 开始时间且 <= 视频总时长。';

  @override
  String get projectSavedSuccess => '项目保存成功。';

  @override
  String wordDeletedSuccess(String text) {
    return '已删除词语：\"$text\"';
  }

  @override
  String get splitClip => '拆分片段';

  @override
  String get removeClip => '移除片段';

  @override
  String get resetToOriginal => '恢复原始内容';

  @override
  String splitTimelineAt(String time) {
    return '在 $time 秒处拆分时间轴。';
  }

  @override
  String get splitTimelineError => '播放指针必须位于活动区域内才能进行拆分。';

  @override
  String get exclusionToggled => '已切换播放指针所在片段的排除状态。';

  @override
  String get splitsReset => '重置所有时间轴拆分与排除项。';

  @override
  String get shareVideo => '分享视频';

  @override
  String get openOutputFolder => '打开输出文件夹';

  @override
  String get errorLogCopied => '错误日志已复制到剪贴板。';

  @override
  String get diagnosticsExported => '已在分享面板中打开经过筛选的诊断报告。';

  @override
  String errorDiagnosticsFailed(String error) {
    return '导出诊断报告失败：$error';
  }

  @override
  String logLineCopied(String message) {
    return '已复制日志行到剪贴板：\"$message\"';
  }

  @override
  String commandCopied(String command) {
    return '已复制：\"$command\"';
  }

  @override
  String get settingsRestored => '已恢复默认设置。';

  @override
  String get gpuEncoderNoneCpu => '无 (仅 CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => '下载 VC++ 可再发行组件包';

  @override
  String errorDownloadToolFailed(String error) {
    return '下载工具失败：$error';
  }

  @override
  String get errorFolderNotAccessible => '所选文件夹不存在或无法访问。';

  @override
  String modelDeleted(String name) {
    return '已删除模型：$name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return '删除模型失败：$error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return '下载模型 $name 失败：$error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return '无法自动打开文件夹。路径：$path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return '下载内容包失败：$error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return '下载内容包 $name 失败：$error';
  }

  @override
  String get stickersIndexRefreshed => '自定义贴纸索引已成功刷新！';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return '更改资源文件夹失败：$error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return '设置资源文件夹失败：$error';
  }

  @override
  String get warningNoAvx => '检测到缺少 AVX 指令集支持！正在下载兼容版 whisper-cli (无 AVX)...';

  @override
  String get errorAutoDetectWhisper => '未能自动检测到 whisper-cli。请手动浏览选择。';

  @override
  String get errorAutoDetectFfmpeg => '未能自动检测到 ffmpeg。请手动浏览选择。';

  @override
  String errorToolDownloadFailed(String error) {
    return '下载工具失败：$error';
  }

  @override
  String get returnToDashboard => '返回仪表盘';

  @override
  String errorImportVideoFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get videoRelinkedSuccess => '视频已成功重新关联！';

  @override
  String get errorRelinkVideoFailed => '重新关联视频失败。';

  @override
  String get retranscriptionSuccess => '重新转录成功！';

  @override
  String get retranscriptionFailed => '重新转录失败。';
}
