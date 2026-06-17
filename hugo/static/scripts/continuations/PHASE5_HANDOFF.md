# Handoff → Phase 5 (concurrency, self-update, rollback, channel deference)

## Phase just completed: Phase 4 — PATH, desktop integration, manifest, idempotency
- Commit: `feat(sentinel-install): PATH/desktop integration, manifest, idempotency` (`777285a`, latest on branch `feat/curl-install-script-for-sentinel`).
- Plan tracker updated: Phase 4 marked `[x]`.

## §0 audit result for this commit
Re-read entire `sentinel-install.md`. Phase 4 satisfies its target sections; no regression against earlier ones:
- **Idempotency** (now satisfied) → re-run converges, never duplicates. `write_if_changed` (env, desktop) and `copy_if_changed` (icons) skip when content/bytes are identical. PATH is managed by **one** sourced snippet (`$INSTALL_DATA_DIR/env`); rc files get a single guarded `source` line (`grep -qF` before append) — **never** a blind `export PATH=`. ✓
- **Uninstall** (manifest-writing half, now satisfied) → `manifest_add` appends every created path to `$INSTALL_DATA_DIR/install-manifest.txt`, deduped with `grep -qxF`. Manifest covers versioned dir, `current` + PATH symlinks, env, desktop entry, and every icon. This is the exact set Phase 6 removal consumes. ✓ (Removal half is Phase 6.)
- **Transfer integrity / Verification / Atomic recoverable installs** (still hold) → untouched by Phase 4. ✓
- **Rootless** (still holds) → all writes under XDG/`$HOME`; only `mkdir`/`cp`/`ln`/`mv`/`rm`/`printf`/`cat`; no sudo. ✓
- **Non-interactivity** (still holds) → no `read`; flags/env only. ✓
- **Baseline hygiene** → `set -euo pipefail`, quoting, failure paths `err` non-zero. SC2034 disables on `DESKTOP_DIR`/`ICON_BASE_DIR` removed (now consumed). `bash -n` clean; `shellcheck` 0.11.0 CLEAN.
- **Verified live, end-to-end** against `v0.9.0+dev.cl.1` in an isolated XDG sandbox: clean install exit 0 → env snippet, `.profile` source line, desktop entry (Exec=absolute `current/bin/franklyn`), 8 icons (16–512), manifest with 14 entries. Re-run exit 0 and **fully idempotent**: manifest byte-identical, `.profile` byte-identical, exactly one source line, every file reported "already up to date".
- Deferred to later phases (expected): concurrency/flock, self-update, rollback, channel deference (Phase 5); uninstall removal + final non-interactivity/hardening pass (Phase 6).

## ⚠️ Bug fixed this phase (do not reintroduce)
A function whose **last command** is `[ … ] && cmd` or `check_cmd X && ignore …` returns that command's non-zero status when the left side is false. Under `set -e`, a **bare** call to such a function in `main` (e.g. `setup_path`) aborts the whole script. First live run exited 1 right after the PATH step for exactly this reason. Fixed by converting those trailing `&&` idioms to explicit `if`. **Rule:** never end a function (that is called bare under `set -e`) with a short-circuit `&&`/`||` whose final status can be non-zero — use `if`, or end with `return 0`.

## ⚠️ Release-reality notes (unchanged, IMPORTANT for any live test)
- **`/releases/latest` is still NOT usable for live testing.** Stable `v0.9.0` predates `checksums.txt` + the portable asset; a no-arg run 404s on download (fails closed correctly).
- **Use `--version 0.9.0+dev.cl.1`** for any end-to-end run — that public prerelease has the portable asset + `checksums.txt`. It is a prerelease, so `/releases/latest` does not return it (by design).
- Version tokens contain `+`/`.` — keep quoting; never regex them unquoted.

## Confirmed facts (Phase 4 additions; do not re-derive)
- **The installer runs standalone via `curl | bash` — it CANNOT read the repo's `sentinel/resources/*` at runtime.** All assets must come from the extracted tarball or be generated inline.
- **The portable tarball ships NO `.desktop` file.** Only icons, under `share/icons/hicolor/<size>/apps/franklyn-sentinel.png` for sizes **16,24,32,48,64,128,256,512** (full set, confirmed in the asset). The desktop entry is therefore **rendered inline** by `render_desktop()` to match `sentinel/resources/franklyn-sentinel.desktop` (the `@VERSION@`/`@BINARY_PATH@` template) — keep them in sync if the repo template changes.
- Icons are copied from the **installed** tree (`$INSTALL_DATA_DIR/current/share/icons/hicolor`), not from staging — staging has already been `mv`'d into place by the time `integrate_desktop` runs.
- Desktop `Exec` points at the **absolute** `current/bin/franklyn` so the launcher works regardless of the desktop session PATH (matches the Phase-4 handoff recommendation).
- rc-file source line is `. "$ENV_FILE"`; the set touched is `.bashrc .bash_profile .zshrc .profile` (only those that exist), plus `.profile` is created if no rc file exists. **rc files are deliberately NOT in the manifest** (removing a whole rc file would be wrong) — Phase 6 must strip the source line from this same rc set separately.

## State of the script (`hugo/static/scripts/sentinel-install.sh`)
Everything from Phase 3 plus:
- **New constants:** `ENV_FILE="$INSTALL_DATA_DIR/env"`, `MANIFEST_FILE="$INSTALL_DATA_DIR/install-manifest.txt"`. SC2034 disables removed from `DESKTOP_DIR`/`ICON_BASE_DIR`.
- `manifest_add(path)` — append-once (deduped via `grep -qxF`).
- `write_if_changed(dest, content)` — write only if absent/different; returns 0=wrote, 1=unchanged.
- `copy_if_changed(src, dest)` — `cmp -s` guard; returns 0=copied, 1=identical.
- `record_core_manifest()` — registers versioned dir, `current`, PATH symlink.
- `env_snippet_content(bin_dir)` / `add_source_line(rc, line)` / `setup_path()` — PATH wiring.
- `render_desktop(exec)` / `install_icons()` / `integrate_desktop()` — desktop + icons.
- `main()` now calls, after `install_from_asset`: `record_core_manifest`, `setup_path`, `integrate_desktop`, then a PATH-aware "done" message (detects whether bin dir is already on `$PATH`, else prints the `source` hint).

## Next phase goal: Phase 5 — concurrency, self-update, rollback, channel deference
Must satisfy `sentinel-install.md` sections **Concurrency** and **Self-update & rollback**. Concrete steps in `sentinel-install.plan.md` → "Phase 5". Summary:
- **flock:** FD-based lock on a lock file around install/update (kernel releases on crash). Wire the lock FD into the `trap` cleanup. Do **not** use a `[ -f lockfile ]` check. Lock file path under `$INSTALL_DATA_DIR` (e.g. `$INSTALL_DATA_DIR/.lock`). `need_cmd flock` (or degrade gracefully? — flock is in util-linux, usually present; decide and document).
- **Self-update (`--update`):** reuse Phases 2–3 to download+verify+stage+validate the new version **fully before** touching the live install (the current staged-install path already does this — the new version goes to its own `versions/<ver>` and only the `current` symlink flip publishes it). Add a **smoke test** of the staged binary before flipping (the md wants `--version`; but per Phase 3 note this is a **GUI client** — confirm whether `franklyn --version` is safe/headless before relying on it; if not, keep the static arch check and document the deviation). On any failure leave the old `current` intact (rollback = do nothing destructive). Right now `main` treats `update` as a stub message (`say "update mode selected …"`) then falls through to the normal install path — replace that.
- **Channel deference:** if sentinel is already installed via a system package manager (`command -v franklyn` resolving to `/usr/bin/franklyn`; check dpkg/rpm ownership), do **not** self-update over it — detect and defer with a clear message. The system packages install `/usr/bin/franklyn` (deb/AUR/openSUSE), same command name as ours (intentional) — so resolve the path and compare against our install dir.
- **Done-when:** concurrent invocations serialize; failed update keeps the working binary; apt-installed sentinel is detected and update refused with guidance.
- **Commit:** `feat(sentinel-install): flock, verified self-update, rollback, channel deference`. Then write `PHASE6_HANDOFF.md`.

## Files the next agent needs
- `hugo/static/scripts/sentinel-install.sh` — the script (edit this)
- `hugo/static/scripts/sentinel-install.md` — requirements contract (re-read fully after every commit; §0)
- `hugo/static/scripts/sentinel-install.plan.md` — build plan (Phase 5 steps + §0 protocol)
- `.github/workflows/release.yaml` — asset names / channels, if channel detection needs the deb naming

## Tooling note
shellcheck not installed system-wide. Run: `nix run nixpkgs#shellcheck -- hugo/static/scripts/sentinel-install.sh`. Must be clean before each commit. To unit-test internal functions, `head -n -1 sentinel-install.sh > /tmp/lib.sh && source /tmp/lib.sh` (strips the final `main "$@"`), then call functions with the needed globals set. For live runs, isolate with a sandbox `HOME`/`XDG_*` (`mktemp -d`) and `--version 0.9.0+dev.cl.1`.

## Open questions / blockers
None blocking.
- Confirm `franklyn --version` runs headless (no display/GUI) before using it as the Phase 5 smoke test; if it needs a display, keep the static arch check and document why.
- Decide flock behaviour when `flock` is absent (abort via `need_cmd` vs. degrade) — document the choice.
