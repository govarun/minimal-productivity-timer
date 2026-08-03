#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
build_dir="$project_dir/.build/release"
app_dir="$project_dir/dist/Bell.app"
icon_png="$project_dir/.build/BellIcon.png"
iconset="$project_dir/.build/Bell.iconset"

cd "$project_dir"
swift build -c release

rm -rf "$app_dir"
mkdir -p "$app_dir/Contents/MacOS"
cp "$build_dir/Bell" "$app_dir/Contents/MacOS/Bell"

mkdir -p "$app_dir/Contents/Resources"
swift "$project_dir/Scripts/make-icon.swift" "$icon_png"
rm -rf "$iconset"
mkdir -p "$iconset"
sips -z 16 16 "$icon_png" --out "$iconset/icon_16x16.png" >/dev/null
sips -z 32 32 "$icon_png" --out "$iconset/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$icon_png" --out "$iconset/icon_32x32.png" >/dev/null
sips -z 64 64 "$icon_png" --out "$iconset/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$icon_png" --out "$iconset/icon_128x128.png" >/dev/null
sips -z 256 256 "$icon_png" --out "$iconset/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$icon_png" --out "$iconset/icon_256x256.png" >/dev/null
sips -z 512 512 "$icon_png" --out "$iconset/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$icon_png" --out "$iconset/icon_512x512.png" >/dev/null
cp "$icon_png" "$iconset/icon_512x512@2x.png"
iconutil -c icns "$iconset" -o "$app_dir/Contents/Resources/AppIcon.icns"

plutil -create xml1 "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string Bell" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Bell" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string app.minimalistic.productivityoverlay" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string Bell" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 14.0" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$app_dir/Contents/Info.plist"

xattr -cr "$app_dir"
codesign --force --deep --sign - "$app_dir"
xattr -d com.apple.FinderInfo "$app_dir" 2>/dev/null || true
xattr -d 'com.apple.fileprovider.fpfs#P' "$app_dir" 2>/dev/null || true
codesign --verify --deep --strict "$app_dir"
echo "$app_dir"
