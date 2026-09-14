#!/bin/bash
# Builds Onwards.app — a native shell around the web app.
# Usage: ./mac/build.sh     (from the repo root or anywhere)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/mac/build"
APP="$OUT/Onwards.app"

rm -rf "$OUT"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/web"

echo "→ compiling"
swiftc -O \
  -target arm64-apple-macos12.0 \
  -framework Cocoa -framework WebKit \
  -o "$APP/Contents/MacOS/Onwards" \
  "$ROOT/mac/main.swift"

echo "→ bundling the web app"
cp -R "$ROOT/app/." "$APP/Contents/Resources/web/"

echo "→ writing Info.plist"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Onwards</string>
  <key>CFBundleDisplayName</key><string>Onwards</string>
  <key>CFBundleIdentifier</key><string>app.onwards.mac</string>
  <key>CFBundleExecutable</key><string>Onwards</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSSupportsAutomaticTermination</key><false/>
</dict>
</plist>
PLIST

# Ad-hoc signature: enough to run on this machine. Distributing to other people
# needs a paid Developer ID certificate and notarisation, or they'll be blocked
# by Gatekeeper.
echo "→ ad-hoc signing"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || echo "  (codesign skipped)"

# a drag-to-Applications disk image, dropped where the site can serve it
echo "→ packaging Onwards.dmg"
STAGE="$OUT/dmg"
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Onwards" -srcfolder "$STAGE" -ov -format UDZO \
  "$ROOT/Onwards.dmg" >/dev/null
rm -rf "$STAGE"

echo "✓ built $APP"
echo "✓ built $ROOT/Onwards.dmg  ($(du -h "$ROOT/Onwards.dmg" | cut -f1))"
