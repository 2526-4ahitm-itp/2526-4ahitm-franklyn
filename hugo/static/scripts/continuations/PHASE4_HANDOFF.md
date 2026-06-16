# Handoff → Phase 4 (PATH, desktop integration, manifest, idempotency)

## Phase just completed: Phase 3 — Staging, validation, atomic install, recovery
- Commit: `feat(sentinel-install): atomic staged install with recovery` (`1cb1d53`, latest on branch `feat/curl-install-script-for-sentinel`).

## §0 audit result for this commit
Re-read entire `sentinel-install.md`. Phase 3 satisfies its target section; no regression against earlier ones:
- **Atomic, recoverable installs** → extract into a staging dir **adjacent** to the versioned dir and on the **same filesystem** (`mktemp -d "$INSTALL_DATA_DIR/.staging-XXXXXX"`), never into the live tree. Validate staged contents before going live (`validate_staged`: binary present + executable + arch-matched). Publish with a **single atomic `mv -T`** of the staging tree into `versions/<ver>`; `current` and the PATH symlink are swapped atomically (temp symlink + `mv -T`). Existing same-version dir is moved aside and only removed on success (recoverable `.bak-<pid>`); other version dirs are kept. On startup `cleanup_stale_staging` removes leftover `.staging-*` from an interrupted run. ✓
- **Transfer integrity** (still holds) → extraction reads from the verified file (`tar -xf "$ASSET_PATH"`), never a stream. ✓
- **Verification** (still holds) → unchanged; checksum still gates everything before extraction. ✓
- **Rootless** (still holds) → all paths under XDG/`$HOME`; only `mv`/`ln -s`/`rm`; no sudo. ✓
- **Baseline hygiene** (still holds) → `set -euo pipefail`, quoting, every failure path `err` non-zero. Trap now also cleans `STAGING_DIR` (appended to `_CLEANUP_PATHS`). **No new trap added.** ✓
- `bash -n` clean; `shellcheck` 0.11.0 (`nix run nixpkgs#shellcheck`) CLEAN.
- **Verified live, end-to-end** against `v0.9.0+dev.cl.1` in an isolated XDG sandbox: clean install → `versions/<ver>` + `current` + `<bin>/franklyn` resolving to the real executable, exit 0, no staging leftovers. Re-run idempotent (atomic tree replace, same-version backup cleaned). Planted stale `.staging-DEADBEEF` removed with a warning; planted unrelated `versions/0.0.1-old` preserved. `validate_staged` unit-tested: arch match → 0; arch mismatch / missing binary / non-executable → non-zero.
- Deferred to later phases (expected): PATH/env snippet, desktop+icon integration, manifest, idempotency for those writes (Phase 4); concurrency/flock, self-update, rollback, channel deference (Phase 5); uninstall (Phase 6).
- **Note:** `mv -T` is GNU-coreutils only. Acceptable: `get_architecture` already rejects non-Linux. Do not "port" it to BSD `mv` without revisiting atomicity.

## ⚠️ Release-reality notes (unchanged, IMPORTANT for any live test)
- **`/releases/latest` is still NOT usable for live testing.** Stable `v0.9.0` predates `checksums.txt` and the portable asset; a no-arg run 404s on download (fails closed correctly, cannot complete).
- **Use `--version 0.9.0+dev.cl.1`** for any end-to-end run — that public prerelease has the portable asset + `checksums.txt`. It is a prerelease, so `/releases/latest` does not return it (by design).
- Version tokens contain `+`/`.` — keep quoting; never regex them unquoted.

## Confirmed facts about the portable tarball (do not re-derive)
- Extracted layout is a tree rooted directly at: `bin/franklyn`, `lib/`, `libexec/`, `share/`, `LICENSE`, `GSTREAMER_LICENSE`, `README.txt`. **No single wrapper dir.**
- **Binary is `bin/franklyn`** (NOT `bin/franklyn-sentinel`). Constant `ASSET_BIN_REL="bin/franklyn"`, `BIN_NAME="franklyn"`.
- Binary: ELF64 PIE, **RUNPATH `$ORIGIN/../lib`** → must stay alongside `lib/`; whole tree installs as one unit; the PATH symlink works because `$ORIGIN` resolves the real path. Interpreter is the system `/lib64/ld-linux-x86-64.so.2` (host needs glibc ≥ 2.34 per README).
- `share/` already contains icons: `share/icons/hicolor/<size>/apps/franklyn-sentinel.png` (512, 256, 48 seen in the asset). The repo also ships icons at `sentinel/resources/icons/<size>/apps/franklyn-sentinel.png` (16,24,32,48,64,128,256,512).
- **Command/exec name across system packages is `franklyn`** (`/usr/bin/franklyn` in `sentinel/packaging/opensuse/franklyn.spec.in` and `sentinel/packaging/aur/PKGBUILD`). The desktop file `sentinel/resources/franklyn-sentinel.desktop` has `Exec=@BINARY_PATH@` and `Icon=franklyn-sentinel` — `@VERSION@`/`@BINARY_PATH@` are templates the installer must substitute.

## State of the script (`hugo/static/scripts/sentinel-install.sh`)
Everything from Phase 2 plus:
- **New constants:** `BIN_NAME="franklyn"`, `ASSET_BIN_REL="bin/franklyn"`.
- **New globals:** `STAGING_DIR` (mktemp staging, registered in `_CLEANUP_PATHS`), `VERSION_DIR`. `ASSET_PATH` no longer carries the SC2034 disable (now consumed).
- `cleanup_stale_staging()` — startup recovery; removes leftover `.staging-*` only.
- `extract_to_staging()` — `need_cmd zstd`/`tar`; `mktemp -d` under `INSTALL_DATA_DIR`; `tar --use-compress-program=zstd -xf`.
- `arch_elf_machine()` — maps `ARCH` → readelf Machine substring (`X86-64`/`AArch64`).
- `validate_staged(dir)` — binary present/executable/arch-matched (readelf, then `file`, else warn).
- `atomic_symlink(target, link)` — temp symlink + `mv -T`.
- `publish_symlinks()` — `current` → `versions/<ver>` (relative); `${OPT_INSTALL_DIR:-$XDG_BIN_HOME}/franklyn` → `current/bin/franklyn` (absolute).
- `install_staged(dir)` — same-version backup aside, atomic `mv -T` publish, restore-on-failure, then `publish_symlinks`, then drop backup.
- `install_from_asset()` — extract → validate → install orchestrator.
- `main()` — now calls `cleanup_stale_staging`, `download_and_verify`, `install_from_asset`, then prints a "done; ensure <bin> on PATH (Phase 4)" line. **Replace that PATH hint with the real env-snippet + desktop/icon integration in Phase 4.**
- `DESKTOP_DIR`/`ICON_BASE_DIR` still carry `# shellcheck disable=SC2034` — **Phase 4 consumes these; remove the disables when you do.**

## Next phase goal: Phase 4 — PATH, desktop integration, manifest, idempotency
Must satisfy `sentinel-install.md` sections **Idempotency** and the manifest-writing half of **Uninstall**. Concrete steps in `sentinel-install.plan.md` → "Phase 4". Summary:
- **PATH:** write **one** sourced env snippet (e.g. `$INSTALL_DATA_DIR/env`) that prepends the bin dir. In shell rc files, check for an existing `source`/`.` line before adding; **never** blind-append `export PATH=`. (If `OPT_INSTALL_DIR` is set, the env snippet should reference that dir.)
- **Desktop entry + icons:** render `sentinel/resources/franklyn-sentinel.desktop` substituting `@VERSION@` and `@BINARY_PATH@` (point `Exec` at the installed `franklyn` — the PATH symlink or `current/bin/franklyn`); install to `$DESKTOP_DIR`. Install icons into `$ICON_BASE_DIR/<size>/apps/franklyn-sentinel.png`. Before writing, compare against existing content and skip if identical (idempotent). Prefer the icons already inside the extracted `share/` tree, or copy from `sentinel/resources/icons` — do not modify those repo files.
- **Manifest:** append every path the installer creates/writes to a manifest (e.g. `$INSTALL_DATA_DIR/install-manifest.txt`) — this is exactly what Phase 6 uninstall will remove. Decide whether versioned dirs / symlinks belong in the manifest too (recommended: yes, so uninstall is complete).
- **Done-when:** second run is a no-op (no duplicate rc lines, no rewritten identical files); manifest lists every written path.
- **Commit:** `feat(sentinel-install): PATH/desktop integration, manifest, idempotency`. Then write `PHASE5_HANDOFF.md`.

## Files the next agent needs
- `hugo/static/scripts/sentinel-install.sh` — the script (edit this)
- `hugo/static/scripts/sentinel-install.md` — requirements contract (re-read fully after every commit; §0)
- `hugo/static/scripts/sentinel-install.plan.md` — build plan (Phase 4 steps + §0 protocol)
- `sentinel/resources/franklyn-sentinel.desktop` — desktop template (`@VERSION@`, `@BINARY_PATH@`, `Icon=franklyn-sentinel`); **do not modify it**, render a copy
- `sentinel/resources/icons/<size>/apps/franklyn-sentinel.png` — icon sources (16–512); the extracted `share/icons/...` also has a subset

## Tooling note
shellcheck not installed system-wide. Run: `nix run nixpkgs#shellcheck -- hugo/static/scripts/sentinel-install.sh`. Must be clean before each commit. To unit-test internal functions, `head -n -1 sentinel-install.sh > /tmp/lib.sh && source /tmp/lib.sh` (strips the final `main "$@"`), then call the function with `ARCH`/globals set — as done for `validate_staged` in Phase 3.

## Open questions / blockers
None blocking.
- Decide the env-snippet path and rc-file set to touch (e.g. `.bashrc`, `.profile`, `.zshrc` if present) — keep it idempotent and documented.
- Decide whether the desktop `Exec` points at the stable PATH symlink (`$BIN_DIR/franklyn`) or `current/bin/franklyn`. Recommend `current/bin/franklyn` (absolute) so the launcher works even if the bin dir is not on the desktop session PATH.
