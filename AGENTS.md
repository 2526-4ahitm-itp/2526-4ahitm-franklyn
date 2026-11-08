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
