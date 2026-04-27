// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'App Screenshots';

  @override
  String get screenshotStudio => '스크린샷 스튜디오';

  @override
  String get screenshotStudioSubtitle => '아름다운 App Store 스크린샷 만들기';

  @override
  String get settings => '설정';

  @override
  String get appearance => '외관';

  @override
  String get about => '정보';

  @override
  String get themeSystem => '시스템';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get themeSystemSubtitle => '기기 설정에 따름';

  @override
  String get themeLightSubtitle => '항상 라이트 테마 사용';

  @override
  String get themeDarkSubtitle => '항상 다크 테마 사용';

  @override
  String get newDesign => '새 디자인';

  @override
  String get save => '저장';

  @override
  String get saveAs => '다른 이름으로 저장';

  @override
  String get export => '내보내기';

  @override
  String get share => '공유';

  @override
  String get delete => '삭제';

  @override
  String get rename => '이름 변경';

  @override
  String get duplicate => '복제';

  @override
  String get cancel => '취소';

  @override
  String get undo => '실행 취소';

  @override
  String get redo => '다시 실행';

  @override
  String get confirm => '확인';

  @override
  String get done => '완료';

  @override
  String get rotationX => '회전 X';

  @override
  String get rotationY => '회전 Y';

  @override
  String get rotationZ => '회전 Z';

  @override
  String get edit => '편집';

  @override
  String get close => '닫기';

  @override
  String get designName => '디자인 이름';

  @override
  String get enterDesignName => '디자인 이름 입력';

  @override
  String get folder => '폴더';

  @override
  String get newFolder => '새 폴더';

  @override
  String get folderName => '폴더 이름';

  @override
  String get enterFolderName => '폴더 이름 입력';

  @override
  String get moveToFolder => '폴더로 이동';

  @override
  String get noFolder => '폴더 없음';

  @override
  String get emptyFolder => '이 폴더는 비어 있습니다';

  @override
  String get deleteFolder => '폴더 삭제';

  @override
  String get deleteFolderConfirmation => '이 폴더를 삭제하시겠습니까? 디자인은 루트로 이동됩니다.';

  @override
  String get cloneToDevice => '기기로 복제';

  @override
  String get saveAsTemplate => '템플릿으로 저장';

  @override
  String get moveLeft => '왼쪽으로 이동';

  @override
  String get moveRight => '오른쪽으로 이동';

  @override
  String get deleteSelectedConfirmation => '선택한 항목을 삭제하시겠습니까?';

  @override
  String selectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get exportedDesigns => '내보낸 디자인';

  @override
  String get select => '선택';

  @override
  String get move => '이동';

  @override
  String get alsoDeleteAllDesigns => '폴더 내 모든 디자인도 삭제';

  @override
  String get renameFolder => '폴더 이름 변경';

  @override
  String get deleteDesign => '디자인 삭제';

  @override
  String get deleteDesignConfirmation => '이 디자인을 삭제하시겠습니까?';

  @override
  String get background => '배경';

  @override
  String get solidColor => '단색';

  @override
  String get gradient => '그라데이션';

  @override
  String get addGradientStop => '색 정지점 추가';

  @override
  String get removeGradientStop => '색 정지점 제거';

  @override
  String get deviceFrame => '기기 프레임';

  @override
  String get selectDevice => '기기 선택';

  @override
  String get noFrame => '프레임 없음';

  @override
  String get iphone => 'iPhone';

  @override
  String get ipad => 'iPad';

  @override
  String get textOverlay => '텍스트';

  @override
  String get addText => '텍스트 추가';

  @override
  String get newText => '새 텍스트';

  @override
  String get editText => '텍스트 편집';

  @override
  String get fontSize => '글꼴 크기';

  @override
  String get fontWeight => '글꼴 굵기';

  @override
  String get fontFamily => '글꼴';

  @override
  String get textColor => '텍스트 색상';

  @override
  String get textAlign => '텍스트 정렬';

  @override
  String get textRotation => '회전';

  @override
  String get textScale => '크기 조절';

  @override
  String get textDecoration => '장식';

  @override
  String get textBackground => '배경';

  @override
  String get textBorder => '테두리';

  @override
  String get deleteText => '텍스트 삭제';

  @override
  String get imageOverlay => '이미지';

  @override
  String get addImage => '이미지 추가';

  @override
  String get deleteImage => '이미지 삭제';

  @override
  String get doodle => '두들';

  @override
  String get enableDoodle => '두들 패턴 활성화';

  @override
  String get iconSource => '아이콘 소스';

  @override
  String get iconSize => '아이콘 크기';

  @override
  String get iconSpacing => '간격';

  @override
  String get iconOpacity => '불투명도';

  @override
  String get iconRotation => '회전';

  @override
  String get randomizeRotation => '무작위 회전';

  @override
  String get grid => '그리드';

  @override
  String get showGrid => '그리드 표시';

  @override
  String get snapToGrid => '그리드에 맞추기';

  @override
  String get gridSize => '그리드 크기';

  @override
  String get showCenterLines => '중심선 표시';

  @override
  String get padding => '패딩';

  @override
  String get cornerRadius => '모서리 둥글기';

  @override
  String get frameRotation => '프레임 회전';

  @override
  String get orientation => '방향';

  @override
  String get portrait => '세로';

  @override
  String get landscape => '가로';

  @override
  String get tools => '도구';

  @override
  String get pickImage => '이미지 선택';

  @override
  String get importImage => '이미지 가져오기';

  @override
  String get dropImageHere => '여기에 이미지를 드롭하세요';

  @override
  String get replaceImage => '이미지 교체';

  @override
  String get savedToLibrary => '라이브러리에 저장됨';

  @override
  String get exportedSuccessfully => '내보내기 완료';

  @override
  String get failedToExport => '내보내기 실패';

  @override
  String get gridView => '그리드 보기';

  @override
  String get listView => '목록 보기';

  @override
  String get emptyLibrary => '아직 디자인이 없습니다';

  @override
  String get emptyLibrarySubtitle => '+ 를 눌러 첫 번째 스크린샷 디자인을 만드세요';

  @override
  String version(String version) {
    return '버전 $version';
  }

  @override
  String designsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '디자인 $count개',
      zero: '디자인 없음',
    );
    return '$_temp0';
  }

  @override
  String get library => '라이브러리';

  @override
  String get noDesignsYet => '아직 디자인이 없습니다';

  @override
  String get createYourFirstDesign => '첫 번째 스크린샷 디자인을 만드세요';

  @override
  String get solid => '단색';

  @override
  String get backgroundColor => '배경색';

  @override
  String get gradientColors => '그라데이션 색상';

  @override
  String get none => '없음';

  @override
  String get color => '색상';

  @override
  String get location => '위치';

  @override
  String get angle => '각도';

  @override
  String get removeStop => '정지점 제거';

  @override
  String get alignment => '정렬';

  @override
  String get decorationStyle => '장식 스타일';

  @override
  String get decorationColor => '장식 색상';

  @override
  String get borderAndFill => '테두리 및 채우기';

  @override
  String get fillColor => '채우기 색상';

  @override
  String get borderColor => '테두리 색상';

  @override
  String get borderWidth => '테두리 너비';

  @override
  String get borderRadius => '테두리 둥글기';

  @override
  String get horizontalPadding => '가로 패딩';

  @override
  String get verticalPadding => '세로 패딩';

  @override
  String get rotation => '회전';

  @override
  String get selectOrAddText => '텍스트 오버레이를 선택하거나 추가';

  @override
  String editingLocale(String locale) {
    return '$locale 오버라이드 편집 중';
  }

  @override
  String get copyToClipboard => '클립보드에 복사';

  @override
  String get copiedToClipboard => '클립보드에 복사됨';

  @override
  String get pasteFromClipboard => '클립보드에서 붙여넣기';

  @override
  String get noImageInClipboard => '클립보드에 이미지가 없습니다';

  @override
  String get checkOutMyDesign => '내 디자인을 확인하세요!';

  @override
  String get templates => '템플릿';

  @override
  String get more => '더 보기';

  @override
  String get pickAStyleForScreenshots => '스크린샷 스타일을 선택하세요';

  @override
  String get content => '콘텐츠';

  @override
  String get enterText => '텍스트 입력...';

  @override
  String get typography => '타이포그래피';

  @override
  String get sizeAndWeight => '크기 및 굵기';

  @override
  String get transform => '변환';

  @override
  String get transparent => '투명';

  @override
  String get addIcon => '아이콘 추가';

  @override
  String get iconColor => '아이콘 색상';

  @override
  String get sfSymbols => 'SF Symbols';

  @override
  String get materialLabel => 'Material';

  @override
  String get emojiLabel => '이모지';

  @override
  String get searchIcons => '아이콘 검색...';

  @override
  String get roundedStyle => '둥근';

  @override
  String get sharpStyle => '날카로운';

  @override
  String get outlinedStyle => '윤곽선';

  @override
  String get weightLabel => '굵기';

  @override
  String get displayLabel => '디스플레이';

  @override
  String get showGridLabel => '그리드 표시';

  @override
  String get displayGridLines => '캔버스에 그리드 선 표시';

  @override
  String get snapToGridLabel => '그리드에 맞추기';

  @override
  String get snapToGridSubtitle => '요소를 가장 가까운 그리드 선에 맞춤';

  @override
  String get centerLines => '중심선';

  @override
  String get centerLinesSubtitle => '중앙 정렬 가이드 표시';

  @override
  String get gridSizeLabel => '그리드 크기';

  @override
  String get sizeLabel => '크기';

  @override
  String get scatterIconPatterns => '콘텐츠 뒤에 아이콘 패턴 흩뿌리기';

  @override
  String get iconStyle => '아이콘 스타일';

  @override
  String get presetsLabel => '프리셋';

  @override
  String get layoutLabel => '레이아웃';

  @override
  String get opacityLabel => '불투명도';

  @override
  String get iconSizeLabel => '아이콘 크기';

  @override
  String get spacingLabel => '간격';

  @override
  String get customIcons => '커스텀 아이콘';

  @override
  String screenshotLabel(int index) {
    return '스크린샷 $index';
  }

  @override
  String get searchDesignsAndFolders => '디자인 및 폴더 검색…';

  @override
  String noResultsFor(String query) {
    return '\"$query\"에 대한 결과 없음';
  }

  @override
  String get zoomToFit => '화면에 맞추기';

  @override
  String get addScreenshot => '스크린샷 추가';

  @override
  String get exportCurrent => '현재 내보내기';

  @override
  String get exportAll => '전체 내보내기';

  @override
  String get selectExportFolder => '내보내기 폴더 선택';

  @override
  String screenshotStudioCount(int count) {
    return '스크린샷 스튜디오 · $count장';
  }

  @override
  String get deviceFrames => '기기 프레임';

  @override
  String get gradients => '그라데이션';

  @override
  String get textOverlays => '텍스트 오버레이';

  @override
  String get doodles => '두들';

  @override
  String get frame => '프레임';

  @override
  String get text => '텍스트';

  @override
  String get unlockPro => '✨ Pro 잠금 해제';

  @override
  String get removeAllCreativeLimits => '모든 창작 제한 해제';

  @override
  String get foldersUnlimitedSaves => '폴더 및 무제한 저장';

  @override
  String get foldersUnlimitedSavesSubtitle => '폴더로 정리하고 디자인을 무제한으로 저장';

  @override
  String get allDevicesMultiScreenshot => '모든 기기 + 다중 스크린샷';

  @override
  String get allDevicesMultiScreenshotSubtitle =>
      '모든 기기 프레임으로 여러 스크린샷을 한번에 디자인';

  @override
  String get advancedDesignTools => '고급 디자인 도구';

  @override
  String get advancedDesignToolsSubtitle =>
      '텍스트 오버레이, 아이콘, 두들 및 전체 Google Fonts 라이브러리 잠금 해제';

  @override
  String get proUnlimitedMultiSets => '무제한 멀티 스크린샷 세트';

  @override
  String get proUnlimitedMultiSetsSubtitle => '필요한 만큼 세트를 만드세요';

  @override
  String get proAllDevicesMultiMode => '멀티 모드에서 모든 디바이스 프레임';

  @override
  String get proAllDevicesMultiModeSubtitle => 'iPad, Apple Watch 등 일괄 스크린샷용';

  @override
  String get proAiTranslationAllLocales => 'AI 번역 — 모든 언어';

  @override
  String get proAiTranslationSubtitle => 'App Store 모든 언어로 한 번에 번역';

  @override
  String get proAllDoodlePresets => '모든 두들 프리셋 & 맞춤 아이콘';

  @override
  String get proAllDoodlePresetsSubtitle => '무제한 패턴으로 완전한 창작의 자유';

  @override
  String get proLabel => 'Pro';

  @override
  String get continueWithPro => 'Pro로 계속';

  @override
  String get restorePurchases => '구매 복원';

  @override
  String get support => '지원';

  @override
  String get legal => '법률 정보';

  @override
  String get rateOnAppStore => 'App Store에서 평가';

  @override
  String get sendFeedback => '피드백 보내기';

  @override
  String get redeemCode => '코드 사용';

  @override
  String get termsOfService => '이용약관';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get enjoyingApp => 'App Screenshots가 마음에 드시나요?';

  @override
  String get enjoyingAppSubtitle => '탭하여 의견을 알려주세요';

  @override
  String get restoreCode => '코드 복원';

  @override
  String get upgradeNow => '지금 업그레이드';

  @override
  String get oneTimePurchase => '일회성 구매 — 영원히 소유';

  @override
  String get restorePurchase => '구매 복원';

  @override
  String get proActive => 'Pro 활성화됨';

  @override
  String get allFeaturesUnlocked => '모든 기능이 잠금 해제됨';

  @override
  String get upgradeToPro => 'Pro로 업그레이드';

  @override
  String get upgradeToProDescription =>
      '폴더, 모든 기기, 다중 스크린샷, 고급 디자인 도구 등을 잠금 해제하세요.';

  @override
  String get restore => '복원';

  @override
  String get appIcon => '앱 아이콘';

  @override
  String get defaultLabel => '기본';

  @override
  String get purpleLabel => '퍼플';

  @override
  String get exportingScreenshots => '스크린샷 내보내는 중…';

  @override
  String get images => '이미지';

  @override
  String get icons => '아이콘';

  @override
  String get selectFont => '글꼴 선택';

  @override
  String get searchFonts => '글꼴 검색…';

  @override
  String get stops => '정지점';

  @override
  String get tapBarToAdd => '바를 탭하여 추가';

  @override
  String get selectedStop => '선택된 정지점';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 항목',
      one: '1개 항목',
    );
    return '$_temp0';
  }

  @override
  String get chooseScreenSize => '디자인에 사용할 화면 크기를 선택하세요';

  @override
  String get multiScreenshot => '멀티 스크린샷';

  @override
  String get createUpTo10Screenshots => '최대 10장의 스크린샷 생성';

  @override
  String get pickScreenSize => '스크린샷에 사용할 화면 크기를 선택하세요';

  @override
  String get orPickDeviceSize => '또는 기기 크기 선택';

  @override
  String get dragScreenshotsHint => '이 영역으로 스크린샷을 드래그하세요';

  @override
  String get tapImportHint => '또는 여기를 클릭하여 가져오기';

  @override
  String get tapImportHintMobile => '가져오기를 탭하여 스크린샷을 추가하세요';

  @override
  String get shareDesignFile => '디자인 파일 공유';

  @override
  String get importDesign => '디자인 가져오기';

  @override
  String get designExportedSuccessfully => '디자인을 내보냈습니다';

  @override
  String get designImportedSuccessfully => '디자인을 가져왔습니다';

  @override
  String get failedToImportDesign => '디자인 가져오기 실패';

  @override
  String get savedToFile => '파일에 저장됨';

  @override
  String get saveToLibrary => '라이브러리에 저장';

  @override
  String get icloudBackup => 'iCloud 백업';

  @override
  String get backupNow => '지금 백업';

  @override
  String get restoreFromBackup => '백업에서 복원';

  @override
  String get lastBackup => '마지막 백업';

  @override
  String get backupsAutomatic => '백업은 자동으로 생성됩니다';

  @override
  String get noBackupsAvailable => '사용 가능한 백업 없음';

  @override
  String get restoreWarning => '복원하면 현재 모든 디자인이 교체됩니다. 이 작업은 취소할 수 없습니다.';

  @override
  String get backupRestoredSuccessfully => '백업이 복원되었습니다';

  @override
  String get backupCreatedSuccessfully => '백업이 생성되었습니다';

  @override
  String get backupFailed => '백업 실패';

  @override
  String get icloudNotAvailable => 'iCloud를 사용할 수 없습니다';

  @override
  String get gradientType => '그라데이션 유형';

  @override
  String get linear => '선형';

  @override
  String get radial => '방사형';

  @override
  String get sweep => '스윕';

  @override
  String get mesh => '메쉬';

  @override
  String get radialSettings => '방사형 설정';

  @override
  String get radius => '반경';

  @override
  String get sweepSettings => '스윕 설정';

  @override
  String get startAngle => '시작 각도';

  @override
  String get endAngle => '끝 각도';

  @override
  String get meshPoints => '메쉬 포인트';

  @override
  String get meshOptions => '메쉬 옵션';

  @override
  String get blend => '블렌드';

  @override
  String get noise => '노이즈';

  @override
  String get showDotGrid => '캔버스 점';

  @override
  String get showDotGridSubtitle => '편집기 배경에 점 패턴 표시';

  @override
  String get addPoint => '포인트 추가';

  @override
  String get removePoint => '삭제';

  @override
  String get centerX => '중심 X';

  @override
  String get centerY => '중심 Y';

  @override
  String pointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '포인트 $count개',
    );
    return '$_temp0';
  }

  @override
  String pointLabel(int index) {
    return '포인트 $index';
  }

  @override
  String get xAxis => 'X';

  @override
  String get yAxis => 'Y';

  @override
  String get uploadToAppStoreConnect => 'App Store Connect에 업로드';

  @override
  String get loadingApps => '앱 불러오는 중...';

  @override
  String loadingVersionForApp(String appName) {
    return '$appName 버전 불러오는 중...';
  }

  @override
  String get unknownError => '알 수 없는 오류';

  @override
  String get noApiKeyConfigured => 'API 키 미설정';

  @override
  String get ascApiKeySetupHint =>
      '스크린샷을 업로드하려면 App Store Connect API 키를 설정하세요.';

  @override
  String get configureApiKey => 'API 키 설정';

  @override
  String get selectApp => '앱 선택';

  @override
  String get searchApps => '앱 검색...';

  @override
  String get noAppsFound => '앱을 찾을 수 없음';

  @override
  String get checkApiKeyPermissions => 'API 키 권한을 확인하세요.';

  @override
  String noAppsMatchQuery(String query) {
    return '\"$query\"에 일치하는 앱이 없습니다';
  }

  @override
  String get changeApp => '앱 변경';

  @override
  String get screenshotDisplayType => '스크린샷 표시 유형';

  @override
  String get replace => '대체';

  @override
  String get append => '추가';

  @override
  String get rememberForThisDesign => '이 디자인에 기억';

  @override
  String get willSkipAppSelectionNextTime => '다음에 앱 선택을 건너뜁니다';

  @override
  String get youllPickTheAppEachTime => '매번 앱을 선택합니다';

  @override
  String get localesHeader => '언어';

  @override
  String get deselectAll => '전체 해제';

  @override
  String get selectAll => '전체 선택';

  @override
  String get selectLocalesToUpload => '업로드할 언어 선택';

  @override
  String uploadNLocales(int count) {
    return '$count개 언어 업로드';
  }

  @override
  String nScreenshots(int count) {
    return '$count개 스크린샷';
  }

  @override
  String get across => ',';

  @override
  String nLocales(int count) {
    return '$count개 언어';
  }

  @override
  String nFiles(int count) {
    return '$count개 파일';
  }

  @override
  String get uploadFailed => '업로드 실패';

  @override
  String get completedWithIssues => '문제 발생으로 완료';

  @override
  String get uploadComplete => '업로드 완료!';

  @override
  String nSucceeded(int count) {
    return '$count건 성공';
  }

  @override
  String nFailed(int count) {
    return '$count건 실패';
  }

  @override
  String uploadingLocale(String locale) {
    return '$locale 업로드 중';
  }

  @override
  String nOfTotalScreenshots(int current, int total) {
    return '$current / $total장';
  }

  @override
  String get preparingUpload => '업로드 준비 중...';

  @override
  String get statusPending => '대기 중';

  @override
  String get statusUploading => '업로드 중...';

  @override
  String get statusDone => '완료';

  @override
  String get statusFailed => '실패';

  @override
  String get somethingWentWrong => '문제가 발생했습니다';

  @override
  String get retry => '재시도';

  @override
  String get appStoreConnectApiKey => 'App Store Connect API 키';

  @override
  String get ascApiKeyGenerateHint =>
      'App Store Connect → 사용자 및 액세스 → 통합 → 키에서 API 키 생성';

  @override
  String get keyId => '키 ID';

  @override
  String get keyIdHint => '예: ABC1234DEF';

  @override
  String get issuerId => '발급자 ID';

  @override
  String get issuerIdHint => '예: 12345678-1234-1234-1234-123456789012';

  @override
  String get privateKeyLabel => '개인 키 (.p8 파일 내용)';

  @override
  String get privateKeyExistingHint => '••••••• (기존 유지하려면 비워두기)';

  @override
  String get privateKeyNewHint => '-----BEGIN PRIVATE KEY-----\\n...';

  @override
  String get clear => '지우기';

  @override
  String get clearCredentialsTitle => '자격 증명을 지우시겠습니까?';

  @override
  String get clearCredentialsMessage =>
      '저장된 API 키가 삭제됩니다. 향후 업로드 시 다시 입력해야 합니다.';

  @override
  String get apiKeySettingsTitle => 'API 키';

  @override
  String get apiKeyLoading => '불러오는 중...';

  @override
  String apiKeyConfigured(String maskedKeyId) {
    return '키 ID: $maskedKeyId';
  }

  @override
  String get apiKeyNotConfigured => '미설정';

  @override
  String get provider => '공급자';

  @override
  String get appContext => '앱 컨텍스트';

  @override
  String get addContext => '컨텍스트 추가...';

  @override
  String get sourceLanguage => '원본 언어';

  @override
  String get targetLanguages => '대상 언어';

  @override
  String get translateAll => '전체 번역';

  @override
  String translatingProgress(int completed, int total) {
    return '번역 중 $completed / $total';
  }

  @override
  String get manualCopyPaste => '수동 (복사-붙여넣기)';

  @override
  String get uploadToAsc => 'ASC에 업로드';

  @override
  String get uploadExistingFolderToAsc => 'Upload Existing Folder...';

  @override
  String get noImagesFoundInFolder =>
      'No valid screenshot images found in selected folder';

  @override
  String get addMoreLanguages => '언어 추가';

  @override
  String get editTranslations => '번역 편집';

  @override
  String get addTextOverlaysFirst => '먼저 스크린샷에 텍스트를 추가하세요';

  @override
  String get selectAtLeastOneTargetLanguage => '대상 언어를 하나 이상 선택하세요';

  @override
  String get failedToCaptureLocaleScreenshots => '현지화 스크린샷 촬영 실패';

  @override
  String get translationProvider => '번역 공급자';

  @override
  String get chooseHowTextGetsTranslated => '텍스트 번역 방법을 선택하세요';

  @override
  String get apiKey => 'API 키';

  @override
  String get apiKeysStoredSecurely => 'API 키는 macOS 키체인에 안전하게 저장됩니다';

  @override
  String get endpointUrl => '엔드포인트 URL';

  @override
  String get model => '모델';

  @override
  String get providerApple => 'Apple (기기 내)';

  @override
  String get providerOpenai => 'OpenAI';

  @override
  String get providerGemini => 'Google Gemini';

  @override
  String get providerDeepl => 'DeepL';

  @override
  String get providerCustom => '맞춤 엔드포인트';

  @override
  String get providerManual => '수동 (복사-붙여넣기)';

  @override
  String get providerAppleSubtitle => '무료, 비공개 — Apple Intelligence 필요';

  @override
  String get providerOpenaiSubtitle => 'GPT-4o Mini — 자체 API 키 사용';

  @override
  String get providerGeminiSubtitle => 'Gemini 2.0 Flash — 자체 API 키 사용';

  @override
  String get providerDeeplSubtitle => '전문 번역 — 자체 API 키 사용';

  @override
  String get providerCustomSubtitle => 'Ollama, Together AI, LM Studio 등';

  @override
  String get providerManualSubtitle => '프롬프트 복사 → AI에 붙여넣기 → 응답 붙여넣기';

  @override
  String manualTranslateTitle(String locales) {
    return '수동 번역 → $locales';
  }

  @override
  String get step1CopyPrompt => '1단계: 프롬프트 복사';

  @override
  String get step2PasteResponse => '2단계: AI 응답 붙여넣기';

  @override
  String get copied => '복사됨!';

  @override
  String get copyPrompt => '프롬프트 복사';

  @override
  String get paste => '붙여넣기';

  @override
  String get pasteJsonHint => 'ChatGPT, Claude, Gemini 등 AI의 JSON 응답을 붙여넣으세요.';

  @override
  String get applyTranslations => '번역 적용';

  @override
  String get couldNotParseJson => 'JSON을 분석할 수 없습니다. 형식을 확인하고 다시 시도하세요.';

  @override
  String missingLocalesError(String locales) {
    return '누락된 언어: $locales';
  }

  @override
  String localeMissingKeysError(String locale, String keys) {
    return '$locale에 키가 누락됨: $keys';
  }

  @override
  String nTexts(int count) {
    return '$count개 텍스트';
  }

  @override
  String get appContextDialogTitle => '앱 컨텍스트';

  @override
  String get appContextDescription => '번역이 앱의 분위기와 분야에 맞도록 앱을 설명하세요.';

  @override
  String get appContextHint => '예: 러너용 피트니스 트래킹 앱. 에너지 넘치고 동기를 부여하는 언어 사용.';

  @override
  String get addLanguages => '언어 추가';

  @override
  String get searchLanguage => '언어 검색...';

  @override
  String get noLanguagesFound => '언어를 찾을 수 없음';

  @override
  String get selectLanguages => '언어 선택';

  @override
  String addNLanguages(int count) {
    return '$count개 언어 추가';
  }

  @override
  String get appStoreConnect => 'App Store Connect';

  @override
  String get aiGenerate => '✨ AI 생성';

  @override
  String get aiGenerateSubtitle => '스타일을 설명하면 AI가 템플릿을 만듭니다';

  @override
  String get aiTemplatePromptHint => '예: 피트니스 앱을 위한 다크 엘레강스 스타일';

  @override
  String get aiTemplateGenerating => '생성 중…';

  @override
  String get aiTemplateError => '템플릿 생성 실패';

  @override
  String get aiTemplateNoApiKey => 'AI 템플릿을 사용하려면 설정에서 Gemini API 키를 설정하세요';

  @override
  String get generate => '생성';

  @override
  String get applyTemplate => '템플릿 적용';

  @override
  String get applyTemplateConfirm => '현재 모든 스크린샷의 디자인이 선택한 템플릿으로 교체됩니다.';

  @override
  String applyTemplateConfirmExpand(int templateCount, int currentCount) {
    return '이 템플릿에는 $templateCount개의 디자인이 있지만 현재 $currentCount개입니다. 부족한 스크린샷은 자동으로 생성되며 모든 디자인이 교체됩니다.';
  }

  @override
  String get apply => '적용';

  @override
  String get aiProviderSettings => 'AI 공급자';

  @override
  String get aiProvider => '공급자';

  @override
  String get aiApiKeyHint => '여기에 API 키 붙여넣기';

  @override
  String get aiGeminiKeyHelp =>
      'Google AI Studio (aistudio.google.com)에서 API 키를 받으세요.';

  @override
  String get aiOpenaiKeyHelp =>
      'OpenAI 대시보드 (platform.openai.com)에서 API 키를 받으세요.';

  @override
  String get aiAppleFmInfo =>
      'Apple Foundation Models는 기기에서 실행됩니다. API 키나 인터넷 연결이 필요 없습니다.';

  @override
  String get aiKeyNotConfigured => 'API 키 미설정';

  @override
  String get aiAssistant => 'AI 어시스턴트';

  @override
  String get aiAssistantSubtitle => '디자인 변경을 설명하면 AI가 적용합니다';

  @override
  String get aiAssistantHint => '변경하고 싶은 내용을 설명하세요...';

  @override
  String get aiAssistantSuggestions => '이것을 시도해보세요';

  @override
  String get aiAssistantThinking => '생각 중...';

  @override
  String get aiAssistantUndo => 'AI 변경 취소';

  @override
  String get aiAssistantClearChat => '채팅 지우기';

  @override
  String get aiAssistantApplyToAll => '모든 스크린샷에 적용';

  @override
  String aiAssistantAppliedToAll(int count) {
    return '$count개 스크린샷에 변경 적용됨.';
  }

  @override
  String aiAssistantPartialSuccess(int success, int total, int failed) {
    return '$success/$total개에 적용됨. $failed개 실패.';
  }

  @override
  String aiAssistantUnexpectedError(String error) {
    return '예상치 못한 오류: $error';
  }

  @override
  String get aiSuggestionAddGradient => '그라데이션 배경 추가';

  @override
  String get aiSuggestionLightMode => '라이트 모드로 전환';

  @override
  String get aiSuggestionDarkMode => '다크 모드로 전환';

  @override
  String get aiSuggestionAddHeadline => '눈길 끄는 헤드라인 추가';

  @override
  String get aiSuggestionBiggerTitle => '제목 키우기';

  @override
  String get aiSuggestionAddSubtitle => '부제목 추가';

  @override
  String get aiSuggestionTiltFrame => '프레임 기울이기';

  @override
  String get aiSuggestionRoundCorners => '모서리 둥글게';

  @override
  String get aiSuggestionWriteHeadline => '눈길 끄는 헤드라인 작성';

  @override
  String get aiSuggestionColorPalette => '색상 팔레트 제안';

  @override
  String get aiSuggestionAddDoodle => '두들 패턴 배경 추가';

  @override
  String get aiSuggestionEmojiDoodle => '이모지 두들 패턴 사용';

  @override
  String get aiSuggestionAdd3DTilt => '3D 원근감 기울기 추가';

  @override
  String get aiSuggestionTransparentBg => '배경 투명하게';

  @override
  String get aiSuggestionLandscapeMode => '가로 모드로 전환';

  @override
  String get magnifierShapeLabel => '모양';

  @override
  String get magnifierShapeCircle => '원';

  @override
  String get magnifierShapeRounded => '둥근';

  @override
  String get magnifierShapeStar => '별';

  @override
  String get magnifierShapeHexagon => '육각형';

  @override
  String get magnifierShapeDiamond => '다이아몬드';

  @override
  String get magnifierShapeHeart => '하트';

  @override
  String magnifierCorner(int value) {
    return '모서리: $value';
  }

  @override
  String magnifierPoints(int value) {
    return '포인트: $value';
  }

  @override
  String magnifierZoom(String value) {
    return '확대: $value×';
  }

  @override
  String magnifierWidth(int value) {
    return '너비: $value';
  }

  @override
  String magnifierHeight(int value) {
    return '높이: $value';
  }

  @override
  String magnifierBorder(String value) {
    return '테두리: $value';
  }

  @override
  String magnifierSourceX(int value) {
    return '소스 X: $value';
  }

  @override
  String magnifierSourceY(int value) {
    return '소스 Y: $value';
  }

  @override
  String magnifierOpacity(int value) {
    return '불투명도: $value%';
  }

  @override
  String get bringForward => '앞으로 가져오기';

  @override
  String get sendBackward => '뒤로 보내기';

  @override
  String get inFrontOfFrame => '프레임 앞';

  @override
  String get behindFrame => '프레임 뒤';

  @override
  String get onlySelectedLocalesWillBeRendered => '선택한 언어만 렌더링됩니다';

  @override
  String renderNLocales(int count) {
    return '$count개 언어 렌더링';
  }

  @override
  String get source => '소스';

  @override
  String get supportTheDeveloper => '개발자 후원하기';

  @override
  String supportTheDeveloperDescription(String price) {
    return '앱이 마음에 드시나요? 커피 한 잔 사주세요! $price';
  }

  @override
  String get enableCliServer => 'CLI 서버 활성화';

  @override
  String get enableCliServerDescription => 'CLI 도구를 사용하려면 로컬 서버를 시작하세요.';

  @override
  String get cliLearnMoreButton => '문서 읽기';

  @override
  String get cliCompanionTitle => '명령줄 도구';

  @override
  String get cliCompanionDescription =>
      '컴패니언 CLI 도구를 사용하여 터미널에서 스크린샷을 자동화하세요. 설정 방법은 문서를 참조하세요.';
}
