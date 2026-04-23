#!/usr/bin/env bash
set -euo pipefail

# Required env vars:
#   OBS_USER
#   OBS_PASSWORD
# Optional env vars:
#   OBS_API_URL (default: https://api.opensuse.org)
#   OBS_PROJECT (default: home:franklyn)
#   OBS_PACKAGE (default: franklyn)
#   ARTIFACT_GLOB (default: artifacts/franklyn-sentinel*.tar.zst)
#   DO_COMMIT (default: false)

OBS_API_URL="${OBS_API_URL:-https://api.opensuse.org}"
OBS_PROJECT="${OBS_PROJECT:-home:franklyn}"
OBS_PACKAGE="${OBS_PACKAGE:-franklyn}"
ARTIFACT_GLOB="${ARTIFACT_GLOB:-artifacts/franklyn-sentinel*.tar.zst}"
DO_COMMIT="${DO_COMMIT:-false}"

if [ -z "${OBS_USER:-}" ] || [ -z "${OBS_PASSWORD:-}" ]; then
  echo "Missing OBS_USER or OBS_PASSWORD"
  exit 1
fi

mkdir -p ~/.config/osc
{
  printf '%s\n' '[general]'
  printf 'apiurl = %s\n\n' "$OBS_API_URL"
  printf '[%s]\n' "$OBS_API_URL"
  printf 'user = %s\n' "$OBS_USER"
  printf 'pass = %s\n' "$OBS_PASSWORD"
  printf '%s\n' 'credentials_mgr_class = osc.credentials.PlaintextConfigFileCredentialsManager'
} > ~/.oscrc
chmod 600 ~/.oscrc
cp ~/.oscrc ~/.config/osc/oscrc

echo "Validating OBS authentication and access..."
osc -A "$OBS_API_URL" whois "$OBS_USER" >/dev/null
osc -A "$OBS_API_URL" meta prj "$OBS_PROJECT" >/dev/null
osc -A "$OBS_API_URL" meta pkg "$OBS_PROJECT" "$OBS_PACKAGE" >/dev/null

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

osc -A "$OBS_API_URL" checkout "$OBS_PROJECT" "$OBS_PACKAGE" --output-dir "$WORKDIR"

PKG_DIR="$WORKDIR/$OBS_PROJECT/$OBS_PACKAGE"
if [ ! -d "$PKG_DIR" ]; then PKG_DIR="$WORKDIR/$OBS_PACKAGE"; fi
if [ ! -d "$PKG_DIR" ] && [ -d "$WORKDIR/.osc" ]; then PKG_DIR="$WORKDIR"; fi

if [ ! -d "$PKG_DIR" ]; then
  echo "Could not locate checked out OBS package directory in $WORKDIR"
  ls -la "$WORKDIR"
  exit 1
fi

shopt -s nullglob
artifacts=( $ARTIFACT_GLOB )
shopt -u nullglob
if [ ${#artifacts[@]} -eq 0 ]; then
  echo "No artifacts matched: $ARTIFACT_GLOB"
  exit 1
fi

cp "${artifacts[@]}" "$PKG_DIR/"

pushd "$PKG_DIR" >/dev/null
osc addremove
osc status

if [ "$DO_COMMIT" = "true" ]; then
  osc ci -m "Manual local deploy test"
  echo "Committed to OBS."
else
  echo "Dry run complete (DO_COMMIT=false)."
fi
popd >/dev/null

echo "Done."
