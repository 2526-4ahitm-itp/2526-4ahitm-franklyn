# Handoff → Phase 1 (Platform detection & input handling)

## Phase just completed: Phase 0 — Skeleton, shell hygiene, output helpers
- Commit: see `git log` for `feat(sentinel-install): script skeleton...` (latest on branch `feat/curl-install-script-for-sentinel`).

## §0 audit result for this commit
Re-read entire `sentinel-install.md`. Phase 0 delivers only the skeleton, so most sections are not yet exercised. Verified no violations of what *is* present:
- Transfer integrity → body wrapped in `main()`, invoked only on last line ✓
- Baseline shell hygiene → `set -euo pipefail`, all expansions quoted, `trap cleanup EXIT INT TERM`, `err` exits non-zero ✓
- Rootless constraints → no `sudo`; all paths derived under `$HOME`/XDG ✓
- `bash -n` clean; `shellcheck` (0.11.0 via `nix run nixpkgs#shellcheck`) CLEAN.
Not yet implemented (expected): Verification, Atomic installs, Idempotency, Self-update, Non-interactivity input, Concurrency, Uninstall, arch normalization, `$HOME` writability check.

## State of the script (`hugo/static/scripts/sentinel-install.sh`)
- `#!/usr/bin/env bash`, `set -euo pipefail`. **Bash is a hard dependency** (documented in header).
- Constants: `REPO`, `APP_NAME`, `DEFAULT_VARIANT=portable`, XDG dirs (`XDG_BIN_HOME`, `XDG_DATA_HOME`, `XDG_CONFIG_HOME`), derived `INSTALL_DATA_DIR`/`DESKTOP_DIR`/`ICON_BASE_DIR`, `CURL_CONNECT_TIMEOUT`/`CURL_RETRY`.
  - `DESKTOP_DIR`, `ICON_BASE_DIR`, `CURL_*` are forward-declared and carry `# shellcheck disable=SC2034` comments noting the phase that consumes them — **remove the disable comment when you wire each one up.**
- Output helpers (rustup/Homebrew style): `say`, `warn`, `err MSG [CODE]` (exits), `need_cmd`, `check_cmd`, `ensure CMD...`, `ignore CMD...`. TTY color via `[ -t 2 ]` + `NO_COLOR`, ANSI-C quoted.
- `cleanup()` + `trap cleanup EXIT INT TERM`. Uses a mutable `_CLEANUP_PATHS=()` array — **append temp/staging paths to this array** in later phases instead of writing new traps.
- `main()` is a **banner stub** (`need_cmd uname` + prints repo/variant/install dir). Replace its body in Phase 1+.

## Next phase goal: Phase 1 — Platform detection & input handling
Must satisfy `sentinel-install.md` sections: **Rootless constraints** (arch/os normalization, `$HOME` writable check) and **Non-interactivity** (flags/env, no stdin prompts).
Concrete steps in `sentinel-install.plan.md` → "Phase 1". Summary:
- `get_architecture()` — normalize `uname -s`/`uname -m` (`arm64`→`aarch64`, `amd64`→`x86_64`); map to asset arch token {`x86_64`,`aarch64`}; reject unsupported with `err`.
- Version resolution: `--version`/`FRANKLYN_SENTINEL_VERSION` else latest release; build the `*-portable.tar.zst` asset URL.
- `$HOME` set + writable check → `err` if not.
- Arg/env parser: `--version`, `--update`, `--uninstall`, `--help`, install-dir override; safe non-interactive defaults; no `read` from stdin.

## Files the next agent needs
- `hugo/static/scripts/sentinel-install.sh` — the script (edit this)
- `hugo/static/scripts/sentinel-install.md` — requirements contract (re-read after every commit)
- `hugo/static/scripts/sentinel-install.plan.md` — build plan (Phase 1 steps + §0 protocol)
- `.github/workflows/release.yaml` — asset naming patterns + `checksums.txt` (relevant for version/asset URL construction)

## Tooling note
shellcheck is not installed system-wide. Run it via: `nix run nixpkgs#shellcheck -- hugo/static/scripts/sentinel-install.sh`. Plan requires shellcheck-clean before each commit.

## Open questions / blockers
None. Decisions locked: bash (not POSIX sh), portable variant default, `checksums.txt` as primary verification asset.
