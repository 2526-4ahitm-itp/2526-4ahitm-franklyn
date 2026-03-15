#!/usr/bin/env bash
#
# AUR Package Deployment Script
# Publishes franklyn-bin or franklyn-bin-dev packages to the Arch User Repository
#
# Usage: ./aur-deploy.sh -v <version> -c <channel> [-k <ssh-key-path>]
#
# Requirements:
#   - SSH key registered with AUR (as secret AUR_SSH_PRIVATE_KEY in CI)
#   - Package must be pre-registered on AUR (first time requires manual setup)
#

set -euo pipefail

usage() {
  echo "Usage: $0 -v <version> -c <channel> [-k <ssh-key-path>] [-b <binary-x86_64>] [-a <binary-aarch64>]"
  echo ""
  echo "  -v  Package version (required, e.g., 0.4.0 or 0.4.0-rc.1)"
  echo "  -c  Channel: stable or dev (required)"
  echo "  -k  Path to SSH private key (optional, uses SSH_AUTH_SOCK if not provided)"
  echo "  -b  Path to x86_64 binary for checksum calculation (optional)"
  echo "  -a  Path to aarch64 binary for checksum calculation (optional)"
  echo ""
  exit 1
}

VERSION=""
CHANNEL=""
SSH_KEY=""
BINARY_X86=""
BINARY_ARM=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AUR_DIR="${PROJECT_ROOT}/sentinel/aur"

while getopts "v:c:k:b:a:" opt; do
  case $opt in
    v) VERSION="$OPTARG" ;;
    c) CHANNEL="$OPTARG" ;;
    k) SSH_KEY="$OPTARG" ;;
    b) BINARY_X86="$OPTARG" ;;
    a) BINARY_ARM="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  echo "ERROR: Version is required (-v)"
  usage
fi

if [[ -z "$CHANNEL" ]]; then
  echo "ERROR: Channel is required (-c)"
  usage
fi

if [[ "$CHANNEL" != "stable" && "$CHANNEL" != "dev" ]]; then
  echo "ERROR: Channel must be 'stable' or 'dev', got: '${CHANNEL}'"
  usage
fi

# Determine package name based on channel
if [[ "$CHANNEL" == "stable" ]]; then
  PKG_NAME="franklyn-bin"
else
  PKG_NAME="franklyn-bin-dev"
fi

# Convert version for PKGBUILD (replace + with .)
# AUR doesn't allow + in versions, so 0.4.0+dev.1 becomes 0.4.0.dev.1
PKGVER="${VERSION//+/.}"
# Also handle any - for rc versions: 0.4.0-rc.1 becomes 0.4.0_rc.1
PKGVER="${PKGVER//-/_}"

echo "=== AUR Deploy Configuration ==="
echo "  Version:     ${VERSION}"
echo "  PKGVER:      ${PKGVER}"
echo "  Channel:     ${CHANNEL}"
echo "  Package:     ${PKG_NAME}"
echo "  AUR Dir:     ${AUR_DIR}/${PKG_NAME}"
echo "================================="
echo ""

# Setup SSH for AUR
setup_ssh() {
  if [[ -n "$SSH_KEY" ]]; then
    echo "Setting up SSH key from: ${SSH_KEY}"
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    cp "$SSH_KEY" ~/.ssh/aur
    chmod 600 ~/.ssh/aur

    cat >> ~/.ssh/config <<EOF
Host aur.archlinux.org
  IdentityFile ~/.ssh/aur
  User aur
  StrictHostKeyChecking accept-new
EOF
    chmod 600 ~/.ssh/config
  else
    echo "Using existing SSH agent"
    # Add AUR to known hosts if not present
    ssh-keyscan -t ed25519 aur.archlinux.org >> ~/.ssh/known_hosts 2>/dev/null || true
  fi
}

# Calculate SHA256 checksums for binaries
calculate_checksums() {
  local sha_x86="SKIP"
  local sha_arm="SKIP"

  if [[ -n "$BINARY_X86" && -f "$BINARY_X86" ]]; then
    sha_x86=$(sha256sum "$BINARY_X86" | cut -d' ' -f1)
    echo "  x86_64 checksum: ${sha_x86}"
  fi

  if [[ -n "$BINARY_ARM" && -f "$BINARY_ARM" ]]; then
    sha_arm=$(sha256sum "$BINARY_ARM" | cut -d' ' -f1)
    echo "  aarch64 checksum: ${sha_arm}"
  fi

  echo "$sha_x86 $sha_arm"
}

# Clone AUR repo and update
update_aur() {
  local tmpdir
  tmpdir=$(mktemp -d)
  echo "Working in: ${tmpdir}"

  cd "$tmpdir"

  echo "=== Cloning AUR repository ==="
  git clone "ssh://aur@aur.archlinux.org/${PKG_NAME}.git" "${PKG_NAME}" || {
    echo "WARNING: AUR repo doesn't exist yet. Creating initial package..."
    mkdir -p "${PKG_NAME}"
    cd "${PKG_NAME}"
    git init
    git remote add origin "ssh://aur@aur.archlinux.org/${PKG_NAME}.git"
    cd ..
  }

  cd "${PKG_NAME}"

  echo "=== Updating PKGBUILD ==="
  # Copy template files
  cp "${AUR_DIR}/${PKG_NAME}/PKGBUILD" .
  cp "${AUR_DIR}/${PKG_NAME}/franklyn-sentinel.desktop" .

  # Update version in PKGBUILD
  sed -i "s/^pkgver=.*/pkgver=${PKGVER}/" PKGBUILD
  sed -i "s/^_pkgver_orig=.*/_pkgver_orig=${VERSION}/" PKGBUILD
  sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD

  # Calculate and update checksums if binaries provided
  if [[ -n "$BINARY_X86" || -n "$BINARY_ARM" ]]; then
    echo "=== Calculating checksums ==="
    read -r sha_x86 sha_arm < <(calculate_checksums)

    if [[ "$sha_x86" != "SKIP" ]]; then
      # Update x86_64 binary checksum (first entry in sha256sums_x86_64)
      sed -i "s/sha256sums_x86_64=('SKIP'/sha256sums_x86_64=('${sha_x86}'/" PKGBUILD
    fi
    if [[ "$sha_arm" != "SKIP" ]]; then
      # Update aarch64 binary checksum (first entry in sha256sums_aarch64)
      sed -i "s/sha256sums_aarch64=('SKIP'/sha256sums_aarch64=('${sha_arm}'/" PKGBUILD
    fi
  fi

  echo "=== Generating .SRCINFO ==="
  # Generate .SRCINFO (requires makepkg, fall back to manual update)
  if command -v makepkg &> /dev/null; then
    makepkg --printsrcinfo > .SRCINFO
  else
    # Manual .SRCINFO update (for CI environments without makepkg)
    cp "${AUR_DIR}/${PKG_NAME}/.SRCINFO" .
    sed -i "s/pkgver = .*/pkgver = ${PKGVER}/" .SRCINFO
    sed -i "s/pkgrel = .*/pkgrel = 1/" .SRCINFO
    # Update source URLs with original version (containing + for download URLs)
    sed -i "s|franklyn-sentinel-0.0.0|franklyn-sentinel-${VERSION}|g" .SRCINFO
    # Update the local filename reference to use sanitized pkgver
    sed -i "s|franklyn-sentinel-${VERSION}-x86_64::|franklyn-sentinel-${PKGVER}-x86_64::|g" .SRCINFO
    sed -i "s|franklyn-sentinel-${VERSION}-aarch64::|franklyn-sentinel-${PKGVER}-aarch64::|g" .SRCINFO
  fi

  echo "=== Committing changes ==="
  git config user.name "Franklyn CI Bot"
  git config user.email "franklyn@htl-leonding.ac.at"

  git add PKGBUILD .SRCINFO franklyn-sentinel.desktop
  git commit -m "Update to version ${VERSION}" || {
    echo "No changes to commit"
    return 0
  }

  echo "=== Pushing to AUR ==="
  git push origin master || git push origin main

  echo "=== Cleanup ==="
  cd /
  rm -rf "$tmpdir"

  echo ""
  echo "=== AUR Deploy Complete ==="
  echo "Package ${PKG_NAME} updated to version ${PKGVER}"
  echo "AUR URL: https://aur.archlinux.org/packages/${PKG_NAME}"
}

# Main
setup_ssh
update_aur
