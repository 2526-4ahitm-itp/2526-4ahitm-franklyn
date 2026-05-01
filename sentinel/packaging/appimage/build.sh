#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s -v <version> [-i <dist-archive>] [-a <arch>] [-o <output-dir>]\n' "$0" >&2
  exit 1
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

DIST_ARCHIVE=""
VERSION=""
ARCH="x86_64"
OUTPUT_DIR="$ROOT_DIR"

while getopts ":i:v:a:o:h" opt; do
  case "$opt" in
    i) DIST_ARCHIVE="$OPTARG" ;;
    v) VERSION="$OPTARG" ;;
    a) ARCH="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [ -z "$VERSION" ] && [ -f "$ROOT_DIR/VERSION" ]; then
  VERSION="$(tr -d '\n' < "$ROOT_DIR/VERSION")"
fi

if [ -z "$VERSION" ]; then
  printf 'Missing version. Use -v or provide VERSION file.\n' >&2
  exit 1
fi

if [ -z "$DIST_ARCHIVE" ]; then
  candidates=("$ROOT_DIR"/result/franklyn-sentinel-*-"$ARCH"-linux-dist.tar.zst)
  if [ ${#candidates[@]} -eq 1 ] && [ -f "${candidates[0]}" ]; then
    DIST_ARCHIVE="${candidates[0]}"
  else
    printf 'Missing dist archive. Use -i to set path.\n' >&2
    exit 1
  fi
fi

if [ ! -f "$DIST_ARCHIVE" ]; then
  printf 'Dist archive not found: %s\n' "$DIST_ARCHIVE" >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'chmod -R u+w "$WORKDIR" 2>/dev/null || true; rm -rf "$WORKDIR"' EXIT

DIST_DIR="$WORKDIR/dist"
APPDIR="$WORKDIR/AppDir"

mkdir -p "$DIST_DIR" "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons"

tar --zstd -xf "$DIST_ARCHIVE" -C "$DIST_DIR"

install -Dm0755 "$DIST_DIR/bin/franklyn" "$APPDIR/usr/bin/franklyn"
if [ -f "$DIST_DIR/LICENSE" ]; then
  install -Dm0644 "$DIST_DIR/LICENSE" "$APPDIR/usr/share/licenses/franklyn/LICENSE"
fi
if [ -f "$DIST_DIR/GSTREAMER_LICENSE" ]; then
  install -Dm0644 "$DIST_DIR/GSTREAMER_LICENSE" "$APPDIR/usr/share/licenses/franklyn/GSTREAMER_LICENSE"
fi

DESKTOP_TEMPLATE="$ROOT_DIR/sentinel/resources/franklyn-sentinel.desktop"
DESKTOP_OUT="$APPDIR/franklyn-sentinel.desktop"
sed -e "s/@VERSION@/$VERSION/g" -e "s|@BINARY_PATH@|franklyn|g" "$DESKTOP_TEMPLATE" > "$DESKTOP_OUT"
install -Dm0644 "$DESKTOP_OUT" "$APPDIR/usr/share/applications/franklyn-sentinel.desktop"

APP_RUN="$APPDIR/AppRun"
cat > "$APP_RUN" <<'APP_RUN_EOF'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$HERE/usr/bin/franklyn" "$@"
APP_RUN_EOF
chmod 0755 "$APP_RUN"

if [ -d "$DIST_DIR/share/icons/hicolor" ]; then
  cp -a "$DIST_DIR/share/icons/hicolor" "$APPDIR/usr/share/icons/"
fi

RESOURCE_ICONS="$ROOT_DIR/sentinel/resources/icons"
if [ -d "$RESOURCE_ICONS" ]; then
  for size_dir in "$RESOURCE_ICONS"/*; do
    if [ -d "$size_dir/apps" ] && [ -f "$size_dir/apps/franklyn-sentinel.png" ]; then
      size_name="$(basename "$size_dir")"
      install -Dm0644 "$size_dir/apps/franklyn-sentinel.png" \
        "$APPDIR/usr/share/icons/hicolor/$size_name/apps/franklyn-sentinel.png"
    fi
  done
fi

ICON_SOURCE="$RESOURCE_ICONS/256x256/apps/franklyn-sentinel.png"
if [ -f "$ICON_SOURCE" ]; then
  install -Dm0644 "$ICON_SOURCE" "$APPDIR/franklyn-sentinel.png"
fi

APPIMAGETOOL_BIN="${APPIMAGETOOL:-}"
if [ -z "$APPIMAGETOOL_BIN" ]; then
  APPIMAGETOOL_BIN="$WORKDIR/appimagetool-$ARCH.AppImage"
  curl -L -o "$APPIMAGETOOL_BIN" \
    "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$ARCH.AppImage"
  chmod 0755 "$APPIMAGETOOL_BIN"
fi

OUTPUT_FILE="$OUTPUT_DIR/franklyn-sentinel-$VERSION-$ARCH.AppImage"
ARCH="$ARCH" APPIMAGETOOL_EXTRACT_AND_RUN=1 "$APPIMAGETOOL_BIN" "$APPDIR" "$OUTPUT_FILE"

printf 'AppImage created: %s\n' "$OUTPUT_FILE"
