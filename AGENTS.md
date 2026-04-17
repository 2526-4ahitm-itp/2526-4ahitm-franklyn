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

### 3) Nix Files Are Protected
- Never modify any `.nix` file.
- If a change to a `.nix` file is required, stop and ask the user for explicit approval and the exact change to make.
- Do not make Nix-related edits proactively.

### 4) Commit/PR Hygiene
- Run the relevant CI-equivalent checks locally before opening or updating a PR.
- Keep generated artifacts out of commits unless explicitly required.
- For behavior changes, verify the end-to-end flow relevant to touched components.

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
