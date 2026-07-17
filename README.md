# antigravity-project-planner

## 운영 개요

- 코드 원본: GitHub `sonhyosang-ops/antigravity-project-planner`
- 프론트엔드 배포: Vercel
- 인증/영구 저장: Supabase
- 실시간 협업: Yjs WebSocket

## Supabase 운영 기준

- 운영 기준 SQL 파일은 [supabase-final-schema.sql](./supabase-final-schema.sql) 입니다.
- [supabase-collaboration.sql](./supabase-collaboration.sql) 은 중간 작업/이전 마이그레이션 기록용입니다.

## Supabase 복구 절차

1. Supabase Dashboard에서 대상 프로젝트를 엽니다.
2. `SQL Editor`로 이동합니다.
3. [supabase-final-schema.sql](./supabase-final-schema.sql) 전체 내용을 붙여넣습니다.
4. `Run`을 실행합니다.
5. 실행 후 `documents`, `document_versions`, `document_collaborators`, `join_document_by_room()` 이 생성되었는지 확인합니다.

## 운영 점검 순서

1. 배포 주소에 접속합니다.
2. 로그인 전에는 문서 접근이 막히는지 확인합니다.
3. OTP 이메일 로그인이 정상 동작하는지 확인합니다.
4. 로그인 직후 기존 최신 문서가 바로 보이는지 확인합니다.
5. 새로고침 후에도 같은 문서가 유지되고 텍스트가 중복되지 않는지 확인합니다.

## 문제 발생 시 우선 확인

- 로그인은 되는데 문서가 비면: Supabase SQL과 `join_document_by_room()` 함수 상태 확인
- 새로고침 후 텍스트가 중복되면: websocket 초기 sync 이후 snapshot 적용 구조가 유지되는지 확인
- 저장이 안 되면: `documents`, `document_versions`, RLS 정책, OTP 세션 상태 확인

## 현재 앱 구조

- 배포: Vercel
- 인증/영구 저장: Supabase
- 실시간 협업: Yjs WebSocket
- 인증 컨트롤러: [src/auth-controller.js](./src/auth-controller.js)
- 문서 저장 컨트롤러: [src/document-store.js](./src/document-store.js)
- 협업 room 컨트롤러: [src/collaboration-room.js](./src/collaboration-room.js)
- 공동작업 참여자용 가이드: [USER_GUIDE_KO.md](./USER_GUIDE_KO.md)
- 상세 변경 이력: [FINAL_REPORT.md](./FINAL_REPORT.md)
