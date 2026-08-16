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
}
