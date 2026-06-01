## 1. Spec authoring (this thread)

- [x] 1.1 [SPEC] Write `data-admin` capability spec with per-requirement implementation status
- [x] 1.2 [SPEC] Record cross-references (hard-delete/retention targets ← recording-playback Thread 4, file-tracking Thread 5, violation-alarms Thread 6, exam-lifecycle Thread 2; forbidden-AI list consumer ← violation-alarms Thread 6 §10.3; role gating ← auth-identity Thread 1) and note current `ExamDao.delete` is teacher-scoped row-only (no cascade)
- [x] 1.3 [SPEC] Validate change with `openspec validate spec-data-admin --strict`

## 2. Retention (§12.1)

- [ ] 2.1 [GAP] Add a scheduled cleanup keyed off exam end + 30 days, enumerating all data types
- [ ] 2.2 [GAP] Decide whether retention deletion reuses the manual hard-delete cascade or a separate path

## 3. Hard-delete cascade (§12.2, US-07)

- [ ] 3.1 [GAP] Extend exam deletion to cascade-delete video (Thread 4), diffs (Thread 5), events/alarms (Thread 6), metadata (Thread 2), and backups
- [ ] 3.2 [GAP] Ensure backups (wherever stored) are reached by the cascade
- [ ] 3.3 [GAP] Keep deletion immediate and total (no soft-delete / deferral)

## 4. Data access (§13.2)

- [ ] 4.1 [GAP] Enforce teacher-own-exam scoping uniformly; close the non-teacher-scoped `examId` read (cross-cutting finding)
- [ ] 4.2 [GAP] Grant admin full access to all exam data (Admin role from Thread 1)

## 5. Forbidden-AI list management (§10.3)

- [ ] 5.1 [GAP] Add a DB-backed forbidden-AI list (domains/processes) with admin-gated CRUD
- [ ] 5.2 [GAP] Expose the list to the violation-alarms rule engine (Thread 6)

## 6. Encryption / audit stance (§13.3, §13.4)

- [ ] 6.1 [GAP] Confirm TLS in transit (deployment) and document at-rest-unencrypted as an accepted risk
- [x] 6.2 [SPEC] Record that no formal audit/revision facility is required in v1

## 7. Verification

- [ ] 7.1 [GAP] Confirm deleting an exam immediately purges video, diffs, alarms, metadata, and backups (US-07)
- [ ] 7.2 [GAP] Confirm exam data older than 30 days from exam end is removed (§12.1)
- [ ] 7.3 [GAP] Confirm teacher sees only own exams and admin sees all (§13.2)
