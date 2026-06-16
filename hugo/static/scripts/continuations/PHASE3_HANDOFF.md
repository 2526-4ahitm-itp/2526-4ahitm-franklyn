# Handoff → Phase 3 (Staging, validation, atomic install, recovery)

## Phase just completed: Phase 2 — Download & checksum verification
- Commit: `feat(sentinel-install): verified download via checksums.txt` (`63d34fc`, latest on branch `feat/curl-install-script-for-sentinel`).

## §0 audit result for this commit
Re-read entire `sentinel-install.md`. Phase 2 satisfies its two target sections; no regression against earlier ones:
- **Transfer integrity** → `download()` uses `curl -fsSL --connect-timeout --retry`, writes to a file with `-o` (no pipe), non-2xx fatal via `curl -f` + `|| err`. Artifact + `checksums.txt` go to an `mktemp -d` dir; nothing is pipe-extracted from the stream. ✓
- **Verification** → `checksums.txt` is the primary path. `verify_checksum()` **fails closed**: aborts if `checksums.txt` missing, if the file missing, if `awk` finds no exact `$2 == ASSET_NAME` entry (guards against `--ignore-missing` passing on zero checks), then `sha256sum --ignore-missing --strict --check`. md `<!-- TODO -->` replaced to record `checksums.txt` exists + is primary; API `.assets[].digest` kept as documented fallback. ✓
- **Baseline hygiene** (still holds) → temp dir appended to the Phase-0 `_CLEANUP_PATHS` array; **no new trap added**. `set -euo pipefail`, quoting, non-zero exits intact. ✓
- **Rootless** (still holds) → temp dir under `${TMPDIR:-/tmp}`; no `sudo`. ✓
- `bash -n` clean; `shellcheck` (0.11.0 via `nix run nixpkgs#shellcheck`) CLEAN.
- **Verified live, end-to-end** against the public prerelease `v0.9.0+dev.cl.1` (`--version 0.9.0+dev.cl.1`): real portable asset + `checksums.txt` downloaded, checksum OK, exit 0, temp dir removed by the trap. `verify_checksum` unit-tested for good→0, tampered→non-zero, asset-not-listed→non-zero, missing-checksums→non-zero.
Not yet implemented (expected): Atomic/staged install, Idempotency, Self-update, Concurrency, Uninstall body, extraction.

## ⚠️ Release-reality notes (IMPORTANT for any live test)
- **`/releases/latest` is NOT usable for live testing yet.** Latest stable is `v0.9.0`, built *before* the `checksums.txt` CI step (`df4eec2`) and the portable Linux variant — it has **neither a `*-linux-portable.tar.zst` asset nor `checksums.txt`**. A no-arg run (latest) currently 404s on download (fails closed correctly, but cannot complete).
- **Use `--version 0.9.0+dev.cl.1`** for any end-to-end run — that public prerelease has both the portable asset and `checksums.txt`. It is a prerelease, so `/releases/latest` does not return it (by design; `fetch_latest_tag` correctly skips prereleases).
- Asset/tag confirmed: tag `v0.9.0+dev.cl.1`, asset `franklyn-sentinel-0.9.0+dev.cl.1-x86_64-linux-portable.tar.zst`. Version tokens contain `+`/`.` — keep quoting; do not regex them unquoted.

## State of the script (`hugo/static/scripts/sentinel-install.sh`)
Everything from Phase 1 plus:
- **New globals:** `WORK_DIR` (mktemp dir, registered in `_CLEANUP_PATHS`) and `ASSET_PATH` (verified tarball path, `# shellcheck disable=SC2034` until Phase 3 consumes it).
- `download(url, dest)` — `curl -fsSL --connect-timeout --retry -o`. Returns curl's status; callers `|| err`.
- `verify_checksum(dir, asset)` — fail-closed checksum check (see audit above).
- `download_and_verify()` — `need_cmd curl`/`sha256sum`; `mktemp -d` → `_CLEANUP_PATHS`; downloads `ASSET_URL` + `checksums.txt`; verifies; sets `ASSET_PATH`.
- `main()` — after the resolution banner now calls `download_and_verify` then prints a "verified artifact staged at $ASSET_PATH (extraction lands in Phase 3)" line. **Replace that line with real extraction + staged install in Phase 3.**
- `DESKTOP_DIR`/`ICON_BASE_DIR` still carry `# shellcheck disable=SC2034` for Phase 4.

## Next phase goal: Phase 3 — Staging, validation, atomic install, recovery
Must satisfy `sentinel-install.md` section **Atomic, recoverable installs**. Concrete steps in `sentinel-install.plan.md` → "Phase 3". Summary:
- `need_cmd zstd`/`tar`. Extract `ASSET_PATH` (`.tar.zst`) into a **staging dir adjacent to** the final versioned dir — e.g. `~/.local/share/franklyn-sentinel/.staging-<pid>` — never into the live dir, never pipe from the stream.
- Validate staged contents *before* going live: expected binary present, executable bit, correct arch (`file`/`readelf -h`, or a sandboxed staged `--version`).
- Install into a **versioned dir** `.../versions/<ver>`; flip a `current` symlink with a single atomic `mv`/`ln -sfn`. No multi-file copy loop into the live path.
- Keep the previous version dir (or `.bak`) recoverable until the Phase-5 smoke test confirms the new one.
- On startup, detect leftover `.staging-*` dirs from a prior interrupted run and clean/resume.
- Respect `OPT_INSTALL_DIR` for the binary/symlink location (default `XDG_BIN_HOME`); app data under `INSTALL_DATA_DIR`.

## Files the next agent needs
- `hugo/static/scripts/sentinel-install.sh` — the script (edit this)
- `hugo/static/scripts/sentinel-install.md` — requirements contract (re-read fully after every commit; §0)
- `hugo/static/scripts/sentinel-install.plan.md` — build plan (Phase 3 steps + §0 protocol)
- Inspect the real tarball layout before extracting: `bash sentinel-install.sh --version 0.9.0+dev.cl.1` stages it, or `curl -fsSL <asset-url> | tar --use-compress-program=unzstd -tvf -` to list members and confirm the binary path/name inside the archive.

## Tooling note
shellcheck not installed system-wide. Run: `nix run nixpkgs#shellcheck -- hugo/static/scripts/sentinel-install.sh`. Must be clean before each commit. `need_cmd zstd`/`tar` belong in Phase 3.

## Open questions / blockers
None blocking. Confirm the exact binary name/path inside the portable tarball before writing the staged-validation check (do not assume `bin/franklyn-sentinel`; list the archive first).
