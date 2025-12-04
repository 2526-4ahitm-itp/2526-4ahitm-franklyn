#!/usr/bin/env bash

# Exit on error, strict pipe handling
set -e
set -o pipefail

# -----------------------------------------------------------------------------
# HELPER: Log to stderr (so we don't pollute stdout for the CI reader)
# -----------------------------------------------------------------------------
log() {
    echo "[VERSION-CALC] $1" >&2
}

# -----------------------------------------------------------------------------
# VALIDATION: Check arguments
# -----------------------------------------------------------------------------
if [ -z "$1" ]; then
    log "Error: Missing argument. Usage: $0 [major|minor|hotfix|dev]"
    exit 1
fi

BUMP_TYPE=$1
VALID_TYPES="major minor hotfix dev"
if [[ ! " $VALID_TYPES " =~ " $BUMP_TYPE " ]]; then
    log "Error: Invalid argument '$BUMP_TYPE'. Allowed: $VALID_TYPES"
    exit 1
fi

# -----------------------------------------------------------------------------
# STEP 1: Get latest version from Git
# -----------------------------------------------------------------------------
# We look for tags starting with 'v', sort by version number, take the last one.
# If no tags exist, default to v0.0.0 for calculation purposes.
LATEST_TAG=$(git tag -l "v*" | sort -V | tail -n1)

if [ -z "$LATEST_TAG" ]; then
    log "No tags found. Defaulting to v0.0.0"
    LATEST_TAG="v0.0.0"
else
    log "Latest tag found: $LATEST_TAG"
fi

# -----------------------------------------------------------------------------
# STEP 2: Parse the version using Regex
# -----------------------------------------------------------------------------
# Regex explanation:
# ^v                  : Starts with v
# ([0-9]+)            : Group 1: Major
# \.([0-9]+)          : Group 2: Minor
# \.([0-9]+)          : Group 3: Patch
# (-dev\.([0-9]+))? : Group 4: Optional suffix, Group 5: Build number
REGEX="^v([0-9]+)\.([0-9]+)\.([0-9]+)(-dev\.([0-9]+))?$"

if [[ $LATEST_TAG =~ $REGEX ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"
    IS_DEV="${BASH_REMATCH[4]}" # -dev.X or empty
    DEV_BUILD="${BASH_REMATCH[5]}" # X or empty
else
    log "Error: Latest tag $LATEST_TAG does not match format vX.Y.Z[-dev.BUILD]"
    exit 1
fi

# -----------------------------------------------------------------------------
# STEP 3: Calculate Next Version
# -----------------------------------------------------------------------------
NEXT_VERSION=""

case "$BUMP_TYPE" in
    major)
        # Increment Major, reset others
        NEXT_VERSION="$((MAJOR + 1)).0.0"
        log "Bumping Major: $LATEST_TAG -> $NEXT_VERSION"
        ;;

    minor)
        # Increment Minor, reset Patch
        NEXT_VERSION="$MAJOR.$((MINOR + 1)).0"
        log "Bumping Minor: $LATEST_TAG -> $NEXT_VERSION"
        ;;

    hotfix)
        # Increment Patch
        NEXT_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
        log "Bumping Hotfix: $LATEST_TAG -> $NEXT_VERSION"
        ;;

    dev)
        if [[ -n "$IS_DEV" ]]; then
            # SCENARIO A: Already on a dev version (e.g., v0.5.0-dev.1)
            # Just increment the build number.
            NEXT_BUILD=$((DEV_BUILD + 1))
            NEXT_VERSION="$MAJOR.$MINOR.$PATCH-dev.$NEXT_BUILD"
            log "Incrementing Dev Build: $LATEST_TAG -> $NEXT_VERSION"
        else
            # SCENARIO B: Currently on a stable version (e.g., v0.4.5)
            # 1. Calculate the *next* minor release (0.5.0)
            # 2. Append -dev.1
            NEXT_MINOR=$((MINOR + 1))
            NEXT_VERSION="$MAJOR.$NEXT_MINOR.0-dev.1"
            log "Starting new Dev chain: $LATEST_TAG -> $NEXT_VERSION"
        fi
        ;;
esac

# -----------------------------------------------------------------------------
# FINAL OUTPUT: Print strictly to stdout without newline
# -----------------------------------------------------------------------------
printf "%s" "$NEXT_VERSION"