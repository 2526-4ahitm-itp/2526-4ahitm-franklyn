# Implementation Plan — sentinel-install.sh

This plan describes **how** to build `sentinel-install.sh`, phase by phase. The **what** is fixed by [`sentinel-install.md`](./sentinel-install.md) — that file is the requirements contract; this file is the build order. Do not re-decide requirements here; implement them in the sequence below.

**Scope:** the `sentinel-install.sh` file only. No changes to the sentinel binary, the server, the release workflow, or any other repo artifact. "Uninstall" is implemented *inside the script* (manifest + flag), never as a binary subcommand.

---

## 0. Verification protocol (read every time, non-negotiable)

This protocol exists so an agent working one phase at a time does not drift away from the requirements.

1. **Requirements are the source of truth.** Before writing any code in a phase, re-read the relevant section(s) of [`sentinel-install.md`](./sentinel-install.md). Each phase below names the exact sections it must satisfy.
2. **Check after every commit.** Immediately after each `git commit`, re-read the *entire* [`sentinel-install.md`](./sentinel-install.md) and confirm the code committed so far does not violate any item — not only the items for the current phase. A regression introduced in a later phase against an earlier requirement is a defect. Record the audit result in the commit body or the phase handoff.
3. **Fail closed on ambiguity.** If a requirement and this plan appear to conflict, the requirement wins; stop and note it in the handoff rather than guessing.
4. **One phase ≈ one focused work session.** Phases are sized so a single agent can complete one without exhausting context. Do not start phase N+1 in the same session that finished phase N unless context budget is clearly ample.
5. **Continuation handoff closes every phase.** Before ending a phase, write `hugo/static/scripts/continuations/PHASE{N+1}_HANDOFF.md` (see §Continuations). The next agent must be able to resume from *only* that handoff plus the files it references.

---

## Reference material (study before phase 1)

Lift structure and idioms from these battle-tested rootless/curl-pipe installers — do not reinvent boilerplate:

- **rustup** — `https://sh.rustup.rs` (a.k.a. `rustup-init.sh`). Take: the single-`main`-wrapped body invoked on the last line; the `say` / `err` / `warn` / `need_cmd` / `check_cmd` / `ensure` / `ignore` helper set; `get_architecture` normalizing `uname -m`/`uname -s`; `mktemp`-based temp dir with `trap` cleanup; the downloader abstraction (`curl` with retries, fail on non-2xx).
- **Homebrew install.sh** — `https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh`. Take: `abort` / `ohai` / `warn` output helpers; explicit `/dev/tty` handling and `[ -t 0 ]` TTY detection for the rare unavoidable prompt; idempotent "already installed / already on PATH" checks; `execute` wrapper that aborts on failure with a useful message.
- Secondary: `nvm`, `deno`, `starship` install scripts for self-update / channel-detection patterns.

---

## Project facts (already established — do not re-derive)

- **Repo:** `2526-4ahitm-itp/2526-4ahitm-franklyn` (GitHub releases).
- **Checksums asset:** the release workflow (`.github/workflows/release.yaml`, job `release`) runs `sha256sum * > checksums.txt` over all artifacts and uploads it. So a `sha256sum -c`-compatible checksum file **already exists** as a release asset named `checksums.txt`. The installer fetches that and runs `sha256sum --ignore-missing -c checksums.txt`. The GitHub-API-JSON `.assets[].digest` path in the md is the *fallback only*; prefer `checksums.txt`. Update the md's `<!-- TODO -->` comment in Phase 2 to record that the asset now exists.
- **Asset name patterns** (version token like `0.9.0+dev.cl.1`):
  - `franklyn-sentinel-<ver>-<arch>-linux-portable.tar.zst` — rootless, self-contained. **Default for this installer.**
  - `franklyn-sentinel-<ver>-<arch>-linux-dist.tar.zst` — has system deps; not the rootless default.
  - `franklyn-sentinel_<ver>_<debarch>.deb` — system-package channel; the installer must *defer* to apt, not consume this.
  - `<arch>` ∈ {`x86_64`, `aarch64`}; `<debarch>` ∈ {`amd64`, `arm64`}.
- **Rootless target paths (XDG):** binary → `~/.local/bin`, app data → `~/.local/share/franklyn-sentinel`, desktop entry → `~/.local/share/applications`, icons → `~/.local/share/icons/hicolor/...`, env snippet + manifest → `~/.local/share/franklyn-sentinel` (or `~/.config/franklyn-sentinel`). No `sudo`, ever.

---

## Phases

Each phase: **Goal → How (concrete steps) → Done-when → Commit → Handoff.** Commit at the end of each phase (and at sane sub-points). Run the §0 audit after each commit.

### Phase 0 — Skeleton, shell hygiene, output helpers
- **Requirements covered:** Transfer integrity (function-wrap), Baseline shell hygiene.
- **How:**
  - Shebang `#!/bin/sh` *or* `#!/usr/bin/env bash` — decide one and document. (Rustup targets POSIX sh; given `pipefail`, `flock`, and arrays later, **bash** is the pragmatic choice. State the bash dependency and `need_cmd bash` early.)
  - Wrap the whole body in `main() { ... }`; the **last line** of the file is `main "$@"`. Nothing executes during a truncated download.
  - `set -euo pipefail`; set safe `IFS`.
  - Implement output/util helpers ported from rustup/Homebrew: `say`, `warn`, `err`/`abort` (exit non-zero), `need_cmd` (abort if missing), `check_cmd`, `ensure` (run-or-abort), `ignore`.
  - Stub `trap`-based cleanup function (fills in real temp/lock handling in later phases) on `EXIT INT TERM`.
  - Define top-level constants: `REPO`, default channel/variant, XDG path variables (resolved from `XDG_*` env with documented defaults).
- **Done-when:** `bash -n` parses clean; `shellcheck` clean; running it does nothing harmful (helpers defined, `main` is a no-op stub that prints a version banner).
- **Commit:** `feat(sentinel-install): script skeleton, shell hygiene, helpers`
- **Handoff:** write `PHASE1_HANDOFF.md`.

### Phase 1 — Platform detection & input handling
- **Requirements covered:** Rootless constraints (arch/os normalization, `$HOME` check), Non-interactivity (flags/env, no prompts).
- **How:**
  - `get_architecture()` modeled on rustup: read `uname -s`/`uname -m`, normalize (`arm64`→`aarch64`, `amd64`→`x86_64`), reject unsupported with a clear error. Map to the asset `<arch>` token.
  - Resolve target version: explicit flag/env (`--version` / `FRANKLYN_SENTINEL_VERSION`) else "latest release" via the releases API. Resolve the matching `*-portable.tar.zst` asset URL.
  - Verify `$HOME` is set and writable; abort immediately and clearly otherwise.
  - Arg/env parser: `--version`, `--update`, `--uninstall`, `--help`, install-dir override; safe non-interactive defaults for all. No `read` from stdin (stdin is the piped script).
- **Done-when:** `--help` prints usage; arch detection correct on x86_64 + aarch64; bad arch and unwritable `$HOME` both abort with non-zero + message.
- **Commit:** `feat(sentinel-install): platform detection and arg/env parsing`
- **Handoff:** `PHASE2_HANDOFF.md`.

### Phase 2 — Download & checksum verification
- **Requirements covered:** Transfer integrity, Verification.
- **How:**
  - `download()` wrapper: `curl -fsSL --retry <n> --connect-timeout <s>`; non-2xx is fatal. (Provide a `wget` fallback only if trivial; otherwise `need_cmd curl`.)
  - Create a temp dir with `mktemp -d`; wire it into the Phase-0 `trap` cleanup. Download the artifact **to a temp file**, never pipe-extract from the stream.
  - Fetch `checksums.txt` release asset; verify with `sha256sum --ignore-missing -c checksums.txt` run from the temp dir, or extract the single expected line and compare to `sha256sum` of the file. Fail closed: missing/mismatch → abort, never "install anyway."
  - Update the `<!-- TODO -->` in `sentinel-install.md` to note `checksums.txt` exists and is the primary path; keep API-digest as documented fallback.
- **Done-when:** good artifact verifies and proceeds; corrupted file aborts; missing checksum entry aborts.
- **Commit:** `feat(sentinel-install): verified download via checksums.txt`
- **Handoff:** `PHASE3_HANDOFF.md`.

### Phase 3 — Staging, validation, atomic install, recovery
- **Requirements covered:** Atomic recoverable installs.
- **How:**
  - Extract the verified `.tar.zst` into a **staging dir adjacent** to the final versioned install dir (e.g. `~/.local/share/franklyn-sentinel/.staging-<pid>`), never into the live dir. `need_cmd zstd`/`tar`.
  - Validate staged contents *before* going live: expected binary present, executable bit, correct arch (e.g. `file`/`readelf -h` or a sandboxed `--version` of the staged binary).
  - Install into a **versioned dir** (`.../versions/<ver>`); flip a `current` symlink with a single atomic `mv`/`ln -sfn`. No multi-file copy loop into the live path.
  - Keep the previous version dir (or `.bak`) until the new one passes the Phase-5 smoke test.
  - On startup, detect leftover `.staging-*` dirs from a prior interrupted run and clean/resume.
- **Done-when:** clean install lands binary under versioned dir + `current` symlink; interrupted run leaves no half-state on re-run.
- **Commit:** `feat(sentinel-install): atomic staged install with recovery`
- **Handoff:** `PHASE4_HANDOFF.md`.

### Phase 4 — PATH, desktop integration, manifest, idempotency
- **Requirements covered:** Idempotency, Uninstall (manifest-writing half).
- **How:**
  - PATH: write **one** sourced env snippet (e.g. `~/.local/share/franklyn-sentinel/env`) that prepends `~/.local/bin`. In shell rc files, check for an existing `source`/`.` line before adding; never blind-append `export PATH=`.
  - Desktop entry + icons: install to XDG dirs; before writing, compare against existing content and skip if identical (idempotent). Use the resources the repo already ships (`sentinel/resources/franklyn-sentinel.desktop`, `sentinel/resources/icons`) as the reference for names/sizes — copy values, don't modify those files.
  - Manifest: append every path the installer creates/writes to a manifest file (e.g. `~/.local/share/franklyn-sentinel/install-manifest.txt`). This is the exact set uninstall will remove in Phase 6.
- **Done-when:** second run is a no-op (no duplicate rc lines, no rewritten identical files); manifest lists every written path.
- **Commit:** `feat(sentinel-install): PATH/desktop integration, manifest, idempotency`
- **Handoff:** `PHASE5_HANDOFF.md`.

### Phase 5 — Concurrency, self-update, rollback, channel deference
- **Requirements covered:** Concurrency, Self-update & rollback.
- **How:**
  - `flock` on a lock file (FD-based) around install/update; kernel releases on crash. Wire lock FD into `trap` cleanup. Do **not** use a `[ -f lockfile ]` check.
  - Self-update (`--update`): download+verify+stage+validate the new version *fully* (reuse Phases 2–3) **before** touching the live install. Smoke test the staged binary (`--version`). Only then flip `current`. On any failure, leave the old `current` intact (rollback = do nothing destructive).
  - Channel detection: if sentinel is already installed via a system package manager (apt/dpkg, the `.deb` channel; rpm/OBS), do **not** self-update over it — detect and defer with a clear message pointing at that channel.
- **Done-when:** concurrent invocations serialize; failed update keeps the working binary; apt-installed sentinel is detected and update is refused with guidance.
- **Commit:** `feat(sentinel-install): flock, verified self-update, rollback, channel deference`
- **Handoff:** `PHASE6_HANDOFF.md`.

### Phase 6 — Uninstall, non-interactivity finish, final hardening
- **Requirements covered:** Uninstall, Non-interactivity, Baseline shell hygiene (final pass).
- **How:**
  - `--uninstall`: read the Phase-4 manifest and remove **exactly** those paths (and the rc `source` line) — no guessed globs. Confirm nothing outside the manifest is touched.
  - Non-interactivity final pass: confirm no `read` from stdin anywhere; any unavoidable prompt reads `/dev/tty` and is gated by `[ -t 0 ]` so CI/containers skip gracefully with the documented default.
  - Final hardening sweep: every variable expansion quoted; every failure path exits non-zero with a meaningful code (define an exit-code table); `trap` cleans temp dirs *and* releases the lock FD on `EXIT/INT/TERM`.
  - Full §0 audit against the *entire* md; fix any regression.
- **Done-when:** uninstall removes exactly the manifest set and nothing else; `shellcheck` clean; runs non-interactively under `curl | bash` with no TTY.
- **Commit:** `feat(sentinel-install): uninstall, non-interactive hardening, final audit`
- **Handoff:** `PHASE7_HANDOFF.md` — final handoff = "complete, ready for review", listing how each md section is satisfied.

---

## Continuations

Path: `hugo/static/scripts/continuations/PHASE{N+1}_HANDOFF.md`. Mirrors the repo's existing per-phase handoff convention.

Each handoff MUST contain:
1. **Phase just completed** + commit hash(es).
2. **§0 audit result** for that commit (which md sections verified, any deferred concerns).
3. **State of the script** — what functions/sections exist, what is stubbed.
4. **Next phase goal** + the exact md section(s) it must satisfy.
5. **Files the next agent needs**, with paths:
   - `hugo/static/scripts/sentinel-install.sh` (the script)
   - `hugo/static/scripts/sentinel-install.md` (requirements)
   - `hugo/static/scripts/sentinel-install.plan.md` (this plan)
   - `.github/workflows/release.yaml` (asset names, checksums.txt) — when relevant
   - `sentinel/resources/franklyn-sentinel.desktop`, `sentinel/resources/icons/` — Phase 4 only
6. **Open questions / blockers** for the user, if any.

The next agent should be able to start from *only* its handoff + the referenced files.

---

## Progress tracker

- [x] Phase 0 — Skeleton, shell hygiene, helpers
- [x] Phase 1 — Platform detection & input handling
- [x] Phase 2 — Download & checksum verification
- [x] Phase 3 — Staging, validation, atomic install, recovery
- [ ] Phase 4 — PATH, desktop, manifest, idempotency
- [ ] Phase 5 — Concurrency, self-update, rollback, channel deference
- [ ] Phase 6 — Uninstall, non-interactivity, final hardening
