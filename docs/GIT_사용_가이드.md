# IF App – Git 사용 가이드 (다른 컴퓨터에서 작업하기)

이 프로젝트를 **다른 컴퓨터**에서도 이어서 작업하려면 Git으로 코드를 GitHub(또는 GitLab 등)에 올리고, 다른 PC에서는 **clone**해서 쓰면 됩니다.

---

## 1. Git 설치 확인

**Windows (PowerShell 또는 명령 프롬프트):**

```powershell
git --version
```

`git version 2.x.x` 처럼 나오면 이미 설치된 것입니다.  
나오지 않으면 [Git 다운로드](https://git-scm.com/download/win)에서 설치한 뒤 터미널을 다시 열어주세요.

---

## 2. 이 컴퓨터에서 처음 한 번만 할 일

### 2-1. 프로젝트 폴더로 이동

```powershell
cd c:\dev\couple_app\if_app
```

### 2-2. Git 저장소 만들기

```powershell
git init
```

`Initialized empty Git repository in c:/dev/couple_app/if_app/.git/` 라고 나오면 성공입니다.

### 2-3. 사용자 이름·이메일 설정 (처음 한 번만)

GitHub에 올릴 때 커밋에 표시될 이름과 이메일입니다.  
**다른 컴퓨터에서도 같은 GitHub 계정을 쓸 거라면, 각 PC에서 한 번씩 설정하면 됩니다.**

```powershell
git config --global user.name "본인이름"
git config --global user.email "github에_가입한_이메일@example.com"
```

예:  
`git config --global user.name "Hong GilDong"`  
`git config --global user.email "hong@gmail.com"`

### 2-4. 첫 커밋 (현재 코드 저장)

```powershell
git add .
git status
```

`status`로 추가된 파일 목록을 확인한 뒤:

```powershell
git commit -m "Initial commit: IF App 프로젝트"
```

`Initial commit` 대신 `"첫 커밋"`, `"프로젝트 초기 버전"` 등 원하는 메시지로 바꿔도 됩니다.

---

## 3. GitHub에 저장소 만들고 연결

### 3-1. GitHub에서 새 저장소 만들기

1. [GitHub](https://github.com) 로그인
2. 오른쪽 상단 **+** → **New repository**
3. **Repository name:** 예) `if_app` (원하는 이름으로)
4. **Public** 선택
5. **"Add a README file"** 등은 체크하지 않고 **Create repository** 클릭

### 3-2. 로컬 프로젝트와 GitHub 연결

GitHub 저장소를 만든 뒤 나오는 주소를 사용합니다.  
예: `https://github.com/내아이디/if_app.git`

```powershell
git remote add origin https://github.com/내아이디/if_app.git
```

`내아이디`와 `if_app`을 본인 GitHub 아이디와 저장소 이름으로 바꾸세요.

### 3-3. 기본 브랜치 이름을 main으로 (선택)

```powershell
git branch -M main
```

### 3-4. GitHub로 올리기 (첫 push)

```powershell
git push -u origin main
```

로그인 창이 뜨면 GitHub 계정으로 로그인합니다.  
끝나면 GitHub 웹사이트에서 코드가 보여야 합니다.

---

## 4. 평소 작업 흐름 (이 컴퓨터에서)

코드를 수정한 뒤, 다시 GitHub에 반영할 때:

```powershell
cd c:\dev\couple_app\if_app

git add .
git status
git commit -m "수정 내용을 짧게 적기 (예: 채팅 스크롤 수정)"
git push
```

- **add:** 변경된 파일을 스테이징  
- **commit:** 그 순간을 하나의 버전으로 저장  
- **push:** 그 버전을 GitHub에 업로드  

`git status`로 뭘 올리는지 확인하는 습관을 들이면 좋습니다.

---

## 5. 다른 컴퓨터에서 처음 할 일 (clone)

다른 PC에서 이 프로젝트를 받아서 작업하려면:

### 5-1. Git 설치

해당 컴퓨터에도 Git이 있어야 합니다.  
`git --version`으로 확인 후, 없으면 [Git 다운로드](https://git-scm.com/download/win)에서 설치합니다.

### 5-2. 프로젝트 받기 (clone)

작업할 폴더로 이동한 뒤 (예: `c:\dev`), 아래처럼 합니다.

```powershell
cd c:\dev
git clone https://github.com/내아이디/if_app.git
cd if_app
```

`내아이디`와 `if_app`을 본인 저장소에 맞게 바꾸세요.  
끝나면 `c:\dev\if_app` 안에 프로젝트가 생깁니다.

### 5-3. 의존성 설치

- **Flutter:**  
  ```powershell
  flutter pub get
  ```
- **Firebase Functions:**  
  ```powershell
  cd functions
  npm install
  cd ..
  ```

### 5-4. (선택) 사용자 이름·이메일

다른 PC에서도 커밋할 거라면:

```powershell
git config --global user.name "본인이름"
git config --global user.email "github에_가입한_이메일@example.com"
```

---

## 6. 다른 컴퓨터에서 평소 작업 흐름

### 6-1. 최신 코드 받기 (다른 PC에서 작업 시작할 때)

```powershell
cd c:\dev\if_app
git pull
```

`git pull`을 하면 GitHub에 올려둔 최신 코드가 이 PC로 내려옵니다.  
**작업 시작 전에 항상 `git pull`** 하면 충돌이 줄어듭니다.

### 6-2. 수정 후 다시 GitHub에 올리기

이 컴퓨터에서 수정한 뒤:

```powershell
git add .
git commit -m "수정 내용 요약"
git push
```

그 다음 **처음 컴퓨터**에서 작업할 때는:

```powershell
git pull
```

해서 방금 다른 PC에서 올린 내용을 받으면 됩니다.

---

## 7. 자주 쓰는 명령어 정리

| 명령어 | 설명 |
|--------|------|
| `git status` | 지금 변경된 파일 목록 확인 |
| `git add .` | 모든 변경 파일 스테이징 |
| `git add 파일경로` | 특정 파일만 스테이징 |
| `git commit -m "메시지"` | 스테이징된 내용으로 커밋 (버전 저장) |
| `git push` | GitHub에 올리기 |
| `git pull` | GitHub에서 최신 코드 받기 |
| `git log --oneline` | 최근 커밋 목록 보기 |

---

## 8. 주의사항

- **비밀번호·API 키:** `.env`, `key.properties` 같은 건 `.gitignore`에 넣어 두었으니 커밋되지 않습니다. 다른 PC에서는 직접 다시 설정해야 합니다.
- **Flutter 실행 옵션:** `--dart-define=TRANSLATE_API_URL=...` 같은 건 터미널/스크립트에 적어 두고, 다른 PC에서도 동일하게 실행하면 됩니다.
- **같은 파일을 두 PC에서 동시에 수정**하면 `git pull` 시 충돌이 날 수 있습니다. 한쪽에서 먼저 `commit` → `push` 하고, 다른 쪽에서 `pull` 한 뒤 수정하는 식으로 하면 안전합니다.

---

정리하면:

1. **이 PC:** `git init` → `git add .` → `git commit` → GitHub 저장소 만들고 `git remote add origin ...` → `git push -u origin main`
2. **다른 PC:** `git clone ...` → `flutter pub get`, `cd functions && npm install`
3. **매일:** 작업 전 `git pull`, 작업 후 `git add .` → `git commit -m "..."` → `git push`

이 순서만 따라 하면 다른 컴퓨터에서도 같은 프로젝트를 이어서 작업할 수 있습니다.
