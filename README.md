# OTime Syria
A clean, minimalist Flutter WebView app for Android that displays the OTime Syria website.

## Features

- **WebView**: Loads https://https://tpm-offers.blogspot.com//
- **Android Back Navigation**: Full support for physical back button navigation through web history
- **Progress Bar**: Thin progress bar at the top (#fb6d0e)
- **Splash Screen**: Displays app logo and version number
- **Clean Design**: Minimalist UI with specified color scheme

## Visual Identity

- **Background Color**: #2c2c2c
- **Accent Color**: #fb6d0e (Progress Bar & Version Text)
- **Text Color**: #efefef
- **Font**: Tajawal (Google Fonts)
- **Icon**: Configured with flutter_launcher_icons

## Requirements

- **Platform**: Android Only
- **minSdkVersion**: 21
- **targetSdkVersion**: 34
- **Package Name**: com.tajdeedpro.mag

## Setup

1. Place your app icon at `assets/icon/icon.png` (1024x1024 PNG recommended)
2. Run `flutter pub get` to install dependencies
3. Run `flutter pub run flutter_launcher_icons:main` to generate app icons
4. Build and run the app

## Build APK

```bash
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`

## GitHub Actions

The project includes a GitHub Actions workflow that automatically builds the Release APK on every push to the main/master branch.

## Dependencies

- `webview_flutter: ^4.4.2` - WebView functionality
- `google_fonts: ^6.1.0` - Tajawal font support
- `flutter_launcher_icons: ^0.13.1` - App icon generation
