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
| 1 | `spec-auth-identity` | **DONE** — archived 2026-05-26 (commit 1d3e5ed) | — |
| 2 | `spec-exam-lifecycle` | **DONE** — archived 2026-06-01 | — |
| 3 | `spec-live-monitoring` | **DONE** — archived 2026-06-01 | — |
| 4 | `spec-recording-playback` | **DONE** — archived 2026-06-01 (all not-implemented) | — |
| 5 | `spec-file-tracking` | not started | `/opsx:propose spec-file-tracking` |
| 6 | `spec-violation-alarms` | not started | `/opsx:propose spec-violation-alarms` |
| 7 | `spec-data-admin` | not started | `/opsx:propose spec-data-admin` |

## Thread 0: config-setup — DONE ✓

Archived at `openspec/changes/archive/2026-05-26-config-setup/`.

## Thread 1: spec-auth-identity — DONE ✓

Archived at `openspec/changes/archive/2026-05-26-spec-auth-identity/`.
Final spec: `openspec/specs/auth-identity/spec.md` (6 requirements, passes `--strict`).
Code changes applied: `UserRole.java` (ADMIN role + OU=Admins + extractClass()),
`OidcUserService.java` (ADMIN guard + schoolClass), `UserDao.java`, `Student.java`,
`V10__student_school_class.sql`.

## Spec Format Rules (learned the hard way — apply to all threads)

OpenSpec `validate --specs --strict` enforces structure. A spec.md MUST:
1. Start with `## Purpose` (one-line capability description), then `## Requirements`.
2. Each `### Requirement:` body MUST contain SHALL/MUST in the **first paragraph**
   directly under the heading.
3. The `` `status: ...` `` marker goes **AFTER** the SHALL paragraph, NOT directly
   under the heading — else validator reads the status line as the body and fails
   with "Requirement must contain SHALL or MUST keyword".

Template:
```
## Purpose
<one line>

## Requirements

### Requirement: <name>
The system SHALL ...

`status: implemented|partial|not-implemented`

#### Scenario: <name>
- **WHEN** ...
- **THEN** ...
```

Both existing specs were retro-fixed to this shape on 2026-06-01.

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

## Workflow Per Thread (proven over Threads 2–4)

1. Read FSD sections + key files (table above). Build a gap table: FSD requirement → status → evidence.
2. `openspec new change "spec-<capability>"`.
3. Write `proposal.md`, `design.md`, `specs/<capability>/spec.md` (delta uses `## ADDED Requirements`), `tasks.md` ([SPEC] + [GAP]).
4. `openspec validate spec-<capability> --strict`.
5. Archive: write the durable `openspec/specs/<capability>/spec.md` BY HAND with `## Purpose` + `## Requirements` headers (the delta's `## ADDED Requirements` is NOT a valid durable spec — see Spec Format Rules), then `mv openspec/changes/spec-<capability> openspec/changes/archive/YYYY-MM-DD-spec-<capability>`.
6. `openspec validate --specs --strict` (all green) + update this table.

Note: `openspec` CLI prints a harmless warning `Rules for 'specs' must be an array of strings` on every call (config.yaml format quirk). Filter with `| grep -v "must be an array"`. Specs are unaffected.

## Known Code Findings (cross-cutting — don't lose these)

Surfaced during speccing; NOT fixed (this is a spec effort, not implementation):
- **BLOCKER: duplicate Flyway version `V10`.** `V10__add_settings_to_teacher.sql` AND `V10__student_school_class.sql` (Thread 1). Flyway refuses to start. Rename Thread-1 one to `V11` before any code work.
- **`Recorder::set_quality` is a no-op** (`recorder.rs`) — server `set-profile`/`set-resolution` ignored client-side. Adaptive downscale (live-monitoring) non-functional.
- **Capture FPS hardcoded 2.0, clamped ≤5** (`fps_to_fraction`) vs FSD default 10 (§7.2).
- **`examId` GraphQL query not teacher-scoped** (`ExamResource.examId` → `findById`, any teacher reads any exam). RBAC follow-up (auth-identity §13.2).
- **No persistence tables** for video/diffs/events/alarms/session — only `fr_user/teacher/student/exam/notice`. Recording-playback (Thread 4) entirely unbuilt; exam delete cascade + retention have no targets yet.

## Next Step

Start **Thread 5**: propose `spec-file-tracking` (FSD §9, US-05). Read: search `sentinel/src/` and `server/src/` for any diff/file-tracking code (expected: little/none → mostly not-implemented, like Thread 4). Follow the Workflow + Spec Format Rules above.
After Thread 5: Thread 6 `spec-violation-alarms` (§10–11), Thread 7 `spec-data-admin` (§12–13).
