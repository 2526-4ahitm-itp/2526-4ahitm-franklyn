# Installer Requirements — sentinel-install.sh (rootless curl | bash)

> **This file is the contract.** To change installer behavior, edit this spec **first**,
> then follow [`sentinel-install.maintenance.md`](./sentinel-install.maintenance.md) and run
> its §0 verification protocol. Never edit `sentinel-install.sh` before this spec. Items
> below are the §0 audit checklist; weakening or removing a requirement requires changing
> this file deliberately, not as a side effect of a code edit.

Read this before writing, reviewing, or modifying `sentinel-install.sh`. The install is rootless — everything lives under `$HOME` / XDG dirs, no `sudo` anywhere, ever. Each category below is a standard procedure expected of any production curl-pipe installer; treat a missing item as a defect, not a stylistic choice.

## Transfer integrity
- Wrap the entire script body in one function, invoked only on the last line — a truncated download then fails at parse time instead of executing partial commands.
- `curl -fsSL` with `--retry`, `--connect-timeout`; any non-2xx response is fatal, never fall through silently.
- Download to a temp file first. Never extract or execute directly from a streaming response.

## Verification
- A `SHA256SUMS` release asset already exists — the release workflow (`release.yaml` job "release") runs `sha256sum *` over every artifact and uploads the result. It is the **primary** verification path: fetch `.../releases/download/{tag}/SHA256SUMS`, confirm it has an entry for the exact asset name, then verify with `sha256sum --ignore-missing --strict --check` from the temp dir.
- Verify the SHA256 digest of every downloaded artifact before extracting it. If `SHA256SUMS` is ever unavailable, the documented fallback is the GitHub Releases API (`/repos/.../releases/tags/{ver}`, `.assets[].digest`) compared with `sha256sum`.
- Fail closed: if `SHA256SUMS` is missing, has no entry for the asset, or the digest mismatches, abort. Never degrade to "install anyway."

## Atomic, recoverable installs
- Extract into a staging directory adjacent to the final install location — never directly into it.
- Validate staged contents (binary present, executable, correct arch) before touching anything live.
- Move into place with a single atomic `mv`, not a multi-file copy loop.
- On startup, detect leftover staging directories from a prior interrupted run and clean up or resume rather than ignoring them.
- Keep the previous version recoverable (versioned dir or `.bak`) until the new one is confirmed working.

## Idempotency
- Re-running the installer must converge to the same end state, not duplicate it.
- Check for existing/identical content before writing desktop entries, icon files, or PATH exports again.
- Manage `PATH` via one sourced env snippet, written once and checked for an existing `source` line in shell rc files — never blind-append a raw `export PATH=...` on every run.

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

## Rootless constraints
- Never assume, request, or shell out to `sudo`.
- All paths live under `$HOME` / XDG dirs (`~/.local/bin`, `~/.local/share/...`). Fail immediately and clearly if `$HOME` itself isn't writable.
- Normalize `uname -m` / `uname -s` variants (`aarch64` vs `arm64`, `x86_64` vs `amd64`) — never rely on a single string match.

## Preflight host requirements
- Before downloading, verify the host can actually run the installed (portable) binary. Requirements are derived from `sentinel/resources/README.portable.txt` (canonical) and `sentinel/Cargo.toml`; re-derive only if the artifact changes.
- **glibc ≥ 2.34 (required).** The portable tarball bundles the app's own libraries (`lib/`, RUNPATH `$ORIGIN/../lib`) but still loads through the **host's** `ld-linux` + glibc, so an older glibc cannot run it. Detect via `getconf GNU_LIBC_VERSION`, fall back to `ldd --version`. If the host glibc is **detectably** older than 2.34, abort **before download** with exit code `66` and host guidance. If the version is undetectable (e.g. musl, no `getconf`/`ldd`), warn and continue — the `--version` smoke test remains the authoritative runnability gate.
- **GStreamer is bundled** in the portable tree (`lib/`, `GSTREAMER_LICENSE`) and is therefore **not** a host requirement — do not check for a system GStreamer. (Only the non-portable `dist`/deb/rpm variants depend on system GStreamer; this installer never ships those.)
- **PipeWire (conditional, advisory).** Needed only for Wayland screen capture (`ashpd` screencast portal); X11 sessions need nothing extra. If the session is Wayland (`XDG_SESSION_TYPE=wayland` or `WAYLAND_DISPLAY` set) and PipeWire is absent, warn — never fail.
- Provide a non-interactive override: `--skip-checks` / `FRANKLYN_SENTINEL_SKIP_CHECKS` skips all preflight checks (escape hatch for a false negative). Checks run on install and update only, never on uninstall, and never exec the binary (no-exec — fully testable locally).

## Uninstall
- Ship a way to reverse the install (flag or separate script).
- Track a manifest of every path the installer wrote, so uninstall removes exactly that — not a guessed glob.

## Baseline shell hygiene
- `set -euo pipefail`; quote every variable expansion.
- `trap` cleanup of temp dirs and lock file descriptors on `EXIT` / `INT` / `TERM`.
- Every failure path exits with a meaningful non-zero code — no silent fallthrough.