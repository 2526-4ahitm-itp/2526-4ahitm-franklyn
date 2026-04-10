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

echo "Installing Rust..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION}-x86_64-pc-windows-gnu --profile minimal
else
    rustup toolchain install ${RUST_VERSION}-x86_64-pc-windows-gnu
    rustup default ${RUST_VERSION}-x86_64-pc-windows-gnu
fi

export PATH="/ucrt64/bin:$(cygpath -u "$USERPROFILE")/.cargo/bin:$PATH"

export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER="gcc"
export CC="gcc"
export CXX="g++"
export AR="ar"
export PKG_CONFIG_ALLOW_CROSS=1

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

cp ./LICENSE "$OUT/LICENSE"

echo "Deployment packaged in $OUT/"

zip -r franklyn-sentinel-$VERSION-x86_64-windows.zip dist/*
