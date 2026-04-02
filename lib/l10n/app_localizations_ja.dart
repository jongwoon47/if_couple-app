// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'IF App';

  @override
  String get splashPreparingIf => 'IFを準備しています…';

  @override
  String get splashCheckingLogin => 'ログイン状態を確認しています…';

  @override
  String get splashLoadingProfile => 'プロフィールを読み込んでいます…';

  @override
  String get splashDefault => 'アプリを準備しています…';

  @override
  String get appLoadErrorTitle => 'アプリの読み込みに問題が発生しました';

  @override
  String get appLoadErrorBody => 'ネットワーク接続を確認してから\nアプリを再起動してください。';

  @override
  String get settingsTitle => '設定';

  @override
  String get profileEdit => 'プロフィール編集';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get disconnect => '連携解除';

  @override
  String get disconnecting => '連携解除中…';

  @override
  String get disconnectConfirmTitle => '本当に連携を解除しますか？';

  @override
  String get disconnectConfirmBody =>
      '連携だけが解かれ、チャットやアルバムのデータはサーバーに残ります。90日以内に再ログインして以前の連携を復元できます。解除後はログアウトされます。';

  @override
  String get restoreCoupleTitle => '以前の連携を復元';

  @override
  String get restoreCoupleSubtitle =>
      '相手もログインしたうえで、お互いが90日以内にここで復元を押すと、再び連携されます。';

  @override
  String get restoreCoupleButton => '以前の連携に戻る';

  @override
  String get restoreCoupleRestoring => '復元中…';

  @override
  String get restoreErrorExpired => '復元期間（90日）が過ぎました。';

  @override
  String get restoreErrorPartnerNotReady => '相手がまだログインしていないか、条件が揃っていません。';

  @override
  String get restoreErrorGeneric => '復元できませんでした。しばらくしてから再度お試しください。';

  @override
  String get accountDeleteTitle => 'アカウント削除';

  @override
  String get accountDeleteBody =>
      '自分のアカウント情報が削除され、相手側の連携も切れます。お二人とも退会すると、チャット・アルバムなどのデータがすべて削除されます。';

  @override
  String get accountDeleteConfirm => '退会する';

  @override
  String get accountDeleting => '退会処理中…';

  @override
  String get cancel => 'キャンセル';

  @override
  String get appInfo => 'アプリ情報';

  @override
  String get partnerDefault => 'パートナー';

  @override
  String get statusDefaultEmpty => 'ふたりの日常を一緒に彩りましょう。';

  @override
  String get languageSettings => '言語';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageJapanese => '日本語';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabChat => 'トーク';

  @override
  String get tabTrip => '旅行';

  @override
  String get tabCalendar => 'カレンダー';

  @override
  String get tabAlbum => 'アルバム';

  @override
  String get save => '保存';

  @override
  String get saving => '保存中…';

  @override
  String get done => '完了';

  @override
  String get delete => '削除';

  @override
  String get close => '閉じる';

  @override
  String get confirm => '確認';

  @override
  String get confirming => '確認中…';

  @override
  String get loginTagline => 'ふたりの言葉をつなぐ空間';

  @override
  String get loginServerNotConfigured =>
      'サーバーURLが設定されていません。\n--dart-define=AUTH_API_BASE_URL を指定してください。';

  @override
  String get loginNetworkUnstable => 'ネットワークが不安定です。\nしばらくしてから再度お試しください。';

  @override
  String get loginOAuthFailed => 'ソーシャルログインに失敗しました。\nもう一度お試しください。';

  @override
  String get loginAccountExists => 'すでに登録済みのアカウントです。\n元のログイン方法でお試しください。';

  @override
  String get loginFailed => 'ログインに失敗しました。\nもう一度お試しください。';

  @override
  String get loginKakao => 'Kakaoでログイン';

  @override
  String get loginLine => 'LINEでログイン';

  @override
  String get loginLineShort => 'LINE';

  @override
  String get loginGoogle => 'Googleでログイン';

  @override
  String get connectTitle => 'パートナーと連携しましょう';

  @override
  String get connectSubtitle => '招待コードを入力するか、作成して連携できます。';

  @override
  String get connectButton => '連携する';

  @override
  String get connectConnecting => '連携中…';

  @override
  String get connectOr => 'または';

  @override
  String get inviteCopyDone => '招待コードをコピーしました。';

  @override
  String get inviteGenerate => '招待コードを作成';

  @override
  String get inviteGenerating => 'コード作成中…';

  @override
  String get inviteRefresh => '新しいコードを作成';

  @override
  String get inviteRefreshing => '新しいコードを作成中…';

  @override
  String get timeRemainingPrefix => '残り時間: ';

  @override
  String get connectErrorPermission => '連携の権限がありません。Firestoreのルールを確認してください。';

  @override
  String get connectErrorGeneric =>
      '処理中にエラーが発生しました。しばらくしてから再度お試しください。\n（ログイン状態とFirestoreのルールを確認してください。）';

  @override
  String get codeHintEmpty => '英数字6桁の招待コードを入力してください。';

  @override
  String get codeHintValid => '形式は正しいです。';

  @override
  String get codeHintInvalid => '形式が正しくありません。6桁に合わせてください。';

  @override
  String get coupleConnectedTitle => 'カップル連携が完了しました！';

  @override
  String get coupleConnectedSubtitle => '連携されました！\nふたりだけの空間を楽しんでください。';

  @override
  String get coupleInvalidCode => '無効なコードです。';

  @override
  String get coupleInviteExpired => '招待コードの有効期限が切れています。';

  @override
  String get coupleUserNotFound => 'ユーザー情報が見つかりません。';

  @override
  String get coupleConnectionInvalid => '連携情報が正しくありません。';

  @override
  String get coupleInviteCreateFailed => '招待コードの作成に失敗しました。';

  @override
  String get coupleDisconnectNoPermission =>
      '連携解除の権限がありません。Firestoreのルールを確認してください。';

  @override
  String coupleDisconnectError(String code) {
    return '連携解除中にエラーが発生しました。（$code）';
  }

  @override
  String get homeTogetherTime => '一緒に過ごした時間';

  @override
  String homeStartDate(String date) {
    return '$date から';
  }

  @override
  String get homeGreetingQuestion => '今日はあいさつできましたか？';

  @override
  String get homeStartChat => 'トークを始める';

  @override
  String get chatTitle => 'トーク';

  @override
  String get chatEmpty => 'まだメッセージがありません。最初のあいさつを送ってみましょう。';

  @override
  String get camera => 'カメラ';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get gallery => 'ギャラリー';

  @override
  String get pickPhotosMax5 => '写真を選択（最大5枚）';

  @override
  String cameraOpenFailed(String error) {
    return 'カメラを開けませんでした。$error';
  }

  @override
  String galleryOpenFailed(String error) {
    return 'ギャラリーを開けませんでした。$error';
  }

  @override
  String photoSentCount(int count) {
    return '写真を$count枚送信しました。';
  }

  @override
  String get reply => '返信';

  @override
  String get showTranslation => '翻訳を見る';

  @override
  String get retranslate => '再翻訳';

  @override
  String get copyOriginal => '原文をコピー';

  @override
  String get copyTranslation => '訳文をコピー';

  @override
  String get deleteMessage => 'メッセージを削除';

  @override
  String get messageCopied => 'メッセージをコピーしました。';

  @override
  String get translationCopied => '訳文をコピーしました。';

  @override
  String get deleteMessageTitle => 'メッセージを削除';

  @override
  String get deleteMessageConfirm => 'このメッセージを削除しますか？';

  @override
  String get deleteMessageDone => 'メッセージを削除しました。';

  @override
  String get translateServerNotConfigured =>
      '初回翻訳サーバーがありません。TRANSLATE_API_URL に自宅の Gemma 用 URL を設定してください。';

  @override
  String get retranslateServerNotConfigured =>
      '再翻訳サーバーがありません。TRANSLATE_RETRANSLATE_API_URL に Gemini（クラウド）の URL を設定してください。';

  @override
  String get translateSheetTitle => '翻訳を見る';

  @override
  String get originalLabel => '原文';

  @override
  String get translationLabel => '翻訳';

  @override
  String get translating => '翻訳中…';

  @override
  String get messageSendFailed => '送信に失敗しました。もう一度お試しください。';

  @override
  String get messageHint => 'メッセージを入力…';

  @override
  String get saveStarted => '保存を開始しました。（Web: ダウンロードフォルダ・アプリ: 共有メニュー）';

  @override
  String saveFailed(String error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get closeTooltip => '閉じる';

  @override
  String get downloadTooltip => 'ダウンロード';

  @override
  String get albumNoCouple => 'カップル情報がありません。';

  @override
  String get albumTitle => 'アルバム';

  @override
  String get albumAdd => 'アルバムを追加';

  @override
  String get albumEmptyTitle => '最初のアルバムを作りませんか？';

  @override
  String get albumEmptySubtitle => '下の「アルバムを追加」から\n思い出を保存してみましょう。';

  @override
  String get albumUntitled => '無題';

  @override
  String albumPhotoCountShort(int count) {
    return '$count枚';
  }

  @override
  String get albumEditTitle => 'アルバムを編集';

  @override
  String get albumAddTitle => 'アルバムを追加';

  @override
  String get albumMaxPhotos => 'このアルバムには最大50枚まで追加できます。';

  @override
  String albumLoadImageFailed(String error) {
    return '画像を読み込めませんでした。$error';
  }

  @override
  String get albumTitleRequired => 'アルバムのタイトルを入力してください。';

  @override
  String get albumSaveButton => '保存する';

  @override
  String get albumTitleLabel => 'アルバムのタイトル';

  @override
  String get albumMemoLabel => 'メモ（任意）';

  @override
  String get albumPhotoAddDisabled => '写真を追加できません（最大50枚）';

  @override
  String albumPhotoAddRemaining(int count) {
    return '写真を追加（残り$count枚）';
  }

  @override
  String get albumPreviewHint => '写真を選ぶとここにプレビューが表示されます。';

  @override
  String get albumNoPhotosHint => 'まだ写真がありません。\n編集から写真を追加してみましょう。';

  @override
  String albumTotalPhotos(int count) {
    return '合計 $count枚';
  }

  @override
  String get coverLabel => '代表';

  @override
  String get photoTitle => '写真';

  @override
  String get setCoverImage => '代表画像に設定';

  @override
  String get deletePhotoTitle => '写真を削除';

  @override
  String get deletePhotoConfirm => 'この写真を削除しますか？';

  @override
  String get firstMeetDay => '初めて会った日';

  @override
  String get myBirthday => '自分の誕生日';

  @override
  String partnerBirthday(String name) {
    return '$nameの誕生日';
  }

  @override
  String get eventAdd => '予定を追加';

  @override
  String get eventEdit => '予定を編集';

  @override
  String get eventDelete => '予定を削除';

  @override
  String get eventNameHint => '予定のタイトルを入力';

  @override
  String get eventMemoHint => 'メモ（任意）';

  @override
  String get eventNameRequired => '予定の名前を入力してください。';

  @override
  String get yearlyEventNote => '毎年自動で表示される予定です。';

  @override
  String get tripEventNote => '旅行プランから自動で追加された予定です。';

  @override
  String get changeDate => '日付を変更';

  @override
  String get scheduleDeleteConfirm => 'この予定を削除しますか？';

  @override
  String get eventDeleted => '予定を削除しました。';

  @override
  String get calendarAddEvent => '予定を追加';

  @override
  String get calendarEmptyLine => 'この日付には予定がありません。';

  @override
  String get calendarTogetherLine => '一緒に過ごした時間';

  @override
  String calendarTodayLine(String date) {
    return '今日 · $date';
  }

  @override
  String get weekDaySun => '日';

  @override
  String get weekDayMon => '月';

  @override
  String get weekDayTue => '火';

  @override
  String get weekDayWed => '水';

  @override
  String get weekDayThu => '木';

  @override
  String get weekDayFri => '金';

  @override
  String get weekDaySat => '土';

  @override
  String get tripTitle => '旅行';

  @override
  String get tripMakeNew => '旅行を作成';

  @override
  String get tripCreateTitle => '旅行を作成';

  @override
  String get tripNameLabel => '旅行名';

  @override
  String get tripDateHint => '日付を選択';

  @override
  String get tripFillRequired => '旅行名と日付を両方入力してください。';

  @override
  String get tripCreateAction => '旅行を作成する';

  @override
  String get tripDeleteTitle => '旅行を削除';

  @override
  String tripDeleteConfirm(String title) {
    return '「$title」の旅行を削除しますか？\n（予定も一緒に削除されます）';
  }

  @override
  String get tripEmptyTitle => '最初の旅行を作りませんか？';

  @override
  String get tripEmptySubtitle => '下の「+ 旅行を作成」から\n旅行名と日付だけ簡単に入力できます。';

  @override
  String tripLoadFailed(String error) {
    return '予定を読み込めませんでした。\n$error';
  }

  @override
  String get today => '今日';

  @override
  String get planAdd => '+ 予定を追加';

  @override
  String get planAddFab => '予定を追加';

  @override
  String get planDeleted => '予定を削除しました。';

  @override
  String planDeleteFailed(String error) {
    return '削除に失敗しました: $error';
  }

  @override
  String get planAdded => '予定を追加しました。';

  @override
  String get planSaved => '予定を保存しました。';

  @override
  String planSaveFailed(String error) {
    return '保存に失敗しました。Firestoreのルール・ネットワークを確認してください。\n$error';
  }

  @override
  String get planOpenInMaps => 'Googleマップで見る';

  @override
  String get planOpenMapsFailed => '地図を開けませんでした。';

  @override
  String get mapPickerTitle => '地図で場所を選択';

  @override
  String get mapDone => '完了';

  @override
  String get mapSearchHint => '場所を検索（例: 大阪城、東京タワー）';

  @override
  String get mapPlaceLoadFailed => '場所情報を読み込めませんでした。';

  @override
  String get mapHintTap => '地図をタップするか、上で場所を検索してから［完了］を押してください';

  @override
  String get mapHintLoading => '住所・場所名を読み込み中…';

  @override
  String get mapHintSelected => '選択済み · ［完了］でこの内容が予定の場所名に入ります';

  @override
  String get planPlaceRequired => '場所名を入力するか、地図で位置を選択してください。';

  @override
  String get planEditHeader => '予定を編集';

  @override
  String get planAddHeader => '予定を追加';

  @override
  String get timeSelectOptional => '時間（任意）';

  @override
  String get placeNameLabel => '場所名';

  @override
  String get placeNameHint => '例: Osaka Castle';

  @override
  String get memoOptionalLabel => 'メモ（任意）';

  @override
  String get mapPickFromMap => '地図で位置を選択（任意）';

  @override
  String mapPickedWithPlace(String place) {
    return '地図で選択済み · $place';
  }

  @override
  String get mapPickedCoordsOnly => '座標を保存';

  @override
  String get savePlan => '保存する';

  @override
  String get addPlan => '追加する';

  @override
  String get deletePlan => '削除する';

  @override
  String get startDateScreenTitle => '初めて会った日を選択';

  @override
  String get startDateQuestion => '初めて会った日はいつですか？';

  @override
  String get startDateSubtitle => 'ふたりが初めて出会った特別な日を\n記念日として記録します。';

  @override
  String get startDateErrorNone => '初めて会った日を選択してください。';

  @override
  String get startDateErrorNoCouple => 'カップル情報がありません。再度ログインしてください。';

  @override
  String get psNicknameQuestion => 'お名前は何とお呼びしましょうか？';

  @override
  String get psBirthdayQuestion => 'お誕生日はいつですか？';

  @override
  String get psLanguageQuestion => 'よく使う言語は？';

  @override
  String get psLangKorean => '韓国語';

  @override
  String get psLangJapanese => '日本語';

  @override
  String get psNicknameLength => '2〜10文字で入力してください。';

  @override
  String get psBirthdayPick => 'ご自身の誕生日を選択してください。';

  @override
  String get psLanguageAccuracy => '主に使う言語を選ぶと翻訳の精度が上がります。';

  @override
  String get psNicknameError => 'ニックネームは2〜10文字で入力してください。';

  @override
  String get psBirthdaySelect => '誕生日を選択してください。';

  @override
  String get psAgeError => '14歳以上のみご利用いただけます。';

  @override
  String get psLanguageSelect => '言語を選択してください。';

  @override
  String get psInputError => '入力内容を確認してください。';

  @override
  String get psConfirmError => '入力内容をもう一度確認してください。';

  @override
  String get psBirthdayPlaceholder => '誕生日を選択';

  @override
  String get psNicknameHint => 'ニックネームを入力';

  @override
  String get psFieldNickname => 'ニックネーム';

  @override
  String get psFieldBirthday => '誕生日';

  @override
  String get psFieldLanguage => '言語';

  @override
  String get psPrevious => '戻る';

  @override
  String get psNext => '次へ';

  @override
  String downloadImageFailed(int code) {
    return '画像を取得できませんでした（HTTP $code）';
  }

  @override
  String get unsupportedSaveImage => 'このプラットフォームでは画像の保存に対応していません。';

  @override
  String get imageSaveShareText => '画像を保存';

  @override
  String locationLatLng(String lat, String lng) {
    return '位置 $lat, $lng';
  }

  @override
  String get appInfoVersion => 'バージョン 0.1.0';

  @override
  String get appInfoUpdateDate => '最新更新: 2026.03.25';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsOfService => '利用規約';

  @override
  String get privacyConsentTitle => '規約への同意';

  @override
  String get privacyConsentIntro => 'サービスを利用するには、以下に同意してください。';

  @override
  String get privacyConsentAgreeAll => 'すべて同意';

  @override
  String get privacyConsentAgreePrivacy => 'プライバシーポリシーに同意します（必須）';

  @override
  String get privacyConsentAgreeTerms => '利用規約に同意します（必須）';

  @override
  String get privacyConsentAgreeAge => '14歳以上であることを確認しました（必須）';

  @override
  String get privacyConsentAgreeMarketing => 'マーケティング情報の受信に同意します（任意）';

  @override
  String get privacyConsentViewDocument => '全文を見る';

  @override
  String get privacyConsentContinue => '同意して続ける';

  @override
  String get privacyConsentSaveError => '保存できませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get appInfoDeveloper => '開発';

  @override
  String get appInfoDeveloperName => 'IF App Team';

  @override
  String get appInfoDescription => 'ふたりの言葉をつなぐカップルアプリ';

  @override
  String get contact => 'お問い合わせ';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutConfirmTitle => 'ログアウト';

  @override
  String get logoutConfirmBody => '本当にログアウトしますか？';

  @override
  String get notificationAll => '通知';

  @override
  String get notificationAllSubtitle => 'アプリのすべての通知を受け取ります。';

  @override
  String get notificationMessage => 'メッセージ通知';

  @override
  String get notificationMessageSubtitle => 'メッセージを受け取ったら通知します。';

  @override
  String get notificationAlbum => 'アルバム通知';

  @override
  String get notificationAlbumSubtitle => 'パートナーがアルバムに写真を追加したら通知します。';

  @override
  String get notificationAnniversary => '記念日通知';

  @override
  String get notificationAnniversarySubtitle => 'カップル開始日（毎年同じ日）に、設定した時刻で通知します。';

  @override
  String get notificationSchedule => '予定通知';

  @override
  String get notificationScheduleSubtitle => 'カレンダーに予定がある日、下で設定した時刻に通知します。';

  @override
  String get notificationTimeTitle => '通知の時間';

  @override
  String get timeAm => '午前';

  @override
  String get timePm => '午後';

  @override
  String get uploadTimeout => '時間がかかりすぎたため中断しました。ネットワーク・CORS・画像サイズを確認してください。';

  @override
  String uploadPermissionDenied(String webCorsLine) {
    return '権限がないためアップロードできません。\n• FirebaseコンソールでStorage・Firestoreのルールが公開されているか\n• 自分のFirestore usersドキュメントにcoupleIdがあるか\n$webCorsLine詳細: docs/firebase_storage_이미지.md';
  }

  @override
  String get uploadLoginRequired => 'ログインが必要です。再度ログインしてからお試しください。';

  @override
  String get uploadCanceled => 'アップロードがキャンセルされました。';

  @override
  String uploadFailedWithMessage(String code, String message) {
    return 'アップロード失敗（$code）: $message';
  }

  @override
  String uploadFailedCodeOnly(String code) {
    return 'アップロード失敗（$code）';
  }

  @override
  String get uploadBrowserBlocked =>
      'ブラウザでアップロードがブロックされている可能性があります。\nFirebase StorageバケットにCORSを設定してください。（プロジェクトルート storage-cors.json · docs参照）';

  @override
  String get albumDownloadUrlTimeout =>
      'ダウンロードURLの取得がタイムアウトしました。ネットワークを確認してください。';

  @override
  String get albumUploadTimeoutBody =>
      '写真のアップロードが3分以内に完了しませんでした。\n• Wi‑Fi/ネットワークを確認\n• Web: Storage CORS・バケット名(if-app-b2854.firebasestorage.app)を確認\n• 画像サイズを小さくする';

  @override
  String get translateEmpty => '翻訳するテキストが空です。';

  @override
  String translateTooLong(int max) {
    return '翻訳は$max文字までです。';
  }

  @override
  String get translateRateLimit => 'リクエスト制限を超えました。しばらくしてから再度お試しください。';

  @override
  String get translateBadRequest => 'リクエストが正しくありません。';

  @override
  String translateServerError(int code) {
    return '翻訳サーバーの呼び出しに失敗しました（$code）';
  }

  @override
  String get translateJsonError =>
      '翻訳サーバーの応答がJSONではありません。（HTML/エラーページの可能性があります）';

  @override
  String get translateNoField => '翻訳サーバーの応答に translated がありません。';

  @override
  String get profilePartnerNicknameLabel => 'パートナーのニックネーム';

  @override
  String get profileEditTitleBar => 'プロフィール編集';

  @override
  String get notificationTitleBar => '通知設定';

  @override
  String get albumDetailTitleBar => 'アルバム';

  @override
  String get albumEditTitleBar => 'アルバムを編集';

  @override
  String get albumAddTitleBar => 'アルバムを追加';

  @override
  String get mapPickerTitleBar => '地図で場所を選択';

  @override
  String get photoViewerTitleBar => '写真';

  @override
  String get appInfoTitleBar => 'アプリ情報';

  @override
  String get webCorsBullet => '• Web: StorageバケットのCORS設定（storage-cors.json）\n';
}
