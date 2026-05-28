# Proctor Cleanup Plan

> **Scope shift:** the original plan was a clean-room rewrite. After analysing
> the current codebase, an in-place **structural cleanup** is more efficient.
> Most issues are local (dead code, duplicated patterns, broken references,
> inconsistent style) and do not require throwing away working code. The
> architectural goals from the rewrite spec still apply — they will be reached
> by refactor, not re-creation.

> **Read order for the agent:** this file → `AGENTS.md` (to be created in Phase 0)
> → the relevant phase section below. Do not start a phase until the previous
> one is green (lint + type-check + manual smoke).

---

## 1. Architectural Goals (unchanged from spec)

- **GraphQL transport:** replace `@apollo/client` with **Villus**. Tagged
  template `gql` queries only. No codegen, no `schema.graphql` build step.
  Local TS types in Proctor mirror request/response shapes.
- **Data layer:** **Pinia Colada** on top of Villus for query cache,
  deduplication, stale/revalidate, and mutation-triggered invalidation. This
  is the service layer. Pinia stores hold **only local/UI state** (theme,
  Keycloak session, WebSocket frame map, dismissed notices).
- **Pattern:** MVVM. Components consume composables / service functions; raw
  `gql` calls never appear in views.
- **Component library:** Reka UI primitives wrapped in project components in
  `src/components/ui/`. Components emerge as views are refactored, not
  upfront.
- **Styling:** all colours, sizes, radii, spacing through CSS custom
  properties. Existing palette stays. Drop heavy hover transitions and
  backdrop blurs. No hardcoded `rgba(0,0,0,…)` literals — everything resolves
  to a token.
- **i18n:** `vue-i18n`. Every user-facing string goes through `t()`. Dates
  always through `d()` with named formats.
- **WebSocket / protobuf:** unchanged protocol. Existing JSON payloads stay
  for now (protobuf wiring in `vite.config.ts` is in place but unused — see
  §4.7).
- **Auth:** Keycloak JS stays. Fix the stored-session race that breaks
  Chrome/Brave on first load.
- **Build tooling:** Bun, Vite, vue-tsc, ESLint strict. Stays.
- **Testing:** out of scope.
- **Agent conventions:** Proctor-only `AGENTS.md` is canonical. Future
  agentic work (opencode + Claude) consumes that file.

---

## 2. Inventory of Flaws Found in Current Code

References are `file:line` where useful. Grouped by severity.

### 2.1 Broken / Dead

1. **Duplicate route import** — `router/index.ts:4,6` both alias `HomeView.vue`
   as `ExamView` and `HomeView`. `ExamView` is dead.
2. **Phantom `de_at` locale** — `SettingsView.vue:69` offers `de_at`, but
   only `en.json` and `de.json` exist. Selecting it silently falls back.
3. **Duplicate CSS custom property** — `assets/main.css:30-31` declares
   `--status-live` twice (the first is dead).
4. **Dead store exports in `WebsocketStore`** — `frameContent`,
   `selectedSentinelList`, `pageCount`, `subscribeToWanted`,
   `increasePageCount`, `decreasePageCount` are exported but unused or
   overlapping with `currentPage`/`totalPages`. Two paging implementations
   coexist.
5. **`updateSettings` not exposed from `UserStore`** vs the cross-store
   mutation: `UserStore.userInfo` writes `theme.value = <Theme>res.data...`
   into a *foreign* store via `storeToRefs`. Old-style angle-bracket cast.
6. **Hardcoded `'en-US'` formatters** — `ExamDetailView.vue:163`
   (`formatTime`), `AdminNoticeBannersView.vue:59` (`formatDate`). Bypasses
   i18n entirely.
7. **`AdminNoticeBannersView` has zero i18n.** All headings, button labels,
   error strings, status badges are hardcoded English. `formatTypeLabel`
   returns English regardless of locale.
8. **`SettingsView.themeOptions` is a `let`, not a `ref`/`computed`.** The
   `watch` on `locale` reassigns it, which Vue cannot track — the UI never
   re-renders translated labels. Lines 60-64 and 38-49.
9. **`SettingsView` ignores promise rejections** — `@click="selectTheme(...);
   updateUserSettings(selectedLanguage!)"` invokes a Promise without `await`
   or `.catch` and uses the `!` non-null assertion on a possibly-undefined
   value.
10. **`@click="updateUserSettings(option.value); locale = option.value"`** —
    multi-statement template expression; fires the mutation **and** flips
    locale synchronously even if the server rejects.
11. **`console.warn(theme.value)` debug logs** — `SettingsView.vue:21,74`.
12. **Type drift on `Exam`** — `types/Exam.ts` declares Date|null fields;
    `ExamDetailView.vue:28-37` redeclares it inline with string|null
    (because Apollo `dateField` only converts cached reads, never the
    interface). Consumers can't tell what they're holding.
13. **Apollo `fetchPolicy: 'network-only'` everywhere** (`ExamStore.ts:33`,
    `NoticeStore.ts:31`, `ExamDetailView.vue:68`, `:99`,
    `ProctoringView.vue:42`). The cache is bypassed in every fetch — paying
    Apollo's weight for nothing.
14. **Fragile error pattern-matching** — `NoticeStore.ts:36-38` reroutes any
    error containing `'403'`. `NoticeStore.ts:128` swallows errors whose
    message includes `'Unknown type'`.
15. **Router guard double-prompt** — `router/index.ts:64-66` and `:73-75`
    both redirect to `/not-allowed` based on the same condition path.
    Refactor into a single decision tree.
16. **Keycloak rehydration race** — `KeycloakStore.ts:26` parses
    `sessionStorage.stored_session ?? null` via `JSON.parse`; on a stale
    token the catch block writes `'undefined'` (string) back. Reported as
    the Chrome/Brave breakage. Switch to a typed guard and clear-on-fail.
17. **`ProctoringView` re-connect bug** — store's `connect()` early-returns
    if `socket.value` is set; on route change the unmounted view calls
    `disconnect()`, but a stored token race can leave a partly-cleared
    state. Add a deterministic teardown order.
18. **Index `<html lang="">`** — empty `lang` attribute, blocks screen
    readers and breaks `hreflang` heuristics.
19. **App.vue + SettingsView duplicate locale init** — both call
    `userStore.init()`, both sync `locale.value` from `userStore.language`,
    both keep their own watch.

### 2.2 Architecture / Pattern

20. **Stores mix transport + state + business logic.** `ExamStore`,
    `NoticeStore`, `UserStore` all contain `gql` calls. With Villus +
    Pinia Colada this moves out: the store keeps UI state only.
21. **No service layer.** Views call `useApolloClientStore().client.query`
    directly (`ExamDetailView`, `ProctoringView`). Violates MVVM.
22. **Inline GraphQL fragments duplicated** — the `Exam` selection set
    appears in `ExamStore`, `ExamDetailView`, and `ProctoringView` with
    slightly different field sets each time.
23. **Modal pattern duplicated 5×** (HomeView wizard, ExamDetailView edit,
    ExamDetailView delete, AdminNoticeBannersView create, edit, delete).
    Each rolls its own overlay + close-on-self CSS.
24. **Form-control CSS duplicated** in every view. Same for `.exam-row /
    .notice-row / .session-row` cards.
25. **Date parsing duplicated** — `formatDateLocal`, `parseDateTime`,
    `formatDateTimeInput`, `toDate`, plus inline `new Date(...).split(...)`
    in HomeView. One `lib/datetime.ts` covers all of it.
26. **`getExamStatus` / `examStatusTranslated` duplicated** in HomeView and
    ExamDetailView. Belongs in a single `lib/examStatus.ts` (or composable).
27. **Theme handling split** between `ThemeStore`, `UserStore`, App.vue, and
    SettingsView. Two sources of truth (pinia-persisted state + backend
    user settings) with no defined resolution rule.
28. **Persisted Pinia plugin used only for one field** (`ThemeStore`).
    Either drop it and source theme from backend on boot, or document the
    "local takes precedence until login" rule explicitly.
29. **No GraphQL error normalisation.** Every store catches `e instanceof
    Error ? e.message : 'Failed to …'`. Centralise.

### 2.3 Style / Hygiene

30. **Mixed quote styles, mixed `.ts` import suffixes** — some imports
    write `'.ts'` extension, some omit. Prettier should enforce one. ESLint
    config doesn't require explicit extensions either way.
31. **Inconsistent semicolons** — `UserStore.ts` uses semicolons, others
    don't. Prettier config doesn't enforce.
32. **`.ts` files import from each other with inconsistent spacing**
    (`{theme}` vs `{ theme }`). Prettier issue.
33. **`bootstrap-icons` raw `<i class="bi bi-…"/>` strings everywhere** —
    no wrapper component. A `<UiIcon name="x-lg"/>` would centralise.
34. **JetBrains Mono only used in 3 spots** (`.exam-meta-pin`, `.pin-badge`,
    `NotAllowedView .code`). Define `--font-mono` token and reference it.
35. **Heavy hover transitions to remove** — `.exam-row:hover transform:
    translateY(-2px)` + `box-shadow: 0 8px 24px …`, `.notice-row:hover`
    same. Replace with token-driven `border-color` change.
36. **No `:focus-visible` state on `.exam-row` / `.notice-row`** even
    though they act as buttons (click handlers).
37. **`alt="Logo"` and other a11y strings hardcoded** — should be `t()`.

### 2.4 Tooling

38. **`vite.config.ts` wires `bufGenerate()`** that copies protobuf gen
    output to `src/proto`, but no source file imports from `@proto`.
    Either start using it (replace JSON over the wire) or remove the
    plugin and the dependency. Per spec the WS protocol stays JSON for
    this cleanup — so **remove the plugin** and the buf devDeps.
39. **`run-p type-check "build-only {@}"`** runs type-check and build in
    parallel; build can emit before type-check fails. Make them sequential
    (`run-s`).
40. **`installer` dep `"install"`** in dependencies — junk leftover.
41. **`rxjs` is a dep but no file imports it.**
42. **`@bufbuild/buf`, `@bufbuild/protobuf`, `@bufbuild/protoc-gen-es`**
    can move to devDependencies (or be removed if §4.7 lands).
43. **Empty README.md** still says "Vue 3 + Vite template". Replace with
    Proctor-specific bootstrap doc.

---

## 3. Updated Continuation Prompt (for the agent doing the work)

> You are cleaning up `proctor/` — the Vue 3 SPA of Franklyn. Do **not**
> start a clean-room rewrite. Work file-by-file, phase-by-phase, per
> `proctor/rewrite.md`. Architectural rules (data layer, service pattern,
> styling, i18n) are in `proctor/AGENTS.md` — read that before each phase.
> Every phase ends with: `bun lint`, `bun type-check`, and a manual smoke
> of the affected view in a browser. The backend (`graphql/`, `ws/`) is
> untouched. Locales must stay in sync — every new key lands in `en.json`
> and `de.json` in the same PR.

---

## 4. Phased Task List

Each phase is independently mergeable.

### Phase 0 — Foundation (no behaviour change)

- [ ] Create `proctor/AGENTS.md` with: project layout, MVVM rule, data-layer
  rule, styling tokens, i18n rule, naming conventions, "never inline gql
  in a view" rule, phase status (this file is the long-form; AGENTS.md is
  the short-form contract).
- [ ] Replace `proctor/README.md` template boilerplate with project intro
  + links to AGENTS.md and rewrite.md.
- [ ] Set `<html lang="en">` in `index.html`.
- [ ] Remove dead deps: `install`, `rxjs`. Keep `@bufbuild/*` (per §6.3).
- [ ] Change `package.json` build script to `run-s type-check build-only`.
- [ ] Tighten Prettier config to lock quote style, semicolons, and trailing
  commas. Run `bun format`. One commit, no logic change.
- [ ] Drop the unused `ExamView` import in `router/index.ts`.
- [ ] Remove `console.warn` debug calls in `SettingsView.vue`.
- [ ] Fix `:root` duplicate `--status-live` in `assets/main.css`.

### Phase 1 — Tokens and shared CSS

- [ ] Audit every `.vue` `<style scoped>`. Move modal/form/card patterns
  to `assets/styles/components.css` (or `@layer components` if we go that
  route). Tokenize:
  - `--space-1` … `--space-8`
  - `--radius-sm`, `--radius-md`, `--radius-lg`
  - `--font-mono`
  - `--shadow-card`, `--shadow-modal` (replacing inline `rgba(0,0,0,…)`)
- [ ] Replace `box-shadow: 0 8px 24px rgba(0,0,0,0.15)` hover effects with
  token-driven `border-color: var(--primary)` only (per spec: no heavy
  hovers).
- [ ] Remove the `rgba(0, 0, 0, 0.4)` modal overlays; introduce
  `--bg-overlay` token (light/dark aware).
- [ ] Add `--font-mono` token and replace 3 inline `JetBrains Mono` refs.
- [ ] Add `:focus-visible` styles for `.exam-row` / `.notice-row`.

### Phase 2 — i18n completeness

- [ ] Translate **every** string in `AdminNoticeBannersView.vue`. Add
  keys under `admin.notices.*`.
- [ ] Translate `NavComponent.vue`: "Admin", "FRANKLYN" wordmark stays as
  brand; all aria-labels go through `t()`.
- [ ] Remove the phantom `de_at` option from `SettingsView` (or add a
  proper `de_at.json` if the user wants three locales — leave `TODO` for
  product decision).
- [ ] Replace every `toLocaleString('en-US', …)` / `toLocaleTimeString('en-
  US', …)` with `d()` from vue-i18n.
- [ ] Add datetime format `datetime` (date + time) to both locales for
  modal date inputs.
- [ ] Linter rule (or pre-commit grep) to reject string literals inside
  `>{{ … }}<` template positions. Optional; documented in AGENTS.md.

### Phase 3 — Service layer (Villus + Pinia Colada)

> This is the biggest phase. Land it behind a feature branch and migrate
> one resource at a time. Apollo stays installed until the last consumer
> is gone, then it's removed in a single commit.

- [x] Add deps: `villus`, `@pinia/colada`. Wire Villus client in
  `src/services/graphql.ts` with the Keycloak auth fetcher (replaces
  `ApolloClientStore`'s SetContextLink).
- [x] Wire `@pinia/colada` plugin in `main.ts`.
- [x] Create `src/services/` per-resource files. Each exports composables
  (`useExamList`, `useExam`, `useCreateExam`, …) backed by Pinia Colada's
  `useQuery` / `useMutation`. Local types in `src/types/`.
- [x] **Migration order** (smallest blast radius first):
  1. `NoticeStore` → `services/notices.ts` + `useDismissedNotices`
     composable for the local dismissed-IDs state.
  2. `UserStore` → `services/user.ts` (`useUser`, `useUpdateSettings`).
     The pinia store keeps only the keycloak claims surface.
  3. `ExamStore` → `services/exams.ts` (`useExamList`, `useExam`,
     `useCreateExam`, `useUpdateExamSchedule`, `useStartExam`,
     `useEndExam`, `useDeleteExam`).
  4. Inline gql in `ExamDetailView` / `ProctoringView` moves to
     `services/exams.ts` and `services/sessions.ts`.
- [x] Mutation invalidations defined alongside each mutation
  (`onSuccess: invalidate(['exams'])`). No view triggers refetch directly.
- [x] **Delete** `ApolloClientStore.ts` and `@apollo/client` + `graphql`
  deps once all consumers are migrated.
- [x] Centralise error normalisation in `services/graphql.ts`
  (`normalizeGqlError(err) → { code, message, traceId }`). Stores/views
  consume normalised errors, never substring-match on `.message`.
- [x] Document caching strategy in AGENTS.md (stale-while-revalidate by
  default, explicit `network-only` only where required).

### Phase 4 — Per-store and per-view cleanup

#### 4.1 `KeycloakStore`

- [ ] Replace `sessionStorage.stored_session ?? null` parse with a typed
  reader that returns `undefined` on any parse/shape failure and
  *removes* the key on failure (currently writes the string
  `"undefined"`).
- [ ] Verify the Chrome/Brave first-load case manually after the fix.
- [ ] Stop calling `keycloak.updateToken(30)` from `ApolloClientStore`
  (which is being deleted). Move it into the Villus auth fetcher and
  debounce — one refresh in flight at a time.

#### 4.2 `ThemeStore`

- [ ] Drop the `onMounted` inside the store factory — store factories
  may be called outside component setup, where `onMounted` is a no-op.
  Initialise via an explicit `applyTheme()` from `main.ts` once.
- [ ] Define resolution rule for theme:
  1. If user is logged in and `user.theme` is set → that wins.
  2. Else local persisted store value.
  3. Else `SYSTEM`.
  Implement in one place (composable `useResolvedTheme()`), not three.

#### 4.3 `WebsocketStore`

- [ ] Remove dead exports: `frameContent`, `selectedSentinelList`,
  `pageCount`, `subscribeToWanted`, `increasePageCount`,
  `decreasePageCount`. Keep the working watch-based subscription model.
- [ ] Promote magic numbers (`pageSize = 6`, `'LOW' | 'HIGH'` profiles) to
  named constants exported from the store.
- [ ] Make `connect()` idempotent and `disconnect()` async-safe (await
  socket close before clearing state).
- [ ] Add a re-connect guard on transient close (`onclose` with
  `wasClean=false`) — currently the view goes blank with no signal.

#### 4.4 `HomeView`

- [ ] Extract create-exam modal into `<NewExamDialog>` component
  (Reka `DialogRoot`).
- [ ] Move `getExamStatus` into `lib/examStatus.ts` and import.
- [ ] Move `getExamTime` into `lib/datetime.ts` (`formatExamRange(exam)`).
- [ ] Move the filter pill row into `<ExamStatusFilter v-model="filter"
  />`.
- [ ] Move each exam row into `<ExamRow :exam="…" />`.

#### 4.5 `ExamDetailView`

- [ ] Drop the inline `Exam` and `ExamSession` interfaces; import from
  `types/`.
- [ ] Replace inline gql calls with `useExam(id)` / `useUpdateExamSchedule`
  / `useStartExam` / `useEndExam` / `useDeleteExam` /
  `useExamSessions(id)` composables.
- [ ] Reuse `<NewExamDialog>` and a generic `<ConfirmDialog>` for delete.
- [ ] Use `formatExamRange` instead of the local `getExamTime`.

#### 4.6 `ProctoringView`

- [ ] Replace inline gql with `useExam(id)` (smaller selection set if
  needed — Villus allows per-call selection).
- [ ] Hook lifecycle: `onBeforeUnmount` does the disconnect; relying on
  `onUnmounted` only works after the next tick — fine but document.
- [ ] Pull the modal/overlay markup into `<ExpandedSentinelOverlay>`.

#### 4.7 Protobuf — keep wired, keep unused (per §6.3 decision)

- [ ] WS payloads stay JSON; do **not** remove `bufGenerate()`,
  `@bufbuild/*`, or the `@proto` alias. The generated code is available
  for a follow-up ticket that flips the WS protocol to protobuf.
- [ ] Add a one-line note in `AGENTS.md` so future agents don't delete
  the plugin as dead code.

#### 4.8 `SettingsView`

- [ ] Convert `themeOptions` to a `computed` so locale changes propagate.
- [ ] Drop the multi-statement template expressions; one handler per
  event with `await` + try/catch.
- [ ] Drop the `selectedLanguage!` non-null assertion; guard properly.
- [ ] Remove duplicated locale init that lives in App.vue.

#### 4.9 `AdminNoticeBannersView`

- [ ] Full i18n pass (see Phase 2).
- [ ] Replace the three modals with `<ConfirmDialog>` / a generic
  `<FormDialog>` driven by Reka.

#### 4.10 `NavComponent`

- [ ] All strings through `t()`.
- [ ] `<UiIcon name="gear"/>` wrapper instead of raw `<i class="bi …"/>`.
- [ ] Settings/admin buttons get proper aria-labels via `t()`.

#### 4.11 `App.vue`

- [ ] Move dismissed-notice management out into
  `useDismissedNotices()` composable (uses localStorage). The view stays
  thin.
- [ ] Drop locale init from App.vue (lives in `main.ts` after Phase 3).

### Phase 5 — Router

- [ ] Collapse the guard's two `/not-allowed` branches into one decision
  tree.
- [ ] Centralise role lookup in `useRoles()` composable so route guards
  and views don't both reach into `kc.keycloak.tokenParsed`.
- [ ] Lazy-import each view (`component: () => import('@/views/…')`) to
  shrink the entry bundle.
- [ ] Drop the duplicate `/proctoring` and `/proctoring/:id` definitions;
  use a single optional-param route.

### Phase 6 — Component library skeleton

> Built incrementally as views are refactored. Don't pre-build.

- [ ] `src/components/ui/Dialog.vue` — Reka `DialogRoot`/`Portal`/
  `Overlay`/`Content` wrapper, tokenised.
- [ ] `src/components/ui/Icon.vue` — `<UiIcon name="x-lg" :label="…"/>`.
- [ ] `src/components/ui/TextField.vue`, `DateField.vue`, `TimeField.vue`
  — only when the first repeat appears.
- [ ] `src/components/ui/Badge.vue` for status pills.
- [ ] `src/components/ui/Card.vue` (or just a class) for the
  `.exam-row` / `.notice-row` repetition.

### Phase 7 — Final pass

- [ ] Remove `pinia-plugin-persistedstate` if Phase 4.2 makes it
  redundant; otherwise document it explicitly in AGENTS.md.
- [ ] Run a `bun lint` with `--max-warnings=0` and fix everything.
- [ ] One-pass scan for `console.log` / `console.warn` left behind.
- [ ] Update screenshots in README.

### Phase 8 — PR Readiness

- [ ] Run Nix PR checks: `nix develop .#proctor --command fr-proctor-pr-check`.
- [ ] Correct stale forward-references in `rewrite.md §9`.
- [ ] Open PR against `main`: `refactor(proctor): structural cleanup (Phases 0–7)`.
- [ ] Manual smoke of all five views in both locales.
- [ ] Write `continuation/PHASE9_HANDOFF.md` if review surfaces follow-up work.

---

## 5. Out of scope (documented for the user, not the agent)

- Backend changes (`graphql/`, `ws/`, Keycloak realm config).
- WS protocol changes (binary protobuf migration is its own ticket).
- Tests.
- Visual redesign beyond the spec's "drop heavy hovers and blurs".
- Adding new product features.

---

## 6. Decisions (resolved with user)

1. **`de_at` removed.** Phase 2 drops the option from `SettingsView` and
   no `de_at.json` is created.
2. **Theme resolution rule (conventional):** backend `user.theme` is the
   source of truth once the user is loaded; the local persisted Pinia
   value only seeds the first paint and is overwritten by the backend
   value on `useUser()` resolve. Updating the theme in `SettingsView`
   writes to the backend and the local store mirrors it.
3. **Protobuf stays not-in-use.** The protobuf `.proto` definitions
   already exist (`../protobuf/ws/*.proto`) and are generated into
   `src/proto` at build time, but no source file imports them. For this
   cleanup the WS protocol stays JSON — but we **keep** the
   `bufGenerate()` Vite plugin and the `@bufbuild/*` deps so the
   generated code remains available for a follow-up ticket. (This
   overrides §4.7 of the original plan.)

## 7. Schema reference (live)

GraphQL schema is served at `http://localhost:5050/api/graphql/schema.graphql`
when the backend is running. Snapshot taken during planning:

- `Exam.startTime: DateTime!`, `endTime: DateTime!` — non-null on the
  wire. Tighten the local `Exam` type accordingly (remove the `| null`
  on these two fields; `startedAt` and `endedAt` stay nullable).
- `User.theme: UserTheme!` enum (`LIGHT | DARK | SYSTEM`). Replace the
  local string type with this enum.
- `User.role: UserRole!` (`STUDENT | TEACHER`) and `User.roleDetails`
  (`TeacherDetails { exams }` / `StudentDetails`) — currently
  unqueried; useful for replacing the `OU=Teacher` DN check in router
  guards.
- `Subscription.noticesSub: Notice` exists. Notices can become a live
  subscription instead of a one-shot fetch on app boot (future ticket).
- `Mutation.updateSettings(settingsInput: UpdateUserSettingsInput!)`
  takes `{ language, theme }` and returns `User!`. Matches current
  usage.

## 8. Progress tracker

| Phase | Status | Notes |
|------:|--------|-------|
| 0     | done   | dead code, deps, build script, prettier, AGENTS.md, README |
| 1     | done   | tokens added, inline literals replaced, focus-visible. Shared `components.css` extraction deferred (see §9) |
| 2     | done   | full i18n pass, dropped de_at, added datetime format. Also picked up four Phase 4.8 items opportunistically (see §9) |
| 3     | done   | infra + notices + user + exams + sessions migrated. Apollo client dropped. |
| 4     | done   | per-store and per-view cleanups complete (dialogs, icons, status/datetime helpers extracted and views refactored) |
| 5     | done   | collapsed duplicate guards, centralized useRoles, lazy imports, merged proctoring routes |
| 6     | done   | Badge, TextField, Card extracted; --bg-subtle token added |
| 7     | done   | console.warn→error in WebsocketStore; pinia-plugin-persistedstate documented in AGENTS.md; lint/type-check/build green |
| 8     | done    | Nix PR checks pass (lint/type-check/build green), §9 stale notes corrected, PR opened |

Update this table at the end of each phase.

## 9. Deviations from the original plan

These changes landed differently than the phase list above describes —
documented here so the agent picking up Phase 3 doesn't redo work or
get confused.

1. **Phase 1 — shared `components.css` not extracted.** The plan said
   to "Move modal/form/card patterns to `assets/styles/components.css`".
   Instead, those patterns will be lifted into proper Vue components in
   Phase 4 (per-view extraction) and Phase 6 (UI primitives like
   `<Dialog>`, `<Card>`). Token coverage and the inline-literal cleanup
   that *was* in scope landed. No separate `components.css` file
   exists. If the agent wants to keep one, it should be additive on top
   of the per-component extractions, not a replacement.

2. **Phase 2 borrowed Phase 4.8 items.** While translating
   `SettingsView`, the following Phase 4.8 items already landed because
   they were trivial to fix in the same edit:
   - `themeOptions` is now a `computed`, not a `let` (re-renders on
     locale change).
   - `languageOptions` is a `computed`, not a literal array.
   - Multi-statement template expressions
     (`@click="a(); b()"`) replaced with single-handler functions.
   - The `selectedLanguage!` non-null assertion is gone — the language
     ref is seeded from the user query data when it arrives.
   When Phase 4.8 runs, only "Remove duplicated locale init that lives
   in App.vue" is still relevant — and that one **also already
   landed** during Phase 3's user migration.

3. **Phase 3 is fully complete.** All service layer migrations are done (notices, user, exams, sessions), the Apollo client and dead stores are deleted, caching is documented in AGENTS.md, and all tests are green.

4. **Phase 4.2 fully landed.** The cross-store mutation from
   `UserStore` into `ThemeStore` is gone because `UserStore` is gone.
   App.vue applies `user.theme` once the user query resolves (the
   "user setting wins" rule from §6.2). Both remaining items from
   the original note also landed during Phase 4:
   - `onMounted` is gone from `ThemeStore.ts`.
   - `useResolvedTheme()` composable was extracted; the resolution
     rule now lives in one named place.

5. **Pinia caching strategy — documented.** The villus client uses
   `cachePolicy: 'network-only'` inside `executeQuery` — this disables
   villus's own cache. Pinia Colada sits above villus and is the only
   cache layer. This is now documented in `AGENTS.md §4` (Two-layer
   Cache paragraph).

