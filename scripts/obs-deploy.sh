#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 -f <rpm-file> -p <project> [-P <package>] [-a <api-url>] [-u <user>] [-w <password>]"
  echo ""
  echo "  -f  Path to .rpm file (required)"
  echo "  -p  OBS project name (required, e.g., home:user/franklyn)"
  echo "  -P  OBS package name (default: franklyn-sentinel)"
  echo "  -a  OBS API URL (default: https://api.opensuse.org)"
  echo "  -u  OBS username (required)"
  echo "  -w  OBS password or API token (required)"
  exit 1
}

RPM_FILE=""
OBS_PROJECT=""
OBS_PACKAGE="franklyn-sentinel"
OBS_API="https://api.opensuse.org"
OBS_USER=""
OBS_PASS=""

while getopts "f:p:P:a:u:w:" opt; do
  case $opt in
    f) RPM_FILE="$OPTARG" ;;
    p) OBS_PROJECT="$OPTARG" ;;
    P) OBS_PACKAGE="$OPTARG" ;;
    a) OBS_API="$OPTARG" ;;
    u) OBS_USER="$OPTARG" ;;
    w) OBS_PASS="$OPTARG" ;;
    *) usage ;;
  esac
done

if [ -z "$RPM_FILE" ] || [ -z "$OBS_PROJECT" ] || [ -z "$OBS_USER" ] || [ -z "$OBS_PASS" ]; then
  usage
fi

if [ ! -f "$RPM_FILE" ]; then
  echo "ERROR: File not found: ${RPM_FILE}"
  exit 1
fi

RPM_FILE_ABS="$(realpath "$RPM_FILE")"

echo "=== OBS Deploy Configuration ==="
echo "  RPM_FILE:     ${RPM_FILE_ABS}"
echo "  OBS_PROJECT:  ${OBS_PROJECT}"
echo "  OBS_PACKAGE:  ${OBS_PACKAGE}"
echo "  OBS_API:      ${OBS_API}"
echo "================================"

curl_check() {
  local desc="$1"
  shift

  echo "--- [START] ${desc} ---"

  local tmpfile
  tmpfile=$(mktemp)

  local http_code
  http_code=$(curl \
    --silent \
    --show-error \
    --fail-with-body \
    --write-out "%{http_code}" \
    --output "$tmpfile" \
    -u "$OBS_USER:$OBS_PASS" \
    "$@" \
  ) || true

  local body
  body=$(cat "$tmpfile")
  rm -f "$tmpfile"

  echo "    HTTP:   ${http_code}"

  if [ "$http_code" -ge 400 ]; then
    echo "    Body:   ${body}"
    echo "ERROR: ${desc} failed with HTTP ${http_code}"
    exit 1
  fi

  echo "--- [OK] ${desc} ---"
  echo ""
}

echo "=== Step 1/3: Upload RPM ==="
curl_check "Uploading ${RPM_FILE_ABS} to OBS" \
  -X POST \
  -F "file=@${RPM_FILE_ABS}" \
  "${OBS_API}/source/${OBS_PROJECT}/${OBS_PACKAGE}"

echo "=== Step 2/3: Commit Changes ==="
curl_check "Committing package changes" \
  -X POST \
  -H "Content-Type: application/xml" \
  -d "<serviceinfo/>" \
  "${OBS_API}/source/${OBS_PROJECT}/${OBS_PACKAGE}?cmd=commit&rev=repository"

echo "=== Step 3/3: Trigger Rebuild ==="
curl_check "Triggering package rebuild" \
  -X POST \
  "${OBS_API}/build/${OBS_PROJECT}?cmd=rebuild"

echo "=== OBS Deploy Complete ==="
echo ""
echo "Package ${OBS_PACKAGE} in ${OBS_PROJECT} will be built by OBS."
echo "Monitor at: ${OBS_API}/package/show/${OBS_PROJECT}/${OBS_PACKAGE}"
