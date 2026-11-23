# Continuation Prompt: Student Join/Leave Events (Proctor)

Repo: 2526-4ahitm-franklyn, branch `feat/student-leave-logs` (rebased on `origin/main`). Follow `CLAUDE.md` (bun only, no `.nix` edits without approval, Reka UI, design tokens, propose before new components, conventional commits + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).

## Goal

Proctor (`proctor/`) shows student join/leave events and a per-student list. The server has no event support, so it is faked client-side. Hard requirement: state can never be inconsistent ("absent student without leave event" must be impossible).

## Key facts

- Server `sentinelId` = `UUID.randomUUID()` (v4, no timestamp). `fr_exam_sessions` has no time column. All times come from client observation.
- Proctor websocket connects app-wide (`App.vue`, teacher/admin) with NO pin, so it gets every live sentinel. `ProctoringView` filters the grid client-side via `setExamFilter(sentinelIds from sessions)`.
- `src/lib/presenceTimeline.ts` (pure functions): `applySnapshot`, `mergeJournals`, `pruneJournal`, `isSessionPresent`, `buildTimeline`.
  - Journal = per sentinelId `{joined?, left?}` marks `{at, exact}`.
  - `buildTimeline` always resolves times: join = journal -> examStart -> fallbackTime; leave = exact journal, else min(journal estimate, next session join, examEnd) -> fallbackTime; leave clamped >= join.
  - Per-student sweep with joins first on equal timestamps, so present <=> last event is a join.
- `src/lib/__tests__/presenceTimeline.test.ts`: `bun test`, 11 pass, randomized 3000-seed simulation; mutation-checked. Excluded from tsconfig, but ESLint fails on it ("not found by the project service"). NOT committed yet: fix the ESLint config (allowDefaultProject or a test tsconfig) or move the file, then commit it.
- `WebsocketStore.ts`: `sentinelJournal` persisted in localStorage `franklyn.sentinel.journal` (+ `franklyn.sentinel.online`), merged across tabs via the `storage` event; `recordSnapshot()`; `presenceKnown`; `onlineSentinelIds`; `setExamFilter`.
- `services/examEvents.ts`: `useExamEvents(examId)` -> `students` (grouped by studentId, `present`), `sentinelIds`, `sessionTimes`, `events` (student name, no numbers, `exact` flag shown as "≈"), `currentStudentCount`, `peakStudentCount`. Refetches sessions when unknown online sentinels appear.
- `services/sessions.ts`: `nameSessions` (sessionIndex/studentName, sorted by sentinelId = random but stable; used for download filenames), `groupSessionsByStudent`.
- `ExamDetailView`: Reka `Collapsible` per student, "Download all" per student, per-session download, `downloadSessions()`/`downloadState()`.
- `ProctoringView`: Reka `Tabs` (Events / Students) in a `UiCard`, counter "now/max".

## Open TODOs

1. `ExamDetailView`: use `useExamEvents(examId).sessionTimes` to show each session's join time ("Session n · HH:MM", "≈" when inexact) and order child rows by join time (keep `sessionIndex` for filenames).
2. Make the test file lint-clean and commit it.
3. Run: `nix develop .#proctor --command fr-proctor-pr-check` (from `proctor/`), `bun test src/lib/__tests__`.
4. Verify end-to-end in the browser: sentinel joins and leaves; reload while absent; close the app, leave, reopen; two tabs. The event list and the red student state must always agree.
5. Delete this file once done.
