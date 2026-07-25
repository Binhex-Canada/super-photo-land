#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f "Resources/AppIcon.icns" && -d "Assets/AppIcon.iconset" ]]; then
  echo "Generating Resources/AppIcon.icns from Assets/AppIcon.iconset..."
  iconutil -c icns Assets/AppIcon.iconset -o Resources/AppIcon.icns
fi

swift build
BIN_DIR=$(swift build --show-bin-path)
EXECUTABLE="$BIN_DIR/SuperPhotoLand"
if [[ ! -x "$EXECUTABLE" ]]; then
  echo "Error: executable not found at $EXECUTABLE"
  exit 1
fi

APP_BUNDLE="$PWD/SuperPhotoLand.app"
CONTENTS="$APP_BUNDLE/Contents"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"
cp "$EXECUTABLE" "$CONTENTS/MacOS/SuperPhotoLand"
chmod +x "$CONTENTS/MacOS/SuperPhotoLand"

cat > "$CONTENTS/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>SuperPhotoLand</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>com.superphotoland.app</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Super Photo Land</string>
  <key>CFBundleDisplayName</key>
  <string>Super Photo Land</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.0.1</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleGetInfoString</key>
  <string>Super Photo Land by Super Cthulhu Software</string>
  <key>NSHumanReadableCopyright</key>
  <string>© 2026 Super Cthulhu Software</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
</dict>
</plist>
EOF

if [[ -f "Resources/AppIcon.icns" ]]; then
  cp "Resources/AppIcon.icns" "$CONTENTS/Resources/"
fi

if [[ -f "Assets/Photos/company-logo.png" ]]; then
  cp "Assets/Photos/company-logo.png" "$CONTENTS/Resources/"
fi

echo "Created or updated $APP_BUNDLE"
if [[ "${1:-}" == "--open" ]]; then
  open "$APP_BUNDLE"
fi
