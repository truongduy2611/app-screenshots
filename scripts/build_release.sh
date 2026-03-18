#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────
# build_release.sh — Build, sign, and package App Screenshots
# Usage:
#   ./scripts/build_release.sh                  # Build + sign + DMG
#   ./scripts/build_release.sh --notarize       # Also notarize with Apple
#   ./scripts/build_release.sh --skip-sign      # Unsigned build (for testing)
# ─────────────────────────────────────────────────────────────────

DISPLAY_NAME="App Screenshots"
BUILD_DIR="build/macos/Build/Products/Release"
ENTITLEMENTS="macos/Runner/Release.entitlements"

# Provisioning profile: set PROV_PROFILE env var, or place in project root
PROV_PROFILE="${PROV_PROFILE:-$(ls ./*.provisionprofile 2>/dev/null | head -1 || echo "")}"

# Parse version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
DMG_NAME="AppScreenshots-${VERSION}-macOS.dmg"

NOTARIZE=false
SKIP_SIGN=false

for arg in "$@"; do
  case $arg in
    --notarize)  NOTARIZE=true ;;
    --skip-sign) SKIP_SIGN=true ;;
    --help|-h)
      echo "Usage: ./scripts/build_release.sh [--notarize] [--skip-sign]"
      echo ""
      echo "  --notarize   Submit to Apple for notarization after building"
      echo "  --skip-sign  Skip code signing (unsigned build)"
      exit 0
      ;;
  esac
done

echo "╔══════════════════════════════════════════════════╗"
echo "║  App Screenshots — Release Build                ║"
echo "║  Version: $VERSION"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Clean & Build ─────────────────────────────────────────
echo "🔨 Building macOS release..."
flutter build macos --release

# Auto-detect the .app bundle name from build output
APP_BUNDLE=$(ls -d "$BUILD_DIR"/*.app 2>/dev/null | head -1)
APP_NAME=$(basename "$APP_BUNDLE")
APP_PATH="$APP_BUNDLE"
echo "   ✅ Build complete: $APP_NAME"
echo ""

# ── Step 2: Sign ──────────────────────────────────────────────────
if [ "$SKIP_SIGN" = false ]; then
  # Auto-detect Developer ID
  IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')

  if [ -z "$IDENTITY" ]; then
    echo "   ⚠️  No Developer ID Application certificate found."
    echo "   Falling back to ad-hoc signing (unsigned)."
    echo ""
    SKIP_SIGN=true
  else
    # Embed provisioning profile
    if [ -f "$PROV_PROFILE" ]; then
      echo "📋 Embedding provisioning profile..."
      cp "$PROV_PROFILE" "$APP_PATH/Contents/embedded.provisionprofile"
    else
      echo "   ⚠️  Provisioning profile not found at $PROV_PROFILE"
      echo "   iCloud entitlements may not work. Falling back to Distribution.entitlements."
      ENTITLEMENTS="macos/Runner/Distribution.entitlements"
    fi

    echo "🔏 Signing with: $IDENTITY"
    codesign --deep --force --options runtime \
      --sign "$IDENTITY" \
      --entitlements "$ENTITLEMENTS" \
      "$APP_PATH"

    # Verify
    codesign --verify --deep --strict "$APP_PATH"
    echo "   ✅ Code signing verified"
    echo ""
  fi
fi

# ── Step 3: Create DMG ────────────────────────────────────────────
echo "📦 Creating DMG: $DMG_NAME"

# Remove old DMG if it exists
rm -f "$DMG_NAME"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
  echo "   Installing create-dmg via Homebrew..."
  brew install create-dmg
fi

create-dmg \
  --volname "$DISPLAY_NAME" \
  --volicon "main-icon.png" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 100 \
  --icon "$APP_NAME" 180 190 \
  --hide-extension "$APP_NAME" \
  --app-drop-link 480 190 \
  "$DMG_NAME" \
  "$APP_PATH"

# Sign the DMG too
if [ "$SKIP_SIGN" = false ]; then
  codesign --force --sign "$IDENTITY" "$DMG_NAME"
fi

echo "   ✅ DMG created: $DMG_NAME"
echo ""

# ── Step 4: Notarize (optional) ──────────────────────────────────
if [ "$NOTARIZE" = true ]; then
  if [ "$SKIP_SIGN" = true ]; then
    echo "   ⚠️  Skipping notarization — app is not signed"
  else
    echo "🍎 Submitting for notarization..."
    echo "   (You may be prompted for your Apple ID credentials)"
    echo ""

    xcrun notarytool submit "$DMG_NAME" \
      --keychain-profile "notarytool-profile" \
      --wait

    xcrun stapler staple "$DMG_NAME"
    echo "   ✅ Notarization complete & stapled"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  ✅ Build complete!                              ║"
echo "║                                                  ║"
echo "║  Output: $DMG_NAME"
echo "║                                                  ║"
echo "║  Next steps:                                     ║"
echo "║  1. Test the DMG — open it and launch the app    ║"
echo "║  2. Create a GitHub Release:                     ║"
echo "║     git tag v$VERSION"
echo "║     git push origin main --tags                  ║"
echo "║  3. Go to GitHub Releases and upload the DMG     ║"
echo "╚══════════════════════════════════════════════════╝"
