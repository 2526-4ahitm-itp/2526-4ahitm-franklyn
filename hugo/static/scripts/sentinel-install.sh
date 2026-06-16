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
readonly XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
readonly XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Derived install locations (all under $HOME).
readonly INSTALL_DATA_DIR="$XDG_DATA_HOME/$APP_NAME"
# shellcheck disable=SC2034  # consumed in Phase 4 (desktop integration).
readonly DESKTOP_DIR="$XDG_DATA_HOME/applications"
# shellcheck disable=SC2034  # consumed in Phase 4 (icon integration).
readonly ICON_BASE_DIR="$XDG_DATA_HOME/icons/hicolor"

# Network tuning for curl.
# shellcheck disable=SC2034  # consumed by the download wrapper in Phase 2.
readonly CURL_CONNECT_TIMEOUT=10
# shellcheck disable=SC2034  # consumed by the download wrapper in Phase 2.
readonly CURL_RETRY=3

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
# main
#
# Currently a banner stub. Phases 1+ add platform detection, download,
# verification, staging, install, integration, self-update, and uninstall.
# ----------------------------------------------------------------------------

main() {
    need_cmd uname

    say "Franklyn Sentinel installer (skeleton — phase 0)"
    say "repo: $REPO"
    say "variant: $DEFAULT_VARIANT"
    say "install dir: $INSTALL_DATA_DIR"
}

main "$@"
