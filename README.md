# antigravity-project-planner

## Supabase 운영 기준

- 운영 기준 SQL 파일은 [supabase-final-schema.sql](./supabase-final-schema.sql) 입니다.
- [supabase-collaboration.sql](./supabase-collaboration.sql) 은 중간 작업/이전 마이그레이션 기록용입니다.

## Supabase 복구 절차

1. Supabase Dashboard에서 대상 프로젝트를 엽니다.
2. `SQL Editor`로 이동합니다.
3. [supabase-final-schema.sql](./supabase-final-schema.sql) 전체 내용을 붙여넣습니다.
4. `Run`을 실행합니다.
5. 실행 후 `documents`, `document_versions`, `document_collaborators`, `join_document_by_room()` 이 생성되었는지 확인합니다.

## 현재 앱 구조

- 배포: Vercel
- 인증/영구 저장: Supabase
- 실시간 협업: Yjs WebSocket
- 인증 컨트롤러: [src/auth-controller.js](./src/auth-controller.js)
- 문서 저장 컨트롤러: [src/document-store.js](./src/document-store.js)
- 협업 room 컨트롤러: [src/collaboration-room.js](./src/collaboration-room.js)
