# Installer Requirements — sentinel-install.sh (rootless curl | bash)

> **This file is the contract.** To change installer behavior, edit this spec **first**,
> then follow [`sentinel-install.maintenance.md`](./sentinel-install.maintenance.md) and run
> its §0 verification protocol. Never edit `sentinel-install.sh` before this spec. Items
> below are the §0 audit checklist; weakening or removing a requirement requires changing
> this file deliberately, not as a side effect of a code edit.

Read this before writing, reviewing, or modifying `sentinel-install.sh`. The install is rootless — everything lives under `$HOME` / XDG dirs, no `sudo` anywhere, ever. Each category below is a standard procedure expected of any production curl-pipe installer; treat a missing item as a defect, not a stylistic choice.

## Platforms
- Supported: **Linux** (`x86_64`, `aarch64`) and **macOS on Apple Silicon** (`aarch64`). Intel Macs are rejected with a clear message (no `x86_64-darwin` artifact is published).
- Asset name: `franklyn-sentinel-<version>-<arch>-<os>-portable.<ext>` with `<os>` = `linux` / `darwin` and `<ext>` = `tar.zst` (Linux) / `tar.gz` (macOS — macOS ships no `zstd`). The Linux name must stay byte-identical to the pre-macOS one.
- One script for both — no separate macOS installer. OS-specific behavior is a branch on the detected OS, never a fork of the file.
- macOS install relies on `curl` **not** setting the `com.apple.quarantine` attribute: the ad-hoc signed artifact never reaches Gatekeeper. Never add a browser-download or `open`-based path.

## Transfer integrity
- Wrap the entire script body in one function, invoked only on the last line — a truncated download then fails at parse time instead of executing partial commands.
- `curl -fsSL` with `--retry`, `--connect-timeout`; any non-2xx response is fatal, never fall through silently.
- Download to a temp file first. Never extract or execute directly from a streaming response.

## Verification
- A `SHA256SUMS` release asset already exists — the release workflow (`release.yaml` job "release") runs `sha256sum *` over every artifact and uploads the result. It is the **primary** verification path: fetch `.../releases/download/{tag}/SHA256SUMS`, confirm it has an entry for the exact asset name, then verify with `sha256sum --ignore-missing --strict --check` from the temp dir.
- Verify the SHA256 digest of every downloaded artifact before extracting it. If `SHA256SUMS` is ever unavailable, the documented fallback is the GitHub Releases API (`/repos/.../releases/tags/{ver}`, `.assets[].digest`) compared with `sha256sum`.
- Fail closed: if `SHA256SUMS` is missing, has no entry for the asset, or the digest mismatches, abort. Never degrade to "install anyway."
- macOS 15 ships a GNU-compatible `/sbin/sha256sum`, older macOS has none. When `sha256sum` is absent, verify with the OS-provided `shasum -a 256 -c` against a file holding **only our asset's line** (so no `--ignore-missing` is needed). The exact-entry guard runs first either way.

## Atomic, recoverable installs
- Extract into a staging directory adjacent to the final install location — never directly into it.
- Validate staged contents (binary present, executable, correct arch) before touching anything live.
- Move into place with a single atomic `mv`, not a multi-file copy loop. The rename must never move *into* an existing directory or follow a symlink: GNU `mv -T`; on macOS (BSD `mv`, no `-T`) `mv -h` after refusing a real directory at the destination.
- On startup, detect leftover staging directories from a prior interrupted run and clean up or resume rather than ignoring them.
- Keep the previous version recoverable (versioned dir or `.bak`) until the new one is confirmed working.

## Idempotency
- Re-running the installer must converge to the same end state, not duplicate it.
- Check for existing/identical content before writing desktop entries, icon files, or PATH exports again.
- Manage `PATH` via one sourced env snippet, written once and checked for an existing `source` line in shell rc files — never blind-append a raw `export PATH=...` on every run.
- macOS: zsh is the default shell and does not read `.profile`, and a fresh Mac has no `~/.zshrc` — create `~/.zshrc` if missing so `PATH` actually works.
- Desktop entries and icons are Linux-only (XDG menus). On macOS the install is CLI-only: write no `.desktop` file and no icons.

## Self-update & rollback
- Download and fully verify the new version before removing or overwriting the currently installed one.
- Never delete the current binary before the replacement is in place and confirmed runnable (e.g. a `--version` smoke test).
- Detect if the install came from a different channel (system package manager, etc.) and defer to that channel instead of self-updating over it.

## Non-interactivity
- Assume stdin is the piped script itself, not a terminal. Never `read` from stdin for a prompt.
- All required input comes from env vars or flags, with safe non-interactive defaults.
- If a prompt is unavoidable, read explicitly from `/dev/tty`, and check `[ -t 0 ]` to skip gracefully when there's no TTY (CI, containers).

## Concurrency
- Guard install/update against overlapping runs with `flock` on a lock file (kernel releases it automatically on crash) — not a plain `[ -f lockfile ]` check, which has a race window.
- macOS has no `flock(1)`: take the same kernel lock with perl's `flock()` on the inherited lock FD (perl ships with macOS). Only if neither exists, warn and proceed unguarded.
- Open the lock on a fixed FD (`9`) — macOS `/bin/bash` 3.2 has no `exec {var}>` FD allocation.

## Rootless constraints
- Never assume, request, or shell out to `sudo`.
- All paths live under `$HOME` / XDG dirs (`~/.local/bin`, `~/.local/share/...`). Fail immediately and clearly if `$HOME` itself isn't writable.
- Normalize `uname -m` / `uname -s` variants (`aarch64` vs `arm64`, `x86_64` vs `amd64`) — never rely on a single string match.
- On macOS, detect Apple Silicon with `sysctl -n hw.optional.arm64` — a shell running under Rosetta reports `uname -m` = `x86_64` on an arm64 Mac.

## Preflight host requirements
- Before downloading, verify the host can actually run the installed (portable) binary. Requirements are derived from `sentinel/resources/README.portable.txt` (Linux, canonical), `sentinel/packaging/osx/README.portable.txt` (macOS, canonical) and `sentinel/Cargo.toml`; re-derive only if the artifact changes.
- **glibc ≥ 2.34 (required, Linux only).** The portable tarball bundles the app's own libraries (`lib/`, RUNPATH `$ORIGIN/../lib`) but still loads through the **host's** `ld-linux` + glibc, so an older glibc cannot run it. Detect via `getconf GNU_LIBC_VERSION`, fall back to `ldd --version`. If the host glibc is **detectably** older than 2.34, abort **before download** with exit code `66` and host guidance. If the version is undetectable (e.g. musl, no `getconf`/`ldd`), warn and continue — the `--version` smoke test remains the authoritative runnability gate.
- **GStreamer is bundled** in the portable tree (`lib/`, `GSTREAMER_LICENSE`) and is therefore **not** a host requirement — do not check for a system GStreamer. (Only the non-portable `dist`/deb/rpm variants depend on system GStreamer; this installer never ships those.)
- **PipeWire (conditional, advisory, Linux only).** Needed only for Wayland screen capture (`ashpd` screencast portal); X11 sessions need nothing extra. If the session is Wayland (`XDG_SESSION_TYPE=wayland` or `WAYLAND_DISPLAY` set) and PipeWire is absent, warn — never fail.
- **macOS ≥ 14.0 (required, macOS only).** The build's deployment target (`MACOSX_DEPLOYMENT_TARGET` in `sentinel/packaging/osx/build.sh`). Detect via `sw_vers -productVersion`; if detectably older, abort **before download** with exit code `66`; if undetectable, warn and continue. No glibc or PipeWire check on macOS. The Screen Recording permission is granted at runtime by the user (to their terminal app) — the installer does not check or request it.
- Provide a non-interactive override: `--skip-checks` / `FRANKLYN_SENTINEL_SKIP_CHECKS` skips all preflight checks (escape hatch for a false negative). Checks run on install and update only, never on uninstall, and never exec the binary (no-exec — fully testable locally).

## Desktop entry
- The rendered `.desktop` entry must pass `desktop-file-validate` for every app version, including dev versions.
- `Version` is the Desktop Entry Specification version the file conforms to (`1.0`), **never** the app version — app versions such as `0.10.0` or `0.9.7+dev.1` are rejected there as "not a known version".
- Keep it in sync with the repo template `sentinel/resources/franklyn-sentinel.desktop` (the only placeholder is `@BINARY_PATH@`).

## Uninstall
- Ship a way to reverse the install (flag or separate script).
- Track a manifest of every path the installer wrote, so uninstall removes exactly that — not a guessed glob.

## Baseline shell hygiene
- `set -euo pipefail`; quote every variable expansion.
- Stay compatible with **bash 3.2** (`/bin/bash` on macOS, which `curl | bash` runs): no `exec {var}>`, `mapfile`/`readarray`, associative arrays, `${x,,}`/`${x^^}`, `[[ -v ]]`, `&>>`; never expand a possibly-empty array under `set -u` without a guard (bash < 4.4 treats it as unbound).
- Use only tools present on both GNU/Linux and stock macOS, or branch explicitly (e.g. `sha256sum`/`shasum`, `mv -T`/`mv -h`, `flock`/perl). No GNU-only flags on the macOS path.
- Messages must render the same under bash 3.2: no backslash-escaped replacements in `${var/pattern/repl}` (bash 3.2 keeps the backslash), e.g. print `~` paths as `"~${path#"$HOME"}"`.
- `trap` cleanup of temp dirs and lock file descriptors on `EXIT` / `INT` / `TERM`.
- Every failure path exits with a meaningful non-zero code — no silent fallthrough.
