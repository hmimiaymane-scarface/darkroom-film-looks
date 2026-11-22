#!/bin/bash
# Builds build/Darkroom.app (universal: Apple silicon + Intel). Needs Xcode Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")/.."
APP=build/Darkroom.app
rm -rf "$APP" build/tmp && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/tmp

echo "› Compiling"
for arch in arm64 x86_64; do
  swiftc -O -swift-version 5 -target "$arch-apple-macos12.0" mac/main.swift -o "build/tmp/Darkroom-$arch"
done
lipo -create build/tmp/Darkroom-arm64 build/tmp/Darkroom-x86_64 -output "$APP/Contents/MacOS/Darkroom"

echo "› Bundling"
cp mac/Info.plist "$APP/Contents/Info.plist"
cp darkroom.html "$APP/Contents/Resources/"

echo "› Icon"
swift mac/icon.swift build/tmp/icon.png
ICONSET=build/tmp/AppIcon.iconset; mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s build/tmp/icon.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) build/tmp/icon.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

echo "› Signing (ad-hoc)"
codesign --force --deep --sign - "$APP"
rm -rf build/tmp
echo "✓ Built $APP"
