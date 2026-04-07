import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ja'),
    Locale('ko')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'IF App'**
  String get appTitle;

  /// No description provided for @splashPreparingIf.
  ///
  /// In ko, this message translates to:
  /// **'IF를 준비하는 중이에요...'**
  String get splashPreparingIf;

  /// No description provided for @splashCheckingLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인 상태를 확인하고 있어요...'**
  String get splashCheckingLogin;

  /// No description provided for @splashLoadingProfile.
  ///
  /// In ko, this message translates to:
  /// **'내 정보를 불러오고 있어요...'**
  String get splashLoadingProfile;

  /// No description provided for @splashDefault.
  ///
  /// In ko, this message translates to:
  /// **'앱을 준비하고 있어요...'**
  String get splashDefault;

  /// No description provided for @appLoadErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱을 불러오는 데 문제가 생겼어요'**
  String get appLoadErrorTitle;

  /// No description provided for @appLoadErrorBody.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인한 뒤\n앱을 다시 실행해 주세요.'**
  String get appLoadErrorBody;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @profileEdit.
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get profileEdit;

  /// No description provided for @notificationSettings.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notificationSettings;

  /// No description provided for @disconnect.
  ///
  /// In ko, this message translates to:
  /// **'연결 해제'**
  String get disconnect;

  /// No description provided for @disconnecting.
  ///
  /// In ko, this message translates to:
  /// **'연결 해제 중...'**
  String get disconnecting;

  /// No description provided for @disconnectConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'정말 연결을 해제하시겠어요?'**
  String get disconnectConfirmTitle;

  /// No description provided for @disconnectConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'연결만 끊기며 채팅·앨범 등 데이터는 서버에 남습니다. 90일 안에 다시 로그인해 이전 연결을 복구할 수 있어요. 해제 후 로그아웃됩니다.'**
  String get disconnectConfirmBody;

  /// No description provided for @restoreCoupleTitle.
  ///
  /// In ko, this message translates to:
  /// **'이전 연결 복구'**
  String get restoreCoupleTitle;

  /// No description provided for @restoreCoupleSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'상대도 로그인한 뒤, 둘 다 90일 안에 여기서 복구를 눌러야 다시 연결돼요.'**
  String get restoreCoupleSubtitle;

  /// No description provided for @restoreCoupleButton.
  ///
  /// In ko, this message translates to:
  /// **'이전 연결로 다시 연결'**
  String get restoreCoupleButton;

  /// No description provided for @restoreCoupleRestoring.
  ///
  /// In ko, this message translates to:
  /// **'복구 중…'**
  String get restoreCoupleRestoring;

  /// No description provided for @restoreErrorExpired.
  ///
  /// In ko, this message translates to:
  /// **'복구 기간(90일)이 지났어요.'**
  String get restoreErrorExpired;

  /// No description provided for @restoreErrorPartnerNotReady.
  ///
  /// In ko, this message translates to:
  /// **'상대가 아직 로그인하지 않았거나, 복구 조건이 맞지 않아요.'**
  String get restoreErrorPartnerNotReady;

  /// No description provided for @restoreErrorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'복구할 수 없어요. 잠시 후 다시 시도해 주세요.'**
  String get restoreErrorGeneric;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In ko, this message translates to:
  /// **'내 계정 정보가 삭제되고 상대는 연결이 끊겨요. 두 분 모두 탈퇴하면 채팅·앨범 등 커플 데이터가 모두 삭제됩니다.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴하기'**
  String get accountDeleteConfirm;

  /// No description provided for @accountDeleting.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 처리 중…'**
  String get accountDeleting;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @appInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get appInfo;

  /// No description provided for @partnerDefault.
  ///
  /// In ko, this message translates to:
  /// **'연인'**
  String get partnerDefault;

  /// No description provided for @statusDefaultEmpty.
  ///
  /// In ko, this message translates to:
  /// **'서로의 일상을 함께 채워요.'**
  String get statusDefaultEmpty;

  /// No description provided for @languageSettings.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get languageSettings;

  /// No description provided for @languageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageJapanese.
  ///
  /// In ko, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @tabHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get tabHome;

  /// No description provided for @tabChat.
  ///
  /// In ko, this message translates to:
  /// **'대화'**
  String get tabChat;

  /// No description provided for @tabTrip.
  ///
  /// In ko, this message translates to:
  /// **'여행'**
  String get tabTrip;

  /// No description provided for @tabCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get tabCalendar;

  /// No description provided for @tabAlbum.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get tabAlbum;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In ko, this message translates to:
  /// **'저장 중...'**
  String get saving;

  /// No description provided for @done.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get done;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @confirming.
  ///
  /// In ko, this message translates to:
  /// **'확인 중...'**
  String get confirming;

  /// No description provided for @loginTagline.
  ///
  /// In ko, this message translates to:
  /// **'서로의 언어를 이어주는 공간'**
  String get loginTagline;

  /// No description provided for @loginServerNotConfigured.
  ///
  /// In ko, this message translates to:
  /// **'서버 주소가 설정되지 않았어요.\n--dart-define=AUTH_API_BASE_URL 값을 넣어 주세요.'**
  String get loginServerNotConfigured;

  /// No description provided for @loginNetworkUnstable.
  ///
  /// In ko, this message translates to:
  /// **'네트워크가 불안정해요.\n잠시 후 다시 시도해 주세요.'**
  String get loginNetworkUnstable;

  /// No description provided for @loginOAuthFailed.
  ///
  /// In ko, this message translates to:
  /// **'소셜 로그인 인증에 실패했어요.\n다시 시도해 주세요.'**
  String get loginOAuthFailed;

  /// No description provided for @loginAccountExists.
  ///
  /// In ko, this message translates to:
  /// **'이미 가입된 계정이에요.\n기존 로그인 방식으로 시도해 주세요.'**
  String get loginAccountExists;

  /// No description provided for @loginFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인에 실패했어요.\n다시 한 번 시도해 주세요.'**
  String get loginFailed;

  /// No description provided for @loginKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오 로그인'**
  String get loginKakao;

  /// No description provided for @loginLine.
  ///
  /// In ko, this message translates to:
  /// **'LINE으로 로그인'**
  String get loginLine;

  /// No description provided for @loginLineShort.
  ///
  /// In ko, this message translates to:
  /// **'LINE'**
  String get loginLineShort;

  /// No description provided for @loginGoogle.
  ///
  /// In ko, this message translates to:
  /// **'구글로 로그인'**
  String get loginGoogle;

  /// No description provided for @loginApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 로그인'**
  String get loginApple;

  /// No description provided for @connectTitle.
  ///
  /// In ko, this message translates to:
  /// **'연인과 연결하세요'**
  String get connectTitle;

  /// No description provided for @connectSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 입력하거나 생성해서 연결할 수 있어요.'**
  String get connectSubtitle;

  /// No description provided for @connectButton.
  ///
  /// In ko, this message translates to:
  /// **'연결하기'**
  String get connectButton;

  /// No description provided for @connectConnecting.
  ///
  /// In ko, this message translates to:
  /// **'연결 중...'**
  String get connectConnecting;

  /// No description provided for @connectOr.
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get connectOr;

  /// No description provided for @inviteCopyDone.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 복사했어요.'**
  String get inviteCopyDone;

  /// No description provided for @inviteGenerate.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드 생성'**
  String get inviteGenerate;

  /// No description provided for @inviteGenerating.
  ///
  /// In ko, this message translates to:
  /// **'코드 생성 중...'**
  String get inviteGenerating;

  /// No description provided for @inviteRefresh.
  ///
  /// In ko, this message translates to:
  /// **'새 코드 생성'**
  String get inviteRefresh;

  /// No description provided for @inviteRefreshing.
  ///
  /// In ko, this message translates to:
  /// **'새 코드 생성 중...'**
  String get inviteRefreshing;

  /// No description provided for @timeRemainingPrefix.
  ///
  /// In ko, this message translates to:
  /// **'남은 시간: '**
  String get timeRemainingPrefix;

  /// No description provided for @connectErrorPermission.
  ///
  /// In ko, this message translates to:
  /// **'연결 권한이 없습니다. Firestore 규칙을 확인해 주세요.'**
  String get connectErrorPermission;

  /// No description provided for @connectErrorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'처리 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.\n(로그인 상태와 Firestore 규칙을 확인해 보세요.)'**
  String get connectErrorGeneric;

  /// No description provided for @codeHintEmpty.
  ///
  /// In ko, this message translates to:
  /// **'영문/숫자 6자리 초대 코드를 입력해 주세요.'**
  String get codeHintEmpty;

  /// No description provided for @codeHintValid.
  ///
  /// In ko, this message translates to:
  /// **'코드 형식이 올바릅니다.'**
  String get codeHintValid;

  /// No description provided for @codeHintInvalid.
  ///
  /// In ko, this message translates to:
  /// **'코드 형식이 올바르지 않습니다. 6자리를 맞춰 주세요.'**
  String get codeHintInvalid;

  /// No description provided for @coupleConnectedTitle.
  ///
  /// In ko, this message translates to:
  /// **'커플 연결 완료!'**
  String get coupleConnectedTitle;

  /// No description provided for @coupleConnectedSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'서로 연결되었어요!\n둘만의 공간을 즐겨보세요.'**
  String get coupleConnectedSubtitle;

  /// No description provided for @coupleInvalidCode.
  ///
  /// In ko, this message translates to:
  /// **'유효하지 않은 코드입니다.'**
  String get coupleInvalidCode;

  /// No description provided for @coupleInviteExpired.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드가 만료되었습니다.'**
  String get coupleInviteExpired;

  /// No description provided for @coupleUserNotFound.
  ///
  /// In ko, this message translates to:
  /// **'사용자 정보를 찾을 수 없습니다.'**
  String get coupleUserNotFound;

  /// No description provided for @coupleConnectionInvalid.
  ///
  /// In ko, this message translates to:
  /// **'연결 정보가 올바르지 않습니다.'**
  String get coupleConnectionInvalid;

  /// No description provided for @coupleInviteCreateFailed.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드 생성에 실패했습니다.'**
  String get coupleInviteCreateFailed;

  /// No description provided for @coupleDisconnectNoPermission.
  ///
  /// In ko, this message translates to:
  /// **'연결 해제 권한이 없습니다. Firestore 규칙을 확인해 주세요.'**
  String get coupleDisconnectNoPermission;

  /// No description provided for @coupleDisconnectError.
  ///
  /// In ko, this message translates to:
  /// **'연결 해제 중 오류가 발생했습니다. ({code})'**
  String coupleDisconnectError(String code);

  /// No description provided for @homeTogetherTime.
  ///
  /// In ko, this message translates to:
  /// **'우리가 함께한 시간'**
  String get homeTogetherTime;

  /// No description provided for @homeStartDate.
  ///
  /// In ko, this message translates to:
  /// **'{date} 시작'**
  String homeStartDate(String date);

  /// No description provided for @homeGreetingQuestion.
  ///
  /// In ko, this message translates to:
  /// **'오늘 서로 인사했나요?'**
  String get homeGreetingQuestion;

  /// No description provided for @homeStartChat.
  ///
  /// In ko, this message translates to:
  /// **'톡 시작하기'**
  String get homeStartChat;

  /// No description provided for @chatTitle.
  ///
  /// In ko, this message translates to:
  /// **'대화'**
  String get chatTitle;

  /// No description provided for @chatEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 메시지가 없어요. 첫 인사를 보내보세요.'**
  String get chatEmpty;

  /// No description provided for @camera.
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get camera;

  /// No description provided for @takePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 촬영'**
  String get takePhoto;

  /// No description provided for @gallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리'**
  String get gallery;

  /// No description provided for @pickPhotosMax5.
  ///
  /// In ko, this message translates to:
  /// **'사진 선택, 최대 5장'**
  String get pickPhotosMax5;

  /// No description provided for @cameraOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 열 수 없어요. {error}'**
  String cameraOpenFailed(String error);

  /// No description provided for @galleryOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'갤러리를 열 수 없어요. {error}'**
  String galleryOpenFailed(String error);

  /// No description provided for @photoSentCount.
  ///
  /// In ko, this message translates to:
  /// **'사진 {count}장을 보냈어요.'**
  String photoSentCount(int count);

  /// No description provided for @reply.
  ///
  /// In ko, this message translates to:
  /// **'답장하기'**
  String get reply;

  /// No description provided for @showTranslation.
  ///
  /// In ko, this message translates to:
  /// **'번역 보기'**
  String get showTranslation;

  /// No description provided for @retranslate.
  ///
  /// In ko, this message translates to:
  /// **'재번역'**
  String get retranslate;

  /// No description provided for @copyOriginal.
  ///
  /// In ko, this message translates to:
  /// **'원문 복사'**
  String get copyOriginal;

  /// No description provided for @copyTranslation.
  ///
  /// In ko, this message translates to:
  /// **'번역본 복사'**
  String get copyTranslation;

  /// No description provided for @deleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'메시지 삭제'**
  String get deleteMessage;

  /// No description provided for @messageCopied.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 복사했어요.'**
  String get messageCopied;

  /// No description provided for @translationCopied.
  ///
  /// In ko, this message translates to:
  /// **'번역본을 복사했어요.'**
  String get translationCopied;

  /// No description provided for @deleteMessageTitle.
  ///
  /// In ko, this message translates to:
  /// **'메시지 삭제'**
  String get deleteMessageTitle;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 메시지를 삭제할까요?'**
  String get deleteMessageConfirm;

  /// No description provided for @deleteMessageDone.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 삭제했어요.'**
  String get deleteMessageDone;

  /// No description provided for @translateServerNotConfigured.
  ///
  /// In ko, this message translates to:
  /// **'첫 번역(번역 보기) 서버가 없어요. TRANSLATE_API_URL에 집 PC Gemma 주소를 넣어 주세요.'**
  String get translateServerNotConfigured;

  /// No description provided for @retranslateServerNotConfigured.
  ///
  /// In ko, this message translates to:
  /// **'재번역 서버가 없어요. TRANSLATE_RETRANSLATE_API_URL에 Gemini(클라우드) 주소를 넣어 주세요.'**
  String get retranslateServerNotConfigured;

  /// No description provided for @translateSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'번역 보기'**
  String get translateSheetTitle;

  /// No description provided for @originalLabel.
  ///
  /// In ko, this message translates to:
  /// **'원문'**
  String get originalLabel;

  /// No description provided for @translationLabel.
  ///
  /// In ko, this message translates to:
  /// **'번역'**
  String get translationLabel;

  /// No description provided for @translating.
  ///
  /// In ko, this message translates to:
  /// **'번역 중...'**
  String get translating;

  /// No description provided for @messageSendFailed.
  ///
  /// In ko, this message translates to:
  /// **'메시지 전송에 실패했어요. 다시 시도해 주세요.'**
  String get messageSendFailed;

  /// No description provided for @messageHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 입력하세요...'**
  String get messageHint;

  /// No description provided for @saveStarted.
  ///
  /// In ko, this message translates to:
  /// **'저장을 시작했어요. (웹: 다운로드 폴더 · 앱: 공유 메뉴)'**
  String get saveStarted;

  /// No description provided for @saveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장에 실패했어요: {error}'**
  String saveFailed(String error);

  /// No description provided for @closeTooltip.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get closeTooltip;

  /// No description provided for @downloadTooltip.
  ///
  /// In ko, this message translates to:
  /// **'다운로드'**
  String get downloadTooltip;

  /// No description provided for @albumNoCouple.
  ///
  /// In ko, this message translates to:
  /// **'커플 정보가 없어요.'**
  String get albumNoCouple;

  /// No description provided for @albumTitle.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get albumTitle;

  /// No description provided for @albumAdd.
  ///
  /// In ko, this message translates to:
  /// **'앨범 추가'**
  String get albumAdd;

  /// No description provided for @albumEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'첫 앨범을 만들어 볼까요?'**
  String get albumEmptyTitle;

  /// No description provided for @albumEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'아래의 “앨범 추가” 버튼을 눌러\n추억을 저장해 보세요.'**
  String get albumEmptySubtitle;

  /// No description provided for @albumUntitled.
  ///
  /// In ko, this message translates to:
  /// **'제목 없음'**
  String get albumUntitled;

  /// No description provided for @albumPhotoCountShort.
  ///
  /// In ko, this message translates to:
  /// **'{count}장'**
  String albumPhotoCountShort(int count);

  /// No description provided for @albumEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'앨범 수정'**
  String get albumEditTitle;

  /// No description provided for @albumAddTitle.
  ///
  /// In ko, this message translates to:
  /// **'앨범 추가'**
  String get albumAddTitle;

  /// No description provided for @albumMaxPhotos.
  ///
  /// In ko, this message translates to:
  /// **'이 앨범에는 최대 50장까지 담을 수 있어요.'**
  String get albumMaxPhotos;

  /// No description provided for @albumLoadImageFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 불러오지 못했어요. {error}'**
  String albumLoadImageFailed(String error);

  /// No description provided for @albumTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'앨범 제목을 입력해 주세요.'**
  String get albumTitleRequired;

  /// No description provided for @albumSaveButton.
  ///
  /// In ko, this message translates to:
  /// **'저장하기'**
  String get albumSaveButton;

  /// No description provided for @albumTitleLabel.
  ///
  /// In ko, this message translates to:
  /// **'앨범 제목'**
  String get albumTitleLabel;

  /// No description provided for @albumMemoLabel.
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get albumMemoLabel;

  /// No description provided for @albumPhotoAddDisabled.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가 불가 (최대 50장)'**
  String get albumPhotoAddDisabled;

  /// No description provided for @albumPhotoAddRemaining.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가 (남은 {count}장)'**
  String albumPhotoAddRemaining(int count);

  /// No description provided for @albumPreviewHint.
  ///
  /// In ko, this message translates to:
  /// **'사진을 선택하면 여기 미리보기가 생겨요.'**
  String get albumPreviewHint;

  /// No description provided for @albumNoPhotosHint.
  ///
  /// In ko, this message translates to:
  /// **'아직 사진이 없어요.\n편집에서 사진을 추가해 보세요.'**
  String get albumNoPhotosHint;

  /// No description provided for @albumTotalPhotos.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}장'**
  String albumTotalPhotos(int count);

  /// No description provided for @coverLabel.
  ///
  /// In ko, this message translates to:
  /// **'대표'**
  String get coverLabel;

  /// No description provided for @photoTitle.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get photoTitle;

  /// No description provided for @setCoverImage.
  ///
  /// In ko, this message translates to:
  /// **'대표 이미지로 설정'**
  String get setCoverImage;

  /// No description provided for @deletePhotoTitle.
  ///
  /// In ko, this message translates to:
  /// **'사진 삭제'**
  String get deletePhotoTitle;

  /// No description provided for @deletePhotoConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 사진을 삭제할까요?'**
  String get deletePhotoConfirm;

  /// No description provided for @firstMeetDay.
  ///
  /// In ko, this message translates to:
  /// **'처음만난날'**
  String get firstMeetDay;

  /// No description provided for @myBirthday.
  ///
  /// In ko, this message translates to:
  /// **'내 생일'**
  String get myBirthday;

  /// No description provided for @partnerBirthday.
  ///
  /// In ko, this message translates to:
  /// **'{name} 생일'**
  String partnerBirthday(String name);

  /// No description provided for @eventAdd.
  ///
  /// In ko, this message translates to:
  /// **'일정 추가'**
  String get eventAdd;

  /// No description provided for @eventEdit.
  ///
  /// In ko, this message translates to:
  /// **'일정 수정'**
  String get eventEdit;

  /// No description provided for @eventDelete.
  ///
  /// In ko, this message translates to:
  /// **'일정 삭제'**
  String get eventDelete;

  /// No description provided for @eventNameHint.
  ///
  /// In ko, this message translates to:
  /// **'일정 제목 입력'**
  String get eventNameHint;

  /// No description provided for @eventMemoHint.
  ///
  /// In ko, this message translates to:
  /// **'메모(선택)'**
  String get eventMemoHint;

  /// No description provided for @eventNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'일정 이름을 입력해 주세요.'**
  String get eventNameRequired;

  /// No description provided for @yearlyEventNote.
  ///
  /// In ko, this message translates to:
  /// **'매년 자동으로 표시되는 일정이에요.'**
  String get yearlyEventNote;

  /// No description provided for @tripEventNote.
  ///
  /// In ko, this message translates to:
  /// **'여행 일정에서 자동으로 추가된 일정이에요.'**
  String get tripEventNote;

  /// No description provided for @changeDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜 변경'**
  String get changeDate;

  /// No description provided for @scheduleDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'일정을 삭제할까요?'**
  String get scheduleDeleteConfirm;

  /// No description provided for @eventDeleted.
  ///
  /// In ko, this message translates to:
  /// **'일정이 삭제되었어요.'**
  String get eventDeleted;

  /// No description provided for @calendarAddEvent.
  ///
  /// In ko, this message translates to:
  /// **'일정 추가'**
  String get calendarAddEvent;

  /// No description provided for @calendarEmptyLine.
  ///
  /// In ko, this message translates to:
  /// **'이 날짜에는 일정이 없어요.'**
  String get calendarEmptyLine;

  /// No description provided for @calendarTogetherLine.
  ///
  /// In ko, this message translates to:
  /// **'우리가 함께한 시간'**
  String get calendarTogetherLine;

  /// No description provided for @calendarTodayLine.
  ///
  /// In ko, this message translates to:
  /// **'오늘 · {date}'**
  String calendarTodayLine(String date);

  /// No description provided for @weekDaySun.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get weekDaySun;

  /// No description provided for @weekDayMon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get weekDayMon;

  /// No description provided for @weekDayTue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get weekDayTue;

  /// No description provided for @weekDayWed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get weekDayWed;

  /// No description provided for @weekDayThu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get weekDayThu;

  /// No description provided for @weekDayFri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get weekDayFri;

  /// No description provided for @weekDaySat.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get weekDaySat;

  /// No description provided for @tripTitle.
  ///
  /// In ko, this message translates to:
  /// **'여행'**
  String get tripTitle;

  /// No description provided for @tripMakeNew.
  ///
  /// In ko, this message translates to:
  /// **'여행 만들기'**
  String get tripMakeNew;

  /// No description provided for @tripCreateTitle.
  ///
  /// In ko, this message translates to:
  /// **'여행 만들기'**
  String get tripCreateTitle;

  /// No description provided for @tripNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'여행 이름'**
  String get tripNameLabel;

  /// No description provided for @tripDateHint.
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get tripDateHint;

  /// No description provided for @tripFillRequired.
  ///
  /// In ko, this message translates to:
  /// **'여행 이름과 날짜를 모두 입력해 주세요.'**
  String get tripFillRequired;

  /// No description provided for @tripCreateAction.
  ///
  /// In ko, this message translates to:
  /// **'여행 생성하기'**
  String get tripCreateAction;

  /// No description provided for @tripDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'여행 삭제'**
  String get tripDeleteTitle;

  /// No description provided for @tripDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 여행을 삭제할까요?\n(일정도 함께 사라집니다)'**
  String tripDeleteConfirm(String title);

  /// No description provided for @tripEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'첫 여행을 만들어 볼까요?'**
  String get tripEmptyTitle;

  /// No description provided for @tripEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'아래의 \"+ 여행 만들기\" 버튼을 눌러\n여행 이름과 날짜만 간단히 입력하면 돼요.'**
  String get tripEmptySubtitle;

  /// No description provided for @tripLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'일정을 불러오지 못했어요.\n{error}'**
  String tripLoadFailed(String error);

  /// No description provided for @today.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get today;

  /// No description provided for @planAdd.
  ///
  /// In ko, this message translates to:
  /// **'+ 일정 추가'**
  String get planAdd;

  /// No description provided for @planAddFab.
  ///
  /// In ko, this message translates to:
  /// **'일정 추가'**
  String get planAddFab;

  /// No description provided for @planDeleted.
  ///
  /// In ko, this message translates to:
  /// **'일정을 삭제했어요.'**
  String get planDeleted;

  /// No description provided for @planDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제에 실패했어요: {error}'**
  String planDeleteFailed(String error);

  /// No description provided for @planAdded.
  ///
  /// In ko, this message translates to:
  /// **'일정을 추가했어요.'**
  String get planAdded;

  /// No description provided for @planSaved.
  ///
  /// In ko, this message translates to:
  /// **'일정을 저장했어요.'**
  String get planSaved;

  /// No description provided for @planSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장에 실패했어요. Firestore 규칙·네트워크를 확인해 주세요.\n{error}'**
  String planSaveFailed(String error);

  /// No description provided for @planOpenInMaps.
  ///
  /// In ko, this message translates to:
  /// **'Google 지도에서 보기'**
  String get planOpenInMaps;

  /// No description provided for @planOpenMapsFailed.
  ///
  /// In ko, this message translates to:
  /// **'지도를 열 수 없어요.'**
  String get planOpenMapsFailed;

  /// No description provided for @mapPickerTitle.
  ///
  /// In ko, this message translates to:
  /// **'지도에서 위치 선택'**
  String get mapPickerTitle;

  /// No description provided for @mapDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get mapDone;

  /// No description provided for @mapSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'장소 검색 (예: 연세대학교, 전쟁기념관)'**
  String get mapSearchHint;

  /// No description provided for @mapPlaceLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'장소 정보를 불러오지 못했어요.'**
  String get mapPlaceLoadFailed;

  /// No description provided for @mapHintTap.
  ///
  /// In ko, this message translates to:
  /// **'지도를 탭하거나 위에서 장소를 검색한 뒤 [완료]를 눌러 주세요'**
  String get mapHintTap;

  /// No description provided for @mapHintLoading.
  ///
  /// In ko, this message translates to:
  /// **'주소·장소 이름을 불러오는 중…'**
  String get mapHintLoading;

  /// No description provided for @mapHintSelected.
  ///
  /// In ko, this message translates to:
  /// **'선택됨 · [완료]를 누르면 이 내용이 일정의 장소 이름에 들어가요'**
  String get mapHintSelected;

  /// No description provided for @planPlaceRequired.
  ///
  /// In ko, this message translates to:
  /// **'장소 이름을 입력하거나 지도에서 위치를 선택해 주세요.'**
  String get planPlaceRequired;

  /// No description provided for @planEditHeader.
  ///
  /// In ko, this message translates to:
  /// **'일정 수정'**
  String get planEditHeader;

  /// No description provided for @planAddHeader.
  ///
  /// In ko, this message translates to:
  /// **'일정 추가'**
  String get planAddHeader;

  /// No description provided for @timeSelectOptional.
  ///
  /// In ko, this message translates to:
  /// **'시간 선택(선택)'**
  String get timeSelectOptional;

  /// No description provided for @placeNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'장소 이름'**
  String get placeNameLabel;

  /// No description provided for @placeNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: Osaka Castle'**
  String get placeNameHint;

  /// No description provided for @memoOptionalLabel.
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get memoOptionalLabel;

  /// No description provided for @mapPickFromMap.
  ///
  /// In ko, this message translates to:
  /// **'지도에서 위치 선택 (선택)'**
  String get mapPickFromMap;

  /// No description provided for @mapPickedWithPlace.
  ///
  /// In ko, this message translates to:
  /// **'지도에서 위치 선택됨 · {place}'**
  String mapPickedWithPlace(String place);

  /// No description provided for @mapPickedCoordsOnly.
  ///
  /// In ko, this message translates to:
  /// **'좌표 저장'**
  String get mapPickedCoordsOnly;

  /// No description provided for @savePlan.
  ///
  /// In ko, this message translates to:
  /// **'저장하기'**
  String get savePlan;

  /// No description provided for @addPlan.
  ///
  /// In ko, this message translates to:
  /// **'추가하기'**
  String get addPlan;

  /// No description provided for @deletePlan.
  ///
  /// In ko, this message translates to:
  /// **'삭제하기'**
  String get deletePlan;

  /// No description provided for @startDateScreenTitle.
  ///
  /// In ko, this message translates to:
  /// **'처음만난날 선택'**
  String get startDateScreenTitle;

  /// No description provided for @startDateQuestion.
  ///
  /// In ko, this message translates to:
  /// **'처음만난날은 언제인가요?'**
  String get startDateQuestion;

  /// No description provided for @startDateSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'둘이 처음 만난 특별한 날을\n기념일로 기록해 둘게요.'**
  String get startDateSubtitle;

  /// No description provided for @startDateErrorNone.
  ///
  /// In ko, this message translates to:
  /// **'처음만난날을 선택해 주세요.'**
  String get startDateErrorNone;

  /// No description provided for @startDateErrorNoCouple.
  ///
  /// In ko, this message translates to:
  /// **'커플 정보가 없어요. 다시 로그인해 주세요.'**
  String get startDateErrorNoCouple;

  /// No description provided for @psNicknameQuestion.
  ///
  /// In ko, this message translates to:
  /// **'어떻게 불러드릴까요?'**
  String get psNicknameQuestion;

  /// No description provided for @psBirthdayQuestion.
  ///
  /// In ko, this message translates to:
  /// **'생일이 언제인가요?'**
  String get psBirthdayQuestion;

  /// No description provided for @psLanguageQuestion.
  ///
  /// In ko, this message translates to:
  /// **'주로 사용하는 언어는?'**
  String get psLanguageQuestion;

  /// No description provided for @psLangKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get psLangKorean;

  /// No description provided for @psLangJapanese.
  ///
  /// In ko, this message translates to:
  /// **'일본어'**
  String get psLangJapanese;

  /// No description provided for @psNicknameLength.
  ///
  /// In ko, this message translates to:
  /// **'2~10자 이내로 입력해 주세요.'**
  String get psNicknameLength;

  /// No description provided for @psBirthdayPick.
  ///
  /// In ko, this message translates to:
  /// **'본인의 생일을 선택해 주세요.'**
  String get psBirthdayPick;

  /// No description provided for @psLanguageAccuracy.
  ///
  /// In ko, this message translates to:
  /// **'주 언어를 선택하면 번역 기능 정확도가 올라가요.'**
  String get psLanguageAccuracy;

  /// No description provided for @psNicknameError.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 2~10자로 입력해 주세요.'**
  String get psNicknameError;

  /// No description provided for @psBirthdaySelect.
  ///
  /// In ko, this message translates to:
  /// **'생일을 선택해 주세요.'**
  String get psBirthdaySelect;

  /// No description provided for @psAgeError.
  ///
  /// In ko, this message translates to:
  /// **'14세 이상만 가입할 수 있어요.'**
  String get psAgeError;

  /// No description provided for @psLanguageSelect.
  ///
  /// In ko, this message translates to:
  /// **'언어를 선택해 주세요.'**
  String get psLanguageSelect;

  /// No description provided for @psInputError.
  ///
  /// In ko, this message translates to:
  /// **'입력값을 확인해 주세요.'**
  String get psInputError;

  /// No description provided for @psConfirmError.
  ///
  /// In ko, this message translates to:
  /// **'입력값을 다시 확인해 주세요.'**
  String get psConfirmError;

  /// No description provided for @psBirthdayPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'생일 선택'**
  String get psBirthdayPlaceholder;

  /// No description provided for @psNicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 입력'**
  String get psNicknameHint;

  /// No description provided for @psFieldNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get psFieldNickname;

  /// No description provided for @psFieldBirthday.
  ///
  /// In ko, this message translates to:
  /// **'생일'**
  String get psFieldBirthday;

  /// No description provided for @psFieldLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get psFieldLanguage;

  /// No description provided for @psPrevious.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get psPrevious;

  /// No description provided for @psNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get psNext;

  /// No description provided for @downloadImageFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 받지 못했어요 (HTTP {code})'**
  String downloadImageFailed(int code);

  /// No description provided for @unsupportedSaveImage.
  ///
  /// In ko, this message translates to:
  /// **'이 플랫폼에서는 이미지 저장을 지원하지 않아요.'**
  String get unsupportedSaveImage;

  /// No description provided for @imageSaveShareText.
  ///
  /// In ko, this message translates to:
  /// **'이미지 저장'**
  String get imageSaveShareText;

  /// No description provided for @locationLatLng.
  ///
  /// In ko, this message translates to:
  /// **'위치 {lat}, {lng}'**
  String locationLatLng(String lat, String lng);

  /// No description provided for @appInfoVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 0.1.0'**
  String get appInfoVersion;

  /// No description provided for @appInfoUpdateDate.
  ///
  /// In ko, this message translates to:
  /// **'최신 업데이트: 2026.03.25'**
  String get appInfoUpdateDate;

  /// No description provided for @privacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get termsOfService;

  /// No description provided for @privacyConsentTitle.
  ///
  /// In ko, this message translates to:
  /// **'약관 동의'**
  String get privacyConsentTitle;

  /// No description provided for @privacyConsentIntro.
  ///
  /// In ko, this message translates to:
  /// **'서비스를 이용하려면 아래에 동의해 주세요.'**
  String get privacyConsentIntro;

  /// No description provided for @privacyConsentAgreeAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 동의'**
  String get privacyConsentAgreeAll;

  /// No description provided for @privacyConsentAgreePrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침에 동의합니다 (필수)'**
  String get privacyConsentAgreePrivacy;

  /// No description provided for @privacyConsentAgreeTerms.
  ///
  /// In ko, this message translates to:
  /// **'이용약관에 동의합니다 (필수)'**
  String get privacyConsentAgreeTerms;

  /// No description provided for @privacyConsentAgreeAge.
  ///
  /// In ko, this message translates to:
  /// **'만 14세 이상입니다 (필수)'**
  String get privacyConsentAgreeAge;

  /// No description provided for @privacyConsentAgreeMarketing.
  ///
  /// In ko, this message translates to:
  /// **'마케팅 정보 수신에 동의합니다 (선택)'**
  String get privacyConsentAgreeMarketing;

  /// No description provided for @privacyConsentViewDocument.
  ///
  /// In ko, this message translates to:
  /// **'전문 보기'**
  String get privacyConsentViewDocument;

  /// No description provided for @privacyConsentContinue.
  ///
  /// In ko, this message translates to:
  /// **'동의하고 계속하기'**
  String get privacyConsentContinue;

  /// No description provided for @privacyConsentSaveError.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 후 다시 시도해 주세요.'**
  String get privacyConsentSaveError;

  /// No description provided for @openSourceLicenses.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get openSourceLicenses;

  /// No description provided for @appInfoDeveloper.
  ///
  /// In ko, this message translates to:
  /// **'개발'**
  String get appInfoDeveloper;

  /// No description provided for @appInfoDeveloperName.
  ///
  /// In ko, this message translates to:
  /// **'IF App Team'**
  String get appInfoDeveloperName;

  /// No description provided for @appInfoDescription.
  ///
  /// In ko, this message translates to:
  /// **'서로의 언어를 이어주는 커플 앱'**
  String get appInfoDescription;

  /// No description provided for @contact.
  ///
  /// In ko, this message translates to:
  /// **'문의하기'**
  String get contact;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'정말 로그아웃하시겠어요?'**
  String get logoutConfirmBody;

  /// No description provided for @notificationAll.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notificationAll;

  /// No description provided for @notificationAllSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'앱의 모든 알림을 받습니다.'**
  String get notificationAllSubtitle;

  /// No description provided for @notificationMessage.
  ///
  /// In ko, this message translates to:
  /// **'메시지 알림'**
  String get notificationMessage;

  /// No description provided for @notificationMessageSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 받으면 알림을 받습니다.'**
  String get notificationMessageSubtitle;

  /// No description provided for @notificationAlbum.
  ///
  /// In ko, this message translates to:
  /// **'앨범 알림'**
  String get notificationAlbum;

  /// No description provided for @notificationAlbumSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'상대가 앨범에 사진을 올리면 알림을 받습니다.'**
  String get notificationAlbumSubtitle;

  /// No description provided for @notificationAnniversary.
  ///
  /// In ko, this message translates to:
  /// **'기념일 알림'**
  String get notificationAnniversary;

  /// No description provided for @notificationAnniversarySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'커플 시작일(매년 같은 날)에 설정한 시각에 알림을 받습니다.'**
  String get notificationAnniversarySubtitle;

  /// No description provided for @notificationSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 알림'**
  String get notificationSchedule;

  /// No description provided for @notificationScheduleSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 일정이 있는 날, 아래에서 설정한 시각에 알림을 받습니다.'**
  String get notificationScheduleSubtitle;

  /// No description provided for @notificationTimeTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림 시간'**
  String get notificationTimeTitle;

  /// No description provided for @timeAm.
  ///
  /// In ko, this message translates to:
  /// **'오전'**
  String get timeAm;

  /// No description provided for @timePm.
  ///
  /// In ko, this message translates to:
  /// **'오후'**
  String get timePm;

  /// No description provided for @uploadTimeout.
  ///
  /// In ko, this message translates to:
  /// **'시간이 너무 오래 걸려 중단했어요. 네트워크·CORS·사진 용량을 확인해 주세요.'**
  String get uploadTimeout;

  /// No description provided for @uploadPermissionDenied.
  ///
  /// In ko, this message translates to:
  /// **'권한이 없어 업로드할 수 없어요.\n• Firebase 콘솔 → Storage·Firestore 규칙이 배포됐는지\n• 내 계정 Firestore users 문서에 coupleId가 있는지\n{webCorsLine}자세한 내용: docs/firebase_storage_이미지.md'**
  String uploadPermissionDenied(String webCorsLine);

  /// No description provided for @uploadLoginRequired.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요해요. 다시 로그인한 뒤 시도해 주세요.'**
  String get uploadLoginRequired;

  /// No description provided for @uploadCanceled.
  ///
  /// In ko, this message translates to:
  /// **'업로드가 취소되었어요.'**
  String get uploadCanceled;

  /// No description provided for @uploadFailedWithMessage.
  ///
  /// In ko, this message translates to:
  /// **'업로드 실패 ({code}): {message}'**
  String uploadFailedWithMessage(String code, String message);

  /// No description provided for @uploadFailedCodeOnly.
  ///
  /// In ko, this message translates to:
  /// **'업로드 실패 ({code})'**
  String uploadFailedCodeOnly(String code);

  /// No description provided for @uploadBrowserBlocked.
  ///
  /// In ko, this message translates to:
  /// **'브라우저에서 업로드가 막혔을 수 있어요.\nFirebase Storage 버킷에 CORS를 설정해 주세요. (프로젝트 루트 storage-cors.json · docs 참고)'**
  String get uploadBrowserBlocked;

  /// No description provided for @albumDownloadUrlTimeout.
  ///
  /// In ko, this message translates to:
  /// **'다운로드 URL을 받는 데 시간이 초과됐어요. 네트워크를 확인해 주세요.'**
  String get albumDownloadUrlTimeout;

  /// No description provided for @albumUploadTimeoutBody.
  ///
  /// In ko, this message translates to:
  /// **'사진 업로드가 3분 안에 끝나지 않았어요.\n• Wi‑Fi/네트워크 확인\n• 웹: Storage CORS·버킷 이름(if-app-b2854.firebasestorage.app) 확인\n• 사진 용량 줄이기'**
  String get albumUploadTimeoutBody;

  /// No description provided for @translateEmpty.
  ///
  /// In ko, this message translates to:
  /// **'번역할 텍스트가 비어 있습니다.'**
  String get translateEmpty;

  /// No description provided for @translateTooLong.
  ///
  /// In ko, this message translates to:
  /// **'번역은 {max}자까지 가능해요.'**
  String translateTooLong(int max);

  /// No description provided for @translateRateLimit.
  ///
  /// In ko, this message translates to:
  /// **'요청 한도를 초과했어요. 잠시 후 다시 시도해 주세요.'**
  String get translateRateLimit;

  /// No description provided for @translateBadRequest.
  ///
  /// In ko, this message translates to:
  /// **'잘못된 요청이에요.'**
  String get translateBadRequest;

  /// No description provided for @translateServerError.
  ///
  /// In ko, this message translates to:
  /// **'번역 서버 호출 실패 ({code})'**
  String translateServerError(int code);

  /// No description provided for @translateJsonError.
  ///
  /// In ko, this message translates to:
  /// **'번역 서버 응답이 JSON이 아닙니다. (HTML/에러 페이지일 수 있음)'**
  String get translateJsonError;

  /// No description provided for @translateNoField.
  ///
  /// In ko, this message translates to:
  /// **'번역 서버 응답에 translated 값이 없습니다.'**
  String get translateNoField;

  /// No description provided for @profilePartnerNicknameLabel.
  ///
  /// In ko, this message translates to:
  /// **'연인 닉네임'**
  String get profilePartnerNicknameLabel;

  /// No description provided for @profileEditTitleBar.
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get profileEditTitleBar;

  /// No description provided for @notificationTitleBar.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notificationTitleBar;

  /// No description provided for @albumDetailTitleBar.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get albumDetailTitleBar;

  /// No description provided for @albumEditTitleBar.
  ///
  /// In ko, this message translates to:
  /// **'앨범 수정'**
  String get albumEditTitleBar;

  /// No description provided for @albumAddTitleBar.
  ///
  /// In ko, this message translates to:
  /// **'앨범 추가'**
  String get albumAddTitleBar;

  /// No description provided for @mapPickerTitleBar.
  ///
  /// In ko, this message translates to:
  /// **'지도에서 위치 선택'**
  String get mapPickerTitleBar;

  /// No description provided for @photoViewerTitleBar.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get photoViewerTitleBar;

  /// No description provided for @appInfoTitleBar.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get appInfoTitleBar;

  /// No description provided for @webCorsBullet.
  ///
  /// In ko, this message translates to:
  /// **'• 웹: Storage 버킷 CORS 설정 (storage-cors.json)\n'**
  String get webCorsBullet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
