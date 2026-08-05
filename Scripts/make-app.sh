#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/Build"
APP_DIR="$BUILD_DIR/Gauge.app"

cd "$PROJECT_DIR"
swift build -c release
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$PROJECT_DIR/.build/release/Gauge" "$APP_DIR/Contents/MacOS/Gauge"
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
if [[ -d "$PROJECT_DIR/Resources" ]]; then
  cp -R "$PROJECT_DIR/Resources/." "$APP_DIR/Contents/Resources/"
fi
echo "Created $APP_DIR"
