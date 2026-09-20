#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
# Standalone Command Line Tools may not add Swift Testing's framework search path.
frameworks="$(xcode-select -p)/Library/Developer/Frameworks"
if [[ -d "$frameworks/Testing.framework" ]]; then
    swift test --disable-xctest -Xswiftc -F -Xswiftc "$frameworks" \
        -Xlinker -rpath -Xlinker "$frameworks" \
        -Xlinker -rpath -Xlinker "$(xcode-select -p)/Library/Developer/usr/lib"
else
    swift test --disable-xctest
fi
