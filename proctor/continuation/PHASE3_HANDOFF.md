# Phase 3 Handoff — Continue the Villus + Pinia Colada Migration

You are picking up the proctor cleanup mid-Phase-3. Phases 0, 1 and 2
are done. Phase 3 is half done: infrastructure landed, notices and user
were migrated, **exams, sessions, and the Apollo removal are still
pending**.

Read these before touching anything:

1. `proctor/rewrite.md` — the long-form plan. The Progress Tracker
   (§8) and the Deviations log (§9) are the source of truth for what
   already changed vs. what the plan originally said.
2. `proctor/AGENTS.md` — the short conventions contract.
3. The schema at `http://localhost:5050/api/graphql/schema.graphql`
   (the backend dev server). The relevant types are documented in
   `rewrite.md` §7.

## Repo state when this hand-off was written

- Branch: `feat/rewrite-proctor`.
- Working tree: clean apart from `rewrite.md` itself (this commit will
  land it).
- Lint and type-check are both **green** as of commit
  `5fea140 refactor(proctor): migrate user to villus + pinia colada`.
- Apollo is still installed and still wired through
  `stores/ApolloClientStore.ts`. The remaining consumers are:
  - `stores/ExamStore.ts` (used by `HomeView`).
  - Inline `gql` in `ExamDetailView.vue` (Exam fetch, sessions fetch,
    updateExamSchedule, deleteExam, startExam, endExam).
  - Inline `gql` in `ProctoringView.vue` (Exam pin fetch).
- New service files already in `src/services/`:
  - `graphql.ts` — singleton villus client, auth plugin,
    `executeQuery`, `executeMutation`, `normalizeGqlError`,
    `isNormalizedError`.
  - `notices.ts` — `useNotices`, `useCreateNotice`, `useUpdateNotice`,
    `useDeleteNotice`. Mutations invalidate `['notices']`.
  - `user.ts` — `useCurrentUser`, `useUpdateSettings`. Mutation
    invalidates `['user']`.
  - `dismissedNotices.ts` — local UI state composable.
- Deleted: `stores/NoticeStore.ts`, `stores/UserStore.ts`.

## What to do next (in order)

### Step A — `services/exams.ts`

Mirror `services/notices.ts`. Composables:

- `useExamList()` — `query exams { id title pin teacherId startTime endTime startedAt endedAt }`.
- `useExam(id)` — `query examId($id: String!) { ... }`. The `id` is a
  `MaybeRefOrGetter<string>` so the query refetches when the route id
  changes (pinia-colada supports a `key` that takes a getter).
- `useCreateExam()` — `mutation createExam(examInput: InsertExamInput!)`.
- `useUpdateExamSchedule()` — `mutation updateExamSchedule($examId: String!, $examScheduleInput: UpdateExamScheduleInput!)`.
- `useStartExam()`, `useEndExam()`, `useDeleteExam()`.

Cache key conventions:

- List: `['exams']`.
- Detail: `['exams', id]`.

Each mutation invalidates `['exams']` (which clears both the list and
all detail entries with that prefix). For deletion specifically,
remove the detail key first then invalidate the list.

Notes from the schema (`rewrite.md` §7):

- `Exam.startTime` and `Exam.endTime` are `DateTime!` (**non-null**).
  Tighten `src/types/Exam.ts` accordingly — currently it has
  `Date | null` for both, but the schema disagrees. `startedAt` and
  `endedAt` stay nullable.
- The schema returns `Exam.id: String` (nullable!). Keep `id` as
  `string` in our type — it's never null in practice — but be aware.

### Step B — `services/sessions.ts`

One composable: `useExamSessions(examId)` → `query allStudents(examId: String!) { studentId sentinelId examId videoFilePath user { preferredUsername givenName familyName } }`.

The returned `user` is `User!` in the schema; `givenName`/`familyName`
are nullable. Mirror this in a local `ExamSession` type next to the
composable (don't re-declare it inside views).

### Step C — Migrate `HomeView.vue`

Replace `useExamStore()` with `useExamList()` and `useCreateExam()`.
After `useCreateExam().mutateAsync(...)` resolves, navigate to
`/exams/${created.id}` (current behaviour). Drop the unused
`loading`/`error` refs from the old store consumer pattern; rely on
pinia-colada's `isLoading` and `error`.

### Step D — Migrate `ExamDetailView.vue`

Replace every inline `gql`/`client.query`/`client.mutate` with the new
composables. Drop the inline `Exam` and `ExamSession` interfaces — use
the ones in `src/types/`. Use `useExam(examId)` and
`useExamSessions(examId)`.

The "Phase 4.5" items in the plan also call for extracting `<NewExamDialog>`
and a generic `<ConfirmDialog>`. **Do not** do that here — leave it
for Phase 4. This commit should be data-layer only.

### Step E — Migrate `ProctoringView.vue`

Replace the inline `client.query` for exam pin with `useExam(examId)`
(small selection set is fine — it's the same cache entry as the
detail view, deduplicated for free). Drop the Apollo import.

### Step F — Delete Apollo

Once steps A–E land and the app lints/types/builds, delete in one
commit:

- `src/stores/ApolloClientStore.ts`.
- The `@apollo/client` and `graphql` deps from `package.json`.
- Run `bun install` to refresh the lockfile.

### Step G — AGENTS.md caching note

Append a short paragraph to `proctor/AGENTS.md` §4 explaining the
two-layer cache:

> Villus is configured as a no-cache transport (`cachePolicy:
> 'network-only'` inside `executeQuery`). The only cache layer is Pinia
> Colada, which gives us stale-while-revalidate by default. Use the
> default behaviour everywhere; only set `staleTime` / `gcTime` /
> `refetchOn*` per call when there is a concrete reason.

## Commit cadence

Use the existing conventional commit scheme. One commit per logical
step works well (see existing history). Short messages. Add
`Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>` at the end of
each commit.

Suggested commit titles for this batch:

- `feat(proctor): add exam and session services`
- `refactor(proctor): migrate HomeView to exam composables`
- `refactor(proctor): migrate ExamDetailView to exam composables`
- `refactor(proctor): migrate ProctoringView to exam composables`
- `chore(proctor): drop apollo client`
- `docs(proctor): document the two-layer cache in AGENTS.md`

## Gotchas already discovered

1. **`bun add` needs to run from `proctor/`.** Running it from the
   repo root installs into the wrong workspace.
2. **`UseQueryReturn` / `UseMutationReturn` must be re-exported** as
   explicit return types on every exported composable — the strict
   eslint rule `@typescript-eslint/explicit-module-boundary-types`
   complains otherwise. See `services/notices.ts` for the pattern.
3. **Don't use `void` as a `TData` generic** — eslint's
   `@typescript-eslint/no-invalid-void-type` rejects it. Use `null`
   and `return null` for "no useful data" mutations like delete.
4. **Pinia Colada's mutation runs the async fn through `mutateAsync`.**
   Calling `.mutate()` instead silently throws into the `error` ref
   without awaiting. Use `.mutateAsync()` in views.
5. **The auth plugin reads from `useKeycloakStore()` inside the
   callback** so it can be called outside component setup. Pinia
   must already be installed by the time the first query runs — and
   it is, because `main.ts` does `app.use(pinia)` before
   `installVillus(app)`.

## After Phase 3 is done

Move to Phase 4. Items already done opportunistically (per
`rewrite.md` §9):

- Most of Phase 4.8 (SettingsView).
- Half of Phase 4.2 (theme cross-store mutation gone).
- All of Phase 4.11 (App.vue dismissed-notice composable + locale init
  removed).

Phase 4 then becomes:

- 4.1 KeycloakStore — typed session reader, debounced refresh.
- 4.2 (remaining) — drop `onMounted` from ThemeStore factory; extract
  `useResolvedTheme()`.
- 4.3 WebsocketStore — dead exports, magic numbers, idempotent
  connect, reconnect-on-close.
- 4.4 HomeView — dialog/row/filter extraction.
- 4.5 ExamDetailView — dialog reuse, drop inline `getExamTime`.
- 4.6 ProctoringView — `<ExpandedSentinelOverlay>` extraction.
- 4.7 Protobuf — already decided to keep wired (rewrite.md §6.3); just
  add the AGENTS.md note if missing.
- 4.9 AdminNoticeBannersView — dialog reuse.
- 4.10 NavComponent — `<UiIcon>` wrapper.

Then Phase 5 (router), Phase 6 (UI primitives — these emerge from
Phase 4 extractions, don't pre-build), Phase 7 (final pass).
