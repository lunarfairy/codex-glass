#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
case "$(uname -m)" in
    arm64) package_arch="arm64" ;;
    x86_64) package_arch="x64" ;;
    *) echo 'Unsupported build architecture.' >&2; exit 1 ;;
esac
package_name="CodexGlass-macos-$package_arch"
staging="$(mktemp -d "$PWD/.build/package.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
package_root="$staging/$package_name"
mkdir -p "$package_root/dist"
ditto "dist/Codex Glass.app" "$package_root/dist/Codex Glass.app"
cp install.sh uninstall.sh Install.command Uninstall.command README.md README.en.md "$package_root/"
cp ../LICENSE "$package_root/LICENSE"
chmod +x "$package_root/"*.sh "$package_root/"*.command
# Do not archive Finder metadata added by cloud-synced build directories.
xattr -rd com.apple.FinderInfo "$package_root" 2>/dev/null || true
xattr -rd com.apple.ResourceFork "$package_root" 2>/dev/null || true
codesign --verify --deep --strict "$package_root/dist/Codex Glass.app"
archive="$PWD/dist/$package_name.zip"
ditto -c -k --keepParent --norsrc "$package_root" "$archive"
cd dist
shasum -a 256 "$package_name.zip" > "$package_name.zip.sha256"
printf 'Packaged: %s\n' "$archive"
