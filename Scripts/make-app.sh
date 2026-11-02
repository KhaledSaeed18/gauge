#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/Build"
APP_DIR="$BUILD_DIR/Gauge.app"
# "-" signs ad hoc; pass a Developer ID name to sign for distribution.
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

cd "$PROJECT_DIR"
swift build -c release
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$PROJECT_DIR/.build/release/Gauge" "$APP_DIR/Contents/MacOS/Gauge"
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
if [[ -d "$PROJECT_DIR/Resources" ]]; then
  cp -R "$PROJECT_DIR/Resources/." "$APP_DIR/Contents/Resources/"
fi
# Seal the whole bundle: the linker only signs the bare executable, which leaves
# Info.plist and resources unsealed and gives the app the identifier "Gauge"
# instead of its bundle ID, so privacy grants such as Screen Recording do not stick.
codesign --force --sign "$CODE_SIGN_IDENTITY" "$APP_DIR"
echo "Created $APP_DIR"
