# Super Photo Land

Warning: This software is terrible, and NO ONE should be using it for any reason.

A macOS 26+ SwiftUI photo viewer with built-in editing tools.

Version: 0.0.1

This software barely works. Will it ever? Possibly. Should you use it? No. Please have more respect for yourself.

## Overview

This package includes:
- `PhotoEditorCore`: reusable image loading and editing logic
- `PhotoEditorApp`: a SwiftUI macOS app front end for viewing and editing photos

## Requirements

- macOS 26 or later
- Swift 6.3 or later

## Build and Run

```bash
cd photo-project
swift build
swift run SuperPhotoLand
```

To create a clickable macOS app bundle with an icon, run:

```bash
cd photo-project
./package-app.sh
open SuperPhotoLand.app
```

You can also open `SuperPhotoLand.app` in Finder and double-click it after packaging.

You can also open `Package.swift` in Xcode and run the `PhotoEditorApp` target.
If you open the package in Xcode, make sure Xcode is the active developer directory and you have agreed to the Xcode license. Otherwise, use the Swift toolchain directly with:

```bash
cd photo-project
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift build
```