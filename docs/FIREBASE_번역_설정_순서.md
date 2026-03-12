# Firebase에서 번역(Gemini) 쓰기 – 할 일 순서

아래 순서대로 하면 됩니다.

---

## 1단계: Firebase CLI 설치·로그인

1. **Node.js 18 이상**이 설치되어 있는지 확인  
   - 터미널: `node -v`

2. **Firebase CLI** 설치  
   ```bash
   npm install -g firebase-tools
   ```

3. **로그인**  
   ```bash
   firebase login
   ```  
   - 브라우저 열리면 Google 계정으로 로그인 (Flutter 앱 쓰는 Firebase 계정이면 됨)

---

## 2단계: 이 프로젝트에 Firebase 프로젝트 연결 (한 번만)

**이미 해 둔 것:** `firebase.json`(Functions 소스: `functions` 폴더)은 프로젝트에 포함되어 있습니다.

1. **프로젝트 폴더로 이동**  
   ```bash
   cd c:\dev\couple_app\if_app
   ```

2. **사용할 Firebase 프로젝트 지정**  
   ```bash
   firebase use
   ```  
   - 목록에 나오는 프로젝트 중 **지금 Flutter 앱에 쓰는 프로젝트** 번호 입력  
   - 또는 프로젝트 ID를 이미 알고 있으면:  
     ```bash
     firebase use 프로젝트ID
     ```

   (처음이면 `firebase login` 후 위 명령을 실행하면 됨. `firebase use`를 하면 `.firebaserc` 파일이 생깁니다.)

---

## 3단계: Gemini API 키 발급

1. **Google AI Studio** 접속  
   - https://aistudio.google.com/apikey

2. **"Create API key"** 클릭  
   - 프로젝트 선택 (Firebase 쓸 Google Cloud 프로젝트 있으면 그걸로 해도 됨)

3. **생성된 키 복사**  
   - 이 키는 **나중에 `functions/.env`에만** 넣고, 앱 코드나 Git에는 넣지 마세요.

---

## 4단계: API 키를 Firebase(Functions)에만 넣기

1. **`functions` 폴더로 이동**  
   ```bash
   cd functions
   ```

2. **`.env` 파일 만들기**  
   - `functions` 폴더 안에 **`.env`** 라는 이름으로 새 파일 생성  
   - 내용 (한 줄):  
     ```  
     GEMINI_API_KEY=여기에_복사한_키_붙여넣기
     ```  
   - 저장 후 **이 파일은 Git에 올리지 마세요.** (이미 `.gitignore`에 있음)

3. **의존성 설치**  
   ```bash
   npm install
   ```

4. **한 단계 위로 나가기**  
   ```bash
   cd ..
   ```

---

## 5단계: Firebase에 배포

1. **프로젝트 루트에서** (if_app 폴더에서):  
   ```bash
   firebase deploy --only functions
   ```

2. **처음이면**  
   - "GEMINI_API_KEY" 값을 입력하라고 할 수 있음  
   - 그때 **3단계에서 복사한 키** 붙여넣기  
   - 또는 이미 `functions/.env`에 넣었으면 자동으로 읽힐 수 있음

3. **배포가 끝나면**  
   - 터미널에 **translate 함수 URL**이 나옴  
   - 예: `https://asia-northeast3-프로젝트ID.cloudfunctions.net/translate`  
   - 이 **URL 전체를 복사**해 두기

---

## 6단계: Firebase 콘솔에서 확인 (선택)

1. **Firebase 콘솔** 접속  
   - https://console.firebase.google.com  
   - 해당 프로젝트 선택

2. **빌드 → Functions**  
   - **translate** 함수가 보이면 정상  
   - 클릭하면 **URL**도 다시 확인 가능

---

## 7단계: 앱에서 번역 URL만 넣기

- **앱에는 API 키를 넣지 않습니다.**  
- **4·5단계에서 받은 Cloud Function URL만** 넣으면 됩니다.

**Flutter 앱 실행할 때:**

```bash
flutter run --dart-define=TRANSLATE_API_URL=여기에_복사한_Cloud_Function_URL
```

예:

```bash
flutter run --dart-define=TRANSLATE_API_URL=https://asia-northeast3-if-app-xxxxx.cloudfunctions.net/translate
```

- **웹으로 실행**해도 같은 방식:  
  `flutter run -d chrome --dart-define=TRANSLATE_API_URL=URL`

---

## 정리

| 할 일 | 어디서 |
|--------|--------|
| Firebase 로그인, init (Functions) | 터미널 `firebase login`, `firebase init` |
| Gemini API 키 발급 | Google AI Studio |
| API 키 저장 | **오직** `functions/.env` (Git 제외) |
| Functions 배포 | `firebase deploy --only functions` |
| 번역 URL 확인 | 배포 로그 또는 Firebase 콘솔 → Functions |
| 앱에 넣는 것 | **URL만** `--dart-define=TRANSLATE_API_URL=...` |

이 순서대로 하면 Firebase에서 번역(Gemini) 쓰는 설정이 끝납니다.
