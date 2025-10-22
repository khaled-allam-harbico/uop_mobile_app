class AppConfig {
  // App Information
  static const String appName = 'UOP Application';
  static const String appVersion = '2.0.0';

  // WebView Configuration
  // static const String baseUrl = 'https://dev-uop.harbico.com:8484';
  // static const String baseUrl = 'https://uop.harbico.com';
  static const String baseUrl = 'https://live-uop.harbico.com';
  static const String userAgent = 'UOP-App/2.0';

  // Cookie and Storage Settings for Laravel Session Management
  static const bool enableCookies = true;
  static const bool enableJavaScriptStorage = true;
  static const bool enableLocalStorage = true;
  static const bool enableSessionStorage = true;
  static const bool enableDatabaseStorage = true;
  static const bool enableDomStorage = true;
  static const bool enableApplicationCache = true;

  // Cookie Settings
  static const bool acceptThirdPartyCookies = true;
  static const bool acceptAllCookies = true;
  static const String cookiePolicy = 'ACCEPT_ALL';

  // Full Screen Settings
  static const bool enableFullScreen = true;
  static const bool hideSystemUI = true;
  static const bool immersiveMode = true;

  // Timeout Settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration readTimeout = Duration(seconds: 30);

  // Cache Settings
  static const bool enableCache = true;
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB

  // Debug Settings
  static const bool enableWebViewDebugging = true;
  static const bool enableConsoleLogging = true;

  // Permission Settings
  static const List<String> requiredPermissions = [
    'camera',
    'microphone',
    'storage',
  ];

  // Platform-specific settings
  static const Map<String, dynamic> platformSettings = {
    'android': {
      'requiresStoragePermission': true,
      'requiresManageExternalStorage': true,
    },
    'ios': {
      'requiresPhotosPermission': true,
      'requiresCameraPermission': true,
      'requiresMicrophonePermission': true,
    },
  };
}
