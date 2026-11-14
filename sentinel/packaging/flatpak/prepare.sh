#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
root="$(git rev-parse --show-toplevel)"
out="$PWD/generated"

rm -rf "$out"
mkdir -p "$out"

cp -rL "$(nix build "$root#protobuf-gen" --no-link --print-out-paths)" "$out/protobuf"
chmod -R u+w "$out/protobuf"

(cd "$root/sentinel" && cargo bundle-licenses -f yaml -o "$out/licenses.yaml")

if command -v flatpak-cargo-generator >/dev/null; then
    flatpak-cargo-generator "$root/sentinel/Cargo.lock" -o "$out/cargo-sources.json"
else
    flatpak run --command=flatpak-cargo-generator org.flatpak.Builder \
        "$root/sentinel/Cargo.lock" -o "$out/cargo-sources.json"
fi
