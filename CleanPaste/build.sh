#!/bin/bash
set -e

APP_NAME="CleanPaste"
BUILD_DIR="$(pwd)/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building $APP_NAME..."

# Build with Swift Package Manager
swift build -c release 2>&1

BINARY=".build/release/$APP_NAME"

if [ ! -f "$BINARY" ]; then
    echo "ERROR: Build failed — binary not found at $BINARY"
    exit 1
fi

# Create .app bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Write Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CleanPaste</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.cleanpaste</string>
    <key>CFBundleName</key>
    <string>CleanPaste</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo ""
echo "Done! App bundle: $APP_BUNDLE"
echo ""
echo "To install:"
echo "  cp -r $APP_BUNDLE /Applications/"
echo "  open /Applications/$APP_NAME.app"
echo ""
echo "On first launch, grant Accessibility permissions:"
echo "  System Settings → Privacy & Security → Accessibility → add CleanPaste"
