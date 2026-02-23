#!/usr/bin/env bash
# sprint-stats.sh — Compute sprint report-card statistics between two git refs.
#
# Outputs key=value pairs to stdout for: commits, prs, issues, newlines,
# remlines, modfiles (files changed).
# Logging goes to stderr.
#
# Usage:
#   ./scripts/sprint-stats.sh [OPTIONS] <start-ref> <end-ref>
#
# The start ref is EXCLUSIVE and the end ref is INCLUSIVE.
# PRs and issues are filtered by the author-date window of the two refs.
#
# Options:
#   --code-only   Filter diff stats to code files recognised by tokei
#   --shortcode   Also print the Hugo report-card shortcode
#   -h, --help    Show this help message

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log() {
	printf '[sprint-stats] %s\n' "$*" >&2
}

die() {
	printf '[sprint-stats] ERROR: %s\n' "$*" >&2
	exit 1
}

usage() {
	sed -n '2,/^$/{ s/^# \?//; p }' "$0" >&2
	exit 0
}

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------

check_requirements() {
	local missing=()
	for cmd in git gh jq; do
		if ! command -v "$cmd" &>/dev/null; then
			missing+=("$cmd")
		fi
	done
	if [[ ${#missing[@]} -gt 0 ]]; then
		die "Missing required commands: ${missing[*]}"
	fi
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

CODE_ONLY=false
SHORTCODE=false
START_REF=""
END_REF=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	--code-only)
		CODE_ONLY=true
		shift
		;;
	--shortcode)
		SHORTCODE=true
		shift
		;;
	-h | --help) usage ;;
	-*) die "Unknown option: $1" ;;
	*)
		if [[ -z "$START_REF" ]]; then
			START_REF="$1"
		elif [[ -z "$END_REF" ]]; then
			END_REF="$1"
		else
			die "Unexpected argument: $1"
		fi
		shift
		;;
	esac
done

[[ -n "$START_REF" ]] || die "Missing <start-ref>"
[[ -n "$END_REF" ]] || die "Missing <end-ref>"

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

check_requirements

# Resolve refs (works for tags, branches, and commit SHAs)
git rev-parse --verify "$START_REF^{commit}" &>/dev/null ||
	die "Cannot resolve start ref: $START_REF"
git rev-parse --verify "$END_REF^{commit}" &>/dev/null ||
	die "Cannot resolve end ref: $END_REF"

# ---------------------------------------------------------------------------
# Commits (start exclusive, end inclusive — git .. range)
# ---------------------------------------------------------------------------

commits=$(git rev-list --count "$START_REF".."$END_REF")
log "Commits: $commits"

# ---------------------------------------------------------------------------
# Author-date window for PR/issue filtering
# ---------------------------------------------------------------------------

# Author date of start ref (exclusive boundary)
start_date=$(git log -1 --format='%aI' "$START_REF")
# Author date of end ref (inclusive boundary)
end_date=$(git log -1 --format='%aI' "$END_REF")

log "Date window: $start_date .. $end_date (author dates)"

# ---------------------------------------------------------------------------
# PRs merged in the date window
# ---------------------------------------------------------------------------

log "Fetching merged PRs from GitHub..."
prs=$(
	gh pr list \
		--state merged \
		--json number,mergedAt \
		--limit 1000 |
		jq --arg after "$start_date" --arg until "$end_date" \
			'[.[] | select(.mergedAt > $after and .mergedAt <= $until)] | length'
)
log "PRs: $prs"

# ---------------------------------------------------------------------------
# Issues closed in the date window
# ---------------------------------------------------------------------------

log "Fetching closed issues from GitHub..."
issues=$(
	gh issue list \
		--state closed \
		--json number,closedAt \
		--limit 1000 |
		jq --arg after "$start_date" --arg until "$end_date" \
			'[.[] | select(.closedAt > $after and .closedAt <= $until)] | length'
)
log "Issues: $issues"

# ---------------------------------------------------------------------------
# Diff stats
# ---------------------------------------------------------------------------

if [[ "$CODE_ONLY" == true ]]; then
	# Check tokei availability
	if ! command -v tokei &>/dev/null; then
		die "tokei is required for --code-only mode but was not found"
	fi

	log "Computing diff stats (code-only via tokei)..."

	# Collect changed file paths and their numstat (skip binary files marked
	# with "-" in the added/removed columns)
	mapfile -t numstat_lines < <(
		git diff --numstat "$START_REF".."$END_REF" | grep -v '^-'
	)

	# Create a temp dir with empty stub files mirroring the changed paths so
	# tokei can classify them by extension/filename.
	tmpdir=$(mktemp -d)
	trap 'rm -rf "$tmpdir"' EXIT

	for line in "${numstat_lines[@]}"; do
		fpath=$(printf '%s' "$line" | cut -f3-)
		# Handle renames: {old => new} format
		if [[ "$fpath" == *"{"*" => "*"}"* ]]; then
			fpath=$(printf '%s' "$fpath" | sed -E 's#(.*)\{.* => (.*)\}(.*)#\1\2\3#')
		fi
		stub="$tmpdir/$fpath"
		mkdir -p "$(dirname "$stub")"
		touch "$stub"
	done

	# Ask tokei which files it recognises.
	# Streaming simple output uses space-padded columns, not tabs:
	#   <language> <path> <lines> <code> <comments> <blanks>
	# Header lines start with '#'.
	declare -A code_files
	while IFS= read -r tline; do
		tpath=$(awk '{print $2}' <<<"$tline")
		# Strip the tmpdir prefix to get the relative path
		rel=${tpath#"$tmpdir/"}
		code_files["$rel"]=1
	done < <(tokei --streaming simple --no-ignore "$tmpdir" 2>/dev/null | grep -v '^#')

	# Sum only the code files from numstat
	newlines=0
	remlines=0
	modfiles=0

	for line in "${numstat_lines[@]}"; do
		added=$(printf '%s' "$line" | cut -f1)
		removed=$(printf '%s' "$line" | cut -f2)
		fpath=$(printf '%s' "$line" | cut -f3-)
		# Normalise renames
		if [[ "$fpath" == *"{"*" => "*"}"* ]]; then
			fpath=$(printf '%s' "$fpath" | sed -E 's#(.*)\{.* => (.*)\}(.*)#\1\2\3#')
		fi
		if [[ -n "${code_files[$fpath]+x}" ]]; then
			newlines=$((newlines + added))
			remlines=$((remlines + removed))
			modfiles=$((modfiles + 1))
		fi
	done
else
	log "Computing diff stats (all files)..."

	diffstat=$(git diff --shortstat "$START_REF".."$END_REF")

	# Parse: " X files changed, Y insertions(+), Z deletions(-)"
	# Any of the three parts may be absent.
	modfiles=0
	newlines=0
	remlines=0

	if [[ "$diffstat" =~ ([0-9]+)\ file ]]; then
		modfiles=${BASH_REMATCH[1]}
	fi
	if [[ "$diffstat" =~ ([0-9]+)\ insertion ]]; then
		newlines=${BASH_REMATCH[1]}
	fi
	if [[ "$diffstat" =~ ([0-9]+)\ deletion ]]; then
		remlines=${BASH_REMATCH[1]}
	fi
fi

log "New lines: $newlines"
log "Removed lines: $remlines"
log "Files changed: $modfiles"

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

printf 'commits=%s\n' "$commits"
printf 'prs=%s\n' "$prs"
printf 'issues=%s\n' "$issues"
printf 'newlines=%s\n' "$newlines"
printf 'remlines=%s\n' "$remlines"
printf 'modfiles=%s\n' "$modfiles"

if [[ "$SHORTCODE" == true ]]; then
	printf '\n{{< report-card commits="%s" prs="%s" issues="%s" newlines="%s" remlines="%s" modfiles="%s" >}}\n' \
		"$commits" "$prs" "$issues" "$newlines" "$remlines" "$modfiles"
fi
