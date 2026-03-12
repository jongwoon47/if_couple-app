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
