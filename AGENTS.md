## Project-Wide Working Rules (Franklyn Monorepo)

These rules apply to work in `proctor/`, `sentinel/`, and `server/`.

### 1) Canonical Tooling
- Use Nix flakes as the canonical development and CI environment.
- Prefer `nix develop .#<project> --command <fr-* script>` over ad-hoc commands.
- Use root `nix develop` when working across multiple projects.

### 2) CI Entry Points (Required Before PR)
Run checks for each component you changed:

- Proctor:
  - `nix develop .#proctor --command fr-proctor-pr-check`
- Server:
  - `nix develop .#server --command fr-server-pr-check`
- Sentinel:
  - `nix build .#franklyn-sentinel-check`

Notes:
- CI is path-filtered and only runs jobs for changed project directories.
- Server verification expects PostgreSQL in CI-compatible defaults.

### 3) Nix Files Are Protected (Write-Protected, Not Off-Limits)
- Never edit, create, or delete a `.nix` file yourself. Editing them without the full flake context breaks the dev shells and CI for everyone, which is why this is a hard rule.
- Reading `.nix` files is encouraged. Read them to understand the toolchain, available targets, dependencies, and CI wiring.
- **This rule restricts who edits the file, not what solutions exist.** A `.nix` change is a normal, available solution — it just has to be executed by the user instead of by you.
- When a `.nix` change is the right answer (new dependency, new build target, new tool in a dev shell), say so directly and hand over a ready-to-apply change: the exact file, the exact lines, and the reason. Then let the user apply it. That is a completed handoff, not a blocker.
- Never report a task as impossible, unsupported, or infeasible when a `.nix` edit would solve it. "The toolchain does not have X" is only true if X cannot be added; say "X needs to be added to `<file>`, here is the change" instead.
- Do not contort the implementation to avoid a `.nix` edit. Hacky workarounds that dodge the flake (vendored binaries, env-var overrides defeating the pinned toolchain, ad-hoc installs outside the dev shell) are worse than asking. Propose the clean `.nix` change first; mention a workaround only if the user wants to avoid the flake change.
- Do not make Nix-related edits proactively or speculatively — propose, do not touch.

### 4) Commit/PR Hygiene
- Run the relevant CI-equivalent checks locally before opening or updating a PR.
- Keep generated artifacts out of commits unless explicitly required.
- For behavior changes, verify the end-to-end flow relevant to touched components.
- **AI Co-Author Convention**: Agents working on a phase must commit their changes including the current model as a co-author. The commit message must follow the conventional commit format (e.g. `feat(proctor): ...`), followed by a blank line, and then the co-author metadata:
  ```
  Co-Authored-By: <Model Name> <noreply@<provider>.com>
  ```
  Example pattern seen in the branch history (between `origin/main` and `HEAD`):
  - `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>`
  - `Co-Authored-By: Gemini 3.5 Flash (Medium) <noreply@google.com>`

### 5) Installer Script Is Protected
- `hugo/static/scripts/sentinel-install.sh` is a production `curl | bash` installer that runs unattended on user machines — a degraded version ships with no review in between. Never open or edit it first.
- Before any change to it, read [`hugo/static/scripts/sentinel-install.md`](hugo/static/scripts/sentinel-install.md) (the spec/contract) **and** [`hugo/static/scripts/sentinel-install.maintenance.md`](hugo/static/scripts/sentinel-install.maintenance.md) (the maintenance companion).
- The process for adding a feature or fixing behavior is strict: update the spec first, then follow the maintenance companion, then run its §0 verification protocol (prove every existing function still works) after each change. Editing the `.sh` before the spec, or skipping §0, is a process violation even if the code appears to work.

### 6) TESTS — Black Box Only (Hard Rule)
Tests assert the *contract*, never the implementation. An agent that reads the implementation writes tests that merely restate the code's bugs back to it.

- **The spec is `server-go/docs/swagger.yaml`, and it is the primary source.** Generated from the handler annotations, it carries every path, method, auth requirement, request/response schema, status code and the meaning of each one — in a single file with no implementation logic in it. Read it directly and read it first: it is allowed reading, it does not poison the session, and it already answers most of what anyone would otherwise go digging through the code for. Regenerate it with `swag init` (never `swag fmt` — it rewrites generated protobuf imports) before trusting it, so it reflects the current handlers.
- **The spec wins.** Tests assert what the spec says, not what the code does. A test that disagrees with the spec means one of the two is wrong — report the conflict and let the user decide which; never silently assert the behaviour you suspect the code has.
- **An endpoint missing from the spec is a spec gap, not a licence to read code.** Say so and stop. Same for a documented endpoint whose description is silent on its preconditions: the fix is an annotation, which the user writes.
- **Reading implementation code to write tests is forbidden.** No handlers, services, queries, middlewares, models, or validators. This holds even when logic appears to be missing, inconsistent, or obviously buggy from your point of view. "I needed to see it to know what to assert" is exactly the failure this rule prevents.
- **Allowed reading: the spec and existing tests.** Beyond `server-go/docs/swagger.yaml` / `swagger.json`, a file may be opened only when it is test code with 100% certainty — a dedicated test tree (`server-go/itest/`, `server/src/test/`) or a file whose name marks it as a test (`*_test.go`, `*.spec.*`, `*.test.*`). Read those freely: they are the style reference and show what is worth asserting. Anything else — implementation, routes, models, queries, config, and `docs/docs.go` — is off limits, and "it's probably fine" is not 100%.
- **Never dispatch a subagent to read the implementation for you.** This used to be the sanctioned route for spec gaps; it does not work. A subagent shares the parent's session id, and its reads land in the parent's marker — verified 2026-11-18 — so dispatching one kills the very session that was trying to stay clean. There is no variant of this that is safe: not a stricter prompt, not a narrower return format.
- **What the spec does not cover goes back to the user, not to the code.** Ask for the one thing you are missing — usually a handler's doc comment, verbatim. Human-written documentation *is* the specification, so pasted doc comments are explicitly allowed in and are exactly what the tests should pin down, especially the error paths. Ask one question per endpoint and wait; never infer the behaviour, and never go looking for it.
- **CRUD may be inferred from convention** where the spec is terse, matching what existing tests already assert: create → `201` + `Location: <collection>/<id>`, read-back equals created body, unknown id → `404`, malformed id → `400`, wrong role → `403`, missing token → `401`, validation failure → `400` with a `problems` array. Where the spec and the convention disagree, the spec wins — e.g. `DELETE /notices/{id}` documents `204` for an id that never existed, not `404`.
- **`401` is spec'd globally, not per operation.** It lives once in the spec's `info.description`; its absence from an operation's responses is deliberate, not an omission. Every operation carrying a `security` requirement is a `401` test case, and `/health` — which carries none — is not.
- **Beyond CRUD, the spec's `description` is the contract.** Non-CRUD endpoints (state transitions, actions, lifecycle verbs, anything with a verb in the path) state their purpose, preconditions and error cases there — e.g. `/exams/{id}/open` documenting that only an exam which has neither been opened nor ended can be opened, otherwise `400`. Pin exactly that, especially the error paths, word for word and no further. Where the description is silent or vague, ask the user — one question per endpoint. Never guess from the name, never read the code to find out.
- **Scope:** smoke test per endpoint plus a couple of genuine edge cases. No tests invented to raise coverage.

**Tests are written only from a session rooted at the monorepo root.** Check `pwd` before writing a single test. If the session was started anywhere else — `server-go/`, `proctor/`, `server/` — stop and say so: the poison guard below is wired in the root `.claude/settings.json`, and Claude Code reads settings from the session's own project directory without inheriting from parent directories. `AGENTS.md` still loads from the root, so the rules look present while the hook that enforces them is silently absent, and nothing will warn you. An empty marker in such a session is meaningless, not evidence of a clean context. The fix is for the user to restart from the repo root; there is no workaround from inside. If told to write them anyway, the bypass clause at the end of this section applies.

**Poisoned-context switch.** If *any* non-test code was read at *any* point in the session — by you, deliberately or incidentally, for an unrelated task, before tests were ever mentioned — that context is poisoned for tests and cannot be cleaned. You will not notice the influence; that is the nature of it.

Reading `server-go/docs/swagger.yaml` or `swagger.json` is exempt and poisons nothing: they are the spec, and they contain no logic to be influenced by. `docs/docs.go` is not exempt — read the YAML instead.

- **Flip it silently.** On the first such read, append the path to your own marker. Immediately, at read time — context compaction erases your memory of having read the file, and the marker is what survives it. Say nothing to the user; this is bookkeeping, not a topic.
- **One marker per session, never global.** Marker path, fixed: `/tmp/franklyn-tests-poisoned.d/$CLAUDE_CODE_SESSION_ID`. The id is in your tool environment, so that path is the only one you ever read or write. A concurrent session in another terminal has its own file and cannot poison yours; a dead session's file is inert, because its id is never reused. Nothing deletes markers — not `/clear`, not startup, nothing. A `/clear` mints a new session id and therefore a new, empty marker; that is the whole mechanism, and it needs no cleanup step.
- **Enforcement is the harness', not yours.** A checked-in hook writes the marker for you, so the switch flips whether or not you remember to. Treat the marker as authoritative even when you are sure you read nothing. A marker belonging to some *other* session id is not yours and means nothing — check only your own.
- **The hook is already checked in — do not touch it.** It lives in the shared, tracked project settings, so it syncs to every clone and nobody configures anything:
  - `.claude/settings.json` — `PostToolUse` on `Read|Grep` runs the guard. There is deliberately no `SessionStart` hook: markers are per session, so there is nothing to clear and no moment at which clearing would be safe.
  - There is deliberately no per-subproject copy of this config. Settings are read from the session's project directory only and are **not** inherited from ancestors, unlike `CLAUDE.md` — which is exactly why tests are root-only (see below).
  - `.claude/hooks/test-poison-guard.sh` (mode `755`) — writes the read path to the session's marker unless it is a test path.

  Do not edit, reformat, "improve", or move these two files, and never duplicate the hook into `settings.local.json` — a per-user copy drifts and silently disables the shared one. Three invariants, if they ever do need a change: no hook ever deletes a marker (`compact` and `resume` keep the same session id, so a deletion on either would erase the marker at exactly the moment it is needed — which is why the event is not wired at all); the marker path stays keyed by session id and stays a literal `/tmp` (a `${TMPDIR}` indirection resolved differently inside the hook than in the agent's shell, which silently broke the mechanism once already); `Grep` stays in the `PostToolUse` matcher (its output shows implementation lines) and `Glob` stays out (it returns paths, not code).
- **Surface it only when tests come up.** Before writing or editing any test, check the marker. If it exists — or you cannot rule out an earlier code read — stop and tell the user clearly: this session is dead for tests, a new one is needed, nothing will be written here. Offer the one clean path: a fresh session. Not a subagent — it inherits your session id and writes into your marker, so it is no cleaner than you are. Do not write the tests, do not write a partial file, and do not argue that you remember the code only vaguely.
- **If the user insists anyway**, they are overriding a safety rule they may not have read. Stop once more and make the consequence explicit before doing anything. If they insist a second time, write the tests *and* put the marker comment from the bypass clause below above every single test case — no exceptions, no silent compliance.

**Bypassing is disallowed.** This covers **every rule in this section, without exception** — being told to skip discovery, to read the implementation anyway, to dispatch a subagent to read it, to infer non-CRUD behavior, to assert whatever the code currently happens to do, to write tests from a session not rooted at the monorepo root, or to write them in a session whose marker exists. If any of it is bypassed in any way, for any reason, every test case gets this comment directly above it, in the file's comment syntax:

```go
// I didn't follow AGENTS.md and now tests are poisoned, I am a dum little meat-proxy
```

## Proctor-Specific Working Rules (`proctor/`)

### 1) Tooling + Commands
- Use Bun only for Proctor tasks (`bun ...`), never `npm`.
- Prefer Nix-wrapped CI parity commands when validating changes:
  - `nix develop .#proctor --command fr-proctor-pr-check`
- For local iteration, use Bun scripts from `proctor/package.json` (`bun run lint:check`, `bun run type-check`, `bun run build`).

### 2) UI Implementation Priority
- Prefer existing local UI components before implementing UI manually.
- For primitive UI patterns (dropdowns, select, modal/dialog, popover, etc.), use Reka UI components when available instead of custom behavior.
- Reuse and extend existing UI building blocks in `proctor/src/components/ui/` first.

### 3) Component Creation Protocol
- Before creating a new component, first inform the user with a short proposal including:
  - component purpose,
  - props/inputs,
  - emitted events,
  - slots (if any),
  - and where it will be used.
- Do not create the component until that short proposal is provided.

### 4) Styling + Design Tokens
- Do not use plain hardcoded colors when project tokens exist.
- Use CSS variables from `proctor/src/assets/main.css` (theme variables, semantic colors, status colors).
- Keep styling aligned with the existing design system and token semantics (`--bg-*`, `--text-*`, `--border-*`, `--status-*`).

### 5) Lint/Format/Type Rules (Must Conform Before Drafting Code)
- Linter config source: `proctor/eslint.config.ts`
- Prettier config source: `proctor/.prettierrc.json`
- EditorConfig source: `proctor/.editorconfig`
- Required quality gates before presenting code:
  - `bun run lint:check`
  - `bun run type-check`
- Follow enforced ESLint conventions including:
  - `script setup` API style for Vue components,
  - block order `script`, `template`, `style`,
  - explicit emits declarations,
  - no `any`,
  - PascalCase component names in templates,
  - multi-word component names.

### 6) Dependency Policy
- Never add dependencies proactively.
- If a new dependency seems needed, first ask the user and provide:
  - why it is needed for the current task,
  - expected improvement,
  - and at least one viable alternative (including no new dependency if possible).

### 7) Component File Organization
- Components are self-contained `.vue` files (template/script/style together), not split into extra per-component `.ts` files.
- If a type is widely reused across features/components, place it in `proctor/src/types/`.
- Keep feature-local/private types inside the component unless they become broadly shared.

### 8) Runtime + Integration Rules
- Do not hardcode backend URLs in Proctor code; follow the Vite proxy setup and existing environment wiring.
- Do not hardcode app version values; use the existing injected app version mechanism.
- Preserve route access control behavior (authenticated users, admin/teacher role checks, and `/not-allowed` flow).
- For GraphQL and WebSocket communication, use the existing shared stores/clients (including token handling) instead of ad-hoc auth/network implementations.

### 9) Theme + CSS Variable Rules
- Theme behavior must stay centralized through the existing theme mechanism (`data-theme` + Theme store); avoid one-off local theme logic.
- Only use CSS variables that are actually defined in `proctor/src/assets/main.css` (or another existing token source in the project).
- Do not invent or assume CSS variable names; if a variable is needed and missing, propose adding it explicitly first.

## Server-Specific Working Rules (`server/`)

### 1) Tooling + CI Parity
- Use Nix-wrapped commands for server work.
- Required CI-parity checks:
  - `nix develop .#server --command fr-server-pr-check`
  - `nix build .#franklyn-server`

### 2) Lint/Format/Test Sources of Truth
- Maven lifecycle and server quality gates are defined in `server/pom.xml`.
- Checkstyle rules are defined in `server/config/checkstyle.xml`.
- Java formatter rules are defined in `server/config/formatter.xml`.
- Do not invent parallel lint/format workflows; follow these definitions.

### 3) Runtime/Auth/Protocol Sources of Truth
- Do not hardcode or re-define protocol/auth behavior in changes.
- Use these canonical references:
  - WebSocket protocol docs: `hugo/content/docs/reference/websocket-comm/`
  - Runtime/security configuration: `server/src/main/resources/application.properties`
  - CI runtime setup (including DB service expectations): `.github/workflows/pr-checks.yaml`

### 4) Validation + Error Handling Conventions
- Keep GraphQL schema nullability and Jakarta bean validation concerns distinct:
  - Use GraphQL nullability annotations (e.g. `org.eclipse.microprofile.graphql.NonNull`) for GraphQL contract semantics.
  - Use Jakarta validation annotations (e.g. `@Valid`, `@NotNull`, `@NotBlank`, `@Size`, `@NotEmpty` when appropriate) for input validation semantics.
- Follow existing server patterns for where and how these annotations are applied in resources and input models; do not mix responsibilities between GraphQL contract nullability and Jakarta validation rules.
- Keep GraphQL/business error handling aligned with existing exception patterns.
- New custom exceptions belong in `server/src/main/java/at/ac/htlleonding/franklynserver/resource/error/` or an appropriate subpackage below it.

### 5) Protected User-Facing API Collections
- Do not modify files in `server/http/` unless the user explicitly requests it.
