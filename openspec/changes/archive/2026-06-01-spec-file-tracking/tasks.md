## 1. Spec authoring (this thread)

- [x] 1.1 [SPEC] Write `file-tracking` capability spec with per-requirement implementation status
- [x] 1.2 [SPEC] Record cross-references (timeline consumer ← recording-playback Thread 4 §8.3; file-source-unavailable alarm ← violation-alarms Thread 6 §11; diff hard-delete ← data-admin Thread 7 / exam-lifecycle Thread 2 §12.2; session binding ← exam-lifecycle Thread 2)
- [x] 1.3 [SPEC] Validate change with `openspec validate spec-file-tracking --strict`

## 2. File-source detection (§9.1)

- [ ] 2.1 [GAP] Add a sentinel file-source probe deriving observed files from the active-window app and last-saved file
- [ ] 2.2 [GAP] Classify text vs binary and exclude binary files (§9.3)

## 3. Diff capture (§9.1, §9.2)

- [ ] 3.1 [GAP] Add a per-minute scheduler that forces a diff run over all observed files
- [ ] 3.2 [GAP] Generate incremental diffs against each file's last saved baseline; persist the baseline between runs
- [ ] 3.3 [GAP] Define a diff wire message (`proto.rs` is currently a stub) and carry diffs to the server

## 4. Diff storage and session binding (§9.2, US-05)

- [ ] 4.1 [GAP] Design a diff store (DB table) keyed by exam + student + session, compatible with retention (§12.1) and delete cascade (§12.2)
- [ ] 4.2 [GAP] Persist diff-only (no full snapshot as primary model) and bind each diff to the student session
- [ ] 4.3 [GAP] Do not reconstruct deleted files (§9.3)

## 5. Integration (cross-thread)

- [ ] 5.1 [GAP] Emit a signal when the monitored file source becomes unavailable to drive the §11 alarm (Thread 6)
- [ ] 5.2 [GAP] Expose diffs for the synchronised playback timeline (Thread 4, §8.3)

## 6. Verification

- [ ] 6.1 [GAP] Confirm a per-minute incremental text diff is captured, stored diff-only, and bound to the correct student session (US-05)
- [ ] 6.2 [GAP] Confirm binary files and deleted-file reconstruction are excluded (§9.3)
