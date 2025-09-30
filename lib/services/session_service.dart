import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../config/app_config.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  InAppWebViewController? _webViewController;
  CookieManager? _cookieManager;

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
    _cookieManager = CookieManager.instance();
    _initializeSessionManagement();
  }

  Future<void> _initializeSessionManagement() async {
    try {
      // Configure cookie manager for Laravel session management
      if (_cookieManager != null) {
        if (AppConfig.enableConsoleLogging) {
          debugPrint('Session service initialized for Laravel');
        }
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error initializing session service: $e');
      }
    }
  }

  Future<void> clearSession() async {
    try {
      if (_cookieManager != null) {
        await _cookieManager!.deleteAllCookies();
        if (AppConfig.enableConsoleLogging) {
          debugPrint('All session cookies cleared');
        }
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error clearing session: $e');
      }
    }
  }

  Future<List<Cookie>> getSessionCookies() async {
    try {
      if (_cookieManager != null) {
        final cookies = await _cookieManager!.getCookies(
          url: WebUri(AppConfig.baseUrl),
        );
        if (AppConfig.enableConsoleLogging) {
          debugPrint('Retrieved ${cookies.length} session cookies');
        }
        return cookies;
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error getting session cookies: $e');
      }
    }
    return [];
  }

  Future<void> injectSessionScript() async {
    try {
      if (_webViewController != null) {
        // Inject JavaScript to ensure localStorage and sessionStorage are enabled
        await _webViewController!.evaluateJavascript(
          source:
              '''
          // Ensure localStorage and sessionStorage are available
          if (typeof localStorage === 'undefined') {
            window.localStorage = {};
          }
          if (typeof sessionStorage === 'undefined') {
            window.sessionStorage = {};
          }
          
          // Log current storage state
          console.log('LocalStorage items:', localStorage.length);
          console.log('SessionStorage items:', sessionStorage.length);
          
          // Ensure cookies are being set properly
          document.cookie = 'laravel_session_test=active; path=/; domain=${Uri.parse(AppConfig.baseUrl).host}';
          
          // Re-inject file upload script to handle dynamically created file inputs
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            console.log('File upload handler available');
          }
          
          // Monitor for logout actions
          const logoutSelectors = [
            'a[href*="logout"]',
            'button[onclick*="logout"]',
            '.logout',
            '#logout',
            '[data-action="logout"]'
          ];
          
          logoutSelectors.forEach(selector => {
            const elements = document.querySelectorAll(selector);
            elements.forEach(element => {
              element.addEventListener('click', function() {
                if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                  window.flutter_inappwebview.callHandler('onLogout');
                }
              });
            });
          });
        ''',
        );

        if (AppConfig.enableConsoleLogging) {
          debugPrint('Session management script injected');
        }
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error injecting session script: $e');
      }
    }
  }

  Future<bool> isUserLoggedIn() async {
    try {
      if (_webViewController != null) {
        // Check if user is logged in by evaluating JavaScript
        final result = await _webViewController!.evaluateJavascript(
          source: '''
          // Check for Laravel session indicators
          const hasLaravelSession = document.cookie.includes('laravel_session');
          const hasAuthToken = document.cookie.includes('XSRF-TOKEN');
          const hasUserData = localStorage.getItem('user') || sessionStorage.getItem('user');
          
          return {
            hasLaravelSession: hasLaravelSession,
            hasAuthToken: hasAuthToken,
            hasUserData: !!hasUserData,
            isLoggedIn: hasLaravelSession && hasAuthToken
          };
        ''',
        );

        if (AppConfig.enableConsoleLogging) {
          debugPrint('Login status check result: $result');
        }

        return result != null && result.toString().contains('true');
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error checking login status: $e');
      }
    }
    return false;
  }

  Future<void> refreshSession() async {
    try {
      if (_webViewController != null) {
        // Refresh the current page to maintain session
        await _webViewController!.reload();

        // Re-inject session management script
        await Future.delayed(const Duration(seconds: 2));
        await injectSessionScript();

        if (AppConfig.enableConsoleLogging) {
          debugPrint('Session refreshed');
        }
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error refreshing session: $e');
      }
    }
  }

  void dispose() {
    _webViewController = null;
    _cookieManager = null;
  }
}
