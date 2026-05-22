#!/bin/bash
set -euo pipefail

# PCの下の力持ち.app を生成して ~/Applications にインストールする。
# Spotlight から「PCの下の力持ち」で起動できるようになる。

cd "$(dirname "$0")"

BUNDLE_NAME="PCの下の力持ち.app"
BINARY_NAME="PCNoShitaNoChikaramochi"
APP_BUILD_DIR="build"
APP_PATH="$APP_BUILD_DIR/$BUNDLE_NAME"
INSTALL_DIR="$HOME/Applications"

# swift コマンドの存在チェック (Xcode Command Line Tools が必要)
if ! command -v swift >/dev/null 2>&1; then
    echo "ERROR: swift が見つかりません。"
    echo "Xcode Command Line Tools を入れてください:"
    echo "    xcode-select --install"
    exit 1
fi

echo "==> Build (release)"
swift build -c release

# Apple Silicon (arm64) / Intel (x86_64) どちらでも動くよう、SwiftPM が出した
# 実バイナリのパスを動的に取得する
BUILD_OUT="$(swift build -c release --show-bin-path)"

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

# 自分でビルドしたバイナリには quarantine 属性は付かないはずだが、
# 別マシンから持ち込んだ場合のためにクリアしておく
xattr -dr com.apple.quarantine "$INSTALL_DIR/$BUNDLE_NAME" 2>/dev/null || true

echo "==> Refresh Spotlight index"
mdimport "$INSTALL_DIR/$BUNDLE_NAME" || true

echo
echo "Installed: $INSTALL_DIR/$BUNDLE_NAME"
echo
echo "起動方法:"
echo "  Spotlight (⌘+Space) で「PCの下の力持ち」と入力 → ⏎"
echo
echo "初回起動時に「開発元を検証できない」と警告が出たら:"
echo "  Finder で ~/Applications/PCの下の力持ち.app を Control+クリック → 開く"
echo "  または: システム設定 > プライバシーとセキュリティ > 「このまま開く」"
