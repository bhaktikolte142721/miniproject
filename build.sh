#!/bin/bash
set -e

echo "========================================="
echo "🛡️ SENTINEL-Ward: Vercel Flutter Web Build"
echo "========================================="

# 1. Clone Flutter SDK if not already cached
if [ ! -d "_flutter" ]; then
  echo "📥 Downloading lightweight stable Flutter SDK..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/_flutter/bin"

# 3. Print Flutter Version
flutter --version

# 4. Fetch dependencies and build optimized release web bundle
echo "📦 Installing Flutter dependencies..."
flutter config --enable-web
flutter pub get

echo "🚀 Compiling Flutter Web Release..."
flutter build web --release --no-tree-shake-icons

echo "✅ Build finished successfully! Output directory: build/web"
