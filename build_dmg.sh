#!/bin/bash

# Build script for Puch macOS app DMG
set -e

APP_NAME="Puch"
BUNDLE_ID="com.yourcompany.puch"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-1.0.dmg"

echo "🏗️  Building $APP_NAME for macOS..."

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the Swift package
echo "📦 Building Swift package..."
swift build -c release

# Create app bundle structure
echo "📱 Creating app bundle..."
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Copy executable
cp ".build/release/$APP_NAME" "$APP_PATH/Contents/MacOS/"

# Copy Info.plist
cp "Info.plist" "$APP_PATH/Contents/"

# Copy entitlements (for reference, not used in unsigned build)
cp "Puch.entitlements" "$BUILD_DIR/"

# Set executable permissions
chmod +x "$APP_PATH/Contents/MacOS/$APP_NAME"

echo "✅ App bundle created at: $APP_PATH"

# Create DMG
echo "📀 Creating DMG..."

# Create temporary dmg directory
DMG_DIR="$BUILD_DIR/dmg"
mkdir -p "$DMG_DIR"

# Copy app to dmg directory
cp -R "$APP_PATH" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_DIR" -ov -format UDZO "$BUILD_DIR/$DMG_NAME"

echo "🎉 DMG created successfully: $BUILD_DIR/$DMG_NAME"
echo ""
echo "📋 Next steps:"
echo "1. Test the app by double-clicking the DMG and dragging to Applications"
echo "2. For distribution, you'll need to:"
echo "   - Sign the app with a Developer ID certificate"
echo "   - Notarize the app with Apple"
echo "   - Update the bundle identifier in Info.plist"
echo ""
echo "⚠️  Note: This is an unsigned build. Users may see security warnings." 