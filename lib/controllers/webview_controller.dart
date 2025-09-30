import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../services/session_service.dart';
import '../services/file_upload_service.dart';
import '../services/navigation_service.dart';

class WebViewController {
  InAppWebViewController? _controller;
  final SessionService _sessionService = SessionService();
  final FileUploadService _fileUploadService = FileUploadService();
  final NavigationService _navigationService = NavigationService();

  InAppWebViewController? get controller => _controller;

  void setController(InAppWebViewController controller) {
    _controller = controller;
    _sessionService.setWebViewController(controller);
    _fileUploadService.setWebViewController(controller);
    _fileUploadService.addJavaScriptHandler();
    _addLogoutHandler(controller);
    _addExternalLinkHandler(controller);
    _addTargetBlankHandler(controller);
  }

  /// Add JavaScript handler for logout events
  void _addLogoutHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'onLogout',
      callback: (args) async {
        if (kDebugMode) {
          print('Logout detected, clearing saved URL');
        }
        await _navigationService.clearSavedUrl();
        return {'success': true};
      },
    );
  }

  /// Add JavaScript handler for external links
  void _addExternalLinkHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'handleExternalLink',
      callback: (args) async {
        if (args.isNotEmpty) {
          final url = args[0].toString();
          await _handleExternalLink(url);
        }
        return {'success': true};
      },
    );
  }

  /// Add JavaScript handler for target="_blank" links
  void _addTargetBlankHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'handleTargetBlank',
      callback: (args) async {
        if (args.isNotEmpty) {
          final url = args[0].toString();
          if (AppConfig.enableConsoleLogging) {
            debugPrint('Target="_blank" link detected: $url');
          }
          await _openInExternalBrowser(url);
        }
        return {'success': true};
      },
    );
  }

  /// Handle external links and redirects
  Future<void> _handleExternalLink(String url) async {
    try {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Handling external link: $url');
      }

      // Load the external URL in the same WebView
      if (_controller != null) {
        await _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error handling external link: $e');
      }
    }
  }

  /// Open URL in external browser
  Future<void> _openInExternalBrowser(String url) async {
    try {
      // Use url_launcher to open in external browser
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (AppConfig.enableConsoleLogging) {
          debugPrint('Successfully opened in external browser: $url');
        }
      } else {
        if (AppConfig.enableConsoleLogging) {
          debugPrint('Could not launch URL: $url');
        }
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error opening external browser: $e');
      }
    }
  }

  /// Check if a link has target="_blank" attribute
  Future<bool> checkIfTargetBlank(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    try {
      // Get the clicked element to check for target="_blank"
      final result = await controller.evaluateJavascript(
        source: '''
        (function() {
          var element = document.activeElement;
          if (element && element.tagName === 'A') {
            return element.getAttribute('target') === '_blank';
          }
          return false;
        })();
      ''',
      );

      return result == 'true';
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error checking target="_blank": $e');
      }
      return false;
    }
  }

  /// Inject JavaScript to detect target="_blank" links
  void injectTargetBlankDetection(InAppWebViewController controller) {
    controller.evaluateJavascript(
      source: '''
      (function() {
        // Store original click handlers
        var originalClickHandlers = new Map();

        // Function to handle target="_blank" links
        function handleTargetBlankClick(event) {
          var link = event.target.closest('a');
          if (link && link.getAttribute('target') === '_blank') {
            event.preventDefault();
            event.stopPropagation();

            // Send the URL to Flutter
            window.flutter_inappwebview.callHandler('handleTargetBlank', link.href);
            return false;
          }
        }

        // Add click listener to document
        document.addEventListener('click', handleTargetBlankClick, true);

        // Also handle window.open calls
        var originalWindowOpen = window.open;
        window.open = function(url, target, features) {
          if (target === '_blank' || target === 'blank') {
            window.flutter_inappwebview.callHandler('handleTargetBlank', url);
            return null;
          }
          return originalWindowOpen.call(this, url, target, features);
        };
      })();
    ''',
    );
  }

  /// Handle page load completion
  Future<void> handleLoadStop(Uri? url) async {
    // Save the final URL after page loads
    if (url != null) {
      await _navigationService.saveUrlIfValid(url.toString());
    }

    // Inject session management script after page loads
    _sessionService.injectSessionScript();

    // Re-inject file upload script for new pages
    _fileUploadService.reinjectFileUploadScript();

    // Inject target="_blank" detection script
    if (_controller != null) {
      injectTargetBlankDetection(_controller!);
    }
  }

  /// Handle permission requests
  Future<PermissionResponse> handlePermissionRequest(
    InAppWebViewController controller,
    PermissionRequest request,
  ) async {
    return PermissionResponse(
      resources: request.resources,
      action: PermissionResponseAction.GRANT,
    );
  }

  /// Handle create window requests
  Future<bool> handleCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction createWindowRequest,
  ) async {
    // Allow all new window requests to handle external links properly
    return true;
  }

  /// Handle URL loading
  Future<NavigationActionPolicy> handleUrlLoading(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    // Allow all navigation to maintain session state and history
    final url = navigationAction.request.url;
    if (AppConfig.enableConsoleLogging) {
      debugPrint('Navigating to: $url');
      debugPrint('Navigation type: ${navigationAction.navigationType}');
      debugPrint('Is redirect: ${navigationAction.isRedirect}');
    }

    // Check if this is a target="_blank" link
    if (navigationAction.navigationType == NavigationType.LINK_ACTIVATED) {
      // Check if the link has target="_blank" attribute
      final isTargetBlank = await checkIfTargetBlank(
        controller,
        navigationAction,
      );
      if (isTargetBlank) {
        if (AppConfig.enableConsoleLogging) {
          debugPrint('Opening target="_blank" link in external browser: $url');
        }
        // Open in external browser
        await _openInExternalBrowser(url.toString());
        return NavigationActionPolicy
            .CANCEL; // Cancel the navigation in WebView
      }
    }

    // Always allow navigation to any domain/link
    // This ensures redirects are followed and history is maintained
    if (url != null) {
      // Save the URL for restoration (but don't restrict navigation)
      await _navigationService.saveUrlIfValid(url.toString());
    }

    // Check if cookies are being maintained
    await _sessionService.getSessionCookies();

    // Allow all navigation including redirects and external domains
    // This includes HTTP, HTTPS, and other protocols
    return NavigationActionPolicy.ALLOW;
  }

  void dispose() {
    _controller?.dispose();
    _sessionService.dispose();
    _fileUploadService.dispose();
  }
}
