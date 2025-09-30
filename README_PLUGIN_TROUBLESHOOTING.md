# InAppWebView Plugin Troubleshooting Guide

## Issue Description

The error `MissingPluginException(No implementation found for method evaluateJavascript on channel com.pichillilorenzo/flutter_inappwebview_0)` indicates that the Flutter InAppWebView plugin is not properly initialized or has missing native implementations.

## Root Causes

1. **Plugin not properly initialized** - The native plugin implementation is not loaded
2. **Version compatibility issues** - Plugin version may not be compatible with Flutter/Android versions
3. **Build cache issues** - Stale build artifacts causing plugin loading problems
4. **Missing native dependencies** - Required Android/iOS native libraries not properly linked

## Solutions Implemented

### 1. Enhanced Plugin Initialization

-   Added proper plugin health checks in `PluginHealthService`
-   Implemented graceful error handling for plugin initialization failures
-   Added fallback mechanisms when plugins fail to load

### 2. Improved Error Handling

-   Updated `ErrorScreen` widget to handle plugin-specific errors
-   Added specific error messages for plugin initialization issues
-   Implemented recovery options (restart app, clear cache)

### 3. Build Process Improvements

-   Created `clean_and_rebuild.sh` script for complete project cleanup
-   Updated plugin version to more stable release (6.0.0)
-   Added proper error handling in WebView creation

## Troubleshooting Steps

### Step 1: Clean and Rebuild

```bash
cd flutter
./scripts/clean_and_rebuild.sh
```

### Step 2: Check Plugin Health

The app now includes automatic plugin health checks. If the plugin fails to initialize:

1. The app will show a specific error message
2. Use the "Restart App" button to restart the application
3. If the issue persists, use "Clear Cache & Restart"

### Step 3: Manual Plugin Verification

If issues persist, manually verify plugin installation:

```bash
flutter clean
flutter pub get
flutter pub deps
```

### Step 4: Check Android Configuration

Ensure the following are properly configured:

-   `android/app/build.gradle.kts` - Correct minSdk and targetSdk
-   `android/app/src/main/AndroidManifest.xml` - Required permissions
-   `pubspec.yaml` - Correct plugin version

## Error Recovery

### Plugin Initialization Error

-   **Error**: "WebView plugin initialization error. Please restart the application."
-   **Solution**: Use the "Restart App" button in the error screen

### MissingPluginException

-   **Error**: "No implementation found for method evaluateJavascript"
-   **Solution**:
    1. Restart the application
    2. If persistent, clear app cache and restart
    3. As last resort, reinstall the application

### Network-Related Errors

-   **Error**: "Server is currently unavailable"
-   **Solution**:
    1. Check internet connection
    2. Use "Retry" button
    3. Use "Debug Network" for detailed diagnostics

## Prevention Measures

### 1. Plugin Health Monitoring

The app now includes:

-   Automatic plugin health checks on startup
-   Graceful degradation when plugins fail
-   User-friendly error messages with recovery options

### 2. Build Process

-   Regular clean builds to prevent cache issues
-   Version pinning for stable plugin releases
-   Proper error handling in build scripts

### 3. Runtime Monitoring

-   Plugin initialization status tracking
-   Automatic retry mechanisms
-   Fallback error handling

## Additional Notes

### Plugin Version

-   Current version: `flutter_inappwebview: ^6.0.0`
-   This version has been tested for stability
-   Avoid using beta/alpha versions in production

### Android Requirements

-   Minimum SDK: 21
-   Target SDK: Latest stable
-   Required permissions: Internet, Camera, Storage, etc.

### Debugging

Enable debug logging by setting `AppConfig.enableConsoleLogging = true` in `config/app_config.dart`

## Support

If issues persist after following these steps:

1. Check Flutter and plugin GitHub issues
2. Verify Android SDK and build tools versions
3. Test on different devices/emulators
4. Consider downgrading to a known stable plugin version
