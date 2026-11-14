#!/usr/bin/env bash
set -euo pipefail

data=/var/lib/flat-manager
cd "$data"

rm -rf gpg
cp -r /flatpak/gpg gpg
chmod 700 gpg
key="$(gpg --homedir gpg --list-secret-keys --with-colons | awk -F: '/^sec/{print $5; exit}')"

mkdir -p build-repo repo
for repo in stable dev; do
    [ -f "repo/$repo/config" ] || ostree init --mode=archive --repo="repo/$repo"
done

sed -e "s|@SECRET@|$FLATPAK_SECRET|" \
    -e "s|@DB_PASSWORD@|$FLATPAK_DB_PASSWORD|" \
    -e "s|@GPG_KEY@|$key|" \
    /flatpak/config.json > config.json

exec flat-manager
