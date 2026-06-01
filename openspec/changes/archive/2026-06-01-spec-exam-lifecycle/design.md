## Context

franklyn is a brownfield exam-integrity platform. The exam-lifecycle slice already has a working spine: `ExamResource` (GraphQL) for CRUD + start/end, `ExamDao` (JDBI) over the `fr_exam` table, `FranklynWebSocketServer` for sentinel/proctor registration, and the Rust sentinel `ws.rs` that registers with `{pin, auth}` and streams frames. The FSD (`spec/fsd.md`) is the target state; this design records how the documented gaps would be closed. The spec itself (`specs/exam-lifecycle/spec.md`) records WHAT; this file records HOW and the open decisions.

Current state (verified in code):
- `Exam` record: `id, teacherId, title, startTime, endTime, startedAt, endedAt, pin` — no class, no room.
- PIN: unique DB constraint (`V7`), but `createExam` dedupes only against the calling teacher's own exams (`exams()` = `findByTeacher`), not globally.
- Sentinel registration (`FranklynWebSocketServer.handleSentinelMessage`): validates PIN range + existence only; no time-window, no per-student session check, no recording-start gate.
- Delete: `ExamDao.delete(id, teacherId)` removes the `fr_exam` row only.

## Goals / Non-Goals

**Goals:**
- Capture exam-lifecycle requirements at FSD target state with accurate per-requirement implementation status.
- Make the class/room, PIN-window, session-uniqueness, and recording-window gaps explicit and individually trackable as `[GAP]` tasks.

**Non-Goals:**
- Implementing the gaps in this change (spec-writing thread; code lands in a later apply pass).
- Connection-loss alarm semantics (§6.3) — owned by `spec-violation-alarms` (Thread 6).
- Cascade delete of video/diffs/events and backup purge mechanics (§12.2) — owned by `spec-data-admin` (Thread 7). This spec states the requirement; the data-layer mechanics are detailed there.

## Decisions

- **Recording-start gate is server-side, not sentinel-side.** The server already owns PIN validation at registration and can reject with `server.registration.reject` (sentinel `ws.rs` handles `RegistrationReject` by shutting down). Putting the `[start − 60 min, end]` window check there keeps the single source of truth on the server and avoids trusting client clocks. Alternative (sentinel self-gates) rejected: client clock drift + bypass risk.
- **Session uniqueness keyed by Keycloak subject, enforced server-side.** `authenticatedSessions` is currently keyed by `connection.id`; a per-`subject` index (student UUID → active sentinel) is needed to reject a second concurrent registration (§4.3). Alternative (DB-backed session table) deferred — in-memory map matches the existing live-state model; durability not required since connection loss already ends a session.
- **Class/room as first-class `Exam` columns.** FSD §4.2 lists both as Pflichtfelder. Add `school_class` and `room` columns + non-null constraints via a new Flyway migration; extend `InsertExam`. Student↔exam class matching (§5.1) consumes the `schoolClass` already derived in Thread 1 (auth-identity).
- **PIN validity window computed from exam times, not stored.** A PIN is valid when `now ∈ [startTime, endTime]` (§4.2). No extra state; the check joins the existing `findByPin` result with current time. Note the recording window (§6.1, `start − 60 min`) is wider than the PIN-validity window (§4.2) — they are distinct checks and the spec keeps them separate.

## Risks / Trade-offs

- [Duplicate Flyway version `V10__*` already on disk] → Must rename one (e.g. → `V11`) before any new migration, else server won't start. Pre-existing; flagged in proposal Impact. Not fixed by this spec thread.
- [In-memory session map lost on server restart] → Acceptable: a restart drops all live WS connections anyway, so sentinels re-register; no stale-session leak.
- [Adding non-null class/room to existing rows] → Migration needs a backfill/default or the table must be empty in target envs. Decide at implementation time (Open Question).
- [Global PIN uniqueness vs per-exam-window reuse] → FSD says unique PIN per exam, valid only in window. Keeping PINs globally unique (current DB constraint) is simpler and avoids ambiguity when two open exams could share a PIN; retain it.

## Open Questions

- Backfill strategy for `school_class`/`room` on existing `fr_exam` rows (default value vs require empty table).
- Should a rejected recording-start (login >60 min early) surface to the student UI, or silently no-op until the window opens? FSD §6.1 only says "kein Recording".
