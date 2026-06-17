# Maintenance Companion — sentinel-install.sh

**Read this file in full before you touch `sentinel-install.sh`. Execute its §0 on every change.**

`sentinel-install.sh` is a production `curl | bash` installer. It is finished and verified. Every requirement in [`sentinel-install.md`](./sentinel-install.md) maps to a concrete code path (see the regression table below). A careless edit silently breaks one of those paths — a broken installer is worse than no installer, because it runs on user machines with no review in between. This document is the procedure that keeps that from happening.

This file is **self-contained**: it carries the §0 protocol, the full requirement→implementation map, and every verification command. You need only this file plus the spec ([`sentinel-install.md`](./sentinel-install.md)) to make a safe change. [`sentinel-install.plan.md`](./sentinel-install.plan.md) is the historical build record; you do not need it for maintenance.

---

## The one rule

**Never start at the shell script.** Any behavior change goes, in this exact order:

1. **Spec first.** Update [`sentinel-install.md`](./sentinel-install.md) to describe the new/changed behavior. The spec is the contract; if it is not in the spec, it is not a requirement, and the next maintainer will treat it as a defect.
2. **Read this companion.** Re-read §0 and the regression table below.
3. **Smallest incremental edit** to `sentinel-install.sh`. One concern per edit. Do not refactor and add a feature in the same change.
4. **Run §0 verification** (below). Every applicable check, every time.
5. **Commit** with the model co-author trailer (see root `AGENTS.md` §4). Record the §0 audit result in the commit body.

Adding a feature without first updating the spec is a process violation, even if the code works. The spec is what the next agent audits against.

---

## §0 — Verification protocol (non-negotiable, run on every change)

This is the most important section. It exists so an agent editing one path does not drift away from, or silently regress, the others.

1. **Spec is the source of truth.** Before writing code, re-read the spec section(s) your change touches. After you finish, re-read the **entire** spec and confirm the committed code violates no item — not only the items you changed. A regression against an untouched requirement is a defect.
2. **Prove all functionality still works.** After every change, walk the **regression table** below and verify each row still holds. Run the test recipe. Do not assume an unrelated path is fine because you "did not touch it" — `set -euo pipefail`, `readonly` constants, and the `trap` make cross-effects easy. If you cannot prove a row, the change is not done.
3. **Fail closed on ambiguity.** If the spec and reality (or this doc) conflict, the spec wins. Stop and surface it; do not guess.
4. **Hand the run-path/exec test to the user.** The dev box is NixOS and **cannot exec the portable glibc binary**. Any step that *runs* the binary (`smoke_test` / a full install that reaches `--version`) is not testable locally. When your change touches that path, do **not** mark it verified — write out the exact commands for the user to run on a real glibc host and wait for their output. No-exec logic (download, verify, flock, channel-detect, manifest, uninstall, rc rewrite) is fully testable locally.
5. **Keep changes small and committed.** One focused change per commit; run this §0 after each. A large unverifiable diff is itself a defect.

---

## Regression table — what must keep working

Every row is a spec requirement with the code that satisfies it. After any change, confirm each still holds. Do not remove or weaken a cell without first changing the spec.

| Spec section | Must keep working | Implementation |
|---|---|---|
| **Transfer integrity** | Whole body wrapped in `main()`, invoked only on the last line (`main "$@"`); truncated download fails at parse, never executes partial. `download()` = `curl -fsSL --retry --connect-timeout`, non-2xx fatal. Artifact goes to a temp file, never pipe-extracted. | `main`, last line `main "$@"`, `download`, `download_and_verify` |
| **Verification** | `SHA256SUMS` required; an **exact entry for our asset** required (awk guard so `--ignore-missing` cannot silently pass a missing line); then `sha256sum --strict --check`. Fail closed on missing file / missing entry / mismatch. Never "install anyway." | `verify_checksum` |
| **Atomic, recoverable installs** | Extract to adjacent `.staging-*`, never the live dir; validate (present/exec/arch) before going live; single atomic publish (`mv -T`) + `.bak` of any same-version dir restored on failure; stale staging swept on startup; old `versions/<ver>` kept for rollback. | `extract_to_staging`, `validate_staged`, `install_staged`, `cleanup_stale_staging` |
| **Idempotency** | Re-run converges, never duplicates. Compare-before-write on env snippet, desktop entry, icons; rc files checked for the source line; no blind `export PATH=` append. | `write_if_changed`, `copy_if_changed`, `add_source_line`, `setup_path` |
| **Self-update & rollback** | `--update` downloads+verifies+stages+validates **fully** before touching live; `smoke_test` (`--version`) gates the flip; old `current` untouched on any failure. | `--update` branch, `smoke_test`, `publish_symlinks` |
| **Channel deference** | If franklyn is managed by a system package manager (dpkg/rpm/pacman), refuse to self-update over it; defer with guidance (exit 65). | `detect_system_channel` |
| **Non-interactivity** | No `read` from stdin anywhere (stdin is the piped script). The only `read` is from a file. All input via flags/env; safe non-interactive defaults. Any unavoidable prompt reads `/dev/tty` gated by `[ -t 0 ]`. | `parse_args`, absence of stdin `read` |
| **Concurrency** | FD-based `flock` around **all** mutation (install, update, uninstall); kernel releases on crash. No `[ -f lockfile ]` race check. | `acquire_lock`, `release_lock` |
| **Rootless constraints** | No `sudo` anywhere (only in doc/error strings). `$HOME` unset/not-dir/unwritable aborts clearly. `uname -m`/`-s` normalized (`amd64`→`x86_64`, `arm64`→`aarch64`). | `check_home`, `get_architecture` |
| **Preflight host requirements** | Before download, glibc floor checked (`getconf GNU_LIBC_VERSION` → `ldd --version` fallback); detectably `< 2.34` aborts **pre-download** (exit 66); undetectable warns + continues. GStreamer **not** checked (bundled in portable tree). PipeWire warned (never fatal) only on a Wayland session when absent. `--skip-checks` / `FRANKLYN_SENTINEL_SKIP_CHECKS` bypasses all checks. No-exec; install/update only, never uninstall. | `check_requirements`, `detect_glibc_version`, `version_ge`, `session_is_wayland`, `have_pipewire` |
| **Uninstall** | Removes **exactly** the manifest set (no guessed globs); strips the env-snippet source line from rc files (rc files are NOT manifested — never delete a whole `.bashrc`); refreshes desktop/icon caches; final `rm -rf` of the data dir tail. | `do_uninstall`, `remove_manifest_paths`, `remove_source_line` |
| **Baseline shell hygiene** | `set -euo pipefail`; every expansion quoted (shellcheck clean); `trap cleanup EXIT INT TERM` removes temp/staging **and** releases the lock FD; every failure path exits non-zero per the exit-code table. | header, `cleanup`, `trap` |

**Exit-code table (keep stable; document any addition in the script header and spec):**
- `0` success · `1` general failure (network/checksum/extract/fs) · `64` usage error (bad flag / missing arg) · `65` refused — managed by a system package channel · `66` host runtime requirement unmet (glibc below the 2.34 floor; overridable with `--skip-checks`).

---

## Test recipe — run before every commit

### Static (always, local, fast)
```sh
bash -n hugo/static/scripts/sentinel-install.sh                 # parse clean
nix run nixpkgs#shellcheck -- hugo/static/scripts/sentinel-install.sh   # must be CLEAN
```
shellcheck is not installed system-wide; the `nix run` form is the canonical invocation.

### Unit (no-exec internals, local)
The whole body is wrapped in `main()` and the last line is `main "$@"`, so sourcing the file minus that last line gives you the helper library without running it:
```sh
head -n -1 hugo/static/scripts/sentinel-install.sh > /tmp/lib.sh
# Constants are readonly and derive from HOME/XDG_*, so export a SANDBOX set BEFORE sourcing:
export HOME=/tmp/si-sandbox XDG_DATA_HOME=/tmp/si-sandbox/.local/share \
       XDG_CONFIG_HOME=/tmp/si-sandbox/.config XDG_BIN_HOME=/tmp/si-sandbox/.local/bin
source /tmp/lib.sh
set +e   # the lib enables `set -e`; intentional `return 1`s would otherwise kill the harness
# now call individual functions and assert on their effects
```
Run test bodies under **bash**, not the zsh login shell. No-exec paths fully testable here: download/verify (mock), flock, channel-detect, manifest add/remove, rc add/remove (`add_source_line`/`remove_source_line`), idempotency compares, uninstall.

### Run-path (exec — HAND TO THE USER, NixOS cannot exec the glibc binary)
When your change touches `smoke_test`, the install publish, or anything that runs `franklyn --version`, give the user a sandboxed end-to-end and wait for output:
```sh
# isolated HOME/XDG/TMPDIR so it cannot touch the real install
env HOME=/tmp/si-e2e XDG_DATA_HOME=/tmp/si-e2e/.local/share \
    bash hugo/static/scripts/sentinel-install.sh --version 0.9.0+dev.cl.1   # fresh install → expect exit 0, smoke_test prints version
# then: re-run (idempotent, exit 0, single rc source line), --update, --uninstall (exit 0, data dir + bin symlink + desktop gone)
```
Do not mark the run-path verified from the dev box. Wait for the user's real-host output.

---

## Confirmed facts about the artifact (do not re-derive)

These were established during the build and verified on a real glibc host. They are not obvious from the script alone; changing the script against a wrong assumption here breaks the installer. Re-confirm only if the release artifact itself changes.

**Portable tarball layout** (`franklyn-sentinel-<ver>-<arch>-linux-portable.tar.zst`)
- Extracts to a tree rooted directly at: `bin/franklyn`, `lib/`, `libexec/`, `share/`, `LICENSE`, `GSTREAMER_LICENSE`, `README.txt`. **No single wrapper dir.**
- The binary is **`bin/franklyn`** — NOT `bin/franklyn-sentinel`. Hence `BIN_NAME="franklyn"`, `ASSET_BIN_REL="bin/franklyn"`.
- Binary is ELF64 PIE with **RUNPATH `$ORIGIN/../lib`** → the whole tree installs and moves as **one unit**; the PATH symlink works because `$ORIGIN` resolves through it. Interpreter is the system `/lib64/ld-linux-x86-64.so.2`; **host needs glibc ≥ 2.34** (per the bundled README). This is why the NixOS dev box cannot exec it.
- Ships icons at `share/icons/hicolor/<size>/apps/franklyn-sentinel.png`, sizes **16,24,32,48,64,128,256,512**. Ships **no `.desktop` file**.

**Runtime constraints**
- The installer runs standalone via `curl | bash` and **cannot read the repo's `sentinel/resources/*` at runtime.** Every asset comes from the extracted tarball or is generated inline.
- The desktop entry is therefore **rendered inline** by `render_desktop()` to match the repo template `sentinel/resources/franklyn-sentinel.desktop` (`@VERSION@` / `@BINARY_PATH@`, `Icon=franklyn-sentinel`). **Keep `render_desktop` in sync if that repo template changes.** `Exec` points at the **absolute** `current/bin/franklyn` so the launcher works regardless of session PATH.
- Icons are copied from the **installed** tree (`$INSTALL_DATA_DIR/current/share/icons/hicolor`), not staging — by the time `integrate_desktop` runs, staging has already been `mv`'d into place.
- rc source line is `. "$ENV_FILE"`; the rc set is `.bashrc .bash_profile .zshrc .profile` (only those that exist; `.profile` is created if none exist). **rc files are deliberately NOT in the manifest** — never delete a whole rc file; `remove_source_line` strips only the line.
- `smoke_test` runs `franklyn --version` against the **staging** tree, **before** any `mv`/symlink flip — a smoke failure leaves the live install untouched. franklyn is a GUI client, but `--version` is headless-safe (confirmed on the glibc host).
- `--update` is **not** a separate install path — it runs the exact same `resolve_version → download_and_verify → install_from_asset → record_core_manifest → setup_path → integrate_desktop` sequence; atomicity/rollback come free from the shared staged-install machinery. Only differences: channel deference is **fatal** on update (a warning on install), plus an "updating…" notice.
- System packages (deb / AUR / openSUSE) install `/usr/bin/franklyn` — **same command name as ours, intentionally.** `detect_system_channel` resolves the path via `readlink -f`, excludes our own tree, and queries `dpkg`/`rpm`/`pacman`; it only fires when one of those is installed **and** owns the resolved path.
- `$INSTALL_DATA_DIR/.lock` is **persistent** (created by `acquire_lock`, never removed by cleanup — correct for a lock file) and is **not** in the manifest; uninstall removes it via the final `rm -rf` of the data-dir tail, not the manifest loop.

**Test-harness nuance** (in addition to the recipe above): run test bodies under **bash explicitly** (login shell is zsh; sourcing the bash lib into zsh breaks on FD / `set -u` semantics). For live sandbox runs, `env -i` with a fresh `HOME`/`XDG_*`/`TMPDIR` (`mktemp -d`) and **create `$TMPDIR` before running**.

---

## Pointers
- [`sentinel-install.md`](./sentinel-install.md) — the spec / contract. The §0 audit source of truth. Change it **first**.
- [`sentinel-install.sh`](./sentinel-install.sh) — the script. Change it **last**, in small steps.
- [`sentinel-install.plan.md`](./sentinel-install.plan.md) — historical build record (phases all done, with the build log + confirmed-facts trail folded in). Not needed for maintenance.
- Root `AGENTS.md` — the "Installer Script Is Protected" rule that points here.
