#!/usr/bin/env bash

set -e

usage() {
  echo "Usage: $0 -f <deb-file> [-u <api-url>] [-r <repo-name>] [-d <distribution>] [-U <user:password>]"
  echo ""
  echo "  -f  Path to .deb file (required)"
  echo "  -u  Aptly API URL (default: http://localhost:8080)"
  echo "  -r  Repository name (default: franklyn-dev)"
  echo "  -d  Distribution (default: dev)"
  echo "  -U  Basic auth credentials as user:password (optional)"
  exit 1
}

APTLY_API="http://localhost:8080"
REPO_NAME="franklyn-dev"
DISTRIBUTION="dev"
DEB_FILE=""
AUTH=""

while getopts "f:u:r:d:U:" opt; do
  case $opt in
    f) DEB_FILE="$OPTARG" ;;
    u) APTLY_API="$OPTARG" ;;
    r) REPO_NAME="$OPTARG" ;;
    d) DISTRIBUTION="$OPTARG" ;;
    U) AUTH="$OPTARG" ;;
    *) usage ;;
  esac
done

if [ -z "$DEB_FILE" ]; then
  echo "Error: .deb file is required"
  usage
fi

if [ ! -f "$DEB_FILE" ]; then
  echo "Error: File not found: $DEB_FILE"
  exit 1
fi

AUTH_ARGS=()
if [ -n "$AUTH" ]; then
  AUTH_ARGS=(-u "$AUTH")
fi

curl_check() {
  local desc="$1"
  shift
  echo ">>> ${desc}"
  echo ">>> curl $@"
  local response
  local http_code
  response=$(curl -sS "${AUTH_ARGS[@]}" -w "\n__HTTP_CODE__:%{http_code}" "$@")
  http_code=$(echo "$response" | grep '__HTTP_CODE__:' | cut -d: -f2)
  body=$(echo "$response" | sed '/__HTTP_CODE__:/d')
  echo "<<< HTTP ${http_code}"
  echo "<<< ${body}"
  if [ "$http_code" -ge 400 ]; then
    echo "ERROR: ${desc} failed with HTTP ${http_code}"
    exit 1
  fi
}

curl_check "Uploading $DEB_FILE" \
  -X POST \
  -F "file=@${DEB_FILE}" \
  "${APTLY_API}/api/files/incoming"

curl_check "Adding to repo ${REPO_NAME}" \
  -X POST \
  "${APTLY_API}/api/repos/${REPO_NAME}/file/incoming"

curl_check "Publishing distribution ${DISTRIBUTION}" \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{"Signing": {"Batch": true}}' \
  "${APTLY_API}/api/publish/filesystem:default:/${DISTRIBUTION}"

echo ""
echo "Done! Packages in ${REPO_NAME}:"
curl -sS "${AUTH_ARGS[@]}" "${APTLY_API}/api/repos/${REPO_NAME}/packages"
echo ""