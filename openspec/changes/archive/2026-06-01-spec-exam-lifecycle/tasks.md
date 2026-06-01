## 1. Spec authoring (this thread)

- [ ] 1.1 [SPEC] Write `exam-lifecycle` capability spec with per-requirement implementation status
- [ ] 1.2 [SPEC] Record gap cross-references (§6.3 → violation-alarms, §12.2 → data-admin)
- [ ] 1.3 [SPEC] Validate change with `openspec validate spec-exam-lifecycle`

## 2. Exam fields: class + room (§4.2, US-01)

- [ ] 2.1 [GAP] Add `school_class` and `room` columns to `fr_exam` via new Flyway migration (resolve duplicate `V10__*` first → bump to next free version)
- [ ] 2.2 [GAP] Add `schoolClass` and `room` to `Exam` record and `ExamDao` insert/select/update queries
- [ ] 2.3 [GAP] Add `schoolClass` + `room` (NotBlank) to `InsertExam` DTO and `createExam` mutation
- [ ] 2.4 [GAP] Add class + room inputs to proctor create-exam form and `ExamStore.createExam`

## 3. PIN integrity (§4.2, US-02)

- [ ] 3.1 [GAP] Make `createExam` PIN dedup global (check all exams, not `findByTeacher`) — or rely on DB unique constraint with retry-on-violation
- [ ] 3.2 [GAP] Enforce PIN validity window: reject sentinel registration when `now ∉ [startTime, endTime]`

## 4. Student join + session uniqueness (§4.3, §5.1, US-02)

- [ ] 4.1 [GAP] Match student Keycloak class (`schoolClass`) to exam class on registration; reject mismatch
- [ ] 4.2 [GAP] Track active sessions by Keycloak subject in `FranklynWebSocketServer`; reject a second concurrent registration for the same subject

## 5. Recording window (§6.1, §6.2)

- [ ] 5.1 [GAP] Gate recording start to `[startTime − 60 min, endTime]` server-side at registration; reject/no-op if login is >60 min early
- [ ] 5.2 [GAP] Ensure recording ends only on manual student logout, not at exam end time

## 6. Exam deletion (§12.2, US-07)

- [ ] 6.1 [GAP] Extend exam delete to hard-delete all associated data (cascade frames/diffs/events/alarms) — coordinate with `spec-data-admin` (Thread 7)
- [ ] 6.2 [GAP] Define backup-purge step for deleted exams (tracked detail in Thread 7)

## 7. Verification

- [ ] 7.1 [GAP] Update/add `ExamDaoTest` coverage for class/room + global PIN uniqueness
- [ ] 7.2 [GAP] Add tests for PIN-window rejection, session-uniqueness rejection, and recording-window gating
