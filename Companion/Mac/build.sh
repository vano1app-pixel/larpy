#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="$PWD/build/Larpy Desktop.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -parse-as-library -target arm64-apple-macos14.0 -O DesktopDialogue.swift LarpyDesktop.swift -o "$APP/Contents/MacOS/LarpyDesktop" -framework AppKit -framework SwiftUI -framework UserNotifications
cp ../larpy_sync.py "$APP/Contents/Resources/larpy_sync.py"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>LarpyDesktop</string>
<key>CFBundleIdentifier</key><string>com.larpy.desktop</string>
<key>CFBundleName</key><string>Larpy Desktop</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
printf '%s\n' "$APP"
