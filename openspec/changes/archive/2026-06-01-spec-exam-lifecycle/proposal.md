## Why

The franklyn FSD defines the full exam lifecycle — creation with mandatory class/room, a PIN valid only during the exam window, single global student sessions, and a recording-start window of `[start − 60 min, end]` (§4.2, §4.3, §5.1, §6). The current implementation covers only basic CRUD and start/end mutations; several FSD-mandated behaviours are missing. This change captures the exam-lifecycle capability as a spec so the gaps are documented and tracked before the next implementation pass.

## What Changes

- Introduce the `exam-lifecycle` capability spec covering exam creation, PIN issuance, student join, session uniqueness, recording start/stop windows, and exam deletion.
- Document FSD-required exam fields **class** and **room** that are absent from `Exam` / `InsertExam` (§4.2). **BREAKING** to the GraphQL `InsertExamInput` schema once implemented.
- Specify PIN validity restricted to the exam time window (§4.2, US-02) — currently any valid PIN registers at any time.
- Specify global single-session enforcement per student (§4.3) — currently a student can open multiple sentinel sessions.
- Specify the recording-start window `[start − 60 min, end]` (§6.1) and recording-end-on-manual-logout (§6.2) — neither is enforced today.
- Specify exam deletion as a full hard-delete of all associated data including backups (§12.2, US-07) — current delete removes only the `fr_exam` row.
- Record implementation status per requirement (implemented / partial / not-implemented); unbuilt FSD requirements become `[GAP]` tasks.

## Capabilities

### New Capabilities
- `exam-lifecycle`: exam creation and mandatory fields (§4.2), unique PIN issuance and time-window validity (§4.2/US-02), student join via Keycloak + PIN with class auto-assignment (§5.1/US-02), global single-session enforcement (§4.3), recording start/stop windows (§6.1/§6.2), exam start/end mutations, and exam hard-deletion (§12.2/US-07).

### Modified Capabilities
<!-- None. auth-identity (Thread 1) already covers role/class derivation; this capability consumes it but does not change its requirements. -->

## Impact

- **Backend (Java/Quarkus)**: `Exam` model, `InsertExam` DTO, `ExamDao` (add class/room columns + global PIN uniqueness), `ExamResource` (PIN window, session checks), `FranklynWebSocketServer` (PIN time-window check, session-uniqueness check, recording-start window gate), new Flyway migration for `class`/`room` columns.
- **Sentinel (Rust)**: recording-start gating now server-driven via registration ack/reject; `ws.rs` reject handling already present.
- **Frontend (Vue)**: `ExamStore` / create-exam form gain class + room inputs.
- **Cross-references**: connection-loss alarm (§6.3) tracked under `spec-violation-alarms` (Thread 6); cascade/backup purge on delete (§12.2) tracked under `spec-data-admin` (Thread 7).
- **Pre-existing blockers (not introduced here)**: duplicate Flyway version `V10__*` (two files) will block startup; `examId` query is not teacher-scoped (RBAC, Thread 1 follow-up).
