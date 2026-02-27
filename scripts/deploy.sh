#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 -f <deb-file> -d <suite> [-u <api-url>] [-U <user:password>]"
  echo ""
  echo "  -f  Path to .deb file (required)"
  echo "  -d  Suite/distribution: stable or dev (required)"
  echo "  -u  Aptly API URL (default: https://franklyn.htl-leonding.ac.at)"
  echo "  -U  Basic auth credentials as user:password (optional)"
  exit
}

APTLY_API="https://franklyn.htl-leonding.ac.at/repo"
DEB_FILE=""
SUITE=""
AUTH=""

while getopts "f:d:u:U:" opt; do
  case $opt in
    f) DEB_FILE="$OPTARG" ;;
    d) SUITE="$OPTARG" ;;
    u) APTLY_API="$OPTARG" ;;
    U) AUTH="$OPTARG" ;;
    *) usage ;;
  esac
done

echo "=== Deploy Configuration ==="
echo "  DEB_FILE:  ${DEB_FILE:-<not set>}"
echo "  SUITE:     ${SUITE:-<not set>}"
echo "  APTLY_API: ${APTLY_API}"
echo "  AUTH:      $([ -n "$AUTH" ] && echo "<provided>" || echo "<not set>")"
echo "==========================="

if [ -z "$DEB_FILE" ]; then
  echo "ERROR: .deb file is required (-f)"
  usage
fi

if [ -z "$SUITE" ]; then
  echo "ERROR: suite is required (-d)"
  usage
fi

if [[ "$SUITE" != "stable" && "$SUITE" != "dev" ]]; then
  echo "ERROR: suite must be 'stable' or 'dev', got: '${SUITE}'"
  usage
fi

if [ ! -f "$DEB_FILE" ]; then
  echo "ERROR: File not found: ${DEB_FILE}"
  exit 1
fi

DEB_FILE_ABS="$(realpath "$DEB_FILE")"
DEB_FILE_SIZE="$(stat -c%s "$DEB_FILE_ABS")"
REPO_NAME="franklyn-${SUITE}"

echo ""
echo "=== Package Info ==="
echo "  File:      ${DEB_FILE_ABS}"
echo "  Size:      ${DEB_FILE_SIZE} bytes"
echo "  Repo:      ${REPO_NAME}"
echo "  Suite:     ${SUITE}"
echo "===================="
echo ""

AUTH_ARGS=()
if [ -n "$AUTH" ]; then
  AUTH_ARGS=(-u "$AUTH")
fi

curl_check() {
  local desc="$1"
  shift

  echo "--- [START] ${desc} ---"
  echo "    URL:    $*"

  local tmpfile
  tmpfile=$(mktemp)

  local http_code
  http_code=$(curl \
    --silent \
    --show-error \
    --fail-with-body \
    --write-out "%{http_code}" \
    --output "$tmpfile" \
    "${AUTH_ARGS[@]}" \
    "$@" \
  ) || true

  local body
  body=$(cat "$tmpfile")
  rm -f "$tmpfile"

  echo "    HTTP:   ${http_code}"
  echo "    Body:   ${body}"

  if [ -z "$http_code" ]; then
    echo "ERROR: No HTTP response received for: ${desc}"
    echo "       This likely means the API is unreachable at: ${APTLY_API}"
    exit 1
  fi

  if [ "$http_code" -ge 400 ]; then
    echo "ERROR: ${desc} failed with HTTP ${http_code}"
    echo "       Response body: ${body}"
    exit 1
  fi

  echo "--- [OK] ${desc} ---"
  echo ""
}

echo "=== Step 1/3: Upload ==="
curl_check "Uploading ${DEB_FILE_ABS} to incoming" \
  -X POST \
  -F "file=@${DEB_FILE_ABS}" \
  "${APTLY_API}/api/files/incoming"

echo "=== Step 2/3: Add to Repo ==="
curl_check "Adding incoming packages to repo ${REPO_NAME}" \
  -X POST \
  "${APTLY_API}/api/repos/${REPO_NAME}/file/incoming"

echo "=== Step 3/3: Publish ==="
curl_check "Publishing distribution '${SUITE}'" \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{"Signing": {"Batch": true}}' \
  "${APTLY_API}/api/publish/filesystem:default:/${SUITE}"

echo "=== Deploy Complete ==="
echo ""
echo "Packages now in ${REPO_NAME}:"
curl \
  --silent \
  --show-error \
  "${AUTH_ARGS[@]}" \
  "${APTLY_API}/api/repos/${REPO_NAME}/packages"
echo ""