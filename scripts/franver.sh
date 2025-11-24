#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Utility Functions ---

# Helper function for conditional debug logging to stderr
# Only logs if the CI_DEBUG environment variable is set (e.g., CI_DEBUG=1)
debug_log() {
    if [ -n "$CI_DEBUG" ]; then
        echo "DEBUG: $@" >&2
    fi
}

# Helper function to check if the current directory is a Git repository
is_git_repo() {
    git rev-parse --is-inside-work-tree > /dev/null 2>&1
}

# Extracts the highest build number for the current month (vYYYY.MM.BUILD)
get_latest_main_build() {
    local calver_prefix="v$(date +%Y.%m)"
    debug_log "Main build search prefix: ${calver_prefix}.*"

    # 1. Get all tags for the current YYYY.MM.*
    # 2. Strip the 'vYYYY.MM.' prefix (leaving BUILD[-suffix])
    # 3. Strip the suffix (leaving only BUILD number)
    # 4. Sort numerically in reverse and take the first (highest) number
    # 5. If no tag is found, default to 0
    local raw_tags=$(git tag -l "${calver_prefix}.*" 2>/dev/null)
    debug_log "Found candidate main tags:\n${raw_tags}"

    local latest_build=$(
        echo "${raw_tags}" |
        sed "s/^${calver_prefix}\.//" |
        cut -d'-' -f1 |
        sort -rn |
        head -n 1
    )

    # If no tag is found, default to 0 (the variable will be empty)
    if [ -z "$latest_build" ]; then
        latest_build=0
    fi

    debug_log "Highest existing main build number: ${latest_build}"

    # Return the incremented build number (Max + 1, or 1 if Max=0)
    echo $(( latest_build + 1 ))
}

# Extracts the highest TWILIGHT build number for the current month
get_latest_twilight_build() {
    local calver_prefix="v$(date +%Y.%m)"
    debug_log "Twilight build search prefix: ${calver_prefix}.*-twilight.*"

    # 1. Get all tags for the current YYYY.MM.*-twilight.*
    # 2. Strip everything up to '-twilight.' (leaving only the TWILIGHT_BUILD)
    # 3. Sort numerically in reverse and take the first (highest) number
    # 4. If no tag is found, default to 0
    local raw_tags=$(git tag -l "${calver_prefix}.*-twilight.*" 2>/dev/null)
    debug_log "Found candidate twilight tags:\n${raw_tags}"

    local latest_twilight_build=$(
        echo "${raw_tags}" |
        sed 's/.*-twilight\.//' |
        sort -rn |
        head -n 1
    )

    # If no tag is found, default to 0
    if [ -z "$latest_twilight_build" ]; then
        latest_twilight_build=0
    fi

    debug_log "Highest existing twilight build number: ${latest_twilight_build}"

    # Return the incremented build number (Max + 1, or 1 if Max=0)
    echo $(( latest_twilight_build + 1 ))
}

# Function to generate the version string
# Usage: generate_version <release_type>
generate_version() {
    if [ -z "$1" ]; then
        echo "Error: Missing release type. Usage: $0 <alpha|beta|stable|twilight>" >&2
        return 1
    fi

    local release_type=$(echo "$1" | tr '[:upper:]' '[:lower:]') # Convert input to lowercase
    debug_log "Requested release type: ${release_type}"

    # Automatically determine the next build numbers from Git tags
    local main_build=$(get_latest_main_build)
    local twilight_build=$(get_latest_twilight_build)
    debug_log "Next main build number: ${main_build}"
    debug_log "Next twilight build number: ${twilight_build}"

    # 1. Get CalVer components (YYYY.MM)
    local calver_part=$(date +%Y.%m)
    debug_log "CalVer YYYY.MM component: ${calver_part}"

    # 2. Base version part (YYYY.MM.BUILD)
    local base_version="${calver_part}.${main_build}"
    debug_log "Base version (for stable/alpha/beta): ${base_version}"

    # 3. Determine the full version string based on release type
    local version_string="" # Variable to hold the final calculated version

    case "$release_type" in
        stable)
            # YYYY.MM.BUILD (Stable omits the suffix)
            version_string="$base_version"
            ;;
        alpha | beta)
            # YYYY.MM.BUILD-alpha or YYYY.MM.BUILD-beta
            version_string="${base_version}-${release_type}"
            ;;
        twilight)
            # YYYY.MM.BUILD-twilight.BUILD
            version_string="${base_version}-twilight.${twilight_build}"
            ;;
        *)
            # Invalid type
            echo "Error: Invalid release type '${release_type}'. Must be alpha, beta, stable, or twilight." >&2
            return 1
            ;;
    esac

    debug_log "Calculated raw version string: ${version_string}"

    # 4. Check if the calculated tag already exists in Git
    local check_tag="v${version_string}"
    debug_log "Checking for existing Git tag: ${check_tag}"

    # Check if 'git tag -l' outputs the exact tag name.
    if git tag -l "$check_tag" 2>/dev/null | grep -q "$check_tag"; then
        echo "Error: The calculated version tag '${check_tag}' already exists in Git for this month. Please commit more changes or manually increment the build count." >&2
        return 1
    fi

    debug_log "Tag ${check_tag} is unique. Proceeding."

    # 5. Output the new unique version (to stdout)
    echo "$version_string"
}

# --- Main Execution ---

# Mandatory check for CI environments
if ! is_git_repo; then
    echo "Error: This script must be run within a Git repository." >&2
    exit 1
fi

# Generate the requested version using the first command line argument
generate_version "$1"