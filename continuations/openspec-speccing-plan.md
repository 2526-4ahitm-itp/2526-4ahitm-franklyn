# Continuation: OpenSpec Speccing Plan for Franklyn

## Context

Goal: populate `openspec/specs/` with capability specs for the **franklyn** exam-proctoring app.  
Source of truth: `spec/fsd.md` (functional spec, German).  
Status: `openspec/` is empty — no changes, no specs yet.

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
    ├── config.yaml  schema: spec-driven (no project context yet)
    └── specs/       EMPTY
```

## OpenSpec Schema: spec-driven

Artifact flow per change:
```
proposal.md → design.md + specs/**/*.md → tasks.md
```
`applyRequires: [tasks]`

Final durable output: `openspec/specs/<capability>/spec.md` (created on archive).

## Decisions Made

**FSD is law.** Specs should reflect FSD requirements. Code is current implementation. Gaps belong in tasks.md as implementation work.

**Thread plan** (8 independent threads after Thread 0):

| Thread | Change Name | Capabilities | FSD §§ | Key Code |
|--------|-------------|-------------|--------|----------|
| 0 | config-setup | (no change) | all | `openspec/config.yaml` |
| 1 | `spec-auth-identity` | auth-identity | §2, §5, §13 | `UserRole.java`, `oidc.rs`, `KeycloakStore.ts` |
| 2 | `spec-exam-lifecycle` | exam-management, student-session | §4.2, §4.3, §6 | `ExamDao.java`, `RegistrationService.java`, `ws.rs` |
| 3 | `spec-live-monitoring` | screen-streaming | §7 | `FranklynWebSocketServer.java`, `Cache.java`, `recorder.rs`, `ProctoringView.vue` |
| 4 | `spec-recording-playback` | video-recording | §8 | `recorder.rs` |
| 5 | `spec-file-tracking` | file-diff-tracking | §9 | (need to locate — may not be implemented) |
| 6 | `spec-violation-alarms` | violation-detection, alarm-system | §10, §11 | `NoticeDao.java`, `NoticeStore.ts` |
| 7 | `spec-data-admin` | data-retention, admin | §12, §13 | (cleanup jobs — need to locate) |

## Thread 0: Config Setup (do first)

Update `openspec/config.yaml` to add project context. Paste this and let Claude fill it in:

```yaml
schema: spec-driven

context: |
  App: franklyn — exam proctoring system for school computer labs
  Purpose: detect and document unauthorized AI tool usage during programming exams
  
  Tech stack:
  - Backend: Java 21 + Quarkus (monolithic), server/
  - Frontend: Vue.js 3 + Pinia + TypeScript, proctor/
  - Client daemon: Rust, sentinel/
  - DB: PostgreSQL + Flyway migrations
  - Identity: Keycloak (JWT/OIDC)
  - Protocol: WebSocket (binary frames for screen streaming)
  - Build: Maven (server), Bun (proctor), Cargo (sentinel)
  
  Domain terms:
  - Exam: a proctored session with title, class, room, start, end, PIN
  - Sentinel: the Rust daemon running on student machines
  - Proctor: the Vue.js teacher UI
  - Session: a student's active connection to an exam
  - Violation: detected rule breach (AI service, mass-paste, etc.)
  - Alarm: notification sent to teacher on violation or connection loss
  
  Roles: Schüler (student), Lehrer (teacher), Admin
  Language: German UI, English code

rules:
  proposal:
    - Scope each change to one or two capabilities maximum
    - Always reference relevant FSD sections (§N.M)
  specs:
    - Each spec covers exactly one capability
    - Include: purpose, actors, core rules, data model, acceptance criteria
    - Note implementation status: implemented / partial / not-implemented
  tasks:
    - Gap tasks (FSD requirement not yet implemented) labeled [GAP]
    - Doc tasks (just writing the spec) labeled [SPEC]
```

## Per-Thread Prompt Template

Use this prompt to start each thread:

```
/opsx:propose spec-<capability>

Context: We are writing OpenSpec specs for the brownfield "franklyn" exam-proctoring app.
FSD is at spec/fsd.md. Relevant FSD sections: §X, §Y.

Before writing artifacts:
1. Read spec/fsd.md sections §X and §Y
2. Read these files: <list key files>
3. Compare FSD requirements to existing implementation
4. Note gaps (FSD says X but code does not implement X)

The change introduces capability: <capability-name>
Write the spec as if it defines the target state (FSD = law).
Label unimplemented requirements as [GAP] in tasks.md.
```

## Next Step

Start with Thread 0 (update openspec/config.yaml), then Thread 1 (spec-auth-identity).
