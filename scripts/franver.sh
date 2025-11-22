#!/usr/bin/env bash

# ==============================================================================
# Version Manager for CI (Strict Mode)
# ==============================================================================
# Usage: ./version_manager.sh [stable|beta|alpha|twilight]
#
# Generates a version string based on a base VERSION file and git tags.
# Fails validation if inputs are malformed or if the resulting tag exists.
# ==============================================================================

set -e

# --- Helper Functions ---
fail() {
    echo "ERROR: $1" >&2
    exit 1
}

# --- 1. Environment & Pre-requisite Checks ---
command -v git >/dev/null 2>&1 || fail "Git is not installed."
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Not inside a git repository."

# --- 2. Input Validation ---
CHANNEL="${1:-twilight}"
VALID_CHANNELS="stable beta alpha twilight"

# shellcheck disable=SC2076
if [[ ! " $VALID_CHANNELS " =~ " $CHANNEL " ]]; then
    fail "Invalid channel '$CHANNEL'. Allowed: $VALID_CHANNELS"
fi

# --- 3. VERSION File Validation ---
if [ ! -f "VERSION" ]; then
    fail "VERSION file is missing. Please create one with format YYYY.MM.BUILD"
fi

BASE_VER=$(cat VERSION | xargs)

# Strict Regex: 4 digits . 1-2 digits . 1+ digits (e.g., 2025.11.2)
if [[ ! "$BASE_VER" =~ ^[0-9]{4}\.[0-9]{1,2}\.[0-9]+$ ]]; then
    fail "VERSION file content '$BASE_VER' is invalid. Required format: YYYY.MM.BUILD (e.g., 2025.11.2)"
fi

echo "Detailed Info:" >&2
echo "  Channel: $CHANNEL" >&2
echo "  Base:    $BASE_VER" >&2

# --- 4. Logic & Tag Analysis ---
FINAL_VERSION=""

# Check if we have tags (warn if shallow fetch might hide tags)
if [ -z "$(git tag)" ]; then
    echo "Warning: No git tags found. Ensure repo is not shallow-fetched (git fetch --tags)." >&2
fi

case "$CHANNEL" in
    stable)
        FINAL_VERSION="${BASE_VER}"
        ;;

    beta)
        FINAL_VERSION="${BASE_VER}-beta"
        ;;

    alpha)
        FINAL_VERSION="${BASE_VER}-alpha"
        ;;

    twilight)
        PREFIX="${BASE_VER}-twilight"

        # Find highest existing counter for this base
        LAST_TWILIGHT_NUM=$(git tag -l "${PREFIX}.*" | \
            sed -nE "s/^.*-twilight\.([0-9]+)$/\1/p" | \
            sort -rn | head -n 1)

        if [ -z "$LAST_TWILIGHT_NUM" ]; then
            NEXT_TWILIGHT_NUM=1
        else
            NEXT_TWILIGHT_NUM=$((LAST_TWILIGHT_NUM + 1))
        fi

        FINAL_VERSION="${PREFIX}.${NEXT_TWILIGHT_NUM}"
        ;;
esac

# --- 6. Output ---
echo "----------------------------------------" >&2
echo "Generated Version: $FINAL_VERSION" >&2
echo "----------------------------------------" >&2

echo "$FINAL_VERSION"