#!/usr/bin/env bash
# Builds the macOS portable tarball
# franklyn-sentinel-<version>-<arch>-darwin-portable.tar.gz into the repo root.
#

set -euo pipefail

GST_VERSION="1.28.7"
GST_RUNTIME_SHA256="529fdf4a4027d942e59b5b3564f6400adaa008f63ce5f3fed4ffe35d73911994"
GST_DEVEL_SHA256="72a44870cf02472cbf6e9a84bcc25ee6807dd1c26659a112066373544d365e7a"
GST_URL="https://gstreamer.freedesktop.org/data/pkg/osx/$GST_VERSION"

export MACOSX_DEPLOYMENT_TARGET="14.0"

CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
VERSION="$(cat "$ROOT/VERSION")"
GST_CACHE="${GST_CACHE:-$HOME/.cache/franklyn-sentinel/gstreamer}"
GST="$GST_CACHE/$GST_VERSION"
OUT="$ROOT/sentinel/target/osx-portable"

case "$(uname -m)" in
    arm64) ARCH="aarch64" LIPO_ARCH="arm64" ;;
    x86_64) ARCH="x86_64" LIPO_ARCH="x86_64" ;;
    *)
        echo "unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

for tool in cargo buf pkg-config; do
    command -v "$tool" >/dev/null || {
        echo "$tool is required" >&2
        exit 1
    }
done

fetch_pkg() {
    curl -fL --retry 3 -o "$tmp/$1" "$GST_URL/$1"
    echo "$2  $tmp/$1" | shasum -a 256 -c -
    pkgutil --expand-full "$tmp/$1" "$3"
    rm "$tmp/$1"
}

if [ ! -f "$GST/.complete" ]; then
    echo "Fetching GStreamer $GST_VERSION..."
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    rm -rf "$GST"
    mkdir -p "$GST" "$tmp/root"

    fetch_pkg "gstreamer-1.0-$GST_VERSION-universal.pkg" "$GST_RUNTIME_SHA256" "$tmp/runtime"
    for payload in "$tmp"/runtime/*.pkg/Payload; do
        case "$payload" in
            */osx-framework-*) ;;
            *) ditto "$payload" "$tmp/root" ;;
        esac
    done
    mv "$tmp/root/lib" "$tmp/root/libexec" "$GST/"
    rm -rf "$tmp/runtime" "$tmp/root"

    fetch_pkg "gstreamer-1.0-devel-$GST_VERSION-universal.pkg" "$GST_DEVEL_SHA256" "$tmp/devel"
    for pc in "$tmp"/devel/*.pkg/Payload/lib/pkgconfig; do
        ditto "$pc" "$GST/lib/pkgconfig"
    done

    touch "$GST/.complete"
fi

command -v cargo-bundle-licenses >/dev/null || cargo install --locked cargo-bundle-licenses

echo "Building sentinel..."
(
    cd "$ROOT/sentinel"
    PKG_CONFIG_LIBDIR="$GST/lib/pkgconfig" PKG_CONFIG_PATH="" cargo build --release
)

echo "Bundling..."
rm -rf "$OUT"
mkdir -p "$OUT/bin" "$OUT/lib/gstreamer-1.0" "$OUT/libexec"
cd "$OUT"

queue=()
add() {
    lipo "$2" -thin "$LIPO_ARCH" -output "$1" 2>/dev/null || cp "$2" "$1"
    chmod u+w "$1"
    queue+=("$1")
}

add bin/franklyn "$ROOT/sentinel/target/release/franklyn-sentinel"
add libexec/gst-plugin-scanner "$GST/libexec/gstreamer-1.0/gst-plugin-scanner"
for plugin in coreelements videoconvertscale videorate app jpeg applemedia; do
    add "lib/gstreamer-1.0/libgst$plugin.dylib" "$GST/lib/gstreamer-1.0/libgst$plugin.dylib"
done

while read -r rpath; do
    case "$rpath" in
        @*) ;;
        *) install_name_tool -delete_rpath "$rpath" bin/franklyn ;;
    esac
done < <(otool -l bin/franklyn | awk '/cmd LC_RPATH/ { getline; getline; print $2 }')
install_name_tool -add_rpath @executable_path/../lib bin/franklyn

i=0
while [ "$i" -lt "${#queue[@]}" ]; do
    f="${queue[$i]}"
    i=$((i + 1))
    id="$(otool -D "$f" | tail -n +2)"

    while read -r dep; do
        if [ "$dep" = "$id" ]; then
            continue
        fi
        case "$dep" in
            /usr/lib/* | /System/*) ;;
            @rpath/*)
                name="${dep#@rpath/}"
                if [ ! -e "lib/$name" ]; then
                    add "lib/$name" "$GST/lib/$name"
                fi
                ;;
            *)
                echo "$f: unexpected dependency $dep" >&2
                exit 1
                ;;
        esac
    done < <(otool -L "$f" | tail -n +2 | awk '{print $1}')
done

for f in "${queue[@]}"; do
    codesign --force --sign "$CODESIGN_IDENTITY" "$f"
done

curl -fsSL "https://gitlab.freedesktop.org/gstreamer/gstreamer/-/raw/$GST_VERSION/subprojects/gstreamer/COPYING" -o GSTREAMER_LICENSE
cp "$ROOT/LICENSE" LICENSE
cp "$ROOT/sentinel/packaging/osx/README.portable.txt" README.txt

TARBALL="$ROOT/franklyn-sentinel-$VERSION-$ARCH-darwin-portable.tar.gz"
COPYFILE_DISABLE=1 tar -czf "$TARBALL" .
echo "Created $TARBALL"
