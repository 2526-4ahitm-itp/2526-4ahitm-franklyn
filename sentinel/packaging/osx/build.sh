#!/usr/bin/env bash
# Builds franklyn-sentinel-<version>-aarch64-darwin-portable.tar.gz into the
# repo root, on Apple Silicon. GStreamer comes from the official framework
# packages, unpacked into a cache dir instead of installed (no sudo).
#
# Requires: Xcode command line tools, cargo, buf, pkg-config.

set -euo pipefail

GST_VERSION="1.28.7"
GST_URL="https://gstreamer.freedesktop.org/data/pkg/osx/$GST_VERSION"
GST_RUNTIME="gstreamer-1.0-$GST_VERSION-universal.pkg"
GST_DEVEL="gstreamer-1.0-devel-$GST_VERSION-universal.pkg"
GST_SHA256SUMS="\
529fdf4a4027d942e59b5b3564f6400adaa008f63ce5f3fed4ffe35d73911994  $GST_RUNTIME
72a44870cf02472cbf6e9a84bcc25ee6807dd1c26659a112066373544d365e7a  $GST_DEVEL"

# Oldest macOS the bundle runs on. Keep in sync with README.portable.txt and
# MIN_MACOS_VERSION in hugo/static/scripts/sentinel-install.sh.
export MACOSX_DEPLOYMENT_TARGET="14.0"

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
GST="${GST_CACHE:-$HOME/.cache/franklyn-sentinel/gstreamer}/$GST_VERSION"
OUT="$ROOT/sentinel/target/osx-portable"

if [ ! -f "$GST/.complete" ]; then
    echo "Fetching GStreamer $GST_VERSION..."
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"
    curl -fL --retry 3 -O "$GST_URL/$GST_RUNTIME" -O "$GST_URL/$GST_DEVEL"
    shasum -a 256 -c <<<"$GST_SHA256SUMS"
    pkgutil --expand-full "$GST_RUNTIME" runtime
    pkgutil --expand-full "$GST_DEVEL" devel
    rm -rf "$GST" "$GST_RUNTIME" "$GST_DEVEL"
    # Skips osx-framework-*, the framework symlinks that install one level up.
    for p in runtime/{base,gstreamer}-*/Payload; do ditto "$p" "$GST"; done
    for p in devel/*/Payload/lib/pkgconfig; do ditto "$p" "$GST/lib/pkgconfig"; done
    touch "$GST/.complete"
fi

command -v cargo-bundle-licenses >/dev/null || cargo install --locked cargo-bundle-licenses

echo "Building sentinel..."
cd "$ROOT/sentinel"
PKG_CONFIG_LIBDIR="$GST/lib/pkgconfig" PKG_CONFIG_PATH="" cargo build --release

echo "Bundling..."
rm -rf "$OUT"
mkdir -p "$OUT/bin" "$OUT/lib/gstreamer-1.0" "$OUT/libexec"
cd "$OUT"

# add DEST SRC — copy SRC (arm64 slice only) and queue it for dependency resolution.
queue=()
add() {
    lipo "$2" -thin arm64 -output "$1" 2>/dev/null || cp "$2" "$1"
    chmod u+w "$1"
    queue+=("$1")
}

add bin/franklyn "$ROOT/sentinel/target/release/franklyn-sentinel"
add libexec/gst-plugin-scanner "$GST/libexec/gstreamer-1.0/gst-plugin-scanner"
for plugin in coreelements videoconvertscale videorate app jpeg applemedia; do
    add "lib/gstreamer-1.0/libgst$plugin.dylib" "$GST/lib/gstreamer-1.0/libgst$plugin.dylib"
done

# Swap the absolute rpaths the .pc files add for one relative to the bundle.
# The framework's own rpaths (@loader_path/.., ...) already fit this layout.
otool -l bin/franklyn | awk '/LC_RPATH/ { getline; getline; if ($2 !~ /^@/) print $2 }' |
    while read -r rpath; do install_name_tool -delete_rpath "$rpath" bin/franklyn; done
install_name_tool -add_rpath @executable_path/../lib bin/franklyn

# Bundle every @rpath dependency; anything else must be a system library.
for ((i = 0; i < ${#queue[@]}; i++)); do
    f="${queue[$i]}"
    id="$(otool -D "$f" | tail -n +2)"
    while read -r dep; do
        [ "$dep" != "$id" ] || continue
        case "$dep" in
            /usr/lib/* | /System/*) ;;
            @rpath/*)
                if [ ! -e "lib/${dep#@rpath/}" ]; then add "lib/${dep#@rpath/}" "$GST/lib/${dep#@rpath/}"; fi
                ;;
            *)
                echo "$f: unexpected dependency $dep" >&2
                exit 1
                ;;
        esac
    done < <(otool -L "$f" | tail -n +2 | awk '{print $1}')
done

# "-" signs ad-hoc; set CODESIGN_IDENTITY to a Developer ID once there is one.
codesign --force --sign "${CODESIGN_IDENTITY:--}" "${queue[@]}"

curl -fsSL -o GSTREAMER_LICENSE "https://gitlab.freedesktop.org/gstreamer/gstreamer/-/raw/$GST_VERSION/subprojects/gstreamer/COPYING"
cp "$ROOT/LICENSE" LICENSE
cp "$ROOT/sentinel/packaging/osx/README.portable.txt" README.txt

COPYFILE_DISABLE=1 tar -czf "$ROOT/franklyn-sentinel-$(cat "$ROOT/VERSION")-aarch64-darwin-portable.tar.gz" .
