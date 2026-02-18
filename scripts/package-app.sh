#!/bin/bash
set -euo pipefail

# Build a .app bundle from the Swift Package Manager executable
# Usage: ./scripts/package-app.sh [release|debug]

CONFIG="${1:-release}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="MinimalTimecard"
APP_BUNDLE="$PROJECT_DIR/build/${APP_NAME}.app"

echo "Building ${APP_NAME} (${CONFIG})..."

if [ "$CONFIG" = "release" ]; then
    swift build -c release --package-path "$PROJECT_DIR"
    BINARY_PATH="$PROJECT_DIR/.build/release/${APP_NAME}"
else
    swift build -c debug --package-path "$PROJECT_DIR"
    BINARY_PATH="$PROJECT_DIR/.build/debug/${APP_NAME}"
fi

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp "$PROJECT_DIR/Sources/MinimalTimecard/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "App bundle created at: $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "To zip:  cd $PROJECT_DIR/build && zip -r ${APP_NAME}.zip ${APP_NAME}.app"
