import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PluginHealthService {
  static bool _isPluginHealthy = false;
  static bool _hasCheckedHealth = false;

  /// Check if the InAppWebView plugin is healthy and properly initialized
  static Future<bool> checkInAppWebViewHealth() async {
    if (_hasCheckedHealth) {
      return _isPluginHealthy;
    }

    try {
      if (Platform.isAndroid) {
        // Test plugin initialization
        await InAppWebViewController.setWebContentsDebuggingEnabled(true);

        // Additional health checks can be added here
        _isPluginHealthy = true;
        if (kDebugMode) {
          print('InAppWebView plugin health check passed');
        }
      } else {
        // For iOS, assume healthy for now
        _isPluginHealthy = true;
      }
    } catch (e) {
      _isPluginHealthy = false;
      if (kDebugMode) {
        print('InAppWebView plugin health check failed: $e');
      }
    }

    _hasCheckedHealth = true;
    return _isPluginHealthy;
  }

  /// Reset health check status (useful for testing)
  static void resetHealthCheck() {
    _hasCheckedHealth = false;
    _isPluginHealthy = false;
  }

  /// Get current plugin health status
  static bool get isPluginHealthy => _isPluginHealthy;

  /// Get whether health has been checked
  static bool get hasCheckedHealth => _hasCheckedHealth;
}
