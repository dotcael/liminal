#!/bin/bash
# Rebuild / reinstall the liminal iOS app — same contract as larpSim's
# app-ios/renew-ios.sh; driven by autorenew.conf + ~/Developer/ios-autorenew.sh.
#
# Usage:  ./ios/renew-ios.sh [--build-only|--install-only] [--no-launch]
#   --build-only   flutter build (embeds a fresh 7-day profile)
#   --install-only install the existing build over Wi-Fi
#   --no-launch    accepted for contract parity; never auto-launches
set -euo pipefail
cd "$(dirname "$0")/.."   # liminal root

APP="build/ios/iphoneos/Runner.app"

BUILD_ONLY=false INSTALL_ONLY=false
for a in "$@"; do
  case "$a" in
    --build-only)   BUILD_ONLY=true ;;
    --install-only) INSTALL_ONLY=true ;;
    --no-launch)    : ;;
    *) echo "unknown arg: $a"; exit 2 ;;
  esac
done

do_build() {
  echo "== flutter build (release, firebase-safe) =="
  ios/build_ios.sh release
  [ -d "$APP" ] || { echo "build product missing: $APP"; exit 1; }
}

if [ "$INSTALL_ONLY" = true ]; then
  [ -d "$APP" ] || { echo "no previous build found — run --build-only first"; exit 1; }
else
  do_build
  [ "$BUILD_ONLY" = true ] && exit 0
fi

DEV="$(xcrun devicectl list devices 2>/dev/null \
  | awk '/available/ && /paired/ {for(i=1;i<=NF;i++) if ($i ~ /^[0-9A-F]{8}-/) {print $i; exit}}')"
[ -n "$DEV" ] || { echo "no paired iPhone visible — unlock it on the same Wi-Fi (or plug it in once)"; exit 1; }

echo
echo "== installing to device $DEV =="
xcrun devicectl device install app --device "$DEV" "$APP"
