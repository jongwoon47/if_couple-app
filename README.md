# IF App (Flutter + Firebase)

International couple app MVP built with Flutter + Firebase.
This repository is configured for Web-first development.

## Implemented now

- Firebase init (web + placeholders for other platforms)
- Auth
  - Google: Firebase Auth sign-in
  - Kakao/LINE (Web): OAuth redirect via backend API, then Firebase custom token sign-in
- Profile setup / couple connection / D-Day / chat / calendar

## Couple invite behavior

- Invite code length: 6 chars
- Expiration: 10 minutes
- Refresh: generates a new code and immediately invalidates the previous one
- Copy: available on generated code card

## Login architecture (current)

- Google: direct Firebase Auth
- Kakao/LINE:
  1) open `${AUTH_API_BASE_URL}/auth/{provider}/start`
  2) backend handles provider OAuth
  3) backend redirects back with query params
  4) app exchanges code (or receives custom token directly)
  5) app calls `FirebaseAuth.instance.signInWithCustomToken(...)`

## Required run config

1. Create project skeleton locally once

```bash
flutter create . --platforms=web,android,ios
```

2. Install dependencies

```bash
flutter pub get
```

3. Firebase setup
- Enable Authentication (Google)
- Create Firestore
- Fill `lib/firebase_options.dart`

4. Run web with backend auth API base URL

```bash
flutter run -d chrome --dart-define=AUTH_API_BASE_URL=https://your-api-domain
```

5. (Optional) Enable chat translation API

```bash
flutter run -d chrome ^
  --dart-define=AUTH_API_BASE_URL=https://your-api-domain ^
  --dart-define=TRANSLATE_API_URL=https://your-ngrok-url/translate ^
  --dart-define=TRANSLATE_SYSTEM_PROMPT="Translate Korean to Japanese naturally for couples."
```

6. **Google Maps (여행 일정 지도 + 주소로 장소 이름 채우기)**

- `web/index.html` 안의 Maps 스크립트 URL에 **브라우저용 API 키**를 넣습니다.
- Google Cloud Console에서 **Maps JavaScript API**와 **Geocoding API**를 켜고, 키는 HTTP 리퍼러(배포 도메인)로 제한하는 것을 권장합니다.
- 지도에서 위치 선택 후 **주소 문자열**로 `장소 이름` 필드를 채우려면, 앱 실행 시 같은 키를 넘깁니다 (웹에서 역지오코딩용):

```bash
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=YOUR_BROWSER_KEY
```

- 키를 넣지 않으면: **Android/iOS**는 기기 역지오코딩으로 주소를 어느 정도 채우고, **웹**은 좌표 문자열만 쓸 수 있습니다.

7. **이미지(채팅·앨범) 업로드**

- Firebase **Storage** 사용 + `storage.rules` 배포 (`firebase deploy --only storage`).
- 웹에서만 실패하면 **버킷 CORS** 설정 필요 → `docs/firebase_storage_이미지.md`, 루트 `storage-cors.json` 참고.

## Backend API contract for Kakao/LINE (required)

### Start OAuth
- `GET /auth/kakao/start?redirect_uri={uri}`
- `GET /auth/line/start?redirect_uri={uri}`

### Exchange code
- `POST /auth/kakao/exchange`
- `POST /auth/line/exchange`

Request JSON:

```json
{
  "code": "...",
  "redirectUri": "https://...",
  "state": "optional"
}
```

Response JSON:

```json
{
  "firebaseCustomToken": "..."
}
```

### Callback query params expected by app

- success with code: `?auth_provider=kakao|line&auth_code=...&auth_state=...`
- success with direct token: `?firebase_custom_token=...`
- failure: `?auth_error=...`
