#!/bin/sh
# Wraps .build/CineKit.app from scripts/bundle.sh in .build/CineKit-<version>.dmg, next to a link to /Applications (ADR 0017).
set -eu
cd "$(dirname "$0")/.."

app=.build/CineKit.app
version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")"
dmg=".build/CineKit-$version.dmg"
staging="$(mktemp -d)/CineKit"
mkdir -p "$staging"
# ditto keeps the signature and the symlinks inside the bundle.
ditto "$app" "$staging/CineKit.app"
ln -s /Applications "$staging/Applications"
hdiutil create -volname CineKit -srcfolder "$staging" -format UDZO -ov "$dmg" >/dev/null
rm -rf "$(dirname "$staging")"
echo "Built $dmg"
