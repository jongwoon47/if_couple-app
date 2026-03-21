# Firestore 데이터 (`users` 등)

## `users/{uid}`

앱에서 사용하는 주요 필드:

| 필드 | 설명 |
|------|------|
| `userId`, `email`, `nickname`, `partnerNickname`, `statusMessage` | 프로필 |
| `birthday`, `language`, `gender` | 프로필·설정 |
| `coupleId`, `startDate`, `coupleJoinedAt` | 커플·기념일 |
| `hasSeenConnectionComplete` | 커플 연결 후 축하 화면 노출 여부 |
| `notification*` | 알림 설정 |
| `createdAt` | 가입 시각 |

초대 코드는 **`inviteCodes` 컬렉션**만 사용합니다. 사용자 문서의 `activeInviteCode`는 레거시이며, 앱이 로그인 시 자동으로 삭제합니다.

## 배포 전 수동 정리 (콘솔)

- 테스트용 문서·컬렉션 삭제
- Firestore **보안 규칙** 프로덕션 검토
- 불필요한 인덱스·중복 데이터 점검

앱 실행 시 `UserService.repairUserDocumentIfNeeded`가 세션당 1회, 위 스키마와 맞지 않는 값을 보정합니다.
