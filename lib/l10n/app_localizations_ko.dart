// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'CapStudio';

  @override
  String get dashboardTitle => '내 프로젝트';

  @override
  String get dashboardSubtitle => '오프라인 AI 자막 제작 스튜디오';

  @override
  String get importVideo => '비디오 가져오기';

  @override
  String get dragDropText => '여기에 비디오 파일을 끌어서 놓으세요';

  @override
  String get clickBrowse => '또는 클릭하여 로컬 파일 탐색';

  @override
  String get demoMode => '데모 모드';

  @override
  String get demoModeDesc => '스타일 및 편집기 기능을 테스트하기 위해 데모 프로젝트를 로드합니다.';

  @override
  String get warningAssets => '리소스 폴더 복구 필요';

  @override
  String get warningAssetsDesc =>
      '앱 지원 폴더에서 기본 제공 리소스를 찾을 수 없습니다. 여기를 더블 클릭하여 복구하거나 리소스 디렉토리를 변경하세요.';

  @override
  String get deleteProjectTitle => '프로젝트 삭제';

  @override
  String deleteProjectConfirm(String projectName) {
    return '\"$projectName\"을(를) 영구히 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.';
  }

  @override
  String get renameProjectTitle => '프로젝트 이름 변경';

  @override
  String get projectNameLabel => '프로젝트 이름';

  @override
  String get btnCancel => '취소';

  @override
  String get btnDelete => '삭제';

  @override
  String get btnRename => '이름 변경';

  @override
  String get btnSave => '저장';

  @override
  String get btnConfirm => '확인';

  @override
  String get btnExport => '내보내기';

  @override
  String get btnUndo => '실행 취소';

  @override
  String get btnRedo => '다시 실행';

  @override
  String get statusDraft => '초안';

  @override
  String get statusCompleted => '완료됨';

  @override
  String get createdLabel => '생성일:';

  @override
  String get durationLabel => '재생 시간:';

  @override
  String get statusLabel => '상태:';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsGeneral => '일반 설정';

  @override
  String get settingsTheme => '앱 테마';

  @override
  String get themeSystem => '시스템 기본값';

  @override
  String get themeLight => '라이트 모드';

  @override
  String get themeDark => '다크 모드';

  @override
  String get settingsLanguage => 'UI 언어';

  @override
  String get settingsTranscription => '음성 인식 및 전사 설정';

  @override
  String get settingsWhisperModel => 'Whisper 모델';

  @override
  String get settingsWhisperModelDesc =>
      '텍스트 변환을 위해 사용할 모델을 선택합니다. 작을수록 빠르고 클수록 정확합니다.';

  @override
  String get settingsTranscribeLang => '전사 언어';

  @override
  String get settingsAutoDetect => '언어 자동 감지';

  @override
  String get settingsGPU => 'GPU 하드웨어 가속 (CUDA)';

  @override
  String get settingsVAD => 'VAD 음성 감지 임계값';

  @override
  String get settingsExport => '내보내기 설정';

  @override
  String get settingsExportDest => '기본 출력 디렉토리';

  @override
  String get settingsBrowse => '찾아보기';

  @override
  String get settingsEmojiPacks => '이모지 및 스타일 팩';

  @override
  String get settingsEmojiPacksDesc => '이모지 렌더링 스타일 및 활성 자막 리소스를 설정합니다.';

  @override
  String get settingsEmojiSearchLang => '이모지 검색 언어';

  @override
  String get settingsBtnManagePacks => '이모지 팩 관리';

  @override
  String get systemTitle => '시스템 정보';

  @override
  String get systemVersion => '버전';

  @override
  String get systemReset => '기본값으로 초기화';

  @override
  String get editorTabCaptions => '자막 편집';

  @override
  String get editorTabStyles => '스타일 설정';

  @override
  String get editorTabTrim => '구간 자르기';

  @override
  String get editorTabAudio => '오디오 효과';

  @override
  String get editorTabTranscription => '자막 재변환';

  @override
  String get editorTabShortcuts => '단축키';

  @override
  String get editorTabDebug => '디버그 패널';

  @override
  String get editorHeaderBack => '뒤로';

  @override
  String get editorKeyboardShortcuts => '키보드 단축키 안내';

  @override
  String get dialogAnalyzing => '비디오 분석 중...';

  @override
  String get dialogTranscribing => '음성 자막 변환 중...';

  @override
  String get dialogExtracting => '오디오 추출 중...';

  @override
  String get dialogWait => '시간이 다소 걸릴 수 있습니다. 잠시만 기다려 주세요.';

  @override
  String get dialogError => '오류';

  @override
  String get dialogImportFailed => '비디오를 가져오지 못했습니다.';

  @override
  String get noProjects => '생성된 프로젝트가 없습니다';

  @override
  String get aboutApp => 'CapStudio 정보';

  @override
  String get aboutAppDesc => 'CapStudio 소개, 크레딧 및 오픈 소스 라이선스 정보입니다.';

  @override
  String get aboutAppThanks => 'CapStudio를 가능하게 해준 오픈 소스 프로젝트에 특별히 감사드립니다:';

  @override
  String get btnViewAllLicenses => '모든 패키지 라이선스 보기';

  @override
  String get exportBurnIn => '자막을 박아 넣은 동영상 내보내기';

  @override
  String get exportTimecodeFormats => '타임코드 자막 형식';

  @override
  String get exportWebEnabled =>
      '클라이언트 측 동영상 내보내기가 활성화되었습니다. 렌더링은 브라우저에서 로컬로 실행됩니다.';

  @override
  String get exportWebCaptionOnly =>
      '웹 내보내기에는 현재 자막만 포함됩니다. 이모지와 음향 효과는 아직 동영상에 박아 넣을 수 없습니다. 전체 결과를 보려면 데스크톱 또는 모바일 앱에서 내보내세요.';

  @override
  String get exportOutputName => '출력 동영상 이름';

  @override
  String get exportMode => '내보내기 모드';

  @override
  String get exportModeFast => '빠르게 (네이티브 FFmpeg)';

  @override
  String get exportModeFastUnsupported => '빠르게 (네이티브 FFmpeg) ⚠️ 지원되지 않음';

  @override
  String get exportModeSlow => '느리게 (1:1 미리보기 렌더링)';

  @override
  String get exportTargetFps => '대상 FPS';

  @override
  String get exportFps24 => '24 FPS (영화)';

  @override
  String get exportFps25 => '25 FPS (PAL)';

  @override
  String get exportFps30 => '30 FPS (표준)';

  @override
  String get exportFps50 => '50 FPS';

  @override
  String get exportFps60 => '60 FPS (부드럽게)';

  @override
  String get exportFastUnsupported =>
      '시스템 FFmpeg 빌드에 자막 렌더링 필터(libass)가 없어 이 기기에서는 빠른 모드를 사용할 수 없습니다. 대신 느린 모드가 사용됩니다.';

  @override
  String get exportSlowInfo =>
      '미리보기에 표시된 그대로 각 프레임을 캡처합니다. 픽셀 단위로 완벽한 자막을 보장하지만 렌더링이 더 느립니다.';

  @override
  String get exportDestDirectory => '대상 폴더';

  @override
  String get exportDestBrowser => '브라우저 다운로드 위치';

  @override
  String get exportDestAndroid => '다운로드 폴더 (/storage/emulated/0/Download)';

  @override
  String get exportDestIos => '앱 문서 (내보내기 후 공유 시트)';

  @override
  String get exportChooseFolder => '출력 폴더 선택';

  @override
  String get exportStartMp4 => 'MP4 내보내기 시작';

  @override
  String get exportSrtTitle => 'SubRip 자막 (.srt)';

  @override
  String get exportSrtDesc =>
      '타임코드 기반의 범용 표준. YouTube, VLC, Premiere Pro와 호환됩니다.';

  @override
  String get exportVttTitle => 'WebVTT 자막 (.vtt)';

  @override
  String get exportVttDesc => 'HTML5 플레이어와 온라인 스트리밍에서 널리 사용되는 웹 최적화 자막 형식입니다.';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha (.ass)';

  @override
  String get exportAssDesc => '글꼴 크기, 스타일, 여백, 인라인 하이라이트를 포함하는 전문가용 형식입니다.';

  @override
  String get exportTxtTitle => '일반 텍스트 대본 (.txt)';

  @override
  String get exportTxtDesc => '타임스탬프 접두어 표시가 포함된 줄 단위 대본입니다.';

  @override
  String exportSuccess(String type) {
    return '$type을(를) 성공적으로 내보냈습니다!';
  }

  @override
  String get exportNoLocation => '저장 위치를 선택하지 않았습니다. 파일 경로를 선택해 주세요.';

  @override
  String get exportNoLocationCancelled => '저장 위치를 선택하지 않았습니다. 내보내기가 취소되었습니다.';

  @override
  String exportFailed(String error) {
    return '내보내기에 실패했습니다: $error';
  }

  @override
  String get exportCopySrtTooltip => 'SRT를 클립보드에 복사';

  @override
  String get exportCopiedSrt => 'SRT가 클립보드에 복사되었습니다!';

  @override
  String exportCopyFailedSrt(String error) {
    return 'SRT 복사에 실패했습니다: $error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return '$type 자막 내보내기';
  }

  @override
  String get exportVideoDialogTitle => '동영상 MP4 내보내기';

  @override
  String get ffmpegRequiredTitle => 'FFmpeg 필요';

  @override
  String get ffmpegRequiredBody =>
      '동영상 파일에 자막을 박아 넣으려면 로컬 FFmpeg 설치가 필요합니다.\n\n설정에서 FFmpeg 경로를 구성해 주세요.';

  @override
  String get okLabel => '확인';

  @override
  String get exportWebTitle => '동영상 내보내는 중 (클라이언트 측)';

  @override
  String exportWebSuccess(String fileName) {
    return '$fileName(으)로 동영상을 성공적으로 내보냈습니다!';
  }

  @override
  String exportWebFailed(String error) {
    return '렌더링 실패: $error';
  }

  @override
  String get viralShortsTitle => '바이럴 쇼츠 스튜디오';

  @override
  String get viralShortsSubtitle => '9:16 세로 리프레임, 무음 점프컷 및 AI 후크 감지기';

  @override
  String get viralReframeTitle => '1. 9:16 세로 리프레임';

  @override
  String get viralSilenceTitle => '2. 무음 구간 제거 (점프컷)';

  @override
  String get viralHooksTitle => '3. AI 바이럴 후크 감지기';

  @override
  String get btnFindViralMoments => '바이럴 순간 찾기';

  @override
  String get btnScanSilences => '무음 구간 스캔';

  @override
  String get btnApplyJumpCuts => '점프컷 적용';

  @override
  String get editorTabShorts => '쇼츠';

  @override
  String get editorTabClips => '클립';

  @override
  String get captionList => '자막 목록';

  @override
  String get uncertainLabel => '불확실 (<40%)';

  @override
  String get mediumConfidenceLabel => '중간 신뢰도 (40-60%)';

  @override
  String get jumpToUncertain => '다음 불확실한 단어로 이동';

  @override
  String get noUncertainWords => '불확실한 단어를 찾을 수 없습니다.';

  @override
  String get findAndReplace => '찾기 및 바꾸기';

  @override
  String get addWordTitle => '단어 추가';

  @override
  String get editWordTitle => '단어 수정';

  @override
  String get wordTextLabel => '단어 텍스트';

  @override
  String get startTimeLabel => '시작 시간 (초)';

  @override
  String get endTimeLabel => '종료 시간 (초)';

  @override
  String get splitChunk => '구간 분할';

  @override
  String get insertLineAfter => '뒤에 줄 삽입';

  @override
  String get duplicateLine => '줄 복제';

  @override
  String get deleteLine => '줄 삭제';

  @override
  String get chooseSfxTitle => '효과음 선택';

  @override
  String get searchSfxPlaceholder => '효과음 검색...';

  @override
  String get noSfxFound => '효과음을 찾을 수 없습니다';

  @override
  String get emojiSearch => '이모지 검색';

  @override
  String get noEmojisFound => '이모지를 찾을 수 없습니다.';

  @override
  String get mySavedPresets => '저장된 프리셋';

  @override
  String get btnImport => '가져오기';

  @override
  String get btnExportCaps => '내보내기';

  @override
  String get btnSaveCurrent => '현재 설정 저장';

  @override
  String get resetToDefault => '기본값으로 재설정';

  @override
  String get resetConfirmBody => '모든 자막 스타일이 기본값으로 재설정됩니다. 이 작업은 취소할 수 없습니다.';

  @override
  String get btnReset => '재설정';

  @override
  String get wordHighlightBox => '단어 강조 박스';

  @override
  String get wordHighlightBoxDesc => '발음 중인 단어 뒤에 색상 캡슐 배경 표시';

  @override
  String get maxWordsPerChunk => '자막 구간당 최대 단어 수';

  @override
  String get maxCharsPerLine => '자막 한 줄당 최대 글자 수';

  @override
  String get fontSettings => '글꼴 설정';

  @override
  String get colorSettings => '색상 설정';

  @override
  String get borderSettings => '테두리 및 그림자 설정';

  @override
  String get speechToTextTitle => '음성-텍스트 변환 (전사)';

  @override
  String get speechToTextDesc =>
      '로컬 음성-텍스트 변환을 다시 실행합니다. 수동 편집 또는 타이밍 오프셋이 모두 교체됩니다.';

  @override
  String get useLocalAi => '로컬 AI 전사 사용';

  @override
  String get runOnDeviceDesc => '이 기기에서 직접 음성을 텍스트로 변환합니다';

  @override
  String get offlineDemoModeActive =>
      '오프라인 데모 모드가 활성화되어 있습니다. 웹에서는 로컬 Whisper AI 전사가 지원되지 않습니다.';

  @override
  String get demoModeNote =>
      '데모 모드는 사실적인 전사 토큰을 즉시 생성합니다. 설정 없이 스타일, 템플릿 및 타임라인 작업을 테스트하기에 완벽합니다.';

  @override
  String get transcriptionQuality => '전사 품질';

  @override
  String get advancedSettings => '고급 설정';

  @override
  String get cpuThreadsLabel => 'CPU 스레드';

  @override
  String get vadSensitivity => 'VAD 감도';

  @override
  String get translateToEnglish => '자막을 영어로 번역';

  @override
  String get startTranscriptionBtn => '전사 시작';

  @override
  String get hardwareLocked => '하드웨어 고정';

  @override
  String get btnDownload => '다운로드';

  @override
  String get welcomeTitle => 'CapStudio에 오신 것을 환영합니다';

  @override
  String get welcomeSubtitle => '고정밀 자막 및 바이럴 쇼츠 제작, 100% 오프라인 지원.';

  @override
  String get setupAssetDirTitle => '리소스 디렉터리 선택';

  @override
  String get setupAssetDirDesc => '모델, 글꼴 및 이모지 팩을 저장할 디렉터리를 선택하세요.';

  @override
  String get downloadPacksTitle => '콘텐츠 팩 다운로드 (선택 사항)';

  @override
  String get downloadPacksDesc => '동영상 프로젝트를 위한 추가 글꼴 및 효과음입니다.';

  @override
  String get setupCompleteTitle => '설정 완료';

  @override
  String get setupCompleteDesc => '멋진 자막 비디오를 제작할 준비가 되었습니다.';

  @override
  String get btnGetStarted => '시작하기';

  @override
  String get btnNext => '다음';

  @override
  String get btnSkip => '건너뛰기';

  @override
  String get onboardingFeaturePrivacy => '100% 개인정보 보호';

  @override
  String get onboardingFeaturePrivacyDesc =>
      '파일은 기기 외부로 절대 유출되지 않습니다. 모든 AI 모델은 로컬에서 실행됩니다.';

  @override
  String get onboardingFeatureGpu => 'GPU 가속 재생';

  @override
  String get onboardingFeatureGpuDesc => '하드웨어 디코딩을 통한 고성능 동영상 편집.';

  @override
  String get onboardingFeatureAssets => '오프라인 사이드카 리소스';

  @override
  String get onboardingFeatureAssetsDesc =>
      '다양한 이모지 팩을 한 번 다운로드하면 완전 오프라인으로 사용할 수 있습니다.';

  @override
  String get onboardingReadyTitle => '모든 준비가 완료되었습니다!';

  @override
  String get onboardingConfigDetails => '구성 세부 정보:';

  @override
  String get btnLaunchCapStudio => 'CapStudio 시작';

  @override
  String get assetVerificationFailed => '리소스 확인 실패. 리소스가 올바르게 다운로드되었는지 확인하세요.';

  @override
  String get assetsFolderNotFound => '리소스 폴더를 찾을 수 없음';

  @override
  String get assetsFolderNotFoundDesc =>
      'CapStudio가 설정된 위치에서 리소스 폴더를 찾을 수 없습니다. 외장 드라이브에 있는 경우 연결해 주세요.';

  @override
  String get expectedPathLabel => '예상 경로:';

  @override
  String get browseNewLocation => '새 위치 찾기';

  @override
  String get resetToDefaultPath => '기본 경로로 재설정';

  @override
  String get retryVerification => '다시 확인';

  @override
  String get storagePathFolder => '저장 경로 폴더';

  @override
  String get tipWindowsDrive =>
      '팁: C 드라이브 용량이 부족한 경우, 공간이 충분한 D 또는 E 드라이브를 선택하세요.';

  @override
  String get tipGeneralDrive => '팁: 루트 볼륨이 가득 찬 경우 외장 드라이브 경로를 선택할 수 있습니다.';

  @override
  String get confirmLocation => '위치 확인';

  @override
  String get requiredBadge => '필수';

  @override
  String get emojiPacksHeader => '이모지 팩';

  @override
  String get fontPacksHeader => '글꼴 팩';

  @override
  String get connectCliTitle => '로컬 CLI 도구 연결';

  @override
  String get connectCliDesc =>
      'CapStudio에서 로컬 전사 및 비디오 내보내기를 수행하려면 whisper.cpp 및 FFmpeg 바이너리가 필요합니다.';

  @override
  String get skipSetup => '지금은 설정 건너뛰기';

  @override
  String get btnValidate => '검증';

  @override
  String get autoDetectAndValidate => '자동 감지 및 검증';

  @override
  String get whisperCliPathLabel => 'Whisper CLI 실행 파일 경로';

  @override
  String get ffmpegCliPathLabel => 'FFmpeg CLI 실행 파일 경로';

  @override
  String get newProject => '새 프로젝트';

  @override
  String get searchProjects => '프로젝트 검색...';

  @override
  String get filterAll => '전체';

  @override
  String get sortByRecent => '최근 항목순';

  @override
  String get sortByDuration => '재생 시간순';

  @override
  String get noMatchingProjects => '검색과 일치하는 프로젝트가 없습니다';

  @override
  String get btnEdit => '편집';

  @override
  String get btnDuplicate => '복제';

  @override
  String get tooltipEdit => '편집';

  @override
  String get tooltipRename => '이름 바꾸기';

  @override
  String get tooltipDuplicate => '복제';

  @override
  String get tooltipDelete => '삭제';

  @override
  String get tooltipTheme => '테마';

  @override
  String get tooltipSettings => '설정';

  @override
  String get selectDemoFormat => '데모 형식 선택';

  @override
  String get selectDemoDesc =>
      '레이아웃 형식을 선택하여 CapStudio의 고정밀 자막 엔진, 실시간 단어별 애니메이션 및 오디오 파형을 즉시 확인하세요.';

  @override
  String get landscapeDemo => '가로 모드 데모';

  @override
  String get landscapeDemoDesc => 'YouTube, 데스크톱 및 프레젠테이션에 적합합니다.';

  @override
  String get portraitDemo => '세로 모드 데모';

  @override
  String get portraitDemoDesc => 'TikTok, Shorts, Reels 및 모바일에 이상적입니다.';

  @override
  String get format16x9 => '16:9 형식';

  @override
  String get format9x16 => '9:16 형식';

  @override
  String get dropVideoHere => '여기에 비디오 드롭';

  @override
  String get dropVideoSupported => 'MP4, MOV, AVI 등 지원';

  @override
  String get statusLocalOffline => '로컬 오프라인';

  @override
  String get speechModelTitle => '음성 인식 모델';

  @override
  String get hardwareUpgradesTitle => '하드웨어 성능 업그레이드';

  @override
  String get showAdvancedPaths => '고급 경로 구성 표시';

  @override
  String get hideAdvancedPaths => '고급 경로 구성 숨기기';

  @override
  String get autoDownload => '자동 다운로드';

  @override
  String get gpuAcceleratedTranscription => 'GPU 가속 전사 (CUDA)';

  @override
  String get gpuRequiresNvidia => 'CUDA와 호환되는 NVIDIA GPU 필요';

  @override
  String get gpuExportEncoder => 'GPU 내보내기 인코더';

  @override
  String get gpuExportEncoderDesc => 'MP4 비디오 내보내기를 위한 하드웨어 가속';

  @override
  String get defaultLanguage => '기본 언어';

  @override
  String get vadTitle => '음성 활동 감지 (VAD)';

  @override
  String get vadDesc => '처리 중 무음 구간 건너뛰기';

  @override
  String get vadThreshold => 'VAD 임계값';

  @override
  String get autoSaveTitle => '자동 저장';

  @override
  String get autoSaveDesc => '3초마다 프로젝트 편집 내용을 데이터베이스에 자동으로 저장';

  @override
  String get defaultOutputsTitle => '기본 출력';

  @override
  String get defaultExportFolder => '기본 내보내기 폴더';

  @override
  String get alwaysAskExportPath => '내보낼 때마다 경로 묻기';

  @override
  String get alwaysAskExportPathDesc => '내보낼 때마다 저장 경로를 확인합니다 (데스크톱)';

  @override
  String get performanceTitle => '성능';

  @override
  String get exportCpuThreads => '내보내기 CPU 스레드';

  @override
  String get exportCpuThreadsDesc => '렌더링에 사용할 프로세서 스레드 수 (기기별로 안전하게 자동 조정)';

  @override
  String get aboutAppSubtitle => '100% 오프라인, 개인정보 우선 AI 자막 제작 스튜디오';

  @override
  String get openSourceLicenses => '오픈 소스 라이선스';

  @override
  String get openSourceComplianceDesc =>
      'CapStudio는 많은 오픈 소스 라이브러리를 사용합니다. 스토어 규정 준수를 위해 모든 Dart 패키지, 전이 종속성 및 전체 라이선스 본문 목록이 아래에 정리되어 있습니다.';

  @override
  String get visitWebsite => '웹사이트 방문';

  @override
  String get btnContinue => '계속';

  @override
  String get btnBack => '뒤로';

  @override
  String get editTiming => '타이밍 수정';

  @override
  String get wordSettingsTitle => '단어 설정';

  @override
  String get emojiSettingsTitle => '이모지 설정';

  @override
  String get changeEmojiTooltip => '이모지 변경';

  @override
  String get searchEmojisHint => '이모지 검색...';

  @override
  String emojiPosX(String offset) {
    return '이모지 위치 (X 오프셋: ${offset}px)';
  }

  @override
  String emojiPosY(String offset) {
    return '이모지 위치 (Y 오프셋: ${offset}px)';
  }

  @override
  String emojiScale(String scale) {
    return '이모지 크기 (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return '애니메이션 속도 (${speed}x)';
  }

  @override
  String get emojiStylePack => '이모지 스타일 / 팩';

  @override
  String get selectStylePackTooltip => '스타일 팩 선택';

  @override
  String get selectEmojiTitle => '이모지 선택';

  @override
  String get stylePackLabel => '스타일 팩';

  @override
  String get searchHint => '검색...';

  @override
  String get btnCreateProject => '프로젝트 생성';

  @override
  String get btnChooseFile => '파일 선택';

  @override
  String get selectSubtitleFile => '자막 파일 선택';

  @override
  String get selectTranscriptionQuality => '전사 품질 선택';

  @override
  String get translateToEnglishDesc => '외국어 음성을 영어 자막으로 직접 변환';

  @override
  String get hardwareSettings => '하드웨어 및 성능 설정';

  @override
  String get styleTemplatesHeader => '스타일 템플릿';

  @override
  String get resetToDefaultStyle => '기본 스타일로 재설정';

  @override
  String get resetStylingTitle => '스타일을 재설정하시겠습니까?';

  @override
  String get resetStylingDesc => '모든 자막 스타일이 기본값으로 재설정됩니다. 이 작업은 취소할 수 없습니다.';

  @override
  String get sizeAndPosition => '크기 및 위치';

  @override
  String get verticalYPos => '수직 Y 위치 (%)';

  @override
  String get fontConfigHeader => '글꼴 구성';

  @override
  String get fontFamilyLabel => '글꼴 패밀리';

  @override
  String get btnImportCustomFont => '사용자 지정 글꼴 가져오기 (.ttf / .otf)';

  @override
  String get fontWeightLabel => '글꼴 두께';

  @override
  String get textCaseLabel => '대소문자';

  @override
  String get fontSizeLabel => '글꼴 크기';

  @override
  String get letterSpacingLabel => '자간';

  @override
  String get lineHeightLabel => '줄 간격';

  @override
  String get onboardingAppTagline => '100% 오프라인 로컬 AI 자막 편집기';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => '데모 모드 (모의)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault => '시스템 PATH 기본값';

  @override
  String get configLabelAssetsLocation => '리소스 위치';

  @override
  String get filePickerAssetsDialogTitle => 'CapStudio 리소스 폴더 선택';

  @override
  String errorSelectFolderFailed(String error) {
    return '폴더 선택 실패: $error';
  }

  @override
  String errorResetFailed(String error) {
    return '재설정 실패: $error';
  }

  @override
  String errorVerificationFailed(String error) {
    return '검증 실패: $error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return '다음 위치에서 여전히 리소스 폴더를 찾을 수 없습니다: $path';
  }

  @override
  String get dbRecoveredTitle => '데이터베이스 자동 복구됨';

  @override
  String dbRecoveredBody(String backupPath) {
    return '데이터베이스 스키마 불일치 또는 손상이 감지되었습니다. 데이터베이스가 재설정되었으며, 이전 데이터는 다음 위치에 백업되었습니다:\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return '데모 비디오 로드 실패: $error';
  }

  @override
  String importProgressPercent(int percent) {
    return '$percent% 완료';
  }

  @override
  String get errorInvalidDropFileFormat => '잘못된 파일 형식입니다. 비디오 파일을 끌어다 놓으세요.';

  @override
  String get findTextLabel => '찾을 텍스트';

  @override
  String get replaceWithLabel => '바꿀 텍스트';

  @override
  String findReplaceSuccessCount(int count) {
    return '$count개 항목을 바꿨습니다!';
  }

  @override
  String get btnReplaceAll => '모두 바꾸기';

  @override
  String errorVideoFileNotFound(String path) {
    return '비디오 파일을 찾을 수 없습니다:\n$path\n비디오 파일을 다시 연결해 주세요.';
  }

  @override
  String get errorTranscriptionFailed => '전사에 실패했습니다. 다시 시도해 주세요.';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return '활성: $quality ($model)';
  }

  @override
  String get badgeRecommended => '추천';

  @override
  String get languageLabel => '언어';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return '경고: 선택한 모델($model)은 영어 전용입니다. \"$language\"(으)로 전사하면 실패하거나 영어 자막이 생성됩니다. 다국어 모델(예: Tiny 또는 Base)을 선택하세요.';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      '팁: 혼합 언어의 경우 자동 감지를 권장하지 않습니다. 사용하는 음성 언어를 명시적으로 선택하면 훨씬 더 정확한 자막이 생성됩니다.';

  @override
  String get detectedHardwareLabel => '감지된 시스템 하드웨어:';

  @override
  String hardwareRamSize(String ramGB) {
    return 'RAM 용량: $ramGB GB';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'CPU 논리 코어: $cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'GPU 기기: $gpu';
  }

  @override
  String get hardwareDetecting => '하드웨어 사양 감지 중...';

  @override
  String get btnStartReTranscribe => '다시 전사 시작';

  @override
  String get btnImportSrtVtt => 'SRT/VTT 파일 가져오기';

  @override
  String importedSubtitleWords(int count) {
    return '자막 파일에서 $count개 단어를 가져왔습니다.';
  }

  @override
  String get errorImportSubtitleFailed => '자막 파일을 가져오지 못했습니다. 파일 형식을 확인하세요.';

  @override
  String get noProjectLoaded => '로드된 프로젝트 없음';

  @override
  String get badge916Vertical => '9:16 세로';

  @override
  String get badge169Landscape => '16:9 가로';

  @override
  String get reframeTargetCanvas =>
      '대상 캔버스: 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)';

  @override
  String get reframeModeLabel => '리프레임 모드:';

  @override
  String get reframeModeBlurPillarbox => '블러 필러박스 (추천)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      '배경 비디오를 확대 및 블러 처리하여 9:16을 채우고, 중앙 비디오를 선명하게 유지합니다.';

  @override
  String get reframeModeCenterCrop => '스마트 중앙 크롭';

  @override
  String get reframeModeCenterCropDesc => '좌우 가장자리를 잘라내어 9:16 전체 화면을 채웁니다.';

  @override
  String get reframeModeSplitScreen => '분할 화면 / 듀얼 레이어';

  @override
  String get reframeModeSplitScreenDesc =>
      '두 비디오 창을 수직으로 배치합니다 (리액션 영상 및 팟캐스트 대화에 적합).';

  @override
  String get btnResetTo169 => '현재 9:16 (16:9로 재설정)';

  @override
  String get btnSetCanvas916 => '프로젝트 캔버스를 9:16으로 설정';

  @override
  String get silenceRemovalDesc =>
      '불필요한 멈춤과 숨소리 구간을 자동으로 잘라내어 시청 지속 시간을 극대화합니다.';

  @override
  String get silenceAggressivenessLabel => '컷 민감도:';

  @override
  String silenceNoiseGateLabel(int db) {
    return '무음 노이즈 게이트: $db dB';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return '최소 일시정지 시간: $duration초';
  }

  @override
  String get btnScanning => '스캔 중...';

  @override
  String silenceNoneFound(String duration) {
    return '$duration초를 초과하는 무음 구간이 없습니다.';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return '$count개의 무음 구간을 찾았습니다 ($totalSecs초의 무음 시간 절약)!';
  }

  @override
  String errorScanningAudio(String error) {
    return '오디오 스캔 중 오류 발생: $error';
  }

  @override
  String jumpCutsApplied(int count) {
    return '프로젝트 타임라인에 $count개의 점프 컷을 적용했습니다!';
  }

  @override
  String get viralHooksDesc =>
      '전사된 단어에서 80개 이상의 바이럴 후크, 말하기 속도(120-170 WPM), 질문, 에너지 밀도 및 클립 경계를 분석합니다.';

  @override
  String get btnAnalyzingTranscript => '전사 내용 분석 중...';

  @override
  String get selectAllLabel => '모두 선택';

  @override
  String selectedCountOf(int selected, int total) {
    return '$total개 중 $selected개 선택됨';
  }

  @override
  String get btnSelectClipsToBatchExport => '일괄 내보낼 클립 선택';

  @override
  String btnBatchExportCount(int count) {
    return '$count개 클립 일괄 내보내기';
  }

  @override
  String get viralNoClipsDetected => '이 비디오 구간에서 고득점 바이럴 클립이 감지되지 않았습니다.';

  @override
  String get badgeCleanCut => '클린 컷';

  @override
  String get badgeFirst5s => '첫 5초';

  @override
  String get btnPreview => '미리보기';

  @override
  String get btnTrim => '자르기';

  @override
  String get tooltipForkAs916 => '새 9:16 쇼츠 프로젝트로 분기 생성';

  @override
  String wpmLabelOk(int wpm) {
    return '$wpm WPM ✓';
  }

  @override
  String wpmLabelFast(int wpm) {
    return '$wpm WPM 빠름';
  }

  @override
  String wpmLabelSlow(int wpm) {
    return '$wpm WPM 느림';
  }

  @override
  String hookScoreLabel(int score) {
    return '후킹 점수 $score/40';
  }

  @override
  String energyScoreLabel(int score) {
    return '에너지 점수 $score/20';
  }

  @override
  String get filePickerClipsFolderTitle => '클립을 저장할 폴더 선택';

  @override
  String get errorChooseOutputFolderFirst => '먼저 출력 폴더를 선택해 주세요.';

  @override
  String batchExportSheetTitle(int count) {
    return '$count개 클립 일괄 내보내기';
  }

  @override
  String get tapToChooseOutputFolder => '출력 폴더를 선택하려면 탭하세요…';

  @override
  String get burnCaptionsOnClipsLabel => '클립에 동적 자막 삽입';

  @override
  String get burnCaptionsOnClipsDesc => '클립 오디오와 동기화된 스타일 애니메이션 자막을 영상에 합성합니다';

  @override
  String exportCancelledProgress(int done, int total) {
    return '내보내기가 취소되었습니다. $done/$total 완료됨.';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return '$done/$total개 내보냄 · $failed개 실패';
  }

  @override
  String get btnExporting => '내보내는 중…';

  @override
  String get btnExportComplete => '내보내기 완료 ✓';

  @override
  String get btnStartExport => '내보내기 시작';

  @override
  String exportClipSavedAt(String path) {
    return '✓ 저장됨: $path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return '프로젝트가 바이럴 클립 #$rank ($start - $end) 구간으로 잘라내어졌습니다!';
  }

  @override
  String shortProjectCreated(String name) {
    return '9:16 쇼츠 프로젝트 생성됨: \"$name\"';
  }

  @override
  String get btnOpen => '열기';

  @override
  String errorCreateShortProjectFailed(String error) {
    return '쇼츠 프로젝트 생성 실패: $error';
  }

  @override
  String get autoDetect => '자동 감지';

  @override
  String presetSaved(String name) {
    return '스타일 프리셋 \"$name\"이(가) 성공적으로 저장되었습니다!';
  }

  @override
  String get presetDeleted => '프리셋이 삭제되었습니다.';

  @override
  String get presetExported => '스타일 프리셋을 내보냈습니다!';

  @override
  String errorPresetExportFailed(String error) {
    return '프리셋 내보내기 실패: $error';
  }

  @override
  String get presetImported => '스타일 프리셋을 가져왔습니다!';

  @override
  String errorPresetImportFailed(String error) {
    return '프리셋 가져오기 실패: $error';
  }

  @override
  String get selectFontFileDialogTitle => 'TTF 또는 OTF 글꼴 파일 선택';

  @override
  String get fontWeightThin => '매우 가늘게 (Thin)';

  @override
  String get fontWeightExtraLight => '더 가늘게 (Extra Light)';

  @override
  String get fontWeightLight => '가늘게 (Light)';

  @override
  String get fontWeightNormal => '보통 (Normal)';

  @override
  String get fontWeightMedium => '중간 (Medium)';

  @override
  String get fontWeightSemiBold => '약간 굵게 (Semi Bold)';

  @override
  String get fontWeightBold => '굵게 (Bold)';

  @override
  String get fontWeightExtraBold => '더 굵게 (Extra Bold)';

  @override
  String get fontWeightBlack => '가장 굵게 (Black)';

  @override
  String get fontCaseNormal => '보통';

  @override
  String get fontCaseUppercase => '대문자';

  @override
  String get fontCaseCapitalize => '첫 글자만 대문자';

  @override
  String get strokeStyleThickOutline => '굵은 외곽선';

  @override
  String get strokeStyleNoneFlat => '없음 (단색)';

  @override
  String get shadowStyleSoft => '부드러운 그림자';

  @override
  String get shadowStyleNone => '없음';

  @override
  String get animStyleActivePop => '액티브 팝';

  @override
  String get animStyleActiveBounce => '액티브 바운스 점프';

  @override
  String get animStyleKineticTilt => '키네틱 틸트';

  @override
  String get animStyleGlowPulse => '글로우 펄스';

  @override
  String get animStyleWordReveal => '단어 순차 표시';

  @override
  String get animStyleNoneStatic => '없음 (정적)';

  @override
  String fontImportedSuccess(String name) {
    return '사용자 지정 글꼴 \"$name\"을(를) 성공적으로 가져와 적용했습니다';
  }

  @override
  String get errorFontImportFailed => '글꼴 파일을 로드하지 못했습니다. 잘못된 데이터입니다.';

  @override
  String get invalidTimingError =>
      '시작/종료 시간이 잘못되었습니다. 시작 시간은 0 이상이어야 하며, 종료 시간은 시작 시간 이상이고 비디오 길이 이하여야 합니다.';

  @override
  String get projectSavedSuccess => '프로젝트가 성공적으로 저장되었습니다.';

  @override
  String wordDeletedSuccess(String text) {
    return '단어가 삭제되었습니다: \"$text\"';
  }

  @override
  String get splitClip => '클립 분할';

  @override
  String get removeClip => '클립 제거';

  @override
  String get resetToOriginal => '원본으로 재설정';

  @override
  String splitTimelineAt(String time) {
    return '$time초 위치에서 타임라인을 분할했습니다.';
  }

  @override
  String get splitTimelineError => '분할하려면 재생 헤드가 활성 영역 내에 있어야 합니다.';

  @override
  String get exclusionToggled => '재생 헤드 아래 세그먼트의 제외 상태를 전환했습니다.';

  @override
  String get splitsReset => '모든 타임라인 분할 및 제외 항목이 재설정되었습니다.';

  @override
  String get shareVideo => '비디오 공유';

  @override
  String get openOutputFolder => '출력 폴더 열기';

  @override
  String get errorLogCopied => '오류 로그가 클립보드에 복사되었습니다.';

  @override
  String get diagnosticsExported => '필터링된 진단 보고서가 공유 시트에서 열렸습니다.';

  @override
  String errorDiagnosticsFailed(String error) {
    return '진단 보고서 내보내기 실패: $error';
  }

  @override
  String logLineCopied(String message) {
    return '로그 내용이 클립보드에 복사되었습니다: \"$message\"';
  }

  @override
  String commandCopied(String command) {
    return '복사됨: \"$command\"';
  }

  @override
  String get settingsRestored => '설정이 기본값으로 복원되었습니다.';

  @override
  String get gpuEncoderNoneCpu => '없음 (CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => 'VC++ 재배포 가능 패키지 다운로드';

  @override
  String errorDownloadToolFailed(String error) {
    return '도구 다운로드 실패: $error';
  }

  @override
  String get errorFolderNotAccessible => '선택한 폴더가 존재하지 않거나 액세스할 수 없습니다.';

  @override
  String modelDeleted(String name) {
    return '모델 삭제됨: $name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return '모델 삭제 실패: $error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return '모델 $name 다운로드 실패: $error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return '폴더를 자동으로 열 수 없습니다. 경로: $path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return '팩 다운로드 실패: $error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return '팩 $name 다운로드 실패: $error';
  }

  @override
  String get stickersIndexRefreshed => '사용자 지정 스티커 인덱스가 새로고침되었습니다!';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return '리소스 폴더 변경 실패: $error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return '리소스 폴더 설정 실패: $error';
  }

  @override
  String get warningNoAvx =>
      'AVX 지원 미비를 감지했습니다! 호환되는 whisper-cli (no-AVX)를 다운로드하는 중...';

  @override
  String get errorAutoDetectWhisper =>
      'whisper-cli를 자동으로 감지할 수 없습니다. 수동으로 찾아보세요.';

  @override
  String get errorAutoDetectFfmpeg => 'ffmpeg을 자동으로 감지할 수 없습니다. 수동으로 찾아보세요.';

  @override
  String errorToolDownloadFailed(String error) {
    return '도구 다운로드 실패: $error';
  }

  @override
  String get returnToDashboard => '대시보드로 돌아가기';

  @override
  String errorImportVideoFailed(String error) {
    return '가져오기 실패: $error';
  }

  @override
  String get videoRelinkedSuccess => '비디오가 다시 연결되었습니다!';

  @override
  String get errorRelinkVideoFailed => '비디오 다시 연결에 실패했습니다.';

  @override
  String get retranscriptionSuccess => '재전사가 완료되었습니다!';

  @override
  String get retranscriptionFailed => '재전사에 실패했습니다.';
}
