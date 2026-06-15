## 1. Spec authoring (this thread)

- [x] 1.1 [SPEC] Write `violation-alarms` capability spec with per-requirement implementation status
- [x] 1.2 [SPEC] Record cross-references (timeline markers ← recording-playback Thread 4 §8.3; file-source alarm ← file-tracking Thread 5 §11; forbidden-AI list + retention/hard-delete ← data-admin Thread 7 §10.3/§12.2, exam-lifecycle Thread 2; connection-lost ← live-monitoring Thread 3 / exam-lifecycle Thread 2) and note `fr_notice` is announcements, not alarms
- [x] 1.3 [SPEC] Validate change with `openspec validate spec-violation-alarms --strict`

## 2. Signal capture (§10.2)

- [ ] 2.1 [GAP] Add sentinel capture of active window/process names and active-tab browser URL
- [ ] 2.2 [GAP] Add continuous OCR on screen images
- [ ] 2.3 [GAP] Add device-wide network destination-domain capture (with required OS permissions)
- [ ] 2.4 [GAP] Ensure clipboard content and keystrokes are never captured (GDPR boundary)

## 3. Rule engine (§10.1, §10.3)

- [ ] 3.1 [GAP] Auto-start monitoring on student connect; detect-and-report only (no blocking)
- [ ] 3.2 [GAP] Evaluate signals against the admin-managed forbidden-AI list (domains/processes)
- [ ] 3.3 [GAP] Implement the mass-paste rule (≥10 lines within ≤1s)
- [ ] 3.4 [GAP] Apply one uniform rule set to all exams (no per-exam config)

## 4. Alarm pipeline and persistence (§10.4, §11, US-04)

- [ ] 4.1 [GAP] Design an alarm table (type, student session, timestamp, acknowledgement) keyed by exam + student + session, compatible with retention (§12.1) and delete cascade (§12.2)
- [ ] 4.2 [GAP] On a hit, produce live teacher popup + event-list entry + DB record + timeline marker
- [ ] 4.3 [GAP] Implement ≤1 alarm/min repeat suppression per ongoing violation
- [ ] 4.4 [GAP] Support the four mandatory alarm types (connection lost, exam-rule, AI suspicion, file source unavailable)
- [ ] 4.5 [GAP] Make alarms acknowledgeable; no escalation levels; no email in v1

## 5. Integration (cross-thread)

- [ ] 5.1 [GAP] Consume the file-source-unavailable signal from file-tracking (Thread 5, §11)
- [ ] 5.2 [GAP] Emit alarm markers for the synchronised playback timeline (Thread 4, §8.3)
- [ ] 5.3 [GAP] Wire connection-lost detection to session/heartbeat state (Thread 3 / Thread 2)

## 6. Verification

- [ ] 6.1 [GAP] Confirm an alarm appears within 10s as popup + event list + DB record + marker (US-04)
- [ ] 6.2 [GAP] Confirm an ongoing violation yields at most 1 alarm/minute
- [ ] 6.3 [GAP] Confirm clipboard/keystrokes are never captured (GDPR boundary)
