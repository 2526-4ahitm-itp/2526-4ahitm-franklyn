# Continuation: OpenSpec Speccing Plan for Franklyn

## Context

Goal: populate `openspec/specs/` with capability specs for the **franklyn** exam-proctoring app.  
Source of truth: `spec/fsd.md` (functional spec, German).

## System Map

```
franklyn/
├── server/         Java + Quarkus (backend)
│   ├── websocket/  FranklynWebSocketServer (live streaming)
│   ├── cache/      Cache.java + FrameListener.java (frame cache)
│   ├── repository/ ExamDao, UserDao, NoticeDao
│   ├── resource/   RegistrationService
│   └── oidc/       UserRole.java, UserSecurityAugmentor.java
│
├── proctor/        Vue.js (teacher UI)
│   ├── views/      ProctoringView.vue, ExamDetailView.vue, HomeView.vue
│   └── stores/     ExamStore.ts, WebsocketStore.ts, UserStore.ts, NoticeStore.ts
│
├── sentinel/       Rust (student daemon)
│   ├── recorder.rs screen capture
│   ├── ws.rs       WebSocket to server
│   ├── oidc.rs     Keycloak auth
│   └── proto.rs    wire protocol
│
└── openspec/
    ├── config.yaml  schema: spec-driven (context + rules populated ✓)
    ├── changes/
    │   └── archive/2026-05-26-config-setup/  ← ARCHIVED ✓
    └── specs/
        ├── openspec-project-config/spec.md  ✓
        └── auth-identity/spec.md  ✓ (pending archive)
```

## OpenSpec Schema: spec-driven

Artifact flow per change:
```
proposal.md → design.md + specs/**/*.md → tasks.md
```
`applyRequires: [tasks]`

Final durable output: `openspec/specs/<capability>/spec.md` (created on archive).

## Decisions Made

**FSD is law.** Specs reflect FSD requirements. Code is current implementation. Gaps belong in tasks.md as `[GAP]` items.

**Implementation status** required on every spec requirement: `implemented` / `partial` / `not-implemented`.

**Task labels**: `[GAP]` = FSD requirement not yet coded. `[SPEC]` = spec-writing-only task.

## Thread Progress

| Thread | Change Name | Status | Next Action |
|--------|-------------|--------|-------------|
| 0 | `config-setup` | **DONE** — archived 2026-05-26 | — |
| 1 | `spec-auth-identity` | **APPLIED** — ready to archive | `/opsx:archive spec-auth-identity` |
| 2 | `spec-exam-lifecycle` | not started | `/opsx:propose spec-exam-lifecycle` |
| 3 | `spec-live-monitoring` | not started | `/opsx:propose spec-live-monitoring` |
| 4 | `spec-recording-playback` | not started | `/opsx:propose spec-recording-playback` |
| 5 | `spec-file-tracking` | not started | `/opsx:propose spec-file-tracking` |
| 6 | `spec-violation-alarms` | not started | `/opsx:propose spec-violation-alarms` |
| 7 | `spec-data-admin` | not started | `/opsx:propose spec-data-admin` |

## Thread 0: config-setup — DONE ✓

Archived at `openspec/changes/archive/2026-05-26-config-setup/`.

## Thread 1: spec-auth-identity — APPLIED, needs archive

All 6 tasks done. Changes made:
- `UserRole.java`: added `ADMIN("admin", null)` + `OU=Admins` mapping + `extractClass()` method
- `OidcUserService.java`: ADMIN guard (throws) + `schoolClass` population on Student
- `UserDao.java`: `school_class` in insert + select
- `Student.java`: `schoolClass` field added
- `V10__student_school_class.sql`: migration added

Run `/opsx:archive spec-auth-identity` then commit before starting Thread 2.

## Per-Thread Prompt Template (Threads 1–7)

```
We are writing OpenSpec specs for the brownfield "franklyn" exam-proctoring app.
FSD is at spec/fsd.md. FSD = law (target state). Code = current implementation.

Before writing artifacts:
1. Read spec/fsd.md sections §X, §Y
2. Read: <list key files>
3. Compare FSD to implementation — find gaps

/opsx:propose spec-<capability>

Capability: <capability-name>
Write spec reflecting FSD target state.
Label unimplemented requirements [GAP] in tasks.md.
Label spec-writing tasks [SPEC].
```

## Thread-Specific File Lists

| Thread | Key Files to Read |
|--------|------------------|
| 1 auth-identity | `server/.../oidc/UserRole.java`, `UserSecurityAugmentor.java`, `OidcUserService.java`, `sentinel/src/oidc.rs`, `proctor/src/stores/KeycloakStore.ts`, `UserStore.ts` |
| 2 exam-lifecycle | `server/.../repository/exam/ExamDao.java`, `resource/RegistrationService.java`, `sentinel/src/ws.rs`, `proctor/src/stores/ExamStore.ts` |
| 3 live-monitoring | `server/.../websocket/FranklynWebSocketServer.java`, `cache/Cache.java`, `sentinel/src/recorder.rs`, `proctor/src/views/ProctoringView.vue`, `stores/WebsocketStore.ts` |
| 4 recording-playback | `sentinel/src/recorder.rs`, `sentinel/src/proto.rs` |
| 5 file-tracking | search for diff/file tracking code in `sentinel/src/` and `server/src/` |
| 6 violation-alarms | `server/.../repository/notice/NoticeDao.java`, `proctor/src/stores/NoticeStore.ts` |
| 7 data-admin | search for retention/cleanup/delete logic in `server/src/` |

## Next Step

1. `/opsx:archive spec-auth-identity`
2. Commit
3. Start Thread 2: propose `spec-exam-lifecycle` using the template above.
