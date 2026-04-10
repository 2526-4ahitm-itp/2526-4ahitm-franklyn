#!/usr/bin/env bash
set -eu

pacman -S --needed --noconfirm \
    mingw-w64-ucrt-x86_64-gstreamer \
    mingw-w64-ucrt-x86_64-gst-plugins-base \
    mingw-w64-ucrt-x86_64-gst-plugins-good \
    mingw-w64-ucrt-x86_64-gst-plugins-bad

OUT="dist"

if [[ -d "$OUT" ]]; then
    rm -r "$OUT"
fi

mkdir -p "$OUT/plugins"

cp ./sentinel/target/release/franklyn-sentinel.exe "$OUT/franklyn.exe"

echo "Resolving core dependencies..."
ldd "$OUT/franklyn.exe" | grep -i -o '/ucrt64/bin/.*\.dll' | xargs -I {} cp -n "{}" "$OUT/"

echo "Copying plugins..."
cp /ucrt64/lib/gstreamer-1.0/libgstcoreelements.dll "$OUT/plugins/"
cp /ucrt64/lib/gstreamer-1.0/libgstvideoconvertscale.dll "$OUT/plugins/"
cp /ucrt64/lib/gstreamer-1.0/libgstvideorate.dll "$OUT/plugins/"
cp /ucrt64/lib/gstreamer-1.0/libgstjpeg.dll "$OUT/plugins/"
cp /ucrt64/lib/gstreamer-1.0/libgstapp.dll "$OUT/plugins/"
cp /ucrt64/lib/gstreamer-1.0/libgstd3d11.dll "$OUT/plugins/"

echo "Resolving plugin dependencies..."
for plugin in "$OUT/plugins/"*.dll; do
    ldd "$plugin" | grep -i -o '/ucrt64/bin/.*\.dll' | xargs -I {} cp -n "{}" "$OUT/" 2>/dev/null
done

cp ./LICENSE "$OUT/LICENSE"

echo "Deployment packaged in $OUT/"