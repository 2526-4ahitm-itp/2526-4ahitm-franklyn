#!/usr/bin/env bash
# Smoke-tests a macOS portable tarball on a real Mac (CI runner). The bundle
# must not depend on the Nix store, every Mach-O must carry a valid signature,
# and the binary must start both directly and through a symlink, the way the
# installer links it into ~/.local/bin.
#
# Usage: smoke-test.sh franklyn-sentinel-<ver>-aarch64-darwin-portable.tar.gz

set -euo pipefail

tarball="$1"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

root="$work/root"
mkdir -p "$root"
tar -xzf "$tarball" -C "$root"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

machos=("$root/bin/franklyn" "$root/libexec/gst-plugin-scanner" "$root"/lib/*.dylib "$root"/lib/gstreamer-1.0/*.dylib)

for f in "${machos[@]}"; do
    [ -f "$f" ] || fail "missing $f"
    rel="${f#"$root"/}"

    # Every load path must be relocatable, and every @rpath dep bundled.
    # otool -L also lists a dylib's own install name; that is not a dep.
    id="$(otool -D "$f" | tail -n +2)"
    while read -r dep; do
        [ "$dep" != "$id" ] || continue
        case "$dep" in
            /nix/store/*) fail "$rel still links $dep" ;;
            @rpath/*) [ -f "$root/lib/${dep#@rpath/}" ] || fail "$rel needs $dep, which is not bundled" ;;
        esac
    done < <(otool -L "$f" | tail -n +2 | awk '{print $1}')

    if otool -l "$f" | grep -A2 LC_RPATH | grep -q /nix/store; then
        fail "$rel has a /nix/store LC_RPATH"
    fi

    codesign --verify --strict "$f" || fail "$rel has no valid signature"
done
echo "OK: ${#machos[@]} Mach-O files relocatable and signed"

# Start directly; dyld must not touch the Nix store (the runner has one, so a
# missed reference would otherwise still resolve here).
out="$(DYLD_PRINT_LIBRARIES=1 "$root/bin/franklyn" --version 2>"$work/dyld.log")" \
    || fail "franklyn --version failed: $(cat "$work/dyld.log")"
grep -q '^Franklyn Sentinel v' <<<"$out" || fail "unexpected --version output: $out"
if grep /nix/store "$work/dyld.log"; then
    fail "dyld loaded libraries from /nix/store"
fi
echo "OK: $out"

# Start through a symlink, as the installer publishes it.
mkdir "$work/bin"
ln -s "$root/bin/franklyn" "$work/bin/franklyn"
"$work/bin/franklyn" --version >/dev/null || fail "franklyn --version via symlink failed"
echo "OK: runs through a symlink"
