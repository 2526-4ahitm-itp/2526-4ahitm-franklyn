#!/usr/bin/env bash

set -e

debug_log() {
    if [ -n "$CI_DEBUG" ]; then
        echo "DEBUG: $@" >&2
    fi
}

is_git_repo() {
    git rev-parse --is-inside-work-tree > /dev/null 2>&1
}

get_latest_existing_main_build() {
    local calver_prefix="v$(date +%Y.%m)"
    
    local raw_tags=$(git tag -l "${calver_prefix}.*" 2>/dev/null)
    
    local latest_build=$(
        echo "${raw_tags}" |
        sed "s/^${calver_prefix}\.//" |
        cut -d'-' -f1 |
        sort -rn |
        head -n 1
    )

    # Default to -1 so the next increment starts at 0 for a new month
    if [ -z "$latest_build" ]; then
        latest_build=-1
    fi
    
    debug_log "Highest existing main build number found: ${latest_build}"
    echo "${latest_build}"
}

get_latest_main_build() {
    local latest_build=$(get_latest_existing_main_build)
    echo $(( latest_build + 1 ))
}

get_latest_twilight_build() {
    local target_main_build="$1"
    
    if [ -z "$target_main_build" ]; then
         echo "Error: get_latest_twilight_build requires a main build number." >&2
         return 1
    fi

    # Scope search to the specific main build to allow resetting
    local calver_prefix="v$(date +%Y.%m).${target_main_build}"
    debug_log "Twilight build search prefix: ${calver_prefix}-twilight.*"

    local raw_tags=$(git tag -l "${calver_prefix}-twilight.*" 2>/dev/null)
    
    local latest_twilight_build=$(
        echo "${raw_tags}" |
        sed "s/^${calver_prefix}-twilight\.//" |
        sort -rn |
        head -n 1
    )

    if [ -z "$latest_twilight_build" ]; then
        latest_twilight_build=0
    fi

    debug_log "Highest existing twilight build: ${latest_twilight_build}"
    echo $(( latest_twilight_build + 1 ))
}

generate_version() {
    if [ -z "$1" ]; then
        echo "Error: Missing release type. Usage: $0 <alpha|beta|stable|twilight>" >&2
        return 1
    fi

    local release_type=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    debug_log "Requested release type: ${release_type}"

    local main_build=""
    local calver_part=$(date +%Y.%m)
    local base_version=""
    local version_string="" 

    if [ "$release_type" == "twilight" ]; then
        main_build=$(get_latest_existing_main_build)
        
        # If no main build exists (-1), assume we are targeting build 0
        if [ "$main_build" -lt 0 ]; then
            main_build=0
        fi

        local twilight_build=$(get_latest_twilight_build "$main_build")
        version_string="${calver_part}.${main_build}-twilight.${twilight_build}"
    else
        main_build=$(get_latest_main_build)
        base_version="${calver_part}.${main_build}"

        case "$release_type" in
            stable)
                version_string="$base_version"
                ;;
            alpha | beta)
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
