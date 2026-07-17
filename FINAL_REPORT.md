# 최종 작업 보고서

## 목적

`antigravity-project-planner`를 다음 조건으로 안정화하는 것이 목표였습니다.

- Vercel 배포 유지
- 이메일 OTP 로그인 적용
- Supabase 기반 영구 저장
- 여러 사용자의 공동 편집 지원
- 로그인 직후 기존 최신 문서 자동 로드
- 새로고침 시에도 동일 문서 유지 및 텍스트 중복 방지

## 최종 구조

- 프론트엔드 배포: Vercel
- 원본 저장소: GitHub
- 사용자 인증: Supabase Auth 이메일 OTP
- 데이터 저장: Supabase `documents`, `document_versions`, `document_collaborators`
- 실시간 협업: Yjs + WebSocket 서버

## 수행한 주요 작업

1. 이메일 OTP 로그인 추가
- Supabase Auth 연동
- 로그인 UI 및 세션 상태 표시 추가
- 로그인 전 문서 접근 차단

2. 메일 발송 환경 구성
- Resend + 커스텀 도메인 기반 SMTP 연동 전제 정리
- OTP 템플릿 한국어화

3. Supabase 영구 저장 구조 추가
- `documents` 테이블 기반 현재 문서 저장
- `document_versions` 기반 버전 이력 저장
- `document_collaborators` 기반 협업자 권한 관리

4. RLS 및 함수 정리
- 문서/버전/협업자 정책 재구성
- `join_document_by_room()` 함수 추가 및 운영 기준 SQL 정리
- 정책 재귀로 인한 `500` 오류 원인 제거

5. 공동 편집 동기화 보완
- 동일 room 편집 상태 반영 문제 수정
- 공동 편집자 간 같은 문서 영구 저장 가능하도록 조정

6. 로그인 직후 문서 로딩 문제 해결
- 로그인 전에는 room 연결 자체를 막도록 변경
- 문서 로딩 시 Supabase snapshot 선로딩 구조로 변경
- websocket 초기 sync 이후 snapshot 적용으로 새로고침 중복 문제 해결

## 코드 구조 정리

기존의 큰 `app.js`를 다음 역할로 분리했습니다.

- [app.js](./app.js): 앱 상태, UI 바인딩, 렌더링, 초기화
- [src/auth-controller.js](./src/auth-controller.js): 인증/세션/초기 room 결정
- [src/document-store.js](./src/document-store.js): Supabase 문서 조회/저장/버전 저장
- [src/collaboration-room.js](./src/collaboration-room.js): Yjs room 연결/해제 및 초기 sync 흐름
- [src/app-constants.js](./src/app-constants.js): 상수 분리

## Supabase 기준 파일

- 운영 기준본: [supabase-final-schema.sql](./supabase-final-schema.sql)
- 중간 작업 기록본: [supabase-collaboration.sql](./supabase-collaboration.sql)

운영/복구/재설치 시에는 항상 `supabase-final-schema.sql`을 기준으로 사용합니다.

## 최종 확인 결과

- 로그인 전 접근 차단 정상
- OTP 로그인 정상
- 로그인 직후 기존 문서 자동 로드 정상
- 공동 편집 및 영구 저장 정상
- 새로고침 후 동일 문서 유지 정상
- 새로고침 시 텍스트 중복 문제 해결

## 정리 사항

- 디버깅용 `.debug-frames/` 이미지 파일 제거
- README에 운영 가이드 및 복구 절차 기록

## 권장 운영 수칙

1. Supabase 정책 변경 시 먼저 `supabase-final-schema.sql`을 수정합니다.
2. 운영 중 직접 SQL Editor만 수정하고 파일을 안 바꾸는 방식은 피합니다.
3. 인증/저장/협업 로직 변경 시에는 `src/` 아래 역할별 파일을 우선 수정합니다.
4. 배포 후에는 로그인, 자동 로드, 새로고침, 공동 편집까지 한 번에 점검합니다.
