## Why

The FSD requires automatic, detect-and-report violation monitoring that starts when a student connects and raises alarms — within 10 seconds — as a live teacher popup, an event-list entry, a DB-persisted record, and a timeline marker, with at most one warning per minute for an ongoing violation (§10, §11, US-04). Detection draws on GDPR-cleared signals (active window/process names, active-tab browser URL, continuous OCR, device-wide network destination domains) and a rule set (admin-managed forbidden-AI-service list, mass-paste ≥10 lines within ≤1s), with four mandatory alarm types (connection lost, exam-rule violation, AI suspicion, monitored file source unavailable). The current system has **none** of this: there is no detection code (no OCR, process, URL, paste, or network capture) and no alarm persistence. The only "notice" feature (`fr_notice`, types ALERT/TIMED/SINGLE) is teacher-authored announcements with no student/exam binding — unrelated to violation alarms. This change captures the violation-alarms capability as a spec so the gap is documented and tracked.

## What Changes

- Introduce the `violation-alarms` capability spec covering automatic detect-and-report monitoring (§10.1), the GDPR-cleared signal set and forbidden signals (§10.2), the rule set — forbidden-AI DB list and mass-paste threshold (§10.3), the alarm-on-hit pipeline popup + event list + DB + marker with the ≤1/min repeat rule (§10.4), the four mandatory alarm types and their properties — acknowledgeable, no escalation, no email, ≤10s latency (§11, US-04).
- Document that violation detection and alarming are **not implemented**: no signal capture, no rule engine, no alarm persistence, no teacher popup pipeline.
- Note that `fr_notice` is teacher announcements, not violation alarms, so it is not the persistence target.
- Record implementation status per requirement; the unbuilt FSD requirements become `[GAP]` tasks.

## Capabilities

### New Capabilities
- `violation-alarms`: automatic detect-and-report monitoring on student connect (§10.1), GDPR-cleared signal capture with forbidden-signal exclusion (§10.2), the rule set — admin-managed forbidden-AI list and mass-paste ≥10 lines/≤1s (§10.3), the alarm pipeline (live popup, event list, DB persistence, timeline marker) with ≤1 alarm/min per ongoing violation (§10.4), and the four mandatory alarm types with acknowledgement, no escalation, no email, ≤10s latency (§11, US-04).

### Modified Capabilities
<!-- None. Alarm markers are rendered on recording-playback's timeline (Thread 4, §8.3); the "monitored file source unavailable" alarm is driven by file-tracking (Thread 5, §11); the forbidden-AI list is admin-managed (data-admin Thread 7, §10.3); alarms are hard-deleted with the exam (exam-lifecycle Thread 2 / data-admin Thread 7, §12.2). This change modifies no existing requirements. -->

## Impact

- **Sentinel (Rust)**: would gain GDPR-cleared signal capture — active window/process names, active-tab URL, continuous OCR on screen images, device-wide network destination domains — plus the mass-paste detector (≥10 lines/≤1s). None exists today; `recorder.rs` does screen capture only.
- **Backend (Java/Quarkus)**: a rule engine evaluating signals against the forbidden-AI list, an alarm table (type, student session, timestamp, acknowledgement), the ≤1/min de-duplication, and a push path to the teacher UI. No alarm schema exists (`fr_notice` is unrelated announcements).
- **Frontend (Vue)**: a live alarm popup, an event list, and acknowledgement — none exists for violations.
- **Cross-references**: alarm markers on the timeline are `spec-recording-playback` (Thread 4, §8.3); the "file source unavailable" alarm signal comes from `spec-file-tracking` (Thread 5, §11); the admin-managed forbidden-AI list and alarm retention/hard-delete are `spec-data-admin` (Thread 7, §10.3, §12.2) and `exam-lifecycle` (Thread 2 delete cascade); connection-lost detection relates to `spec-live-monitoring` (Thread 3) and `exam-lifecycle` session state (Thread 2).
