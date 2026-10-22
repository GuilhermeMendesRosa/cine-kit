#!/bin/sh
# Installs the Android SDK, the cinekit-tv AVD and scrcpy-server used by the Android apps (ADR 0004).
# Idempotent: running it again skips what is already in place.
set -eu

export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
image="system-images;android-36;android-tv;arm64-v8a"
avd=cinekit-tv
scrcpy_version=5.0.1
scrcpy_sha256=764eb6f79811d5211fe9df341120882ba9994c7a61b897d7bf3fb662e53bc536
scrcpy_server="$HOME/Library/Application Support/CineKit/android/scrcpy-server"

command -v sdkmanager >/dev/null || brew install --cask android-commandlinetools

if [ ! -x "$ANDROID_HOME/emulator/emulator" ] || [ ! -d "$ANDROID_HOME/system-images/android-36/android-tv/arm64-v8a" ]; then
    yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses >/dev/null
    sdkmanager --sdk_root="$ANDROID_HOME" "platform-tools" "emulator" "build-tools;35.0.0" "$image"
fi

if [ ! -d "$HOME/.android/avd/$avd.avd" ]; then
    echo no | avdmanager create avd -n "$avd" -k "$image" -d tv_1080p --force
    config="$HOME/.android/avd/$avd.avd/config.ini"
    grep -v -e '^hw.ramSize' -e '^disk.dataPartition.size' "$config" > "$config.tmp"
    printf 'hw.ramSize=2048\ndisk.dataPartition.size=4G\n' >> "$config.tmp"
    mv "$config.tmp" "$config"
fi

if [ ! -f "$scrcpy_server" ] || ! echo "$scrcpy_sha256  $scrcpy_server" | shasum -a 256 -c - >/dev/null 2>&1; then
    mkdir -p "$(dirname "$scrcpy_server")"
    curl -fsSL -o "$scrcpy_server.download" \
        "https://github.com/Genymobile/scrcpy/releases/download/v$scrcpy_version/scrcpy-server-v$scrcpy_version"
    echo "$scrcpy_sha256  $scrcpy_server.download" | shasum -a 256 -c -
    mv "$scrcpy_server.download" "$scrcpy_server"
fi

echo "Android ready: AVD $avd, scrcpy-server v$scrcpy_version"
