#!/bin/bash
set -euo pipefail

# PCの下の力持ち.app を生成して ~/Applications にインストールする。
# Spotlight から「PCの下の力持ち」で起動できるようになる。

cd "$(dirname "$0")"

BUNDLE_NAME="PCの下の力持ち.app"
BINARY_NAME="PCNoShitaNoChikaramochi"
BUILD_OUT=".build/arm64-apple-macosx/release"
APP_BUILD_DIR="build"
APP_PATH="$APP_BUILD_DIR/$BUNDLE_NAME"
INSTALL_DIR="$HOME/Applications"

echo "==> Build (release)"
swift build -c release

echo "==> Compose .app bundle"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp "$BUILD_OUT/$BINARY_NAME" "$APP_PATH/Contents/MacOS/$BINARY_NAME"

cat > "$APP_PATH/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>ja</string>
    <key>CFBundleDisplayName</key>
    <string>PCの下の力持ち</string>
    <key>CFBundleExecutable</key>
    <string>PCNoShitaNoChikaramochi</string>
    <key>CFBundleIdentifier</key>
    <string>com.kondo.pc-no-shita-no-chikaramochi</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>PCの下の力持ち</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "==> Ad-hoc codesign"
codesign --force --deep --sign - "$APP_PATH"

echo "==> Install to $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$BUNDLE_NAME"
cp -R "$APP_PATH" "$INSTALL_DIR/$BUNDLE_NAME"

echo "==> Refresh Spotlight index"
mdimport "$INSTALL_DIR/$BUNDLE_NAME" || true

echo
echo "Installed: $INSTALL_DIR/$BUNDLE_NAME"
echo "Spotlight で「PCの下の力持ち」と入力 → ⏎ で起動できます。"
