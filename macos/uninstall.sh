#!/bin/bash
set -euo pipefail
target="${1:-/Applications}/Codex Glass.app"
if [[ -d "$target" ]]; then
    bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$target/Contents/Info.plist")"
    [[ "$bundle_id" == 'io.github.lunarfairy.codex-glass' ]] || { echo 'Refusing to remove an unrelated app.' >&2; exit 1; }
    "$target/Contents/MacOS/CodexGlass" --disable-login
    "$target/Contents/MacOS/CodexGlass" --quit
    rm -rf "$target"
fi
defaults delete io.github.lunarfairy.codex-glass 2>/dev/null || true
echo 'Codex Glass removed. Codex CLI, desktop app, and account settings are unchanged.'
