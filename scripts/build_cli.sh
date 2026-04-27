#!/bin/bash
set -e

# Change directory to the root of the project
cd "$(dirname "$0")/.."

echo "Compiling app_screenshots_cli..."

# Navigate to the CLI package
cd packages/app_screenshots_cli

# Run dart pub get to ensure dependencies are resolved
dart pub get

# Compile the CLI into a standalone executable
dart compile exe bin/appshots.dart -o ../../appshots

# Make sure the executable has execution permissions
chmod +x ../../appshots

echo "Successfully compiled CLI to appshots"
