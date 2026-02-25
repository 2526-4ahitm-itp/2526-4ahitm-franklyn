#!/usr/bin/env bash

# franver2.sh - Franklyn version bumping tool (v2)
# Wraps semver-tool to implement the release lifecycle defined in
# hugo/content/docs/explanation/release-lifecycle.md
#
# Usage: franver2.sh <command> <version>
#
# Commands:
#   major      Bump major version:           1.2.3 -> 2.0.0
#   minor      Bump minor version:           1.2.3 -> 1.3.0
#   patch      Bump patch version:           1.2.3 -> 1.2.4
#   rc major   Release candidate for major:  1.2.3 -> 2.0.0-rc.1  (or increment existing rc)
#   rc minor   Release candidate for minor:  1.2.3 -> 1.3.0-rc.1  (or increment existing rc)
#   rc patch   Release candidate for patch:  1.2.3 -> 1.2.4-rc.1  (or increment existing rc)
#   rc         Increment existing rc:        1.2.4-rc.1 -> 1.2.4-rc.2
#   dev        Append/increment dev build:   1.2.3 -> 1.2.3+dev.1
#
# The script reads a version string, applies exactly ONE operation, and outputs
# the new version string to stdout. All diagnostics go to stderr.

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() { echo "[franver2] $*" >&2; }
die() {
	log "ERROR: $*"
	exit 1
}

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
command -v semver >/dev/null 2>&1 || die "semver (semver-tool) not found in PATH"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
CMD=""
RC_LEVEL=""
VERSION=""

usage() {
	cat >&2 <<'EOF'
Usage: franver2.sh <command> <version>

Commands:
  major              Bump major version (stable release)
  minor              Bump minor version (stable release)
  patch              Bump patch version (stable release)
  rc major <ver>     Start/bump release candidate for next major
  rc minor <ver>     Start/bump release candidate for next minor
  rc patch <ver>     Start/bump release candidate for next patch
  rc <ver>           Increment existing release candidate number
  dev                Append or increment +dev.N build metadata

Exactly one command must be given. The version string is always the last argument.
EOF
	exit 1
}

case "${1:-}" in
major | minor | patch | dev)
	CMD="$1"
	shift
	;;
rc)
	CMD="rc"
	shift
	case "${1:-}" in
	major | minor | patch)
		RC_LEVEL="$1"
		shift
		;;
	*)
		# bare "rc" -- increment existing rc, version is next arg
		RC_LEVEL=""
		;;
	esac
	;;
-h | --help | "")
	usage
	;;
*)
	die "Unknown command '$1'. Run with --help for usage."
	;;
esac

VERSION="${1:-}"
[[ -z "$VERSION" ]] && die "Missing version argument"
shift
[[ $# -gt 0 ]] && die "Unexpected extra arguments: $*"

# ---------------------------------------------------------------------------
# Validate version
# ---------------------------------------------------------------------------
semver validate "$VERSION" >/dev/null 2>&1 || true
# semver validate exits 0 for valid and prints "valid"/"invalid"
VALID=$(semver validate "$VERSION")
[[ "$VALID" == "valid" ]] || die "Invalid semver version: $VERSION"

# ---------------------------------------------------------------------------
# Parse components from input version
# ---------------------------------------------------------------------------
PREREL=$(semver get prerel "$VERSION")
BUILD=$(semver get build "$VERSION")
RELEASE=$(semver get release "$VERSION") # X.Y.Z without prerel/build

HAS_RC=false
HAS_DEV=false

if [[ "$PREREL" == rc.* ]]; then
	HAS_RC=true
fi

if [[ "$BUILD" == dev.* ]]; then
	HAS_DEV=true
fi

log "Input version: $VERSION"
log "  release=$RELEASE prerel=$PREREL build=$BUILD"
log "  has_rc=$HAS_RC has_dev=$HAS_DEV"
log "  command=$CMD rc_level=$RC_LEVEL"

# ---------------------------------------------------------------------------
# Strip build metadata - semver-tool cannot bump versions that have +build
# We always strip build metadata before operating, since none of the version
# bump commands preserve or care about build metadata (only 'dev' appends it).
# ---------------------------------------------------------------------------
BASE_VERSION="$RELEASE"
if [[ -n "$PREREL" ]]; then
	BASE_VERSION="$RELEASE-$PREREL"
fi

# ---------------------------------------------------------------------------
# Apply the requested operation
# ---------------------------------------------------------------------------
RESULT=""

case "$CMD" in
major)
	# Stable major bump. Strip any prerelease/build first.
	# If we're on an rc for a major bump (e.g. 2.0.0-rc.3), release it.
	if $HAS_RC; then
		RESULT=$(semver bump release "$BASE_VERSION")
		log "Releasing RC to stable major: $VERSION -> $RESULT"
	else
		RESULT=$(semver bump major "$BASE_VERSION")
		log "Bumping major: $VERSION -> $RESULT"
	fi
	;;

minor)
	if $HAS_RC; then
		RESULT=$(semver bump release "$BASE_VERSION")
		log "Releasing RC to stable minor: $VERSION -> $RESULT"
	else
		RESULT=$(semver bump minor "$BASE_VERSION")
		log "Bumping minor: $VERSION -> $RESULT"
	fi
	;;

patch)
	if $HAS_RC; then
		RESULT=$(semver bump release "$BASE_VERSION")
		log "Releasing RC to stable patch: $VERSION -> $RESULT"
	else
		RESULT=$(semver bump patch "$BASE_VERSION")
		log "Bumping patch: $VERSION -> $RESULT"
	fi
	;;

rc)
	if [[ -n "$RC_LEVEL" ]]; then
		# "rc major/minor/patch" -- start a new RC chain or error if already on one
		if $HAS_RC; then
			die "Already on an RC version ($VERSION). Use 'rc' without level to increment, or use major/minor/patch to release."
		fi

		# First bump the target version, then add rc.1
		BUMPED=$(semver bump "$RC_LEVEL" "$BASE_VERSION")
		RESULT=$(semver bump prerel "rc.." "$BUMPED")
		log "Starting RC chain ($RC_LEVEL): $VERSION -> $RESULT"
	else
		# bare "rc" -- increment existing RC number
		if ! $HAS_RC; then
			die "Not on an RC version ($VERSION). Use 'rc major', 'rc minor', or 'rc patch' to start a new RC chain."
		fi

		RESULT=$(semver bump prerel "rc.." "$BASE_VERSION")
		log "Incrementing RC: $VERSION -> $RESULT"
	fi
	;;

dev)
	# Append or increment +dev.N build metadata.
	# semver-tool cannot increment build metadata, so we parse it manually.
	if $HAS_DEV; then
		# Extract current dev number and increment
		DEV_NUM="${BUILD#dev.}"
		if ! [[ "$DEV_NUM" =~ ^[0-9]+$ ]]; then
			die "Cannot parse dev build number from '$BUILD'"
		fi
		NEXT_DEV=$((DEV_NUM + 1))
	else
		NEXT_DEV=1
	fi

	RESULT=$(semver bump build "dev.$NEXT_DEV" "$BASE_VERSION")
	log "Dev build: $VERSION -> $RESULT"
	;;
esac

[[ -z "$RESULT" ]] && die "Bug: no result computed"

# Final validation
FINAL_VALID=$(semver validate "$RESULT")
[[ "$FINAL_VALID" == "valid" ]] || die "Bug: produced invalid version: $RESULT"

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
printf "%s" "$RESULT"
