# Installer Requirements — sentinel-install.sh (rootless curl | bash)

Read this before writing, reviewing, or modifying `sentinel-install.sh`. The install is rootless — everything lives under `$HOME` / XDG dirs, no `sudo` anywhere, ever. Each category below is a standard procedure expected of any production curl-pipe installer; treat a missing item as a defect, not a stylistic choice.

## Transfer integrity
- Wrap the entire script body in one function, invoked only on the last line — a truncated download then fails at parse time instead of executing partial commands.
- `curl -fsSL` with `--retry`, `--connect-timeout`; any non-2xx response is fatal, never fall through silently.
- Download to a temp file first. Never extract or execute directly from a streaming response.

## Verification
<!-- TODO: publish a SHA256SUMS file as a GitHub release asset so the installer can fetch and verify it directly, instead of having to query the GitHub API JSON for per-asset digests. See release.yaml job "release". -->
- Verify the SHA256 digest of every downloaded artifact before extracting it. Until a dedicated `SHA256SUMS` release asset exists, fetch digests from the GitHub Releases API (`/repos/.../releases/tags/{ver}`, `.assets[].digest`) and compare with `sha256sum`.
- Fail closed: if the digest is missing or mismatched, abort. Never degrade to "install anyway."

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

## Uninstall
- Ship a way to reverse the install (flag or separate script).
- Track a manifest of every path the installer wrote, so uninstall removes exactly that — not a guessed glob.

## Baseline shell hygiene
- `set -euo pipefail`; quote every variable expansion.
- `trap` cleanup of temp dirs and lock file descriptors on `EXIT` / `INT` / `TERM`.
- Every failure path exits with a meaningful non-zero code — no silent fallthrough.