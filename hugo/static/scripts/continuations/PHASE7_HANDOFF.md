# Handoff → Phase 7 (none) — COMPLETE, ready for review

All six build phases are done. `sentinel-install.sh` satisfies every section of
`sentinel-install.md`. This handoff is the final one: it maps each requirement to
its implementation and records the closing §0 audit. There is no Phase 7 of work.

## Phase just completed: Phase 6 — uninstall, non-interactivity finish, final hardening
- Commit: `feat(sentinel-install): uninstall, non-interactive hardening, final audit` (`c4391a2`).
- Plan tracker: Phase 6 marked `[x]` (all phases now checked).

## §0 audit result (full re-read of the entire md — no regression)
Every section maps to a concrete implementation:

| md section | Implementation |
|---|---|
| **Transfer integrity** | Whole body in `main()`, invoked only on the last line (`main "$@"`). `download()` = `curl -fsSL --retry --connect-timeout`, non-2xx fatal. Artifact downloaded to a temp file (`download_and_verify`), never pipe-extracted. |
| **Verification** | `verify_checksum`: requires `checksums.txt`, requires an exact entry for our asset (awk guard against `--ignore-missing` silently passing a missing line), then `sha256sum --strict --check`. Fails closed on missing file / missing entry / mismatch. |
| **Atomic, recoverable installs** | `extract_to_staging` (adjacent `.staging-*`), `validate_staged` (present/exec/arch), `install_staged` (single `mv -T` publish + `.bak-$$` of any same-version dir, restored on failure), `cleanup_stale_staging` on startup, other `versions/<ver>` kept for rollback. |
| **Idempotency** | `write_if_changed`/`copy_if_changed`/`add_source_line` all compare before writing. One sourced env snippet; rc files checked for the source line; desktop/icons skipped when identical. Re-run converges. |
| **Self-update & rollback** | `--update` runs the same staged path; `smoke_test` (`--version`) gates the flip; old `current` untouched on any failure. `detect_system_channel` defers to dpkg/rpm/pacman. |
| **Non-interactivity** | No `read` from stdin anywhere (the lone `read` is `read -r path < "$MANIFEST_FILE"`, a file). No prompts, no `/dev/tty`. All input via flags/env. |
| **Concurrency** | FD-based `flock` (`acquire_lock`/`release_lock`) around all mutation, including uninstall. No `[ -f lockfile ]` check. Degrades with a warning if `flock` is absent. |
| **Rootless constraints** | No `sudo` (only in doc/error strings). `check_home` aborts if `$HOME` unset/not-dir/unwritable. `get_architecture` normalizes `amd64`/`arm64`. |
| **Uninstall** (Phase 6) | `do_uninstall` → `remove_manifest_paths` removes **exactly** the manifest set (symlinks unlinked, dirs `rm -rf`, files unlinked); `remove_source_line` strips the env-snippet source line + marker comment from `.bashrc .bash_profile .zshrc .profile` (rc files are NOT manifested); refreshes desktop/icon caches; sweeps the data-dir tail (`.lock`, manifest, `versions/`) with a final `rm -rf "$INSTALL_DATA_DIR"`. |
| **Baseline shell hygiene** | `set -euo pipefail`; expansions quoted (shellcheck clean); `trap cleanup EXIT INT TERM` removes temp/staging **and** `release_lock`; exit-code table documented in the header (0/1/64/65), usage errors aligned to 64. |

- `bash -n`: clean. `shellcheck` 0.11.0 (`nix run nixpkgs#shellcheck`): **CLEAN**.

## Phase 6 changes to the script (`hugo/static/scripts/sentinel-install.sh`)
- **Header:** added an exit-code table comment (0 / 1 / 64 EX_USAGE / 65 EX_DATAERR).
- **`parse_args`:** the three usage errors (`--version`/`--install-dir` missing arg, unknown option) now exit **64** to match the table.
- **New "Uninstall" section** (before `main`):
  - `remove_manifest_paths()` — deletes each manifest line by type (`-L`→`rm -f`, `-d`→`rm -rf`, `-e`→`rm -f`); missing path = no-op; unremovable path = `warn`, never abort. Returns 1 if no manifest.
  - `remove_source_line(rc,line)` — inverse of `add_source_line`; `grep -vxF` the source line and the marker comment into a sibling temp file, atomic `mv -T` back. Returns 1 when rc absent / line not present (idempotent).
  - `do_uninstall()` — `acquire_lock`; if no manifest, warn but still strip rc lines; remove manifest paths; strip rc source line from the four rc files; refresh `update-desktop-database` / `gtk-update-icon-cache`; final `rm -rf "$INSTALL_DATA_DIR"`.
- **`main`:** the `--uninstall` branch now calls `do_uninstall; return 0` (the Phase-5 `err … 64` stub is gone).

## Testing done (local, no binary exec required)
Uninstall is a **no-exec** path (file removal + rc rewrite + lock), so it is fully
testable on the NixOS dev box; no glibc host needed for Phase 6.
- **Unit (`bash`, lib sourced via `head -n -1 … > /tmp/lib.sh`, then `set +e`):**
  - `remove_manifest_paths`: removed all six manifest entries (versioned dir, `current` symlink, PATH symlink, env, desktop, icon); returns 1 with no manifest.
  - `remove_source_line`: stripped the source line **and** marker comment, kept unrelated rc content (`alias x=1`, `export FOO=1`); idempotent re-run returns 1; absent rc returns 1; atomic temp+`mv`.
  - `do_uninstall` end-to-end: bin symlink gone, data dir gone, desktop gone, `.zshrc` cleaned, exit 0.
  - no-install uninstall: warns, exits 0, cleans the dir `acquire_lock` created.
- **Run-path note:** Phase 6 did **not** touch the install/`smoke_test`/run path, so the Phase-5 glibc-host verification still stands. If a future change touches `smoke_test` or the install path, re-run the fresh-install command on a glibc host (the dev box cannot exec the portable glibc binary).

## Full glibc-host verification — DONE (post-Phase-6 re-audit)
Ran a sandboxed (isolated `HOME`/XDG/TMPDIR) end-to-end on a real glibc host with `--version 0.9.0+dev.cl.1`. All gates green:
- Fresh install exit 0; `smoke_test` printed `staged binary runs: Franklyn Sentinel v0.9.0+dev.cl.1` (the exec path).
- Published the full bundled tree (`versions/<ver>` with `lib/`, `libexec/gst-plugin-scanner`, 8 icon sizes), `current` symlink, PATH symlink; binary ran through the PATH symlink (exit 0).
- Idempotent re-run: exit 0, integration files "already up to date", `.profile` had exactly 1 source line. (Note: the re-run re-downloads/re-stages/re-publishes the same version — converges, does not duplicate; a possible future optimization is to skip when `current` already == requested version.)
- `--uninstall` exit 0; data dir, bin symlink, desktop entry all gone; zero residual `franklyn` refs in rc files.

## Exit-code table (now documented in the script header)
- `0` success
- `1` general failure (network, checksum, extract, filesystem, …)
- `64` usage error — bad flag / missing argument (EX_USAGE)
- `65` refused — franklyn is managed by a system package channel; update through it (EX_DATAERR)

## Confirmed facts (Phase 6 additions; do not re-derive)
- The manifest does **not** list `.lock`, the manifest file itself, or the `versions/` parent. `do_uninstall` deliberately removes them via the final `rm -rf "$INSTALL_DATA_DIR"` after the manifest set is gone — the manifest set may include paths **outside** the data dir (PATH symlink, desktop entry, icons), which the per-path loop handles first.
- rc files are intentionally **not** in the manifest (must never delete a whole `.bashrc`); the source line is stripped separately by `remove_source_line`. A stray blank line that `add_source_line` prepended may remain — cosmetic, intentional non-concern.
- `do_uninstall` removes `$INSTALL_DATA_DIR` while still holding the lock FD on `.lock` inside it. On Linux the open FD stays valid after unlink; `release_lock` (via `cleanup` trap) just closes it. No issue.

## Files for any reviewer
- `hugo/static/scripts/sentinel-install.sh` — the finished script.
- `hugo/static/scripts/sentinel-install.md` — requirements contract (the §0 source of truth).
- `hugo/static/scripts/sentinel-install.plan.md` — build plan (all phases `[x]`).

## Tooling note (unchanged)
shellcheck not installed system-wide. Run: `nix run nixpkgs#shellcheck -- hugo/static/scripts/sentinel-install.sh`. Unit-test internals: `head -n -1 sentinel-install.sh > /tmp/lib.sh`, set sandbox `HOME`/`XDG_*` **before** sourcing (the constants are `readonly` and derive from them), `source`, then `set +e` (the lib enables `set -e`; intentional `return 1`s would otherwise abort the harness). Run test bodies under `bash`, not the zsh login shell.

## Open questions / blockers
None. Build complete; ready for review.
