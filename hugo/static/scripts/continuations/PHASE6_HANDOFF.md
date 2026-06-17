# Handoff → Phase 6 (uninstall, non-interactivity finish, final hardening)

## Phase just completed: Phase 5 — concurrency, self-update, rollback, channel deference
- Commit: `feat(sentinel-install): flock, verified self-update, rollback, channel deference` (latest feat on branch `feat/curl-install-script-for-sentinel`).
- Plan tracker updated: Phase 5 marked `[x]`.

## §0 audit result for this commit
Re-read the entire `sentinel-install.md`. Phase 5 satisfies its target sections; no regression against earlier ones:
- **Concurrency** (now satisfied) → FD-based `flock` on `$INSTALL_DATA_DIR/.lock` around all install/update mutation. `acquire_lock` opens a bash-chosen FD (`exec {LOCK_FD}>`), tries `flock -n`, and on contention prints a notice then blocks on `flock`. **No `[ -f lockfile ]` check anywhere.** The FD is held for the whole run and released by `release_lock`, which `cleanup` calls on `EXIT/INT/TERM` (kernel also releases on crash). ✓
- **Self-update & rollback** (now satisfied) → `--update` reuses the Phase 2–3 path: download → verify checksum → extract to staging → `validate_staged` → **`smoke_test`** → only then `install_staged` flips `current`. Nothing live is touched until the new tree is fully staged and verified; other `versions/<ver>` dirs are kept, so a failed update leaves the old `current` intact (rollback = do nothing destructive). ✓
- **Channel deference** (now satisfied) → `detect_system_channel` resolves `command -v franklyn`, treats anything under `$INSTALL_DATA_DIR` (or our own bin symlink) as ours, else queries `dpkg -S` / `rpm -qf` / `pacman -Qo`. On `--update` a system-managed binary is a **fatal** defer (exit 65) pointing at the package manager; on a fresh install it's a non-fatal warning (our rootless copy only shadows on PATH). ✓
- **Idempotency / atomic installs / verification / transfer integrity / rootless / non-interactivity** (still hold) → update path is the same staged/atomic machinery; re-running `--update` on the same version converges (env/rc/desktop/icons all report "already up to date"). No `read`, no sudo, all writes under XDG/`$HOME`. ✓
- **Baseline hygiene** → `set -euo pipefail`, quoting, failure paths `err` non-zero. `bash -n` clean; `shellcheck` 0.11.0 **CLEAN**.
- **Verified live, end-to-end** against `v0.9.0+dev.cl.1` in an isolated `env -i` sandbox (`HOME`/`XDG_*`/`TMPDIR`): clean install exit 0, then `--update --version …` exit 0 and fully idempotent. Smoke test on the **real** GUI binary behaved as designed (see below). No `.staging-*` leftovers; `current` → `versions/0.9.0+dev.cl.1`.
- **Unit-tested in isolation** (`head -n -1 … > /tmp/lib.sh && source`): lock acquire/release sets+clears `LOCK_FD` and creates the lockfile; serialization blocks a second `acquire_lock` ~0.8s behind a 1s background holder; `detect_system_channel` returns empty for our own symlink and **flags** a mocked `dpkg`-owned `/usr/bin/franklyn`.
- Deferred to Phase 6 (expected): uninstall removal half, non-interactivity final pass, final hardening + full §0 sweep.

## ✅ Open questions from Phase 5 — RESOLVED
- **Is `franklyn --version` headless/safe?** No, it is **not** a clean fast-exit CLI flag (live run: "version probe inconclusive"). But the smoke test is built so this does **not** matter:
  - **Primary gate (fatal):** `ldd "$bin"` must show no `not found` — confirms the loader + RUNPATH `$ORIGIN/../lib` + bundled libs are coherent **without executing the GUI**. This is the real "is it runnable" check and aborts the update on failure.
  - **Secondary probe (best-effort, never fatal):** `env -u DISPLAY -u WAYLAND_DISPLAY timeout 10 "$bin" --version`. Display env scrubbed so it can't open a window; `timeout` so it can't hang. Exit 0 → log the version; anything else → "inconclusive", fall back to the ldd + arch checks. **This is a documented, deliberate deviation from the md's literal "`--version` smoke test"** — runnability is proven structurally (ldd) instead of via an unreliable GUI flag.
- **flock-absent behaviour?** **Degrade with a warning, do not abort.** flock ships in util-linux and is present on effectively every Linux; refusing a rootless install over a missing optional tool is worse than losing the guard against the rare concurrent-run case. Documented inline in the Concurrency section.

## ⚠️ Release-reality notes (unchanged, IMPORTANT for any live test)
- **`/releases/latest` is still NOT usable for live testing.** Stable `v0.9.0` predates `checksums.txt` + the portable asset; a no-arg run 404s on download (fails closed correctly).
- **Use `--version 0.9.0+dev.cl.1`** for any end-to-end run — that public prerelease has the portable asset + `checksums.txt`. It is a prerelease, so `/releases/latest` does not return it (by design).
- Version tokens contain `+`/`.` — keep quoting; never regex them unquoted.

## Confirmed facts (Phase 5 additions; do not re-derive)
- `--update` is **not** a distinct install path — it runs the exact same `resolve_version → build_asset_url → download_and_verify → install_from_asset → record_core_manifest → setup_path → integrate_desktop` sequence as a fresh install. Its only structural differences: (1) channel deference is **fatal** instead of a warning, (2) an extra "updating…" notice. Atomicity/rollback come for free from the shared staged-install machinery.
- `smoke_test` runs against the **staging** tree (`$STAGING_DIR/$ASSET_BIN_REL`) **before** any `mv` into `versions/` or symlink flip — so a smoke failure leaves the live install completely untouched.
- The lock file `$INSTALL_DATA_DIR/.lock` is **persistent** (created by `acquire_lock`, never removed by cleanup) — that is correct for a lock file. It is **not** in the manifest yet; Phase 6 uninstall should decide whether to remove it (it's under `$INSTALL_DATA_DIR`, so removing the whole data dir covers it — but the manifest-driven removal won't list it). Consider adding it to the manifest or documenting that uninstall rm's the data dir tail.
- Channel detection only fires when a system package manager (`dpkg`/`rpm`/`pacman`) is actually installed AND owns the resolved path. On a system with none of those, a non-ours `franklyn` on PATH is treated as unmanaged (returns empty) — acceptable.

## State of the script (`hugo/static/scripts/sentinel-install.sh`)
Everything from Phase 4 plus:
- **New constant:** `LOCK_FILE="$INSTALL_DATA_DIR/.lock"`. **New state var:** `LOCK_FD=""`.
- **Concurrency section:** `acquire_lock()` (FD-based `flock`, blocks-with-notice on contention, degrades-with-warning if `flock` absent), `release_lock()` (`flock -u` + close FD via `eval "exec $LOCK_FD>&-"`). `cleanup()` now calls `release_lock`.
- **`smoke_test(bin)`** — ldd runnability gate (fatal) + best-effort scrubbed/timeout `--version` probe (non-fatal). Wired into `install_from_asset` between `validate_staged` and `install_staged`.
- **`detect_system_channel()`** — prints a system-channel label or nothing; resolves via `readlink -f`, excludes our own tree, queries `dpkg`/`rpm`/`pacman`.
- **`main()`** rewrite: `acquire_lock` after `check_home`/`get_architecture`; channel deference (fatal on `update`, warn on install); `update` prints an "updating…" notice then falls through the **shared** install path (the old `say "update mode selected…"` stub is gone). `uninstall` still `err`s with code 64 (Phase 6).

## Next phase goal: Phase 6 — uninstall, non-interactivity finish, final hardening
Must satisfy `sentinel-install.md` sections **Uninstall**, **Non-interactivity**, **Baseline shell hygiene** (final pass). Concrete steps in `sentinel-install.plan.md` → "Phase 6". Summary:
- **`--uninstall`:** read `$MANIFEST_FILE` and remove **exactly** those paths — no guessed globs. Then strip the `. "$ENV_FILE"` source line from the same rc set `setup_path` touches (`.bashrc .bash_profile .zshrc .profile`) — rc files are **deliberately not in the manifest** (don't delete a whole rc file). Decide handling for `versions/`/`current`/the data dir tail and the persistent `.lock` (see Phase-5 note above). Acquire the lock during uninstall too (it mutates).
- **Non-interactivity final pass:** confirm no `read` from stdin anywhere; any unavoidable prompt reads `/dev/tty` gated by `[ -t 0 ]`. (Currently there are zero prompts — keep it that way.)
- **Final hardening:** every expansion quoted; define an exit-code table (already using 64/65 — document them); confirm `trap` cleans temp/staging **and** releases the lock on all of `EXIT/INT/TERM`.
- **Full §0 audit** against the entire md; fix any regression.
- **Commit:** `feat(sentinel-install): uninstall, non-interactive hardening, final audit`. Then write `PHASE7_HANDOFF.md` (final = "complete, ready for review", mapping each md section to its implementation).

## Files the next agent needs
- `hugo/static/scripts/sentinel-install.sh` — the script (edit this)
- `hugo/static/scripts/sentinel-install.md` — requirements contract (re-read fully after every commit; §0)
- `hugo/static/scripts/sentinel-install.plan.md` — build plan (Phase 6 steps + §0 protocol)

## Tooling note
shellcheck not installed system-wide. Run: `nix run nixpkgs#shellcheck -- hugo/static/scripts/sentinel-install.sh`. Must be clean before each commit. Unit-test internals: `head -n -1 sentinel-install.sh > /tmp/lib.sh && source /tmp/lib.sh` (strips the final `main "$@"`), then call functions with the needed globals set. **Run tests under `bash` explicitly** (the login shell is zsh; sourcing the bash lib into zsh breaks on FD/`set -u` semantics — wrap test bodies in a file and run `bash /tmp/t.sh`). For live runs, isolate with `env -i` + a sandbox `HOME`/`XDG_*`/`TMPDIR` (`mktemp -d`, and **create `$TMPDIR` first**) and `--version 0.9.0+dev.cl.1`.

## Open questions / blockers
None blocking.
- Phase 6 must decide: does uninstall remove the persistent `.lock` and the empty `versions/`/data-dir tail? (Manifest lists files/symlinks/versioned dir, not `.lock`.) Recommend: after removing the manifest set + rc source line, `rmdir` now-empty dirs and remove `.lock`, or simply `rm -rf "$INSTALL_DATA_DIR"` as the final step once the manifest set (which may include paths outside it, e.g. the bin symlink and desktop/icon files) is gone.
