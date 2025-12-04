#!/usr/bin/env bash

# Usage: ./franver.sh <command>
#
# Generates a CalVer (YY.MINOR.PATCH) string based on Git tags.
#
# Commands:
#   stable   : New feature release. Increments MINOR, resets PATCH to 0. (e.g. 25.2.0)
#   dev      : Pre-release for next MINOR. (e.g. 25.2.0-dev)
#   alpha    : Pre-release for next MINOR. (e.g. 25.2.0-alpha)
#   beta     : Pre-release for next MINOR. (e.g. 25.2.0-beta)
#   hotfix   : Bug fix for LATEST stable. Increments PATCH. (e.g. 25.2.1)
#   twilight : Snapshot build on EXISTING minor. (e.g. 25.2.0-twilight.12)

set -e

debug_log() {
    if [ -n "$CI_DEBUG" ]; then
        echo "DEBUG: $@" >&2
    fi
}

is_git_repo() {
    git rev-parse --is-inside-work-tree > /dev/null 2>&1
}

# Returns the highest MINOR number found for the current YY year
get_latest_existing_minor() {
    local year_short=$(date +%y)
    local prefix="v${year_short}."

    # List tags matching vYY.*
    local raw_tags=$(git tag -l "${prefix}*" 2>/dev/null)

    # Extract the MINOR segment (2nd field), sort numerically descending, take top
    # We explicitly look for .0 patches to establish the minor version baseline
    local latest_minor=$(
        echo "${raw_tags}" |
        grep -E "^v${year_short}\.[0-9]+\.0" | # Ensure strictly matches structure vYY.N.0...
        sed "s/^v${year_short}\.//" |          # Remove vYY.
        cut -d'.' -f1 |                        # Keep only MINOR
        sort -rn |
        head -n 1
    )

    # Default to 0 so the next increment starts at 1
    if [ -z "$latest_minor" ]; then
        latest_minor=0
    fi

    debug_log "Highest existing minor version for '2${year_short}': ${latest_minor}"
    echo "${latest_minor}"
}

get_next_minor() {
    local latest_minor=$(get_latest_existing_minor)
    echo $(( latest_minor + 1 ))
}

get_latest_twilight_build() {
    local target_version_base="$1" # Expected format: YY.MINOR.PATCH

    if [ -z "$target_version_base" ]; then
         echo "Error: get_latest_twilight_build requires a base version string." >&2
         return 1
    fi

    # Look for vYY.MINOR.PATCH-twilight.N
    local prefix="v${target_version_base}-twilight."
    debug_log "Twilight build search prefix: ${prefix}*"

    local raw_tags=$(git tag -l "${prefix}*" 2>/dev/null)

    local latest_build=$(
        echo "${raw_tags}" |
        sed "s/^${prefix}//" |
        sort -rn |
        head -n 1
    )

    if [ -z "$latest_build" ]; then
        latest_build=0
    fi

    debug_log "Highest existing twilight build for ${target_version_base}: ${latest_build}"
    echo $(( latest_build + 1 ))
}

generate_version() {
    if [ -z "$1" ]; then
        echo "Error: Missing release type. Usage: $0 <dev|alpha|beta|stable|hotfix|twilight>" >&2
        return 1
    fi

    local release_type=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    debug_log "Requested release type: ${release_type}"

    local year_part=$(date +%y)
    local minor_part=""
    local patch_part="0" # Default patch is 0
    local base_version=""
    local version_string=""

    if [ "$release_type" == "hotfix" ]; then
        # 1. Find the latest STABLE tag for this year (exclude pre-releases with hyphens)
        local latest_tag=$(git tag -l "v${year_part}.*" --sort=-v:refname | grep -v "-" | head -n 1)

        if [ -z "$latest_tag" ]; then
            echo "Error: No existing stable releases found. Cannot create a hotfix." >&2
            return 1
        fi

        # 2. Parse and increment PATCH
        # Strip leading 'v'
        local clean_ver=${latest_tag#v}
        # clean_ver is YY.MINOR.PATCH
        local current_patch=$(echo "$clean_ver" | cut -d'.' -f3)
        local current_minor=$(echo "$clean_ver" | cut -d'.' -f2)

        # Increment patch
        local new_patch=$((current_patch + 1))

        version_string="${year_part}.${current_minor}.${new_patch}"

    elif [ "$release_type" == "twilight" ]; then
        # Twilight builds upon the EXISTING minor version.
        local existing_minor=$(get_latest_existing_minor)

        # If no minor version exists (0), we assume we are building twilight for the upcoming 1
        if [ "$existing_minor" -eq 0 ]; then
            existing_minor=1
        else
            # Find the latest stable patch for this minor version
            # Look for vYY.MINOR.*, exclude pre-releases (hyphens), sort descending
            local latest_stable_tag=$(git tag -l "v${year_part}.${existing_minor}.*" --sort=-v:refname | grep -v "-" | head -n 1)

            if [ -n "$latest_stable_tag" ]; then
                # Strip leading v just to be safe before cutting
                local clean_tag=${latest_stable_tag#v}
                patch_part=$(echo "$clean_tag" | cut -d'.' -f3)
            fi
        fi

        base_version="${year_part}.${existing_minor}.${patch_part}"
        local twilight_build=$(get_latest_twilight_build "$base_version")

        version_string="${base_version}-twilight.${twilight_build}"
    else
        # Stable, Dev, Alpha, Beta all increment to the NEXT minor version
        minor_part=$(get_next_minor)
        base_version="${year_part}.${minor_part}.${patch_part}"

        case "$release_type" in
            stable)
                version_string="$base_version"
                ;;
            dev | alpha | beta)
                version_string="${base_version}-${release_type}"
                ;;
            *)
                echo "Error: Invalid release type '${release_type}'." >&2
                return 1
                ;;
        esac
    fi

    debug_log "Calculated raw version string: ${version_string}"

    local check_tag="v${version_string}"
    if git tag -l "$check_tag" 2>/dev/null | grep -q "$check_tag"; then
        echo "Error: Tag '${check_tag}' already exists." >&2
        return 1
    fi

    echo "$version_string"
}

if ! is_git_repo; then
    echo "Error: This script must be run within a Git repository." >&2
    exit 1
fi

generate_version "$1"