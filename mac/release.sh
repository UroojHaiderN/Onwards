#!/bin/bash
# Signs, notarises and packages Onwards.app for distribution.
#
# One-time setup before this will work:
#   1. Paid Apple Developer Program membership ($99/yr).
#   2. In the portal: Certificates → + → "Developer ID Application".
#      Download it and double-click to install into the login keychain.
#   3. Create an app-specific password at appleid.apple.com → Sign-In and
#      Security → App-Specific Passwords.
#   4. Store it once (this never touches the repo):
#        xcrun notarytool store-credentials onwards \
#          --apple-id "you@example.com" --team-id "TEAMID" --password "xxxx-xxxx-xxxx-xxxx"
#
# Then: ./mac/release.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/mac/build"
APP="$OUT/Onwards.app"
ZIP="$OUT/Onwards.zip"
DMG="$OUT/Onwards.dmg"
PROFILE="${NOTARY_PROFILE:-onwards}"

# --- find the Developer ID identity -----------------------------------------
IDENTITY="$(security find-identity -v -p codesigning \
  | grep "Developer ID Application" | head -1 \
  | sed -E 's/.*"(.*)"/\1/')" || true

if [ -z "${IDENTITY:-}" ]; then
  cat <<'MSG'
✗ No "Developer ID Application" certificate found in your keychain.

   An "Apple Development" certificate will NOT work for distribution — it only
   runs on your own registered devices.

   Get one: developer.apple.com → Certificates, IDs & Profiles → Certificates
            → + → Developer ID Application → download → double-click to install.
            (Requires the paid Apple Developer Program.)
MSG
  exit 1
fi
echo "→ signing as: $IDENTITY"

# --- build fresh -------------------------------------------------------------
"$ROOT/mac/build.sh" >/dev/null
echo "→ built"

# --- sign with hardened runtime (notarisation requires it) -------------------
codesign --force --options runtime --timestamp \
  --sign "$IDENTITY" "$APP"
codesign --verify --strict --verbose=2 "$APP"
echo "→ signed"

# --- notarise ----------------------------------------------------------------
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "→ submitting to Apple (this usually takes a few minutes)"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

# staple the ticket so it works offline / first launch
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
echo "→ notarised and stapled"

# --- package -----------------------------------------------------------------
rm -f "$ZIP" "$DMG"
ditto -c -k --keepParent "$APP" "$ZIP"

# a drag-to-Applications disk image
STAGE="$OUT/dmg"
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Onwards" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

# --- verify exactly as a downloader's Mac will ---------------------------------
echo
echo "→ Gatekeeper verdict:"
if spctl -a -vvv -t install "$APP" 2>&1 | tee /dev/stderr | grep -q "accepted"; then
  echo
  echo "✓ accepted — this will open with no warning on any Mac"
else
  echo
  echo "✗ still rejected — notarisation did not take. Check the log above."
  exit 1
fi

echo
echo "Ready to ship:"
echo "   $ZIP"
echo "   $DMG"
echo
echo "Next: attach Onwards.dmg to a GitHub Release, then set DOWNLOAD_URL in"
echo "index.html to  https://github.com/<you>/onwards/releases/latest/download/Onwards.dmg"
