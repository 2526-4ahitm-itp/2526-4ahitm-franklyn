#!/usr/bin/env bash
# sentinel-install.sh — rootless installer for Franklyn Sentinel.
#
# Designed to be run via:   curl -fsSL <url>/sentinel-install.sh | bash
#
# The entire body lives inside main(), invoked only on the last line, so a
# truncated download fails at parse time instead of executing partial commands.
# Everything installs under $HOME / XDG dirs — no sudo, ever.
#
# Requirements contract: hugo/static/scripts/sentinel-install.md
# Build plan:            hugo/static/scripts/sentinel-install.plan.md
#
# Bash is required (this script uses bashisms: pipefail, [[ ]], arrays, local).

set -euo pipefail

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------

# GitHub repository that hosts the Sentinel releases.
readonly REPO="2526-4ahitm-itp/2526-4ahitm-franklyn"

# Human-facing name of the application.
readonly APP_NAME="franklyn-sentinel"

# Default release artifact variant. "portable" is fully self-contained and the
# correct choice for a rootless install; "dist" carries system dependencies.
readonly DEFAULT_VARIANT="portable"

# XDG base directories, resolved from the environment with documented defaults.
# $HOME is expanded with a `:-` guard so an unset $HOME does not trip `set -u`
# here; check_home() reports the missing/unwritable $HOME with a clear message.
readonly XDG_BIN_HOME="${XDG_BIN_HOME:-${HOME:-}/.local/bin}"
readonly XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME:-}/.local/share}"
readonly XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME:-}/.config}"

# Command name exposed on PATH. The portable tarball ships the binary as
# 'bin/franklyn', and the system packages (deb/AUR/openSUSE) all install it as
# '/usr/bin/franklyn' — keep the same name so `command -v franklyn` is stable
# across install channels (Phase 5 channel detection relies on this).
readonly BIN_NAME="franklyn"
# Path of the binary inside the extracted portable tree.
readonly ASSET_BIN_REL="bin/$BIN_NAME"

# Derived install locations (all under $HOME).
readonly INSTALL_DATA_DIR="$XDG_DATA_HOME/$APP_NAME"
readonly DESKTOP_DIR="$XDG_DATA_HOME/applications"
readonly ICON_BASE_DIR="$XDG_DATA_HOME/icons/hicolor"

# Sourced env snippet (prepends the bin dir to PATH) and the install manifest
# (every path the installer creates — the exact set Phase 6 uninstall removes).
readonly ENV_FILE="$INSTALL_DATA_DIR/env"
readonly MANIFEST_FILE="$INSTALL_DATA_DIR/install-manifest.txt"

# Concurrency lock. A single FD-based flock around the install/update mutation
# serializes overlapping runs; the kernel releases it automatically on crash.
readonly LOCK_FILE="$INSTALL_DATA_DIR/.lock"

# Network tuning for curl.
readonly CURL_CONNECT_TIMEOUT=10
readonly CURL_RETRY=3

# ----------------------------------------------------------------------------
# Mutable run state (set by parse_args / platform detection)
# ----------------------------------------------------------------------------

# What the invocation should do: install | update | uninstall.
ACTION="install"
# Explicit version request (flag or env); empty => resolve latest release.
OPT_VERSION="${FRANKLYN_SENTINEL_VERSION:-}"
# Optional binary-dir override; empty => XDG_BIN_HOME. Consumed in Phase 3/4.
OPT_INSTALL_DIR=""
# Normalized asset arch token: x86_64 | aarch64.
ARCH=""
# Resolved version token (no leading 'v') and matching git tag (with 'v').
VERSION=""
RELEASE_TAG=""
# Resolved release asset name and download URL.
ASSET_NAME=""
ASSET_URL=""
# Per-run temp working dir (mktemp -d) and the verified artifact inside it.
# WORK_DIR is registered with the cleanup trap; ASSET_PATH is the verified
# tarball consumed by the extraction step.
WORK_DIR=""
ASSET_PATH=""
# Staging dir (adjacent to the versioned install) and the versioned dir the
# staged tree is published to. STAGING_DIR is registered with the cleanup trap.
STAGING_DIR=""
VERSION_DIR=""
# Open file descriptor holding the concurrency lock (empty until acquired).
LOCK_FD=""

# ----------------------------------------------------------------------------
# Output helpers (ported from rustup / Homebrew install conventions)
# ----------------------------------------------------------------------------

# Detect whether stderr is a terminal so we only emit color when it helps.
if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
    readonly TTY_BOLD=$'\033[1m'
    readonly TTY_RED=$'\033[31m'
    readonly TTY_YELLOW=$'\033[33m'
    readonly TTY_BLUE=$'\033[34m'
    readonly TTY_RESET=$'\033[0m'
else
    readonly TTY_BOLD=""
    readonly TTY_RED=""
    readonly TTY_YELLOW=""
    readonly TTY_BLUE=""
    readonly TTY_RESET=""
fi

# say MESSAGE — informational progress line on stderr.
say() {
    printf '%s%s:%s %s\n' "$TTY_BLUE" "$APP_NAME" "$TTY_RESET" "$1" >&2
}

# warn MESSAGE — non-fatal warning on stderr.
warn() {
    printf '%s%swarning:%s %s\n' "$TTY_BOLD" "$TTY_YELLOW" "$TTY_RESET" "$1" >&2
}

# err MESSAGE [CODE] — fatal error; prints to stderr and exits non-zero.
err() {
    printf '%s%serror:%s %s\n' "$TTY_BOLD" "$TTY_RED" "$TTY_RESET" "$1" >&2
    exit "${2:-1}"
}

# need_cmd CMD — abort if CMD is not on PATH.
need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        err "required command not found: '$1'"
    fi
}

# check_cmd CMD — true/false test for an optional command, no abort.
check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# ensure CMD... — run a command, aborting with its description on failure.
ensure() {
    if ! "$@"; then
        err "command failed: $*"
    fi
}

# ignore CMD... — run a command, swallowing any failure.
ignore() {
    "$@" || true
}

# ----------------------------------------------------------------------------
# Cleanup / trap handling
#
# Removes per-run temp/staging dirs and releases the concurrency lock FD on
# EXIT / INT / TERM. The kernel would release the flock on process death anyway;
# we release it explicitly so the FD does not linger and so the behaviour is
# obvious from the trap surface.
# ----------------------------------------------------------------------------

# Mutable list of paths to remove on exit (populated in Phase 2+).
_CLEANUP_PATHS=()

cleanup() {
    local path
    for path in "${_CLEANUP_PATHS[@]:-}"; do
        [ -n "$path" ] && rm -rf "$path" 2>/dev/null || true
    done
    release_lock
}

trap cleanup EXIT INT TERM

# ----------------------------------------------------------------------------
# Concurrency (flock)
#
# An overlapping install/update could corrupt the staging/publish dance, so we
# serialize them with an advisory lock held on a dedicated FD for the whole run.
# We deliberately do NOT use a `[ -f lockfile ]` check (it has a TOCTOU race and
# leaks a stale lock if the holder is killed). flock ships in util-linux and is
# present on effectively every Linux; if it is somehow missing we warn and
# proceed unguarded rather than refusing to install over a missing tool — the
# only loss is the guard against the rare concurrent-run case.
# ----------------------------------------------------------------------------

# acquire_lock — take the exclusive install lock, blocking (with a notice) if
# another run holds it. Stores the open FD in LOCK_FD for release_lock/cleanup.
acquire_lock() {
    ensure mkdir -p "$INSTALL_DATA_DIR"
    if ! check_cmd flock; then
        warn "flock not found; proceeding without a concurrency guard (do not run two installs at once)"
        return 0
    fi
    # Open the lock file on a fresh FD chosen by bash and held open until exit.
    exec {LOCK_FD}>"$LOCK_FILE" \
        || err "could not open lock file '$LOCK_FILE'"
    if ! flock -n "$LOCK_FD"; then
        say "another $APP_NAME install/update is in progress; waiting for it to finish..."
        flock "$LOCK_FD" || err "failed to acquire the install lock '$LOCK_FILE'"
    fi
}

# release_lock — drop the lock and close its FD. Safe to call when unlocked.
release_lock() {
    [ -n "${LOCK_FD:-}" ] || return 0
    flock -u "$LOCK_FD" 2>/dev/null || true
    # Close the variable FD (eval keeps this portable across bash versions).
    eval "exec ${LOCK_FD}>&-" 2>/dev/null || true
    LOCK_FD=""
}

# ----------------------------------------------------------------------------
# Input handling (non-interactive: flags + env only, never stdin)
# ----------------------------------------------------------------------------

usage() {
    cat <<EOF
$APP_NAME installer — rootless installation for Franklyn Sentinel.

USAGE:
    curl -fsSL <url>/sentinel-install.sh | bash -s -- [OPTIONS]

OPTIONS:
    --version <VER>      Install a specific release (with or without leading 'v').
    --update             Update an existing installation to the latest release.
    --uninstall          Remove a previous installation.
    --install-dir <DIR>  Override the binary install directory
                         (default: $XDG_BIN_HOME).
    -h, --help           Show this help and exit.

ENVIRONMENT:
    FRANKLYN_SENTINEL_VERSION    Same as --version.
    XDG_BIN_HOME / XDG_DATA_HOME / XDG_CONFIG_HOME    Standard XDG overrides.
    NO_COLOR                     Disable colored output.

All input is taken from flags and environment variables; the installer never
reads from stdin, since stdin is the piped script itself.
EOF
}

# parse_args ARG... — populate ACTION / OPT_VERSION / OPT_INSTALL_DIR.
parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h | --help)
                usage
                exit 0
                ;;
            --update)
                ACTION="update"
                ;;
            --uninstall)
                ACTION="uninstall"
                ;;
            --version)
                [ "$#" -ge 2 ] || err "--version requires an argument"
                OPT_VERSION="$2"
                shift
                ;;
            --version=*)
                OPT_VERSION="${1#*=}"
                ;;
            --install-dir)
                [ "$#" -ge 2 ] || err "--install-dir requires an argument"
                OPT_INSTALL_DIR="$2"
                shift
                ;;
            --install-dir=*)
                OPT_INSTALL_DIR="${1#*=}"
                ;;
            *)
                err "unknown option: '$1' (try --help)"
                ;;
        esac
        shift
    done
}

# check_home — abort unless $HOME is set, a directory, and writable.
check_home() {
    [ -n "${HOME:-}" ] || err "\$HOME is not set; cannot determine a rootless install location"
    [ -d "$HOME" ] || err "\$HOME ('$HOME') is not a directory"
    [ -w "$HOME" ] || err "\$HOME ('$HOME') is not writable; this installer never uses sudo"
}

# ----------------------------------------------------------------------------
# Platform detection
# ----------------------------------------------------------------------------

# get_architecture — set ARCH to the asset arch token, or abort.
get_architecture() {
    local ostype machine
    ostype="$(uname -s)"
    machine="$(uname -m)"

    if [ "$ostype" != "Linux" ]; then
        err "unsupported operating system: '$ostype' (this installer supports Linux only)"
    fi

    case "$machine" in
        x86_64 | amd64) ARCH="x86_64" ;;
        aarch64 | arm64) ARCH="aarch64" ;;
        *) err "unsupported architecture: '$machine' (supported: x86_64, aarch64)" ;;
    esac
}

# ----------------------------------------------------------------------------
# Version & asset resolution
# ----------------------------------------------------------------------------

# fetch_latest_tag — print the tag_name of the latest non-prerelease release.
# (Dev builds are GitHub prereleases, so /releases/latest yields the newest
# stable tag, which is the right default.)
fetch_latest_tag() {
    local api_url json
    api_url="https://api.github.com/repos/$REPO/releases/latest"
    # Capture the full response first, then parse with a bash regex. Piping
    # curl into a short-circuiting filter (grep -m1) closes the pipe early,
    # which makes curl fail with code 23 under `set -o pipefail`.
    json="$(curl -fsSL --connect-timeout "$CURL_CONNECT_TIMEOUT" --retry "$CURL_RETRY" "$api_url")" || return 1
    [[ "$json" =~ \"tag_name\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]] || return 1
    printf '%s\n' "${BASH_REMATCH[1]}"
}

# resolve_version — set VERSION (token, no 'v') and RELEASE_TAG (with 'v').
resolve_version() {
    local raw
    if [ -n "$OPT_VERSION" ]; then
        raw="$OPT_VERSION"
    else
        say "resolving latest release..."
        need_cmd curl
        raw="$(fetch_latest_tag)" || raw=""
        [ -n "$raw" ] || err "could not determine the latest release version from the GitHub API"
    fi

    VERSION="${raw#v}"
    [ -n "$VERSION" ] || err "empty version requested"
    RELEASE_TAG="v$VERSION"
}

# build_asset_url — set ASSET_NAME / ASSET_URL for the portable Linux artifact.
build_asset_url() {
    ASSET_NAME="$APP_NAME-$VERSION-$ARCH-linux-$DEFAULT_VARIANT.tar.zst"
    ASSET_URL="https://github.com/$REPO/releases/download/$RELEASE_TAG/$ASSET_NAME"
}

# ----------------------------------------------------------------------------
# Download & checksum verification
# ----------------------------------------------------------------------------

# download URL DEST — fetch URL to file DEST. Returns non-zero on any transfer
# error or non-2xx response (curl -f). Writes to a file with -o, so there is no
# pipe to short-circuit (unlike fetch_latest_tag).
download() {
    local url="$1" dest="$2"
    curl -fsSL \
        --connect-timeout "$CURL_CONNECT_TIMEOUT" \
        --retry "$CURL_RETRY" \
        -o "$dest" \
        "$url"
}

# verify_checksum DIR ASSET — confirm DIR/ASSET matches its checksums.txt entry.
# Fails closed: a missing file, a missing entry for ASSET, or a hash mismatch
# all abort. Never degrades to "install anyway."
verify_checksum() {
    local dir="$1" asset="$2"
    [ -f "$dir/checksums.txt" ] \
        || err "checksums.txt is missing; cannot verify download integrity"
    [ -f "$dir/$asset" ] \
        || err "downloaded asset '$asset' is missing; cannot verify integrity"

    # checksums.txt is produced by 'sha256sum *' over every release artifact, so
    # it lists assets we did not download. '--ignore-missing' skips those — but
    # it would also silently pass if OUR asset has no line at all. Require an
    # exact entry first, then let sha256sum verify the present file.
    awk -v f="$asset" '$2 == f { found = 1 } END { exit(found ? 0 : 1) }' \
        "$dir/checksums.txt" \
        || err "no checksum entry for '$asset' in checksums.txt; refusing to install an unverified artifact"

    ( cd "$dir" && sha256sum --ignore-missing --strict --check checksums.txt ) \
        >/dev/null 2>&1 \
        || err "checksum verification failed for '$asset'; the download is corrupt or has been tampered with"
}

# download_and_verify — fetch the artifact + checksums.txt into a temp dir and
# verify the artifact before any extraction. Sets WORK_DIR and ASSET_PATH.
download_and_verify() {
    need_cmd curl
    need_cmd sha256sum

    WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/$APP_NAME.XXXXXX")" \
        || err "could not create a temporary working directory"
    _CLEANUP_PATHS+=("$WORK_DIR")

    local checksums_url="https://github.com/$REPO/releases/download/$RELEASE_TAG/checksums.txt"

    say "downloading $ASSET_NAME..."
    download "$ASSET_URL" "$WORK_DIR/$ASSET_NAME" \
        || err "failed to download artifact from $ASSET_URL"

    say "downloading checksums.txt..."
    download "$checksums_url" "$WORK_DIR/checksums.txt" \
        || err "failed to download checksums.txt from $checksums_url"

    say "verifying SHA256 checksum..."
    verify_checksum "$WORK_DIR" "$ASSET_NAME"
    say "checksum OK"

    ASSET_PATH="$WORK_DIR/$ASSET_NAME"
}

# ----------------------------------------------------------------------------
# Staging, validation, atomic install, recovery
#
# The portable tarball extracts to a tree rooted at bin/ lib/ libexec/ share/.
# The binary (bin/franklyn) has RUNPATH '$ORIGIN/../lib', so it must stay
# alongside its bundled lib/ — the whole tree is installed as one unit into a
# versioned dir, and a 'current' symlink plus a PATH symlink point through it.
# Nothing is ever written into the live tree directly: we extract into a staging
# dir on the SAME filesystem, validate it, then publish with atomic renames.
# ----------------------------------------------------------------------------

# cleanup_stale_staging — remove leftover .staging-* dirs from a prior run that
# was interrupted before it could publish (or have its trap fire). Safe no-op
# when the data dir does not exist yet. Versioned dirs and *.bak-* are left
# alone: those are real, recoverable installs.
cleanup_stale_staging() {
    [ -d "$INSTALL_DATA_DIR" ] || return 0
    local d
    for d in "$INSTALL_DATA_DIR"/.staging-*; do
        [ -e "$d" ] || continue  # glob did not match anything
        warn "removing leftover staging dir from an interrupted run: $d"
        rm -rf "$d" 2>/dev/null || true
    done
}

# extract_to_staging — extract the verified ASSET_PATH into a fresh staging dir
# adjacent to the versioned install (so the later publish is a same-filesystem
# rename). Sets STAGING_DIR and registers it for trap cleanup.
extract_to_staging() {
    need_cmd zstd
    need_cmd tar

    ensure mkdir -p "$INSTALL_DATA_DIR"
    STAGING_DIR="$(mktemp -d "$INSTALL_DATA_DIR/.staging-XXXXXX")" \
        || err "could not create a staging directory under $INSTALL_DATA_DIR"
    _CLEANUP_PATHS+=("$STAGING_DIR")

    say "extracting into staging..."
    # GNU tar invokes 'zstd -d' for extraction via --use-compress-program, so
    # zstd (not just unzstd) is the dependency. Extract from the file, never
    # from a stream.
    tar --use-compress-program=zstd -C "$STAGING_DIR" -xf "$ASSET_PATH" \
        || err "failed to extract '$ASSET_NAME'"
}

# arch_elf_machine — print the 'readelf -h' Machine substring expected for ARCH.
arch_elf_machine() {
    case "$ARCH" in
        x86_64) printf '%s\n' 'X86-64' ;;
        aarch64) printf '%s\n' 'AArch64' ;;
        *) printf '%s\n' '' ;;
    esac
}

# validate_staged DIR — confirm the staged tree is sane before going live:
# the expected binary is present, executable, and built for the target arch.
# This is a cheap offline pre-check (no exec); the authoritative runnability
# gate is the --version smoke test in smoke_test(), run immediately after.
validate_staged() {
    local dir="$1"
    local bin="$dir/$ASSET_BIN_REL"

    [ -f "$bin" ] \
        || err "staged tree is missing the expected binary '$ASSET_BIN_REL'"
    [ -x "$bin" ] \
        || err "staged binary '$ASSET_BIN_REL' is not executable"

    # Verify the architecture so we never publish, e.g., an aarch64 build onto
    # an x86_64 host. Prefer readelf; fall back to file; warn only if neither
    # tool exists rather than skipping silently.
    if check_cmd readelf; then
        local want
        want="$(arch_elf_machine)"
        readelf -h "$bin" 2>/dev/null | grep -q "Machine:.*$want" \
            || err "staged binary architecture does not match '$ARCH'"
    elif check_cmd file; then
        file "$bin" 2>/dev/null | grep -qi "$ARCH" \
            || err "staged binary architecture does not match '$ARCH'"
    else
        warn "neither readelf nor file is available; skipping arch validation"
    fi
}

# smoke_test BIN — confirm the staged binary actually runs before we publish it,
# so a broken download/extract never replaces a working install. This is the
# authoritative runnability gate (the md's "--version smoke test").
#
# franklyn is a headless CLI: clap handles --version at the very top of main and
# process::exit(0)s immediately, before any tokio/network/screen-capture init —
# so this is fast and side-effect-free. The dynamic loader still maps the whole
# bundled lib graph (RUNPATH '$ORIGIN/../lib') at startup, so a clean exit also
# proves the tree's libraries resolve. A non-zero exit, a timeout, or no output
# means the staged build is not runnable: abort, leaving the live 'current'
# untouched (rollback = do nothing destructive). `timeout` is a safety net
# against a future regression that might not exit promptly.
smoke_test() {
    local bin="$1" out rc=0
    if check_cmd timeout; then
        out="$(timeout 10 "$bin" --version 2>&1)" || rc=$?
    else
        out="$("$bin" --version 2>&1)" || rc=$?
    fi

    if [ "$rc" -ne 0 ]; then
        err "staged binary failed its --version smoke test (exit $rc); not runnable, keeping the existing install:
$out"
    fi
    [ -n "$out" ] \
        || err "staged binary produced no --version output; refusing to publish an unverified build"
    say "staged binary runs: $out"
}

# atomic_symlink TARGET LINK — point LINK at TARGET, replacing any existing
# link in a single atomic step (create a sibling temp symlink, then rename
# over LINK). mv -T renames the symlink itself rather than following it.
atomic_symlink() {
    local target="$1" link="$2"
    local tmp="$link.new.$$"
    rm -f "$tmp" 2>/dev/null || true
    ensure ln -s "$target" "$tmp"
    if ! mv -T "$tmp" "$link"; then
        rm -f "$tmp" 2>/dev/null || true
        err "failed to update symlink '$link'"
    fi
}

# publish_symlinks — flip the 'current' symlink to the new version and point the
# PATH binary symlink through it. 'current' uses a relative target so the data
# dir stays relocatable; the PATH symlink is absolute.
publish_symlinks() {
    local bin_dir="${OPT_INSTALL_DIR:-$XDG_BIN_HOME}"

    atomic_symlink "versions/$VERSION" "$INSTALL_DATA_DIR/current"

    ensure mkdir -p "$bin_dir"
    atomic_symlink "$INSTALL_DATA_DIR/current/$ASSET_BIN_REL" "$bin_dir/$BIN_NAME"
}

# install_staged DIR — publish the validated staging dir as versions/<ver> with
# a single atomic rename, then flip the symlinks. Any existing same-version dir
# is moved aside first and only removed once the new one is in place; on failure
# the previous version is restored. Other versioned dirs are kept for rollback.
install_staged() {
    local staging="$1"
    local versions_dir="$INSTALL_DATA_DIR/versions"
    VERSION_DIR="$versions_dir/$VERSION"
    ensure mkdir -p "$versions_dir"

    # Move any existing install of this exact version aside. We keep the backup
    # until the new tree is in place; a hard kill in the gap leaves a
    # recoverable '.bak-<pid>' rather than destroying the old copy.
    local backup=""
    if [ -e "$VERSION_DIR" ]; then
        backup="$VERSION_DIR.bak-$$"
        ensure mv -T "$VERSION_DIR" "$backup"
    fi

    # Atomic publish: rename the staging tree (same filesystem) into place.
    if ! mv -T "$staging" "$VERSION_DIR"; then
        [ -n "$backup" ] && mv -T "$backup" "$VERSION_DIR" 2>/dev/null || true
        err "failed to move the staged install into place at '$VERSION_DIR'"
    fi

    publish_symlinks

    # New version is live and linked; the same-version backup is now obsolete.
    [ -n "$backup" ] && rm -rf "$backup" 2>/dev/null || true
}

# install_from_asset — extract, validate, and atomically publish ASSET_PATH.
install_from_asset() {
    extract_to_staging
    say "validating staged binary..."
    validate_staged "$STAGING_DIR"
    say "smoke-testing staged binary..."
    smoke_test "$STAGING_DIR/$ASSET_BIN_REL"
    say "installing version $VERSION..."
    install_staged "$STAGING_DIR"
    say "installed $BIN_NAME $VERSION -> $INSTALL_DATA_DIR/current/$ASSET_BIN_REL"
}

# ----------------------------------------------------------------------------
# PATH, desktop integration, manifest, idempotency
#
# Everything here must converge on re-run: identical files are left untouched,
# rc files gain exactly one source line, and every path written is appended to
# the manifest (deduplicated) so Phase 6 uninstall can remove exactly that set.
# The installer runs standalone via `curl | bash`, so it cannot read the repo's
# sentinel/resources/* — desktop content is rendered inline and icons are taken
# from the bundled share/ tree of the installed version.
# ----------------------------------------------------------------------------

# manifest_add PATH — record PATH in the manifest, once. Safe to call repeatedly.
manifest_add() {
    local path="$1"
    ensure mkdir -p "$INSTALL_DATA_DIR"
    if [ -f "$MANIFEST_FILE" ] && grep -qxF "$path" "$MANIFEST_FILE"; then
        return 0
    fi
    printf '%s\n' "$path" >> "$MANIFEST_FILE" \
        || err "failed to update install manifest '$MANIFEST_FILE'"
}

# write_if_changed DEST CONTENT — write CONTENT (plus a trailing newline) to DEST
# only if DEST is absent or differs. Returns 0 when it wrote, 1 when unchanged,
# so callers can report idempotently. Never aborts on the "unchanged" path.
write_if_changed() {
    local dest="$1" content="$2"
    if [ -f "$dest" ]; then
        local existing
        existing="$(cat "$dest")"
        if [ "$existing" = "$content" ]; then
            return 1
        fi
    fi
    ensure mkdir -p "$(dirname "$dest")"
    printf '%s\n' "$content" > "$dest" || err "failed to write '$dest'"
    return 0
}

# copy_if_changed SRC DEST — copy SRC to DEST only if absent or byte-different.
# Returns 0 when it copied, 1 when already identical.
copy_if_changed() {
    local src="$1" dest="$2"
    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        return 1
    fi
    ensure mkdir -p "$(dirname "$dest")"
    ensure cp "$src" "$dest"
    return 0
}

# record_core_manifest — register the install paths created during the staged
# install (versioned dir, 'current' symlink, PATH symlink) so uninstall is
# complete, not just the Phase-4 integration files.
record_core_manifest() {
    manifest_add "$VERSION_DIR"
    manifest_add "$INSTALL_DATA_DIR/current"
    manifest_add "${OPT_INSTALL_DIR:-$XDG_BIN_HOME}/$BIN_NAME"
}

# env_snippet_content — the POSIX-sh snippet that prepends the bin dir to PATH.
# Guarded so re-sourcing it (or an already-correct PATH) never duplicates the
# entry. Printed, not echoed, so the bin dir is interpolated verbatim.
env_snippet_content() {
    local bin_dir="$1"
    cat <<EOF
#!/bin/sh
# franklyn-sentinel shell setup — prepends the install dir to PATH.
# Generated by the installer; sourced from your shell rc file. Safe to re-source.
case ":\${PATH}:" in
    *:"$bin_dir":*) ;;
    *) export PATH="$bin_dir:\${PATH}" ;;
esac
EOF
}

# add_source_line RC LINE — append LINE to rc file RC unless it is already
# present. Returns 0 when it appended, 1 when the line already existed. The rc
# file is created if missing. We never write a raw 'export PATH=' here — only a
# single 'source' of the env snippet, per the idempotency requirement.
add_source_line() {
    local rc="$1" line="$2"
    if [ -f "$rc" ] && grep -qF "$line" "$rc"; then
        return 1
    fi
    printf '\n# Added by the franklyn-sentinel installer\n%s\n' "$line" >> "$rc" \
        || err "failed to update shell rc file '$rc'"
    return 0
}

# setup_path — write the env snippet once and ensure each relevant shell rc file
# sources it exactly once. The snippet (not the rc files) is what uninstall
# removes; Phase 6 strips the source line from the rc set separately.
setup_path() {
    local bin_dir="${OPT_INSTALL_DIR:-$XDG_BIN_HOME}"

    local content
    content="$(env_snippet_content "$bin_dir")"
    if write_if_changed "$ENV_FILE" "$content"; then
        say "wrote env snippet: $ENV_FILE"
    else
        say "env snippet already up to date"
    fi
    manifest_add "$ENV_FILE"

    # Source the snippet from the user's login/interactive rc files. Only files
    # that already exist are touched, except .profile which we create as the
    # portable login default if no rc file exists at all.
    local src_line=". \"$ENV_FILE\""
    local -a rc_files=()
    local f
    for f in .bashrc .bash_profile .zshrc .profile; do
        [ -f "$HOME/$f" ] && rc_files+=("$HOME/$f")
    done
    [ -f "$HOME/.profile" ] || rc_files+=("$HOME/.profile")

    local rc touched=0
    for rc in "${rc_files[@]}"; do
        if add_source_line "$rc" "$src_line"; then
            say "added PATH setup to ${rc/#$HOME/\~}"
            touched=1
        fi
    done
    if [ "$touched" -eq 0 ]; then
        say "shell rc files already source the env snippet"
    fi
}

# render_desktop EXEC — print the .desktop entry with the app version and Exec
# path substituted. Mirrors sentinel/resources/franklyn-sentinel.desktop (the
# @VERSION@ / @BINARY_PATH@ template) which is not available at runtime.
render_desktop() {
    local exec_path="$1"
    cat <<EOF
[Desktop Entry]
Version=$VERSION
Type=Application
Name=Franklyn Sentinel
GenericName=Screen Monitoring Client
Comment=Streams student screen activity to the teacher during exams
Exec=$exec_path
Icon=$APP_NAME
Categories=Education;Network;
Keywords=exam;monitor;screen;sentinel;franklyn;
Terminal=false
StartupNotify=true
EOF
}

# install_icons — copy the bundled hicolor icons from the installed tree into the
# user icon theme, skipping any that are already identical. Reads from the live
# 'current' tree (staging has already been moved into place by now).
install_icons() {
    local src_base="$INSTALL_DATA_DIR/current/share/icons/hicolor"
    if [ ! -d "$src_base" ]; then
        warn "no bundled icons found under '$src_base'; skipping icon install"
        return 0
    fi

    local src rel dest installed=0
    for src in "$src_base"/*/apps/"$APP_NAME.png"; do
        [ -f "$src" ] || continue          # glob did not match
        rel="${src#"$src_base"/}"          # e.g. 48x48/apps/franklyn-sentinel.png
        dest="$ICON_BASE_DIR/$rel"
        if copy_if_changed "$src" "$dest"; then
            installed=1
        fi
        manifest_add "$dest"
    done
    if [ "$installed" -eq 1 ]; then
        say "installed application icons"
    else
        say "application icons already up to date"
    fi

    # Refresh the icon cache if the tooling is present; harmless if it is not.
    if check_cmd gtk-update-icon-cache; then
        ignore gtk-update-icon-cache -q -t "$XDG_DATA_HOME/icons/hicolor"
    fi
}

# integrate_desktop — render and install the desktop entry (idempotently) and
# the application icons, recording both in the manifest. Exec points at the
# absolute 'current/bin/franklyn' so the launcher works regardless of whether
# the bin dir is on the desktop session's PATH.
integrate_desktop() {
    local exec_path="$INSTALL_DATA_DIR/current/$ASSET_BIN_REL"
    local dest="$DESKTOP_DIR/$APP_NAME.desktop"

    local content
    content="$(render_desktop "$exec_path")"
    if write_if_changed "$dest" "$content"; then
        say "wrote desktop entry: $dest"
    else
        say "desktop entry already up to date"
    fi
    manifest_add "$dest"

    if check_cmd update-desktop-database; then
        ignore update-desktop-database "$DESKTOP_DIR"
    fi

    install_icons
}

# ----------------------------------------------------------------------------
# Channel detection
#
# The deb/AUR/openSUSE packages install the SAME command name ('franklyn') at
# '/usr/bin/franklyn'. We must never self-update over a system-package install:
# resolve the command, decide whether it is ours, and if not ask the system
# package managers who owns it. Prints a human channel label when the binary is
# system-managed, nothing when it is ours / unmanaged / absent.
# ----------------------------------------------------------------------------

detect_system_channel() {
    local resolved
    resolved="$(command -v "$BIN_NAME" 2>/dev/null)" || return 0
    [ -n "$resolved" ] || return 0

    # Canonicalize through our own PATH symlink before judging ownership.
    local real
    real="$(readlink -f "$resolved" 2>/dev/null || printf '%s' "$resolved")"

    # Anything pointing into our rootless tree (or our own bin symlink) is ours.
    case "$real" in
        "$INSTALL_DATA_DIR"/*) return 0 ;;
    esac
    case "$resolved" in
        "$INSTALL_DATA_DIR"/* | "${OPT_INSTALL_DIR:-$XDG_BIN_HOME}/$BIN_NAME") return 0 ;;
    esac

    # Not ours — ask each available system package manager who owns the path.
    if check_cmd dpkg && dpkg -S "$real" >/dev/null 2>&1; then
        printf 'the system package manager (dpkg/apt) at %s\n' "$real"
        return 0
    fi
    if check_cmd rpm && rpm -qf "$real" >/dev/null 2>&1; then
        printf 'the system package manager (rpm) at %s\n' "$real"
        return 0
    fi
    if check_cmd pacman && pacman -Qo "$real" >/dev/null 2>&1; then
        printf 'the system package manager (pacman) at %s\n' "$real"
        return 0
    fi
    return 0
}

# ----------------------------------------------------------------------------
# main
#
# Parse input, detect platform, resolve the target release/asset, download and
# verify it, then extract/validate/atomically install it, and finally wire up
# PATH, the desktop entry, icons, and the uninstall manifest. Later phases add
# concurrency, self-update, and uninstall.
# ----------------------------------------------------------------------------

main() {
    need_cmd uname

    parse_args "$@"
    check_home
    get_architecture

    if [ "$ACTION" = "uninstall" ]; then
        err "--uninstall is not implemented yet (Phase 6)" 64
    fi

    # Serialize all install/update mutations before touching anything on disk.
    acquire_lock

    # Channel deference: never self-update over a system-package install. On
    # update this is fatal (point the user at their package manager); on a fresh
    # install we only warn, since our rootless copy lives in its own dir and
    # merely shadows the system one on PATH.
    local sys_channel
    sys_channel="$(detect_system_channel)"
    if [ -n "$sys_channel" ]; then
        if [ "$ACTION" = "update" ]; then
            err "$BIN_NAME is managed by $sys_channel; update it through that channel, not this installer" 65
        fi
        warn "$BIN_NAME is also managed by $sys_channel; this rootless install will shadow it on PATH"
    fi

    if [ "$ACTION" = "update" ]; then
        say "updating $BIN_NAME (the running install is replaced only after the new version is staged, verified, and smoke-tested)"
    fi

    resolve_version
    build_asset_url

    say "Franklyn Sentinel installer"
    say "  platform:  linux-$ARCH"
    say "  version:   $VERSION (tag $RELEASE_TAG)"
    say "  variant:   $DEFAULT_VARIANT"
    say "  asset:     $ASSET_NAME"
    say "  download:  $ASSET_URL"
    say "  bin dir:   ${OPT_INSTALL_DIR:-$XDG_BIN_HOME}"
    say "  data dir:  $INSTALL_DATA_DIR"

    cleanup_stale_staging
    download_and_verify
    install_from_asset

    record_core_manifest
    setup_path
    integrate_desktop

    local bin_dir="${OPT_INSTALL_DIR:-$XDG_BIN_HOME}"
    say "done. installed $BIN_NAME $VERSION"
    case ":${PATH}:" in
        *:"$bin_dir":*)
            say "run '$BIN_NAME' to start (it is already on your PATH)"
            ;;
        *)
            say "run '$BIN_NAME' after restarting your shell, or source it now:"
            say "  . \"$ENV_FILE\""
            ;;
    esac
}

main "$@"
