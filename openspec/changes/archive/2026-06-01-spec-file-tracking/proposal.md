## Why

The FSD requires that each student's text-file changes during an exam be captured as incremental diffs, forced once per minute, stored as diffs only (no full snapshot), and bound to the correct student session so a teacher can reconstruct the file history afterwards (§9, US-05). File diffs also feed the synchronised playback timeline (§8.3) and a mandatory alarm type — "monitored file access / file source unavailable" (§11). The current system has **no** file-tracking code at all: the sentinel (`proto.rs` is a 3-line stub; `recorder.rs` does screen capture only) never reads, watches, or diffs files, and the server has no diff table or endpoint. This change captures the file-tracking capability as a spec so the gap is documented and tracked.

## What Changes

- Introduce the `file-tracking` capability spec covering text-file scope (§9.1), best-effort source detection (active-window app + last-saved file, §9.1), the forced 1-minute incremental diff run over all observed files (§9.1, §9.2), diff-only storage incremental against the last saved state (§9.2), and binding diffs to the student session (US-05).
- Document the explicit non-scope: binary files and reconstruction of deleted files (§9.3).
- Document that file tracking is **not implemented**: no file watching, no diffing, no diff persistence, no proto messages for diffs.
- Record implementation status per requirement; the unbuilt FSD requirements become `[GAP]` tasks.

## Capabilities

### New Capabilities
- `file-tracking`: text-file-only scope (§9.1), best-effort file-source detection via active-window app and last-saved file (§9.1), forced 1-minute incremental diff run over all observed files (§9.1, §9.2), diff-only storage incremental against the last saved state (§9.2), per-session binding of diffs (US-05), and explicit exclusion of binary files and deleted-file reconstruction (§9.3).

### Modified Capabilities
<!-- None. File diffs are consumed by recording-playback's timeline (Thread 4, §8.3) and the "file source unavailable" alarm of violation-alarms (Thread 6, §11), and are deleted by data-admin/exam-lifecycle hard-delete (§12.2), but this change modifies no existing requirements. -->

## Impact

- **Sentinel (Rust)**: would gain a file-source probe (active-window app + last-saved file), a per-minute diff scheduler, and an incremental text-diff generator. `proto.rs` (currently 3 lines) would need a diff message; the `ws` path would carry diffs to the server. None exists today.
- **Backend (Java/Quarkus)**: new diff storage (DB table keyed by student session + timestamp) and association to the exam/student session — no diff schema exists (only `fr_user/teacher/student/exam/notice`).
- **Frontend (Vue)**: file diffs surface on the recording-playback timeline (Thread 4) — no file-diff UI exists.
- **Cross-references**: the playback timeline that shows file-diff events is `spec-recording-playback` (Thread 4, §8.3); the "monitored file access / file source unavailable" alarm is `spec-violation-alarms` (Thread 6, §11); diff hard-delete on exam deletion is `spec-data-admin` (Thread 7) / `exam-lifecycle` (Thread 2, §12.2); the student session diffs bind to is `exam-lifecycle` (Thread 2).
