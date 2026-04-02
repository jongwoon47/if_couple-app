// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'IF App';

  @override
  String get splashPreparingIf => 'IF를 준비하는 중이에요...';

  @override
  String get splashCheckingLogin => '로그인 상태를 확인하고 있어요...';

  @override
  String get splashLoadingProfile => '내 정보를 불러오고 있어요...';

  @override
  String get splashDefault => '앱을 준비하고 있어요...';

  @override
  String get appLoadErrorTitle => '앱을 불러오는 데 문제가 생겼어요';

  @override
  String get appLoadErrorBody => '네트워크 연결을 확인한 뒤\n앱을 다시 실행해 주세요.';

  @override
  String get settingsTitle => '설정';

  @override
  String get profileEdit => '프로필 편집';

  @override
  String get notificationSettings => '알림 설정';

  @override
  String get disconnect => '연결 해제';

  @override
  String get disconnecting => '연결 해제 중...';

  @override
  String get disconnectConfirmTitle => '정말 연결을 해제하시겠어요?';

  @override
  String get disconnectConfirmBody =>
      '연결만 끊기며 채팅·앨범 등 데이터는 서버에 남습니다. 90일 안에 다시 로그인해 이전 연결을 복구할 수 있어요. 해제 후 로그아웃됩니다.';

  @override
  String get restoreCoupleTitle => '이전 연결 복구';

  @override
  String get restoreCoupleSubtitle =>
      '상대도 로그인한 뒤, 둘 다 90일 안에 여기서 복구를 눌러야 다시 연결돼요.';

  @override
  String get restoreCoupleButton => '이전 연결로 다시 연결';

  @override
  String get restoreCoupleRestoring => '복구 중…';

  @override
  String get restoreErrorExpired => '복구 기간(90일)이 지났어요.';

  @override
  String get restoreErrorPartnerNotReady => '상대가 아직 로그인하지 않았거나, 복구 조건이 맞지 않아요.';

  @override
  String get restoreErrorGeneric => '복구할 수 없어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get accountDeleteTitle => '회원 탈퇴';

  @override
  String get accountDeleteBody =>
      '내 계정 정보가 삭제되고 상대는 연결이 끊겨요. 두 분 모두 탈퇴하면 채팅·앨범 등 커플 데이터가 모두 삭제됩니다.';

  @override
  String get accountDeleteConfirm => '탈퇴하기';

  @override
  String get accountDeleting => '탈퇴 처리 중…';

  @override
  String get cancel => '취소';

  @override
  String get appInfo => '앱 정보';

  @override
  String get partnerDefault => '연인';

  @override
  String get statusDefaultEmpty => '서로의 일상을 함께 채워요.';

  @override
  String get languageSettings => '언어';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageJapanese => '日本語';

  @override
  String get tabHome => '홈';

  @override
  String get tabChat => '대화';

  @override
  String get tabTrip => '여행';

  @override
  String get tabCalendar => '캘린더';

  @override
  String get tabAlbum => '앨범';

  @override
  String get save => '저장';

  @override
  String get saving => '저장 중...';

  @override
  String get done => '완료';

  @override
  String get delete => '삭제';

  @override
  String get close => '닫기';

  @override
  String get confirm => '확인';

  @override
  String get confirming => '확인 중...';

  @override
  String get loginTagline => '서로의 언어를 이어주는 공간';

  @override
  String get loginServerNotConfigured =>
      '서버 주소가 설정되지 않았어요.\n--dart-define=AUTH_API_BASE_URL 값을 넣어 주세요.';

  @override
  String get loginNetworkUnstable => '네트워크가 불안정해요.\n잠시 후 다시 시도해 주세요.';

  @override
  String get loginOAuthFailed => '소셜 로그인 인증에 실패했어요.\n다시 시도해 주세요.';

  @override
  String get loginAccountExists => '이미 가입된 계정이에요.\n기존 로그인 방식으로 시도해 주세요.';

  @override
  String get loginFailed => '로그인에 실패했어요.\n다시 한 번 시도해 주세요.';

  @override
  String get loginKakao => '카카오 로그인';

  @override
  String get loginLine => 'LINE으로 로그인';

  @override
  String get loginLineShort => 'LINE';

  @override
  String get loginGoogle => '구글로 로그인';

  @override
  String get connectTitle => '연인과 연결하세요';

  @override
  String get connectSubtitle => '초대 코드를 입력하거나 생성해서 연결할 수 있어요.';

  @override
  String get connectButton => '연결하기';

  @override
  String get connectConnecting => '연결 중...';

  @override
  String get connectOr => '또는';

  @override
  String get inviteCopyDone => '초대 코드를 복사했어요.';

  @override
  String get inviteGenerate => '초대 코드 생성';

  @override
  String get inviteGenerating => '코드 생성 중...';

  @override
  String get inviteRefresh => '새 코드 생성';

  @override
  String get inviteRefreshing => '새 코드 생성 중...';

  @override
  String get timeRemainingPrefix => '남은 시간: ';

  @override
  String get connectErrorPermission => '연결 권한이 없습니다. Firestore 규칙을 확인해 주세요.';

  @override
  String get connectErrorGeneric =>
      '처리 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.\n(로그인 상태와 Firestore 규칙을 확인해 보세요.)';

  @override
  String get codeHintEmpty => '영문/숫자 6자리 초대 코드를 입력해 주세요.';

  @override
  String get codeHintValid => '코드 형식이 올바릅니다.';

  @override
  String get codeHintInvalid => '코드 형식이 올바르지 않습니다. 6자리를 맞춰 주세요.';

  @override
  String get coupleConnectedTitle => '커플 연결 완료!';

  @override
  String get coupleConnectedSubtitle => '서로 연결되었어요!\n둘만의 공간을 즐겨보세요.';

  @override
  String get coupleInvalidCode => '유효하지 않은 코드입니다.';

  @override
  String get coupleInviteExpired => '초대 코드가 만료되었습니다.';

  @override
  String get coupleUserNotFound => '사용자 정보를 찾을 수 없습니다.';

  @override
  String get coupleConnectionInvalid => '연결 정보가 올바르지 않습니다.';

  @override
  String get coupleInviteCreateFailed => '초대 코드 생성에 실패했습니다.';

  @override
  String get coupleDisconnectNoPermission =>
      '연결 해제 권한이 없습니다. Firestore 규칙을 확인해 주세요.';

  @override
  String coupleDisconnectError(String code) {
    return '연결 해제 중 오류가 발생했습니다. ($code)';
  }

  @override
  String get homeTogetherTime => '우리가 함께한 시간';

  @override
  String homeStartDate(String date) {
    return '$date 시작';
  }

  @override
  String get homeGreetingQuestion => '오늘 서로 인사했나요?';

  @override
  String get homeStartChat => '톡 시작하기';

  @override
  String get chatTitle => '대화';

  @override
  String get chatEmpty => '아직 메시지가 없어요. 첫 인사를 보내보세요.';

  @override
  String get camera => '카메라';

  @override
  String get takePhoto => '사진 촬영';

  @override
  String get gallery => '갤러리';

  @override
  String get pickPhotosMax5 => '사진 선택, 최대 5장';

  @override
  String cameraOpenFailed(String error) {
    return '카메라를 열 수 없어요. $error';
  }

  @override
  String galleryOpenFailed(String error) {
    return '갤러리를 열 수 없어요. $error';
  }

  @override
  String photoSentCount(int count) {
    return '사진 $count장을 보냈어요.';
  }

  @override
  String get reply => '답장하기';

  @override
  String get showTranslation => '번역 보기';

  @override
  String get retranslate => '재번역';

  @override
  String get copyOriginal => '원문 복사';

  @override
  String get copyTranslation => '번역본 복사';

  @override
  String get deleteMessage => '메시지 삭제';

  @override
  String get messageCopied => '메시지를 복사했어요.';

  @override
  String get translationCopied => '번역본을 복사했어요.';

  @override
  String get deleteMessageTitle => '메시지 삭제';

  @override
  String get deleteMessageConfirm => '이 메시지를 삭제할까요?';

  @override
  String get deleteMessageDone => '메시지를 삭제했어요.';

  @override
  String get translateServerNotConfigured =>
      '첫 번역(번역 보기) 서버가 없어요. TRANSLATE_API_URL에 집 PC Gemma 주소를 넣어 주세요.';

  @override
  String get retranslateServerNotConfigured =>
      '재번역 서버가 없어요. TRANSLATE_RETRANSLATE_API_URL에 Gemini(클라우드) 주소를 넣어 주세요.';

  @override
  String get translateSheetTitle => '번역 보기';

  @override
  String get originalLabel => '원문';

  @override
  String get translationLabel => '번역';

  @override
  String get translating => '번역 중...';

  @override
  String get messageSendFailed => '메시지 전송에 실패했어요. 다시 시도해 주세요.';

  @override
  String get messageHint => '메시지를 입력하세요...';

  @override
  String get saveStarted => '저장을 시작했어요. (웹: 다운로드 폴더 · 앱: 공유 메뉴)';

  @override
  String saveFailed(String error) {
    return '저장에 실패했어요: $error';
  }

  @override
  String get closeTooltip => '닫기';

  @override
  String get downloadTooltip => '다운로드';

  @override
  String get albumNoCouple => '커플 정보가 없어요.';

  @override
  String get albumTitle => '앨범';

  @override
  String get albumAdd => '앨범 추가';

  @override
  String get albumEmptyTitle => '첫 앨범을 만들어 볼까요?';

  @override
  String get albumEmptySubtitle => '아래의 “앨범 추가” 버튼을 눌러\n추억을 저장해 보세요.';

  @override
  String get albumUntitled => '제목 없음';

  @override
  String albumPhotoCountShort(int count) {
    return '$count장';
  }

  @override
  String get albumEditTitle => '앨범 수정';

  @override
  String get albumAddTitle => '앨범 추가';

  @override
  String get albumMaxPhotos => '이 앨범에는 최대 50장까지 담을 수 있어요.';

  @override
  String albumLoadImageFailed(String error) {
    return '이미지를 불러오지 못했어요. $error';
  }

  @override
  String get albumTitleRequired => '앨범 제목을 입력해 주세요.';

  @override
  String get albumSaveButton => '저장하기';

  @override
  String get albumTitleLabel => '앨범 제목';

  @override
  String get albumMemoLabel => '메모 (선택)';

  @override
  String get albumPhotoAddDisabled => '사진 추가 불가 (최대 50장)';

  @override
  String albumPhotoAddRemaining(int count) {
    return '사진 추가 (남은 $count장)';
  }

  @override
  String get albumPreviewHint => '사진을 선택하면 여기 미리보기가 생겨요.';

  @override
  String get albumNoPhotosHint => '아직 사진이 없어요.\n편집에서 사진을 추가해 보세요.';

  @override
  String albumTotalPhotos(int count) {
    return '총 $count장';
  }

  @override
  String get coverLabel => '대표';

  @override
  String get photoTitle => '사진';

  @override
  String get setCoverImage => '대표 이미지로 설정';

  @override
  String get deletePhotoTitle => '사진 삭제';

  @override
  String get deletePhotoConfirm => '이 사진을 삭제할까요?';

  @override
  String get firstMeetDay => '처음만난날';

  @override
  String get myBirthday => '내 생일';

  @override
  String partnerBirthday(String name) {
    return '$name 생일';
  }

  @override
  String get eventAdd => '일정 추가';

  @override
  String get eventEdit => '일정 수정';

  @override
  String get eventDelete => '일정 삭제';

  @override
  String get eventNameHint => '일정 제목 입력';

  @override
  String get eventMemoHint => '메모(선택)';

  @override
  String get eventNameRequired => '일정 이름을 입력해 주세요.';

  @override
  String get yearlyEventNote => '매년 자동으로 표시되는 일정이에요.';

  @override
  String get tripEventNote => '여행 일정에서 자동으로 추가된 일정이에요.';

  @override
  String get changeDate => '날짜 변경';

  @override
  String get scheduleDeleteConfirm => '일정을 삭제할까요?';

  @override
  String get eventDeleted => '일정이 삭제되었어요.';

  @override
  String get calendarAddEvent => '일정 추가';

  @override
  String get calendarEmptyLine => '이 날짜에는 일정이 없어요.';

  @override
  String get calendarTogetherLine => '우리가 함께한 시간';

  @override
  String calendarTodayLine(String date) {
    return '오늘 · $date';
  }

  @override
  String get weekDaySun => '일';

  @override
  String get weekDayMon => '월';

  @override
  String get weekDayTue => '화';

  @override
  String get weekDayWed => '수';

  @override
  String get weekDayThu => '목';

  @override
  String get weekDayFri => '금';

  @override
  String get weekDaySat => '토';

  @override
  String get tripTitle => '여행';

  @override
  String get tripMakeNew => '여행 만들기';

  @override
  String get tripCreateTitle => '여행 만들기';

  @override
  String get tripNameLabel => '여행 이름';

  @override
  String get tripDateHint => '날짜 선택';

  @override
  String get tripFillRequired => '여행 이름과 날짜를 모두 입력해 주세요.';

  @override
  String get tripCreateAction => '여행 생성하기';

  @override
  String get tripDeleteTitle => '여행 삭제';

  @override
  String tripDeleteConfirm(String title) {
    return '\"$title\" 여행을 삭제할까요?\n(일정도 함께 사라집니다)';
  }

  @override
  String get tripEmptyTitle => '첫 여행을 만들어 볼까요?';

  @override
  String get tripEmptySubtitle =>
      '아래의 \"+ 여행 만들기\" 버튼을 눌러\n여행 이름과 날짜만 간단히 입력하면 돼요.';

  @override
  String tripLoadFailed(String error) {
    return '일정을 불러오지 못했어요.\n$error';
  }

  @override
  String get today => '오늘';

  @override
  String get planAdd => '+ 일정 추가';

  @override
  String get planAddFab => '일정 추가';

  @override
  String get planDeleted => '일정을 삭제했어요.';

  @override
  String planDeleteFailed(String error) {
    return '삭제에 실패했어요: $error';
  }

  @override
  String get planAdded => '일정을 추가했어요.';

  @override
  String get planSaved => '일정을 저장했어요.';

  @override
  String planSaveFailed(String error) {
    return '저장에 실패했어요. Firestore 규칙·네트워크를 확인해 주세요.\n$error';
  }

  @override
  String get planOpenInMaps => 'Google 지도에서 보기';

  @override
  String get planOpenMapsFailed => '지도를 열 수 없어요.';

  @override
  String get mapPickerTitle => '지도에서 위치 선택';

  @override
  String get mapDone => '완료';

  @override
  String get mapSearchHint => '장소 검색 (예: 연세대학교, 전쟁기념관)';

  @override
  String get mapPlaceLoadFailed => '장소 정보를 불러오지 못했어요.';

  @override
  String get mapHintTap => '지도를 탭하거나 위에서 장소를 검색한 뒤 [완료]를 눌러 주세요';

  @override
  String get mapHintLoading => '주소·장소 이름을 불러오는 중…';

  @override
  String get mapHintSelected => '선택됨 · [완료]를 누르면 이 내용이 일정의 장소 이름에 들어가요';

  @override
  String get planPlaceRequired => '장소 이름을 입력하거나 지도에서 위치를 선택해 주세요.';

  @override
  String get planEditHeader => '일정 수정';

  @override
  String get planAddHeader => '일정 추가';

  @override
  String get timeSelectOptional => '시간 선택(선택)';

  @override
  String get placeNameLabel => '장소 이름';

  @override
  String get placeNameHint => '예: Osaka Castle';

  @override
  String get memoOptionalLabel => '메모 (선택)';

  @override
  String get mapPickFromMap => '지도에서 위치 선택 (선택)';

  @override
  String mapPickedWithPlace(String place) {
    return '지도에서 위치 선택됨 · $place';
  }

  @override
  String get mapPickedCoordsOnly => '좌표 저장';

  @override
  String get savePlan => '저장하기';

  @override
  String get addPlan => '추가하기';

  @override
  String get deletePlan => '삭제하기';

  @override
  String get startDateScreenTitle => '처음만난날 선택';

  @override
  String get startDateQuestion => '처음만난날은 언제인가요?';

  @override
  String get startDateSubtitle => '둘이 처음 만난 특별한 날을\n기념일로 기록해 둘게요.';

  @override
  String get startDateErrorNone => '처음만난날을 선택해 주세요.';

  @override
  String get startDateErrorNoCouple => '커플 정보가 없어요. 다시 로그인해 주세요.';

  @override
  String get psNicknameQuestion => '어떻게 불러드릴까요?';

  @override
  String get psBirthdayQuestion => '생일이 언제인가요?';

  @override
  String get psLanguageQuestion => '주로 사용하는 언어는?';

  @override
  String get psLangKorean => '한국어';

  @override
  String get psLangJapanese => '일본어';

  @override
  String get psNicknameLength => '2~10자 이내로 입력해 주세요.';

  @override
  String get psBirthdayPick => '본인의 생일을 선택해 주세요.';

  @override
  String get psLanguageAccuracy => '주 언어를 선택하면 번역 기능 정확도가 올라가요.';

  @override
  String get psNicknameError => '닉네임을 2~10자로 입력해 주세요.';

  @override
  String get psBirthdaySelect => '생일을 선택해 주세요.';

  @override
  String get psAgeError => '14세 이상만 가입할 수 있어요.';

  @override
  String get psLanguageSelect => '언어를 선택해 주세요.';

  @override
  String get psInputError => '입력값을 확인해 주세요.';

  @override
  String get psConfirmError => '입력값을 다시 확인해 주세요.';

  @override
  String get psBirthdayPlaceholder => '생일 선택';

  @override
  String get psNicknameHint => '닉네임 입력';

  @override
  String get psFieldNickname => '닉네임';

  @override
  String get psFieldBirthday => '생일';

  @override
  String get psFieldLanguage => '언어';

  @override
  String get psPrevious => '이전';

  @override
  String get psNext => '다음';

  @override
  String downloadImageFailed(int code) {
    return '이미지를 받지 못했어요 (HTTP $code)';
  }

  @override
  String get unsupportedSaveImage => '이 플랫폼에서는 이미지 저장을 지원하지 않아요.';

  @override
  String get imageSaveShareText => '이미지 저장';

  @override
  String locationLatLng(String lat, String lng) {
    return '위치 $lat, $lng';
  }

  @override
  String get appInfoVersion => '버전 0.1.0';

  @override
  String get appInfoUpdateDate => '최신 업데이트: 2026.03.25';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get termsOfService => '이용약관';

  @override
  String get privacyConsentTitle => '약관 동의';

  @override
  String get privacyConsentIntro => '서비스를 이용하려면 아래에 동의해 주세요.';

  @override
  String get privacyConsentAgreeAll => '전체 동의';

  @override
  String get privacyConsentAgreePrivacy => '개인정보처리방침에 동의합니다 (필수)';

  @override
  String get privacyConsentAgreeTerms => '이용약관에 동의합니다 (필수)';

  @override
  String get privacyConsentAgreeAge => '만 14세 이상입니다 (필수)';

  @override
  String get privacyConsentAgreeMarketing => '마케팅 정보 수신에 동의합니다 (선택)';

  @override
  String get privacyConsentViewDocument => '전문 보기';

  @override
  String get privacyConsentContinue => '동의하고 계속하기';

  @override
  String get privacyConsentSaveError => '저장하지 못했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get openSourceLicenses => '오픈소스 라이선스';

  @override
  String get appInfoDeveloper => '개발';

  @override
  String get appInfoDeveloperName => 'IF App Team';

  @override
  String get appInfoDescription => '서로의 언어를 이어주는 커플 앱';

  @override
  String get contact => '문의하기';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutConfirmTitle => '로그아웃';

  @override
  String get logoutConfirmBody => '정말 로그아웃하시겠어요?';

  @override
  String get notificationAll => '알림';

  @override
  String get notificationAllSubtitle => '앱의 모든 알림을 받습니다.';

  @override
  String get notificationMessage => '메시지 알림';

  @override
  String get notificationMessageSubtitle => '메시지를 받으면 알림을 받습니다.';

  @override
  String get notificationAlbum => '앨범 알림';

  @override
  String get notificationAlbumSubtitle => '상대가 앨범에 사진을 올리면 알림을 받습니다.';

  @override
  String get notificationAnniversary => '기념일 알림';

  @override
  String get notificationAnniversarySubtitle =>
      '커플 시작일(매년 같은 날)에 설정한 시각에 알림을 받습니다.';

  @override
  String get notificationSchedule => '일정 알림';

  @override
  String get notificationScheduleSubtitle =>
      '캘린더 일정이 있는 날, 아래에서 설정한 시각에 알림을 받습니다.';

  @override
  String get notificationTimeTitle => '알림 시간';

  @override
  String get timeAm => '오전';

  @override
  String get timePm => '오후';

  @override
  String get uploadTimeout => '시간이 너무 오래 걸려 중단했어요. 네트워크·CORS·사진 용량을 확인해 주세요.';

  @override
  String uploadPermissionDenied(String webCorsLine) {
    return '권한이 없어 업로드할 수 없어요.\n• Firebase 콘솔 → Storage·Firestore 규칙이 배포됐는지\n• 내 계정 Firestore users 문서에 coupleId가 있는지\n$webCorsLine자세한 내용: docs/firebase_storage_이미지.md';
  }

  @override
  String get uploadLoginRequired => '로그인이 필요해요. 다시 로그인한 뒤 시도해 주세요.';

  @override
  String get uploadCanceled => '업로드가 취소되었어요.';

  @override
  String uploadFailedWithMessage(String code, String message) {
    return '업로드 실패 ($code): $message';
  }

  @override
  String uploadFailedCodeOnly(String code) {
    return '업로드 실패 ($code)';
  }

  @override
  String get uploadBrowserBlocked =>
      '브라우저에서 업로드가 막혔을 수 있어요.\nFirebase Storage 버킷에 CORS를 설정해 주세요. (프로젝트 루트 storage-cors.json · docs 참고)';

  @override
  String get albumDownloadUrlTimeout =>
      '다운로드 URL을 받는 데 시간이 초과됐어요. 네트워크를 확인해 주세요.';

  @override
  String get albumUploadTimeoutBody =>
      '사진 업로드가 3분 안에 끝나지 않았어요.\n• Wi‑Fi/네트워크 확인\n• 웹: Storage CORS·버킷 이름(if-app-b2854.firebasestorage.app) 확인\n• 사진 용량 줄이기';

  @override
  String get translateEmpty => '번역할 텍스트가 비어 있습니다.';

  @override
  String translateTooLong(int max) {
    return '번역은 $max자까지 가능해요.';
  }

  @override
  String get translateRateLimit => '요청 한도를 초과했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get translateBadRequest => '잘못된 요청이에요.';

  @override
  String translateServerError(int code) {
    return '번역 서버 호출 실패 ($code)';
  }

  @override
  String get translateJsonError => '번역 서버 응답이 JSON이 아닙니다. (HTML/에러 페이지일 수 있음)';

  @override
  String get translateNoField => '번역 서버 응답에 translated 값이 없습니다.';

  @override
  String get profilePartnerNicknameLabel => '연인 닉네임';

  @override
  String get profileEditTitleBar => '프로필 편집';

  @override
  String get notificationTitleBar => '알림 설정';

  @override
  String get albumDetailTitleBar => '앨범';

  @override
  String get albumEditTitleBar => '앨범 수정';

  @override
  String get albumAddTitleBar => '앨범 추가';

  @override
  String get mapPickerTitleBar => '지도에서 위치 선택';

  @override
  String get photoViewerTitleBar => '사진';

  @override
  String get appInfoTitleBar => '앱 정보';

  @override
  String get webCorsBullet => '• 웹: Storage 버킷 CORS 설정 (storage-cors.json)\n';
}
