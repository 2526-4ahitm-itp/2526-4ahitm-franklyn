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
    log "Error: Missing argument. Usage: $0 [major|minor|hotfix|dev|prerel]"
    exit 1
fi

BUMP_TYPE=$1
# Added 'prerel' to valid types
VALID_TYPES="major minor hotfix dev prerel"
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
# STEP 2.5: Check for Stale Dev Tags
# -----------------------------------------------------------------------------
# If we found a dev tag (e.g., v1.0.0-dev.1), but the corresponding stable tag
# (v1.0.0) ALREADY exists, then the dev tag is stale/outdated (likely due to
# sorting quirks or old tags left behind). We should treat this as being on
# the stable version.
if [[ -n "$IS_DEV" ]]; then
    STABLE_TAG="v$MAJOR.$MINOR.$PATCH"
    if git rev-parse "$STABLE_TAG" >/dev/null 2>&1; then
        log "Stable tag $STABLE_TAG exists. Ignoring stale dev suffix ($IS_DEV)."
        IS_DEV=""
        DEV_BUILD=""
    fi
fi

# -----------------------------------------------------------------------------
# STEP 3: Calculate Next Version
# -----------------------------------------------------------------------------
NEXT_VERSION=""

case "$BUMP_TYPE" in
    major)
        # If we are already on a pre-release for a major version (e.g., v1.0.0-dev.1),
        # bumping "major" should just release that version (v1.0.0), not skip to v2.0.0.
        if [[ -n "$IS_DEV" ]] && [[ "$MINOR" -eq 0 ]] && [[ "$PATCH" -eq 0 ]]; then
            NEXT_VERSION="$MAJOR.0.0"
            log "Stabilizing Major: $LATEST_TAG -> $NEXT_VERSION"
        else
            # Increment Major, reset others
            NEXT_VERSION="$((MAJOR + 1)).0.0"
            log "Bumping Major: $LATEST_TAG -> $NEXT_VERSION"
        fi
        ;;

    minor)
        # FIX APPLIED HERE:
        # If we are on a pre-release of a minor version (e.g., v0.1.0-dev.1),
        # bumping "minor" should release that version (v0.1.0), not skip to v0.2.0.
        # We know it's a minor pre-release if Patch is 0.
        if [[ -n "$IS_DEV" ]] && [[ "$PATCH" -eq 0 ]]; then
            NEXT_VERSION="$MAJOR.$MINOR.0"
            log "Stabilizing Minor: $LATEST_TAG -> $NEXT_VERSION"
        else
            # Increment Minor, reset Patch
            NEXT_VERSION="$MAJOR.$((MINOR + 1)).0"
            log "Bumping Minor: $LATEST_TAG -> $NEXT_VERSION"
        fi
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
            log "Starting new Dev chain (Minor bump): $LATEST_TAG -> $NEXT_VERSION"
        fi
        ;;

    prerel)
        # Check if we are already on a "Major" dev chain (x.0.0-dev.N)
        # We assume it is a Major chain ONLY if Minor and Patch are 0.
        if [[ -n "$IS_DEV" ]] && [[ "$MINOR" -eq 0 ]] && [[ "$PATCH" -eq 0 ]]; then
            # SCENARIO A: Already on a Major dev version (e.g., v2.0.0-dev.1)
            # Just increment the build number.
            NEXT_BUILD=$((DEV_BUILD + 1))
            NEXT_VERSION="$MAJOR.$MINOR.$PATCH-dev.$NEXT_BUILD"
            log "Incrementing Prerelease (Major) Build: $LATEST_TAG -> $NEXT_VERSION"
        else
            # SCENARIO B:
            # - Currently on a stable version (e.g., v1.4.5)
            # - OR Currently on a dev version that IS NOT a major bump (e.g., v1.5.0-dev.3)
            # In both cases, we force a switch to the NEXT Major version.

            NEXT_MAJOR=$((MAJOR + 1))
            NEXT_VERSION="$NEXT_MAJOR.0.0-dev.1"
            log "Starting new Prerelease chain (Major bump): $LATEST_TAG -> $NEXT_VERSION"
        fi
        ;;
esac

# -----------------------------------------------------------------------------
# FINAL OUTPUT: Print strictly to stdout without newline
# -----------------------------------------------------------------------------
printf "%s" "$NEXT_VERSION"