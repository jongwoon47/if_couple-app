# 채팅·앨범 이미지가 안 올라갈 때

## 0. 웹에서 콘솔에 `blocked by CORS policy` / `localhost` 가 보일 때 (가장 흔함)

**증상 예:**

- `Access to XMLHttpRequest at 'https://firebasestorage.googleapis.com/...' from origin 'http://localhost:xxxxx' has been blocked by CORS policy`
- `Response to preflight request doesn't pass access control check`

**원인:** Firebase Storage는 **Google Cloud Storage 버킷**을 쓰는데, 브라우저에서 업로드·다운로드하려면 **그 버킷에 CORS 설정**이 반드시 올라가 있어야 합니다. 프로젝트에 `storage-cors.json` 파일만 있고 **`gsutil`로 버킷에 적용하지 않으면** 로컬/웹에서 계속 실패합니다.

**해결 (한 번만 하면 됨):**

1. [Google Cloud SDK](https://cloud.google.com/sdk) 설치 후 터미널에서 로그인:
   - `gcloud auth login`
   - `gcloud config set project if-app-b2854` (본 프로젝트 ID)
2. 프로젝트 루트(`storage-cors.json` 있는 폴더)에서 실행:

```bash
# 실제 버킷 이름은 `gcloud storage buckets list --project=if-app-b2854` 로 확인.
# 신규 Firebase 프로젝트는 `if-app-b2854.firebasestorage.app` 인 경우가 많음.
gcloud storage buckets update gs://if-app-b2854.firebasestorage.app --cors-file=storage-cors.json
```

(구버전 `gsutil`: `gsutil cors set storage-cors.json gs://if-app-b2854.firebasestorage.app`)

3. 적용 확인:

```bash
gcloud storage buckets describe gs://if-app-b2854.firebasestorage.app --format="default(cors_config)"
```

4. Chrome에서 **강력 새로고침**(Ctrl+Shift+R) 후 다시 이미지 전송.

> Flutter 웹은 실행할 때마다 **포트가 바뀔 수** 있어서 `storage-cors.json`의 `"origin": ["*"]` 로 두는 경우가 많습니다. 배포용 도메인이 정해지면 `*` 대신 실제 도메인만 넣는 편이 더 안전합니다.

### CORS는 넣었는데 콘솔에 여전히 `.../v0/b/...appspot.com/...` 이 보일 때

- 실제 GCS 버킷은 `if-app-b2854.firebasestorage.app` 인데, 요청만 `...appspot.com` 으로 가면 **CORS를 맞춘 버킷과 요청 대상이 달라** 실패할 수 있습니다.
- 앱에서는 `lib/services/app_firebase_storage.dart` 로 **Storage 버킷을 `firebase_options`와 동일하게 명시**합니다.
- 그다음 **`flutter clean` 후 웹 다시 실행**, Chrome에서 **localhost 사이트 데이터 삭제** 또는 **시크릿 창**으로 확인해 보세요.

---

## 1. Storage 보안 규칙이 막는 경우

Firebase 콘솔 → **Storage → Rules**에 아래가 **게시**되어 있어야 합니다.  
`allow read, write: if false;` 이면 **절대** 업로드되지 않습니다.

프로젝트 루트의 `storage.rules` 내용을 콘솔에 붙여넣고 **게시**하거나:

```bash
firebase deploy --only storage
```

## 2. `users/{내 uid}`에 `coupleId`가 없는 경우

규칙이 `Firestore`의 사용자 문서에서 `coupleId`를 읽어 같은 커플만 허용합니다.  
커플 연결이 안 되었거나 필드가 비어 있으면 **permission-denied**가 납니다.

## 3. 웹(Chrome)에서만 실패하는 경우 — **CORS**

브라우저에서 Storage로 직접 업로드할 때 **버킷 CORS**가 없으면 업로드가 막힙니다.

1. [Google Cloud Console](https://console.cloud.google.com) → 해당 프로젝트 → **Cloud Storage** → 버킷 이름 확인 (`xxx.appspot.com` 또는 `xxx.firebasestorage.app` 등 — `gcloud storage buckets list` 로 확인)
2. 로컬에 `storage-cors.json` 준비 (프로젝트 루트 참고)
3. [Google Cloud SDK](https://cloud.google.com/sdk) 설치 후:

```bash
gsutil cors set storage-cors.json gs://YOUR_BUCKET_NAME
```

배포 도메인이 정해지면 `origin`에 그 도메인을 추가하는 것이 안전합니다.

## 4. 앨범만 안 되고 채팅은 될 때

- **Firestore**에 `couples/{coupleId}/albums` 규칙이 없으면 메타데이터 저장이 실패합니다.  
  `firestore.rules`에 앨범 경로가 있는지 확인하고 `firebase deploy --only firestore:rules`

## 5. 앱에서 확인하는 방법

채팅에서 사진 전송 실패 시 **스낵바**에  
`permission-denied`, `CORS`, `unauthenticated` 등 메시지가 나오면 위 항목을 대응하면 됩니다.
