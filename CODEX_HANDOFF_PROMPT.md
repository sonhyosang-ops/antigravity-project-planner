# Codex 인수인계 프롬프트

새 컴퓨터에서 Codex를 시작할 때 아래 문장을 그대로 첫 메시지로 붙여 넣으면 됩니다.

```text
이 저장소 작업을 이어서 진행해.

우선 다음 파일들을 먼저 읽고 현재 상태를 정확히 파악해:
- README.md
- FINAL_REPORT.md
- USER_GUIDE_KO.md
- supabase-final-schema.sql

프로젝트 정보:
- 저장소: antigravity-project-planner
- 배포: Vercel
- 인증/영구 저장: Supabase
- 실시간 협업: Yjs WebSocket

현재까지 정리된 상태:
- 로그인 전에는 문서 접근이 막혀야 함
- 이메일 OTP 로그인 후 기존 공동작업 문서가 자동으로 열려야 함
- 여러 사용자가 같은 문서를 공동 편집할 수 있어야 함
- 작업 내용은 Supabase에 영구 저장되어야 함
- 새로고침 후에도 같은 문서가 유지되어야 함
- 새로고침 시 텍스트가 중복 저장되면 안 됨

코드 구조:
- app.js: 앱 상태, UI 바인딩, 렌더링, 초기화
- src/auth-controller.js: 인증/세션/초기 room 결정
- src/document-store.js: Supabase 문서 조회/저장/버전 저장
- src/collaboration-room.js: Yjs room 연결/해제 및 초기 sync 흐름
- src/app-constants.js: 상수 분리

Supabase 기준:
- 운영 기준 SQL은 supabase-final-schema.sql
- supabase-collaboration.sql 은 중간 작업/legacy 파일

작업 시작 전 해야 할 일:
1. git 상태 확인
2. README.md와 FINAL_REPORT.md 기준으로 현재 구조 요약
3. 내가 요청한 다음 작업을 이어서 진행

먼저 현재 상태를 짧게 요약한 뒤, 바로 작업을 이어가.
```

## 사용 방법

1. 새 컴퓨터에서 저장소를 `git clone` 합니다.
2. `main` 최신 상태를 `git pull` 합니다.
3. Codex를 열고 이 파일의 프롬프트 본문을 그대로 붙여 넣습니다.
4. Codex가 `README.md`, `FINAL_REPORT.md`, `USER_GUIDE_KO.md`, `supabase-final-schema.sql` 을 먼저 읽게 합니다.
