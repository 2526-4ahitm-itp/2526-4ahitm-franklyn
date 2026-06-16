# Handoff → Phase 2 (Download & checksum verification)

## Phase just completed: Phase 1 — Platform detection & input handling
- Commit: `feat(sentinel-install): platform detection and arg/env parsing` (latest on branch `feat/curl-install-script-for-sentinel`; see `git log`).

## §0 audit result for this commit
Re-read entire `sentinel-install.md`. Phase 1 satisfies its two target sections and introduces no regressions against earlier ones:
- **Rootless constraints** → `get_architecture()` normalizes `uname -s`/`uname -m` (`amd64`→`x86_64`, `arm64`→`aarch64`), rejects non-Linux + unsupported arch with non-zero `err`. `check_home()` aborts clearly when `$HOME` is unset/empty/non-dir/unwritable. No `sudo`. All derived paths under `$HOME`/XDG ✓
- **Non-interactivity** → input only via flags + env (`FRANKLYN_SENTINEL_VERSION`); no `read`, no stdin use anywhere ✓
- **Baseline shell hygiene** (still holds) → `set -euo pipefail`, all expansions quoted, `trap cleanup EXIT INT TERM` intact, every failure path exits non-zero ✓
- `bash -n` clean; `shellcheck` (0.11.0 via `nix run nixpkgs#shellcheck`) CLEAN.
- Verified live: latest stable resolves to `v0.9.0`; asset URL built correctly.
Not yet implemented (expected): Verification, Atomic installs, Idempotency, Self-update, Concurrency, Uninstall body, the actual download.

## State of the script (`hugo/static/scripts/sentinel-install.sh`)
Everything from Phase 0 plus:
- **Mutable run-state globals** (after constants): `ACTION` (install|update|uninstall), `OPT_VERSION` (seeded from `FRANKLYN_SENTINEL_VERSION`), `OPT_INSTALL_DIR`, `ARCH`, `VERSION`, `RELEASE_TAG`, `ASSET_NAME`, `ASSET_URL`.
- **XDG default fix:** `XDG_*` defaults use `${HOME:-}` so an unset `$HOME` does not trip `set -u` at load — `check_home()` reports it instead.
- `usage()` — `--help` text, prints to stdout, `exit 0`.
- `parse_args()` — handles `--help/-h`, `--update`, `--uninstall`, `--version[=]`, `--install-dir[=]`; unknown flag → `err`. No stdin.
- `check_home()` — `$HOME` set/dir/writable guard.
- `get_architecture()` — sets `ARCH`; aborts on non-Linux or unsupported machine.
- `fetch_latest_tag()` — curls `/repos/$REPO/releases/latest`, captures full body, parses `tag_name` with a **bash regex** (NOT a `grep -m1` pipe — that closes the pipe early and curl dies with code 23 under `pipefail`). Returns the tag (`vX.Y.Z`).
- `resolve_version()` — sets `VERSION` (token, no `v`) and `RELEASE_TAG` (`v`+token) from `OPT_VERSION` else latest. `need_cmd curl` only on the latest path.
- `build_asset_url()` — `ASSET_NAME="$APP_NAME-$VERSION-$ARCH-linux-$DEFAULT_VARIANT.tar.zst"`, `ASSET_URL=".../releases/download/$RELEASE_TAG/$ASSET_NAME"`.
- `main()` — `parse_args` → `check_home` → `get_architecture` → route `uninstall`(err, Phase 6 stub)/`update`(say stub) → `resolve_version` → `build_asset_url` → print resolution banner. **Replace the banner with real download in Phase 2.**
- `CURL_CONNECT_TIMEOUT`/`CURL_RETRY` are now WIRED (disable comments removed). `DESKTOP_DIR`/`ICON_BASE_DIR` still carry `# shellcheck disable=SC2034` for Phase 4.

## Next phase goal: Phase 2 — Download & checksum verification
Must satisfy `sentinel-install.md` sections: **Transfer integrity** and **Verification**.
Concrete steps in `sentinel-install.plan.md` → "Phase 2". Summary:
- `download()` wrapper around `curl -fsSL --retry --connect-timeout`; non-2xx fatal. Reuse `CURL_*` constants. (`fetch_latest_tag` already shows the SIGPIPE-safe capture pattern — but `download()` writes to a file with `-o`, so no pipe issue there.)
- `mktemp -d` temp dir; **append it to `_CLEANUP_PATHS`** (the Phase-0 trap array) — do not add a new trap. Download `ASSET_URL` to a temp file; never pipe-extract from the stream.
- Fetch the `checksums.txt` release asset (`.../releases/download/$RELEASE_TAG/checksums.txt`) and verify: `cd` temp dir, `sha256sum --ignore-missing -c checksums.txt`, OR grep the single `$ASSET_NAME` line and compare to `sha256sum` of the file. **Fail closed** on missing/mismatch — never "install anyway".
- Update the `<!-- TODO -->` in `sentinel-install.md` (Verification section) to record that `checksums.txt` now exists and is the primary path; keep the GitHub-API `.assets[].digest` as documented fallback.

## Files the next agent needs
- `hugo/static/scripts/sentinel-install.sh` — the script (edit this)
- `hugo/static/scripts/sentinel-install.md` — requirements contract (re-read fully after every commit; also edit the Verification TODO this phase)
- `hugo/static/scripts/sentinel-install.plan.md` — build plan (Phase 2 steps + §0 protocol)
- `.github/workflows/release.yaml` — confirms `checksums.txt` (job `release`, step "Calculate checksums": `sha256sum * > checksums.txt`, uploaded with `files: artifacts/*`) and asset names.

## Tooling note
shellcheck not installed system-wide. Run: `nix run nixpkgs#shellcheck -- hugo/static/scripts/sentinel-install.sh`. Must be clean before each commit. `need_cmd zstd`/`tar` belong in Phase 3 (extraction), not Phase 2.

## Open questions / blockers
None. Confirmed live: repo `2526-4ahitm-itp/2526-4ahitm-franklyn`, latest stable `v0.9.0`. Dev builds are GitHub prereleases, so `/releases/latest` correctly returns the newest stable — documented in `fetch_latest_tag`.
