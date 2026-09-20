#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swift build --configuration release
binary_dir="$(swift build --configuration release --show-bin-path)"
bundle="$PWD/dist/Codex Glass.app"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
cp "$binary_dir/CodexGlass" "$bundle/Contents/MacOS/CodexGlass"
cp Info.plist "$bundle/Contents/Info.plist"
cp ../LICENSE "$bundle/Contents/Resources/LICENSE"
swift scripts/MakeIcon.swift .build/AppIcon.iconset
iconutil -c icns .build/AppIcon.iconset -o "$bundle/Contents/Resources/AppIcon.icns"
# Finder / cloud-synced folders can attach metadata forbidden inside signed bundles.
# Remove only that generated-bundle metadata; never clear quarantine or security attributes.
xattr -rd com.apple.FinderInfo "$bundle" 2>/dev/null || true
xattr -rd com.apple.ResourceFork "$bundle" 2>/dev/null || true
codesign --force --sign - --identifier io.github.lunarfairy.codex-glass "$bundle"
codesign --verify --deep --strict "$bundle"
plutil -lint "$bundle/Contents/Info.plist"
printf 'Built: %s\n' "$bundle"
