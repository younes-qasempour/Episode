# Android Build & Environment Documentation

## Overview
This document outlines the environment configuration, build procedures, and
security policies for building Episode Android artifacts. The checked-out
folder may still be named `OtakuLog-mobile`; that repository-folder name is a
legacy stable path, not current product copy.

## Toolchain & Versions
- **Flutter**: 3.44.8 (Channel stable)
- **Dart**: 3.12.2
- **Java JDK**: OpenJDK 21.0.8 (bundled with Android Studio at `C:\Program Files\Andriod\Android Studio\jbr`)
- **Android SDK**: 36.1.0 (Platform android-36, Build Tools 36.1.0)
- **Gradle Wrapper**: 9.1.0
- **Android Gradle Plugin (AGP)**: 9.0.1
- **Kotlin**: 2.3.20
- **Java Compatibility Level**: Java 17

## Security & Cleartext Traffic Policy
- **Debug Builds**: `android:usesCleartextTraffic="true"` is enabled strictly in `android/app/src/debug/AndroidManifest.xml` to allow developer communication with local FastAPI backend servers (`http://10.0.2.2:8000` or local HTTP endpoints).
- **Main / Release Builds**: `android:usesCleartextTraffic` is **disabled** by default in `android/app/src/main/AndroidManifest.xml`. All production network traffic must enforce HTTPS/TLS connections.
- **Permissions**: `android.permission.INTERNET` is configured in `android/app/src/main/AndroidManifest.xml`.

## Episode identity and launcher assets

- The application label is `Episode`, and `MainActivity` is located at
  `android/app/src/main/kotlin/com/example/episode/MainActivity.kt`.
- Android launcher coverage includes legacy square icons, round icons, and
  adaptive foreground/background resources. Pre-Android-12 launch backgrounds
  and Android 12+ splash styles use the same Episode mark and brand navy.
- These raster resources are generated from `tool/brand_sources/` with
  `python tool/generate_brand_assets.py`; regenerate them as a set.
- `com.example.episode` remains a template-grade application ID. A production
  ID and release signing configuration still require owner input.

## Build Artifacts & Output Paths
- **Debug APK**: `build/app/outputs/flutter-apk/app-debug.apk` (Signed with Flutter default debug key).
- **Profile APK**: `build/app/outputs/flutter-apk/app-profile.apk` (Signed with debug key for performance profiling).
- **Release APK**: Production builds require configured release signing keys in `android/app/build.gradle.kts` (or `key.properties`).

## Build Commands
```bash
# Debug APK Build
flutter build apk --debug

# Profile APK Build
flutter build apk --profile

# Release APK Build (Requires signing configuration)
flutter build apk --release
```

## Known Caveats & Troubleshooting
- **Kotlin Gradle Plugin (KGP) Warnings**: `device_info_plus` and `package_info_plus` plugins currently emit KGP migration warnings for future Flutter compatibility.
- **Network Download Errors during Release Build**: Downloading Flutter Engine release binaries (`arm64_v8a_release`) from `storage.googleapis.com` may encounter TLS/Handshake timeouts if network restrictions or proxies block Google storage endpoints.
