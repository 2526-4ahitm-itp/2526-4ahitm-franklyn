#!/usr/bin/env bash
# CI script for running in MSYS2 UCRT64

set -eu

RUST_VERSION="1.91.1"
CARGO_CMD="cargo build --release --features=prod"
VERSION="$(cat VERSION)"

echo "Installing MSYS2 dependencies..."
pacman -S --needed --noconfirm \
    mingw-w64-ucrt-x86_64-gstreamer \
    mingw-w64-ucrt-x86_64-gst-plugins-base \
    mingw-w64-ucrt-x86_64-gst-plugins-good \
    mingw-w64-ucrt-x86_64-gst-plugins-bad \
    mingw-w64-ucrt-x86_64-pkgconf \
    mingw-w64-ucrt-x86_64-gcc \
    mingw-w64-ucrt-x86_64-openssl \
    zip

echo "Installing cargo-bundle-licenses..."
cargo install cargo-bundle-licenses

echo "Setting environment variables..."
export PKG_CONFIG_PATH="/ucrt64/lib/pkgconfig"
export OPENSSL_DIR="/ucrt64"
export OPENSSL_LIB_DIR="/ucrt64/lib"
export OPENSSL_INCLUDE_DIR="/ucrt64/include"

echo "Building sentinel..."
pushd sentinel
$CARGO_CMD
popd

OUT="dist"

if [[ -d "$OUT" ]]; then
    rm -r "$OUT"
fi

mkdir -p "$OUT/plugins"

cp ./sentinel/target/release/franklyn-sentinel.exe "$OUT/franklyn.exe"

echo "Resolving core dependencies..."
ldd "$OUT/franklyn.exe" | grep -i -o '/ucrt64/bin/.*\.dll' | xargs -I {} cp -n "{}" "$OUT/" || true

echo "Copying plugins..."
cp /ucrt64/lib/gstreamer-1.0/libgstcoreelements.dll "$OUT/plugins/"
cp /ucrt64/lib/gstreamer-1.0/libgstvideoconvertscale.dll "$OUT/plugins/"
cp /ucrt64/lib/gstreamer-1.0/libgstvideorate.dll "$OUT/plugins/"
cp /ucrt64/lib/gstreamer-1.0/libgstjpeg.dll "$OUT/plugins/"
cp /ucrt64/lib/gstreamer-1.0/libgstapp.dll "$OUT/plugins/"
cp /ucrt64/lib/gstreamer-1.0/libgstd3d11.dll "$OUT/plugins/"

echo "Resolving plugin dependencies..."
for plugin in "$OUT/plugins/"*.dll; do
    ldd "$plugin" | grep -i -o '/ucrt64/bin/.*\.dll' | xargs -I {} cp -n "{}" "$OUT/" 2>/dev/null || true
done

curl https://gitlab.freedesktop.org/gstreamer/gstreamer/-/raw/main/LICENSE -o "$OUT/GSTREAMER_LICENSE"
cp ./LICENSE "$OUT/LICENSE"

cp sentinel/packaging/windows/README.portable.txt "$OUT/README.txt"

echo "Deployment packaged in $OUT/"

cd dist/
zip -r ../franklyn-sentinel-$VERSION-x86_64-windows-portable.zip .
