#!/bin/sh
# Builds the release binary and wraps it in .build/CineKit.app (ad hoc signed).
set -eu
cd "$(dirname "$0")/.."
# The CLT macOS 27 SDK needs SwiftUI macro plugins that only ship with Xcode (see AGENTS.md).
export SDKROOT="${SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk}"

swift build -c release
app=.build/CineKit.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
bin="$(swift build -c release --show-bin-path)"
cp "$bin/CineKit" "$app/Contents/MacOS/CineKit"
# Bundle.module looks for the SwiftPM resource bundle in Contents/Resources.
cp -R "$bin/CineKit_CineKit.bundle" "$app/Contents/Resources/"

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CineKit</string>
    <key>CFBundleIdentifier</key>
    <string>dev.guilhermemendes.CineKit</string>
    <key>CFBundleName</key>
    <string>CineKit</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

codesign -s - --force "$app"
echo "Built $app"
