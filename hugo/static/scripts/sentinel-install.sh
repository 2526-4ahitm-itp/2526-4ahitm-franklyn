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
# shellcheck disable=SC2034  # consumed in Phase 4 (desktop integration).
readonly DESKTOP_DIR="$XDG_DATA_HOME/applications"
# shellcheck disable=SC2034  # consumed in Phase 4 (icon integration).
readonly ICON_BASE_DIR="$XDG_DATA_HOME/icons/hicolor"

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
# Real temp-dir and lock-FD handling is wired in during later phases. This stub
# establishes the trap surface now so subsequent phases only fill in the body.
# ----------------------------------------------------------------------------

# Mutable list of paths to remove on exit (populated in Phase 2+).
_CLEANUP_PATHS=()

cleanup() {
    local path
    for path in "${_CLEANUP_PATHS[@]:-}"; do
        [ -n "$path" ] && rm -rf "$path" 2>/dev/null || true
    done
}

trap cleanup EXIT INT TERM

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
# A sandboxed --version smoke test is deliberately left to Phase 5 (the binary
# is a GUI client; a static arch check is the safe, offline guard here).
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
    say "installing version $VERSION..."
    install_staged "$STAGING_DIR"
    say "installed $BIN_NAME $VERSION -> $INSTALL_DATA_DIR/current/$ASSET_BIN_REL"
}

# ----------------------------------------------------------------------------
# main
#
# Parse input, detect platform, resolve the target release/asset, download and
# verify it, then extract/validate/atomically install it. Later phases add PATH
# and desktop integration, concurrency, self-update, and uninstall.
# ----------------------------------------------------------------------------

main() {
    need_cmd uname

    parse_args "$@"
    check_home
    get_architecture

    case "$ACTION" in
        uninstall)
            err "--uninstall is not implemented yet (Phase 6)" 64
            ;;
        update)
            say "update mode selected (verified self-update lands in Phase 5)"
            ;;
    esac

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

    say "done. run '$BIN_NAME' (ensure ${OPT_INSTALL_DIR:-$XDG_BIN_HOME} is on PATH — Phase 4)"
}

main "$@"
