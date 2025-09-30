# UOP Application - Flutter WebView App

A Flutter application that provides a full-screen WebView experience for the UOP (University of Peshawar) application.

## Project Structure

The project has been refactored into a modular structure for better maintainability and code organization:

```
lib/
├── main.dart                    # Entry point - simplified app initialization
├── config/
│   └── app_config.dart         # Application configuration and constants
├── controllers/
│   └── webview_controller.dart # WebView-specific logic and JavaScript handlers
├── managers/
│   └── connectivity_manager.dart # Network connectivity management
├── pages/
│   ├── webview_page.dart       # Main WebView page component
│   └── icon_generator_page.dart # Icon generator utility
├── services/
│   ├── connectivity_service.dart # Network connectivity monitoring
│   ├── file_upload_service.dart # File upload handling
│   ├── navigation_service.dart  # URL navigation and persistence
│   ├── permission_service.dart  # Device permissions management
│   └── session_service.dart     # Session management and cookies
├── widgets/
│   ├── error_screen.dart       # Error display widget
│   ├── loading_screen.dart     # Loading indicator widget
│   └── permission_loading_screen.dart # Permission request screen
└── utils/                      # Utility functions and helpers
```

## Key Features

### 1. **Modular Architecture**

-   **Controllers**: Handle specific functionality (WebView, connectivity)
-   **Managers**: Coordinate between services and UI
-   **Services**: Core business logic and external integrations
-   **Widgets**: Reusable UI components
-   **Pages**: Main application screens

### 2. **Enhanced Error Handling**

-   Progressive timeout checks (30s, 60s, 90s warnings)
-   Server connectivity testing before showing errors
-   Retry mechanism with configurable attempts
-   Different error messages based on failure type

### 3. **Network Management**

-   Real-time connectivity monitoring
-   Server reachability testing
-   Automatic retry with connectivity checks
-   Debug tools for network troubleshooting

### 4. **WebView Features**

-   Full-screen immersive mode
-   JavaScript injection for enhanced functionality
-   External link handling
-   Session management
-   File upload support

## Recent Improvements

### Timeout Error Resolution

-   **Extended timeout duration** from 60s to 90s
-   **Progressive warnings** at 30s and 60s before final error
-   **Server connectivity testing** before showing timeout errors
-   **Retry counter** with maximum of 3 attempts
-   **Better error messages** differentiating network vs server issues

### Code Organization

-   **Separated concerns** into dedicated controllers and managers
-   **Reduced main.dart** from 956 lines to 34 lines
-   **Reusable widgets** for error, loading, and permission screens
-   **Cleaner imports** and better dependency management

## Configuration

Key configuration options in `config/app_config.dart`:

```dart
class AppConfig {
  static const String baseUrl = 'https://dev-uop.harbico.com:8484/login';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const bool enableFullScreen = true;
  static const bool enableCache = true;
  // ... more configuration options
}
```

## Usage

1. **Development**: Run with `flutter run`
2. **Debug Mode**: Use the "Debug Network" button to test connectivity
3. **Error Recovery**: Use "Retry" or "Reset to Login" buttons
4. **Full Screen**: App runs in immersive mode by default

## Error Handling

The app now provides better error handling with:

-   **Progressive timeout warnings** in debug mode
-   **Server connectivity testing** before showing errors
-   **Retry attempt tracking** (shows current retry count)
-   **Different error messages** for network vs server issues
-   **Automatic connectivity checks** before retrying

## Dependencies

-   `flutter_inappwebview`: WebView functionality
-   `connectivity_plus`: Network connectivity monitoring
-   `url_launcher`: External browser handling
-   `shared_preferences`: Local storage for URL persistence

## Contributing

When adding new features:

1. **Controllers**: Add WebView-specific logic to `webview_controller.dart`
2. **Managers**: Add coordination logic to appropriate manager classes
3. **Services**: Add business logic to service classes
4. **Widgets**: Create reusable UI components in the widgets directory
5. **Configuration**: Add new settings to `app_config.dart`

This modular structure makes the codebase more maintainable, testable, and easier to extend with new features.
