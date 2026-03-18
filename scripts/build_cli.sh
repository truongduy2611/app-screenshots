#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────
# build_cli.sh — Compile the appshots CLI to a native binary
# Usage:
#   ./scripts/build_cli.sh
#
# Output:
#   appshots-{version}-macos-arm64.tar.gz (in project root)
# ─────────────────────────────────────────────────────────────────

CLI_DIR="packages/app_screenshots_cli"
VERSION=$(grep '^version:' "$CLI_DIR/pubspec.yaml" | sed 's/version: //')
ARCH=$(uname -m)
BINARY_NAME="appshots"
TARBALL_NAME="appshots-${VERSION}-macos-${ARCH}.tar.gz"

echo "╔══════════════════════════════════════════════════╗"
echo "║  App Screenshots CLI — Build Native Binary       ║"
echo "║  Version: $VERSION"
echo "║  Arch:    $ARCH"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Get dependencies ─────────────────────────────────────
echo "📦 Getting dependencies..."
(cd "$CLI_DIR" && dart pub get)
echo "   ✅ Dependencies resolved"
echo ""

# ── Step 2: Compile to native binary ─────────────────────────────
echo "🔨 Compiling to native binary..."
dart compile exe "$CLI_DIR/bin/appshots.dart" -o "$BINARY_NAME"
echo "   ✅ Compiled: $BINARY_NAME ($(du -h "$BINARY_NAME" | cut -f1))"
echo ""

# ── Step 3: Package as tarball ────────────────────────────────────
echo "📦 Creating tarball: $TARBALL_NAME"
tar -czf "$TARBALL_NAME" "$BINARY_NAME"
rm "$BINARY_NAME"

# Print SHA256 for Homebrew formula
SHA256=$(shasum -a 256 "$TARBALL_NAME" | cut -d' ' -f1)
echo "   ✅ Tarball created: $TARBALL_NAME ($(du -h "$TARBALL_NAME" | cut -f1))"
echo ""

# ── Done ──────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════╗"
echo "║  ✅ CLI build complete!                          ║"
echo "║                                                  ║"
echo "║  Output:  $TARBALL_NAME"
echo "║  SHA256:  $SHA256"
echo "║                                                  ║"
echo "║  Update the Homebrew formula with this SHA256:   ║"
echo "║  homebrew-tap/Formula/appshots.rb                ║"
echo "╚══════════════════════════════════════════════════╝"
