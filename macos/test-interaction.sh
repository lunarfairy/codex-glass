#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swift build --configuration release
binary_dir="$(swift build --configuration release --show-bin-path)"
swiftc -parse-as-library -I "$binary_dir/Modules" \
    "$binary_dir/GlassCore.build/"*.swift.o \
    Sources/CodexGlass/Overlay.swift scripts/CheckOverlayHitTesting.swift \
    -o "$binary_dir/CheckOverlayHitTesting"
"$binary_dir/CheckOverlayHitTesting"
