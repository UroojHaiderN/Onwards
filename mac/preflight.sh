#!/bin/bash
# Tells you exactly what's still missing before Onwards can be notarised.
# Usage: ./mac/preflight.sh
set -uo pipefail

ok=0; bad=0
pass() { printf "  \033[32m✓\033[0m %s\n" "$1"; ok=$((ok+1)); }
fail() { printf "  \033[31m✗\033[0m %s\n" "$1"; shift; for l in "$@"; do printf "      %s\n" "$l"; done; bad=$((bad+1)); }

echo
echo "Notarisation preflight"
echo "──────────────────────"

# 1 ── Developer ID Application certificate
IDENT="$(security find-identity -v -p codesigning 2>/dev/null | grep 'Developer ID Application' | head -1 | sed -E 's/.*"(.*)"/\1/')"
if [ -n "$IDENT" ]; then
  pass "Developer ID certificate — $IDENT"
else
  fail "No \"Developer ID Application\" certificate" \
       "Easiest route (handles the signing request for you):" \
       "  Xcode → Settings → Accounts → pick your team →" \
       "  Manage Certificates… → + → Developer ID Application" \
       "" \
       "Requires the PAID Apple Developer Program (\$99/yr)." \
       "An \"Apple Development\" cert will not work for distribution."
fi

# 2 ── Team ID
TEAM="$(echo "$IDENT" | sed -nE 's/.*\(([A-Z0-9]{10})\)$/\1/p')"
if [ -n "$TEAM" ]; then
  pass "Team ID — $TEAM"
else
  fail "Team ID unknown (comes with the certificate)" \
       "Also shown at developer.apple.com/account → Membership"
fi

# 3 ── stored notary credentials
if xcrun notarytool history --keychain-profile onwards >/dev/null 2>&1; then
  pass "Notary credentials stored (profile: onwards)"
else
  fail "Notary credentials not stored" \
       "Create an app-specific password:" \
       "  appleid.apple.com → Sign-In and Security → App-Specific Passwords" \
       "Then store it once (goes to your keychain, never the repo):" \
       "  xcrun notarytool store-credentials onwards \\" \
       "    --apple-id \"you@example.com\" \\" \
       "    --team-id \"${TEAM:-YOURTEAMID}\" \\" \
       "    --password \"xxxx-xxxx-xxxx-xxxx\""
fi

# 4 ── bundle identifier
BID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
        "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/mac/build/Onwards.app/Contents/Info.plist" 2>/dev/null)"
BID="${BID:-com.onwards.app}"
if [ "$BID" = "com.onwards.app" ]; then
  fail "Bundle ID is still the placeholder ($BID)" \
       "Use a domain you control, e.g. com.yourname.onwards" \
       "Edit CFBundleIdentifier in mac/build.sh"
else
  pass "Bundle ID — $BID"
fi

echo
if [ "$bad" -eq 0 ]; then
  echo "All clear. Run: ./mac/release.sh"
else
  echo "$bad thing(s) to sort out, then re-run this."
fi
echo
