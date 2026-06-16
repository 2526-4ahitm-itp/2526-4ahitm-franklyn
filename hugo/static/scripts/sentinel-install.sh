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
# main
#
# Phase 1: parse input, detect platform, resolve the target release/asset.
# Later phases add download, verification, staging, install, integration,
# self-update, and uninstall.
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
}

main "$@"
