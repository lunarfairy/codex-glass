#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -d "dist/Codex Glass.app" ]]; then ./build.sh; fi
destination="${1:-/Applications}"
mkdir -p "$destination"
destination="$(cd "$destination" && pwd)"
target="$destination/Codex Glass.app"
staging="$(mktemp -d "$destination/.codex-glass-install.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
ditto "dist/Codex Glass.app" "$staging/Codex Glass.app"
xattr -rd com.apple.FinderInfo "$staging/Codex Glass.app" 2>/dev/null || true
xattr -rd com.apple.ResourceFork "$staging/Codex Glass.app" 2>/dev/null || true
codesign --verify --deep --strict "$staging/Codex Glass.app"
if [[ -e "$target" ]]; then
    bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$target/Contents/Info.plist")"
    [[ "$bundle_id" == 'io.github.lunarfairy.codex-glass' ]] || { echo 'Refusing to replace an unrelated app.' >&2; exit 1; }
    "$target/Contents/MacOS/CodexGlass" --quit
    mv "$target" "$staging/previous.app"
fi
if ! mv "$staging/Codex Glass.app" "$target"; then
    if [[ -d "$staging/previous.app" ]]; then mv "$staging/previous.app" "$target"; fi
    exit 1
fi
open "$target" --args --control
printf 'Installed: %s\n' "$target"
