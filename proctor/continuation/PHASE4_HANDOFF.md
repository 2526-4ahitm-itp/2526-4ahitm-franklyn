# Phase 4 Handoff — Continue the Per-Store and Per-View Cleanup

You are picking up the proctor cleanup at the start of Phase 4. Phase 3 is fully completed and all Apollo/GraphQL dependencies have been deleted.

Read these before touching anything:

1. `proctor/rewrite.md` — the long-form plan. The Progress Tracker (§8) and the Deviations log (§9) are the source of truth.
2. `proctor/AGENTS.md` — the short conventions contract.

## Repo state when this hand-off was written

- Branch: `feat/rewrite-proctor`.
- Working tree: clean.
- Lint, type-check, and build are all **green**.
- Service layer (exams, sessions, notices, user) are all using Villus + Pinia Colada.
- Apollo client store and Apollo dependencies have been completely removed.

## What to do next (in order)

### Step A — KeycloakStore & ThemeStore (Phases 4.1 & 4.2)
- In `src/stores/KeycloakStore.ts`, replace `sessionStorage.stored_session ?? null` parsing with a typed guard. Clear on failure to avoid Chrome/Brave first-load rehydration race.
- In `src/stores/ThemeStore.ts`, drop the `onMounted` hook inside the store factory. Extract a `useResolvedTheme()` helper/composable so the theme resolution logic lives in a centralized place rather than implicitly inside `App.vue`'s watcher.

### Step B — WebsocketStore (Phase 4.3)
- In `src/stores/WebsocketStore.ts`, clean up dead exports (`frameContent`, `selectedSentinelList`, `pageCount`, etc.).
- Promote magic numbers to constants (e.g. `pageSize = 6`, `profiles` list).
- Make `connect()` idempotent and `disconnect()` async-safe (await close).
- Add a re-connect guard on transient close (`onclose` with non-1000 codes).

### Step C — HomeView (Phase 4.4)
- Extract the create-exam modal into a `<NewExamDialog>` component in `src/components/`.
- Extract the filter pill row into `<ExamStatusFilter v-model="filter">`.
- Extract each exam row into `<ExamRow :exam="exam" />`.
- Use helpers in `src/lib/` or local logic for datetime rendering.

### Step D — ExamDetailView (Phase 4.5)
- Reuse `<NewExamDialog>` and extract/reuse a generic `<ConfirmDialog>` for delete.
- Use `formatExamRange` or similar helper from `src/lib/datetime.ts` instead of local time logic.

### Step E — ProctoringView (Phase 4.6)
- Pull the modal/overlay markup into `<ExpandedSentinelOverlay>`.
- Refactor the component to use the extracted components.

### Step F — AdminViews and NavComponent (Phases 4.9 & 4.10)
- In `AdminNoticeBannersView.vue`, reuse the dialog components.
- In `NavComponent.vue`, wrap raw icons in a `<UiIcon>` wrapper.

## Gotchas to remember
1. Always run `bun run lint:check` and `bun run type-check` before presenting or committing your code.
2. Maintain explicit return types on all service functions and composables.
3. Be careful not to introduce floating promises when calling cache invalidation methods. Use `void` to explicitly mark them.
