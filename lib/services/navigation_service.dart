import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static const String _lastUrlKey = 'last_url';
  static const String _lastUrlTimestampKey = 'last_url_timestamp';
  static const Duration _urlExpiryDuration = Duration(
    hours: 24,
  ); // URLs expire after 24 hours

  /// Save the current URL for later restoration
  Future<void> saveCurrentUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(_lastUrlKey, url);
      await prefs.setInt(_lastUrlTimestampKey, timestamp);

      if (AppConfig.enableConsoleLogging) {
        debugPrint('Saved URL for restoration: $url');
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error saving URL: $e');
      }
    }
  }

  /// Get the last saved URL if it's still valid
  Future<String?> getLastUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUrl = prefs.getString(_lastUrlKey);
      final timestamp = prefs.getInt(_lastUrlTimestampKey);

      if (lastUrl == null || timestamp == null) {
        if (AppConfig.enableConsoleLogging) {
          debugPrint('No saved URL found');
        }
        return null;
      }

      // Check if the URL is still valid (not expired)
      final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(savedTime);

      if (difference > _urlExpiryDuration) {
        if (AppConfig.enableConsoleLogging) {
          debugPrint('Saved URL has expired, clearing');
        }
        await clearSavedUrl();
        return null;
      }

      if (AppConfig.enableConsoleLogging) {
        debugPrint('Restoring URL: $lastUrl');
      }
      return lastUrl;
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error getting last URL: $e');
      }
      return null;
    }
  }

  /// Clear the saved URL
  Future<void> clearSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastUrlKey);
      await prefs.remove(_lastUrlTimestampKey);

      if (AppConfig.enableConsoleLogging) {
        debugPrint('Cleared saved URL');
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error clearing saved URL: $e');
      }
    }
  }

  /// Check if the URL should be saved (exclude certain URLs)
  bool shouldSaveUrl(String url) {
    // Don't save login/logout URLs or error pages
    final excludedPatterns = [
      '/login',
      '/logout',
      '/auth',
      'error',
      '404',
      '500',
    ];

    final lowerUrl = url.toLowerCase();
    for (final pattern in excludedPatterns) {
      if (lowerUrl.contains(pattern)) {
        return false;
      }
    }

    return true;
  }

  /// Get the initial URL to load (either saved URL or default)
  Future<String> getInitialUrl() async {
    final savedUrl = await getLastUrl();
    if (savedUrl != null && shouldSaveUrl(savedUrl)) {
      return savedUrl;
    }
    return AppConfig.baseUrl;
  }

  /// Save URL with validation
  Future<void> saveUrlIfValid(String url) async {
    if (shouldSaveUrl(url)) {
      await saveCurrentUrl(url);
    }
  }
}
