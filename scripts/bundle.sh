#!/bin/sh
# Builds the release binary and wraps it in .build/CineKit.app (ad hoc signed).
set -eu
cd "$(dirname "$0")/.."
# The CLT macOS 27 SDK needs SwiftUI macro plugins that only ship with Xcode (see AGENTS.md); with Xcode, as in CI, no pin.
case "$(xcode-select -p 2>/dev/null)" in
    *.app/*) ;;
    *) export SDKROOT="${SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk}" ;;
esac
# Set from the release tag (ADR 0017).
version="${VERSION:-0.0.0-dev}"

swift build -c release
app=.build/CineKit.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
bin="$(swift build -c release --show-bin-path)"
cp "$bin/CineKit" "$app/Contents/MacOS/CineKit"
# Bundle.module looks for the SwiftPM resource bundle in Contents/Resources.
cp -R "$bin/CineKit_CineKit.bundle" "$app/Contents/Resources/"
# The web remote the app serves on the local network (ADR 0003, 0011).
(cd remote && npm ci && npm run build)
cp -R remote/dist "$app/Contents/Resources/remote"

# iconutil and sips ship with macOS, so the icon builds without Xcode.
iconset="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
    sips -z $size $size assets/AppIcon.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) assets/AppIcon.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CineKit</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>dev.guilhermemendes.CineKit</string>
    <key>CFBundleName</key>
    <string>CineKit</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$version</string>
    <key>CFBundleVersion</key>
    <string>$version</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>NSLocalNetworkUsageDescription</key>
    <string>O controle remoto no celular se conecta ao CineKit pela rede local.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

codesign -s - --force "$app"
echo "Built $app"
