#!/usr/bin/env bash
#
# Regenerates every platform app icon from assets/icon/billbox_icon.svg.
# macOS only: it uses swiftc and AppKit's SVG support to rasterize.
#
#   ./tool/icon/generate_icons.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MASTER="$ROOT/assets/icon/billbox_icon.svg"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

echo "==> building rasterizer"
swiftc -O -o "$BUILD/rasterize" "$ROOT/tool/icon/rasterize.swift"
RASTER="$BUILD/rasterize"

# Single source of truth: the gradient and the artwork both come out of the master.
DEFS="$(awk '/<defs>/,/<\/defs>/' "$MASTER")"
MARK="$(awk '/MARK:BEGIN/{f=1;next} /MARK:END/{f=0} f' "$MASTER")"

# The artwork occupies x 158..866, y 178..856 of the 1024 canvas, so it is
# centred on (512, 517) — scaled variants pivot there and re-centre on the canvas.
MARK_CX=512
MARK_CY=517

# svg <file> <body...> — wraps SVG body fragments in a 1024x1024 document.
svg() {
  local out="$1"; shift
  {
    echo '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">'
    echo "$DEFS"
    printf '%s\n' "$@"
    echo '</svg>'
  } > "$BUILD/$out"
}

# scaled <factor> — the mark, scaled about its own centre and centred on the canvas.
scaled() {
  printf '<g transform="translate(512,512) scale(%s) translate(-%s,-%s)">%s</g>' \
    "$1" "$MARK_CX" "$MARK_CY" "$MARK"
}

BG='<rect width="1024" height="1024" fill="url(#billboxBg)"/>'

echo "==> composing variants"
# Full bleed: iOS, web, Windows.
svg full.svg "$BG" "$MARK"

# Android legacy launcher icons: rounded square and round.
svg rounded.svg \
  '<clipPath id="clip"><rect width="1024" height="1024" rx="180"/></clipPath>' \
  '<g clip-path="url(#clip)">'"$BG$MARK"'</g>'
svg circle.svg \
  '<clipPath id="clip"><circle cx="512" cy="512" r="512"/></clipPath>' \
  '<g clip-path="url(#clip)">'"$BG$MARK"'</g>'

# Android adaptive foreground: transparent, artwork inside the 66% safe zone.
svg foreground.svg "$(scaled 0.82)"

# Web maskable: background plus artwork inside the safe circle.
svg maskable.svg "$BG" "$(scaled 0.80)"

# macOS: artwork on the 824/1024 rounded-rectangle plate Apple's grid calls for.
svg macos.svg \
  '<clipPath id="plate"><rect x="100" y="100" width="824" height="824" rx="185"/></clipPath>' \
  '<g clip-path="url(#plate)" transform="translate(100,100) scale(0.8047)">'"$BG$MARK"'</g>'

# Android themed (monochrome) icon: the same silhouette with the bill lines
# punched out, since the system paints the whole shape one colour.
# Geometry mirrors the master — update both together.
svg monochrome.svg \
  '<mask id="cut">' \
  '  <g transform="translate(512,512) scale(0.82) translate(-512,-517)">' \
  '    <g transform="translate(0,-14)">' \
  '      <g transform="rotate(10 560 440)"><path d="M430 240 a26 26 0 0 1 26-26 h224 a26 26 0 0 1 26 26 v420 h-276 z" fill="#FFFFFF"/></g>' \
  '      <path d="M356 222 a30 30 0 0 1 30-30 h252 a30 30 0 0 1 30 30 v446 h-312 z" fill="#FFFFFF"/>' \
  '      <rect x="404" y="282" width="188" height="34" rx="17" fill="#000000"/>' \
  '      <rect x="404" y="352" width="216" height="34" rx="17" fill="#000000"/>' \
  '      <rect x="404" y="422" width="124" height="34" rx="17" fill="#000000"/>' \
  '      <path d="M182 648 h660 l-14 170 a56 56 0 0 1 -56 52 h-520 a56 56 0 0 1 -56 -52 z" fill="#FFFFFF"/>' \
  '      <rect x="158" y="610" width="708" height="88" rx="44" fill="#FFFFFF"/>' \
  '    </g>' \
  '  </g>' \
  '</mask>' \
  '<rect width="1024" height="1024" fill="#FFFFFF" mask="url(#cut)"/>'

png()        { "$RASTER" png        "$BUILD/$1" "$2" "$3"; }
png_opaque() { "$RASTER" png-opaque "$BUILD/$1" "$2" "$3"; }

echo "==> iOS"
IOS="$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
while read -r name size; do
  png_opaque full.svg "$IOS/$name" "$size"   # App Store icons must have no alpha
done <<'SIZES'
Icon-App-20x20@1x.png 20
Icon-App-20x20@2x.png 40
Icon-App-20x20@3x.png 60
Icon-App-29x29@1x.png 29
Icon-App-29x29@2x.png 58
Icon-App-29x29@3x.png 87
Icon-App-40x40@1x.png 40
Icon-App-40x40@2x.png 80
Icon-App-40x40@3x.png 120
Icon-App-60x60@2x.png 120
Icon-App-60x60@3x.png 180
Icon-App-76x76@1x.png 76
Icon-App-76x76@2x.png 152
Icon-App-83.5x83.5@2x.png 167
Icon-App-1024x1024@1x.png 1024
SIZES

echo "==> Android"
RES="$ROOT/android/app/src/main/res"
while read -r density legacy foreground; do
  png rounded.svg    "$RES/mipmap-$density/ic_launcher.png"            "$legacy"
  png circle.svg     "$RES/mipmap-$density/ic_launcher_round.png"      "$legacy"
  png foreground.svg "$RES/mipmap-$density/ic_launcher_foreground.png" "$foreground"
  png monochrome.svg "$RES/mipmap-$density/ic_launcher_monochrome.png" "$foreground"
done <<'SIZES'
mdpi 48 108
hdpi 72 162
xhdpi 96 216
xxhdpi 144 324
xxxhdpi 192 432
SIZES

echo "==> macOS"
MACOS="$ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset"
for size in 16 32 64 128 256 512 1024; do
  png macos.svg "$MACOS/app_icon_$size.png" "$size"
done

echo "==> web"
png full.svg     "$ROOT/web/favicon.png"                  32
png full.svg     "$ROOT/web/icons/Icon-192.png"           192
png full.svg     "$ROOT/web/icons/Icon-512.png"           512
png maskable.svg "$ROOT/web/icons/Icon-maskable-192.png"  192
png maskable.svg "$ROOT/web/icons/Icon-maskable-512.png"  512

echo "==> Windows"
"$RASTER" ico "$BUILD/full.svg" "$ROOT/windows/runner/resources/app_icon.ico"

echo "==> done"
