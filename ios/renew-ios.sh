#!/bin/bash
# Rebuild / reinstall the liminal iOS app — same contract as larpSim's
# app-ios/renew-ios.sh; driven by autorenew.conf + ~/Developer/ios-autorenew.sh.
#
# Usage:  ./ios/renew-ios.sh [--debug|--release] [--build-only|--install-only] [--no-launch]
#   --debug         build the debug variant (fast — skips Dart AOT + release
#                   optimization; used by the autorenew watchdog)
#   --release       build the release variant (default; slower by far)
#   --build-only    flutter build (embeds a fresh 7-day profile)
#   --install-only  install the existing build over Wi-Fi
#   --no-launch     accepted for contract parity; never auto-launches
set -euo pipefail
cd "$(dirname "$0")/.."   # liminal root

VARIANT=release
BUILD_ONLY=false INSTALL_ONLY=false
for a in "$@"; do
  case "$a" in
    --debug)        VARIANT=debug ;;
    --release)      VARIANT=release ;;
    --build-only)   BUILD_ONLY=true ;;
    --install-only) INSTALL_ONLY=true ;;
    --no-launch)    : ;;
    *) echo "unknown arg: $a"; exit 2 ;;
  esac
done

app_path() {
  case "$VARIANT" in
    debug)   echo "build/ios/Debug-iphoneos/Runner.app" ;;
    release) for p in build/ios/iphoneos/Runner.app build/ios/Release-iphoneos/Runner.app; do
               [ -d "$p" ] && { echo "$p"; return; }
             done
             echo "build/ios/iphoneos/Runner.app" ;;
  esac
}
APP="$(app_path)"

do_build() {
  echo "== flutter build ($VARIANT, firebase-safe) =="
  ios/build_ios.sh "$VARIANT"
  [ -d "$APP" ] || { echo "build product missing: $APP"; exit 1; }
}

if [ "$INSTALL_ONLY" = true ]; then
  [ -d "$APP" ] || { echo "no previous $VARIANT build found — run --build-only first"; exit 1; }
else
  do_build
  [ "$BUILD_ONLY" = true ] && exit 0
fi

DEV="$(xcrun devicectl list devices 2>/dev/null \
  | awk '/available/ && /paired/ {for(i=1;i<=NF;i++) if ($i ~ /^[0-9A-F]{8}-/) {print $i; exit}}')"
[ -n "$DEV" ] || { echo "no paired iPhone visible — unlock it on the same Wi-Fi (or plug it in once)"; exit 1; }

echo
echo "== installing $VARIANT build to device $DEV =="
xcrun devicectl device install app --device "$DEV" "$APP"
