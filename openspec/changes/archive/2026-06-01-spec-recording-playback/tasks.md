## 1. Spec authoring (this thread)

- [ ] 1.1 [SPEC] Write `recording-playback` capability spec with per-requirement implementation status
- [ ] 1.2 [SPEC] Record cross-references (timeline ← file-tracking Thread 5, violation-alarms Thread 6; storage/retention ← data-admin Thread 7, exam-lifecycle Thread 2 delete)
- [ ] 1.3 [SPEC] Validate change with `openspec validate spec-recording-playback --strict`

## 2. Video encoding (§8.1)

- [ ] 2.1 [GAP] Add an H.265 encode + MP4 mux path to the sentinel (or server-side) pipeline alongside the live JPEG path
- [ ] 2.2 [GAP] Ensure recordings contain no audio track

## 3. Storage and retrieval (§8, US-06, §17)

- [ ] 3.1 [GAP] Design a video store (filesystem layout + DB metadata) keyed by exam + student + session, compatible with retention (§12.1) and delete cascade (§12.2)
- [ ] 3.2 [GAP] Persist a recording when a session ends
- [ ] 3.3 [GAP] Add an authorised retrieval endpoint for raw video (teacher own exams / admin all)

## 4. Playback UI (§8.2)

- [ ] 4.1 [GAP] Build a playback view with play/pause and frame-by-frame stepping
- [ ] 4.2 [GAP] Implement jump-to-alarm/marker navigation

## 5. Timeline (§8.3)

- [ ] 5.1 [GAP] Build a synchronised timeline overlaying screen events, file diffs (Thread 5), and alarm markers (Thread 6)
- [ ] 5.2 [GAP] Seek video when a timeline event is selected

## 6. Verification

- [ ] 6.1 [GAP] Confirm stored video is MP4/H.265, no audio, and replays on the proctor UI
- [ ] 6.2 [GAP] Confirm §17 acceptance: student exam videos are stored and playable
