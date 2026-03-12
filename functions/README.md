# IF App – 번역용 Cloud Functions (Gemini)

**Gemini API 키는 이 서버(Firebase)에만 저장하고, 앱에는 넣지 않습니다.**

## 1. 준비

- Node.js 18 이상
- Firebase CLI: `npm install -g firebase-tools` 후 `firebase login`
- **프로젝트 루트**(if_app)에서 한 번만: `firebase init`
  - "Functions" 선택
  - "Use an existing project" 또는 새 프로젝트 선택
  - 언어: JavaScript
  - **"Directory for Firebase Functions"에 `functions` 입력** (이미 만들어 둔 폴더 사용)
  - ESLint 등은 취향대로

## 2. Gemini API 키 발급

1. [Google AI Studio](https://aistudio.google.com/apikey) 접속
2. "Create API key"로 키 생성
3. 이 키는 **여기(Cloud Functions)에서만** 사용하고, 앱이나 Git에는 넣지 마세요.

## 3. API 키 넣는 방법 (Google Secret Manager – 권장)

이 프로젝트는 **Secret Manager**로 API 키를 넣도록 되어 있습니다. 키가 암호화·버전 관리되며, 앱/배포 로그에 노출되지 않습니다.

### 3-1. Secret Manager에 키 생성

1. [Google Cloud Console](https://console.cloud.google.com/)에서 **같은 Firebase 프로젝트** 선택
2. 상단 검색에서 **"Secret Manager"** 검색 후 이동
3. **"시크릿 만들기"** 클릭
   - **이름:** `GEMINI_API_KEY` (정확히 이 이름)
   - **시크릿 값:** Gemini API 키 붙여넣기
   - 지역 등 기본값으로 생성

또는 gcloud로:

```bash
# 프로젝트 선택 (Firebase 프로젝트 ID와 동일)
gcloud config set project YOUR_PROJECT_ID

# 시크릿 생성 (키를 직접 입력)
echo -n "여기에_Gemini_API_키_붙여넣기" | gcloud secrets create GEMINI_API_KEY --data-file=-
```

### 3-2. Functions에 시크릿 접근 권한 부여

Cloud Functions가 사용하는 기본 서비스 계정에 시크릿 접근 권한을 줍니다.

- **콘솔:** [IAM 및 관리자](https://console.cloud.google.com/iam-admin/iam) → 프로젝트 선택 →  
  `if-app.gserviceaccount.com` (기본 App Engine 서비스 계정) 찾기 →  
  **편집** → **다른 역할 추가** → **Secret Manager 시크릿 액세스자** 추가

또는 gcloud로:

```bash
# 기본 App Engine 서비스 계정에 시크릿 접근 권한 부여
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:YOUR_PROJECT_ID@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

`YOUR_PROJECT_ID`는 Firebase 프로젝트 ID로 바꾸세요.

### 3-3. 배포

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

배포 시 Firebase CLI가 `GEMINI_API_KEY` 시크릿이 있는지 확인합니다. 없으면 배포가 막힐 수 있으니, 위 3-1을 먼저 진행하세요.

## 4. 배포 후 URL 확인

배포가 끝나면 Firebase 콘솔에서:

- **Functions** → `translate` 함수 → **URL** 복사

또는 터미널에서:

```bash
firebase functions:list
```

URL 형식 예:

- `https://asia-northeast3-프로젝트ID.cloudfunctions.net/translate`

이 URL이 **앱이 호출할 번역 API 주소**입니다.

## 5. 앱에서 쓰는 방법

앱은 **기존처럼** `TRANSLATE_API_URL` 하나만 쓰면 됩니다.  
이제 그 값을 **위에서 복사한 Cloud Function URL**로 넣으면 됩니다.

- **개발/빌드 시**

  ```bash
  flutter run --dart-define=TRANSLATE_API_URL=https://asia-northeast3-프로젝트ID.cloudfunctions.net/translate
  ```

- **Firebase / 배포 설정에서 URL 관리**  
  URL만 Remote Config나 Firestore에 넣어두고, 앱은 그 URL을 읽어서 쓰도록 할 수도 있습니다.  
  (API 키는 계속 Cloud Functions 쪽에만 두고, 앱에는 **URL만** 넘깁니다.)

## 6. 요청/응답 형식 (지금 앱과 동일)

- **POST** `Content-Type: application/json`
- **Body:** `{ "text": "번역할 글", "system_prompt": "선택 사항" }`
- **Response:** `{ "translated": "번역 결과" }`

앱의 `TranslationService`는 그대로 두고, `TRANSLATE_API_URL`만 이 Cloud Function 주소로 바꾸면 됩니다.

## 정리

| 저장 위치 | 내용 |
|-----------|------|
| **Google Secret Manager** | `GEMINI_API_KEY` (암호화·버전 관리, 앱/배포 로그에 노출 안 됨) |
| **앱** | `TRANSLATE_API_URL` = Cloud Function URL만 (API 키 없음) |

이렇게 하면 API 키는 Secret Manager에만 있고, 앱에는 번역 서버 URL만 있어서 안전하게 Gemini를 쓸 수 있습니다.
