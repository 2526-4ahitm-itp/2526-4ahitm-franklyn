## Context

Violation-alarms is a large unbuilt FSD capability, alongside file-tracking and recording-playback. The FSD (§10, §11, US-04) wants automatic detect-and-report monitoring with a strict GDPR-cleared signal allow-list, a rule set, a four-type alarm taxonomy, and a ≤10s alarm pipeline (popup + event list + DB + timeline marker) with ≤1/min repeat suppression. The sentinel today captures the screen only; the server has no detection, rule engine, or alarm store. This design records the target architecture and its dependencies.

Verified current state:
- No detection signals captured in `sentinel/src/` — no OCR, process/window enumeration, active-tab URL, network-domain capture, or paste detection.
- No rule engine or alarm code in `server/src/main/java`; no alarm/blocklist table among the Flyway migrations.
- `fr_notice` (`Notice` record: `id`, `NoticeType{ALERT,TIMED,SINGLE}`, `startTime`, `endTime`, `content`) is teacher-authored announcements — no student/exam binding, no alarm semantics. Not the violation-alarm store.
- No violation popup / event list in `proctor/` (`NoticeStore` is for the announcement feature).

## Goals / Non-Goals

**Goals:**
- Capture violation-alarms requirements at FSD target state with accurate status (entirely not-implemented).
- Pin the GDPR boundary explicitly (allowed signals vs forbidden clipboard/keylogging) so implementation cannot drift across it.
- Make cross-thread dependencies explicit (timeline markers, file-source alarm, forbidden-AI list ownership, delete cascade).

**Non-Goals:**
- Implementing detection, the rule engine, alarm storage, or the popup UI (spec thread).
- Defining the playback timeline that renders markers (Thread 4) or the file-source-unavailable signal source (Thread 5) — this spec states the alarm type exists and is driven by those.
- Defining admin management of the forbidden-AI list (Thread 7, §10.3) beyond stating the rule consumes it.

## Decisions

- **Detect-and-report only, never block (FSD-mandated).** §10.1 requires monitoring to be purely detecting and reporting; no blocking or remote control. Recorded as a hard constraint on the future implementation.
- **GDPR signal allow-list is closed.** §10.2 permits exactly: active window/process names, active-tab browser URL, continuous OCR on screen images, device-wide network destination domains. Clipboard content and keylogging are forbidden. The spec states both the allow-list and the prohibition so the boundary is auditable.
- **Uniform rules in v1, no per-exam config.** §10.3 applies one rule set to all exams; the forbidden-AI list (domains/processes) lives in the DB and is admin-managed (ownership in Thread 7). Mass-paste rule is fixed at ≥10 lines within ≤1s.
- **Alarms are a marker source, not the timeline owner.** Alarms are produced and persisted here; the synchronised playback timeline that renders markers is recording-playback (Thread 4, §8.3). Producer and consumer kept separate.
- **Repeat suppression at ≤1 alarm/min per ongoing violation (§10.4).** De-duplication keyed by (student session, violation identity) within a 1-minute window — a server-side rule recorded for implementation.

## Risks / Trade-offs

- [≤10s end-to-end latency, §11] → Capture → transmit → rule-eval → push within 10s constrains OCR cadence and the rule-engine path; flagged for the implementation spike, out of scope for the spec.
- [Continuous OCR + network-domain capture device-wide] → Significant CPU/permission surface on student devices and a real GDPR exposure; the allow-list/prohibition must be enforced in code, not just spec'd.
- [No alarm storage layer exists] → The alarm table must be designed with Thread 7 retention (§12.1, 30 days) and Thread 2 delete cascade (§12.2) in mind, or deletion/retention cannot be honoured — same constraint as video (Thread 4) and diffs (Thread 5).
- [`fr_notice` reuse temptation] → It is announcements, not alarms; reusing it would conflate teacher messages with violation records. The spec marks it out of scope to prevent that.

## Open Questions

- Where does the rule engine run — server-side over transmitted signals, or partly on the sentinel (and how is that reconciled with detect-and-report-only)?
- How is "ongoing violation identity" defined for the ≤1/min suppression (per rule, per domain/process, per signal)?
- What is the alarm schema and how is it keyed to exam + student + session, consistent with the (still-undesigned) stores of Threads 4–5?
- How is the forbidden-AI list structured (domains vs processes, matching semantics) and how does Thread 7 admin management feed it live?
- Connection-lost detection: which component owns the heartbeat/timeout that raises it (live-monitoring Thread 3, exam-lifecycle session state Thread 2, or this capability)?
