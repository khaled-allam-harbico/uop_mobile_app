import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/app_config.dart';
import '../services/permission_service.dart';
import '../services/navigation_service.dart';
import '../services/plugin_health_service.dart';
import '../widgets/error_screen.dart';
import '../widgets/loading_screen.dart';
import '../widgets/permission_loading_screen.dart';
import '../controllers/webview_controller.dart';
import '../managers/connectivity_manager.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _progress = 0;
  String? _errorMessage;
  bool _permissionsGranted = false;
  bool _isConnected = true;
  String _currentUrl = AppConfig.baseUrl;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  final PermissionService _permissionService = PermissionService();
  final NavigationService _navigationService = NavigationService();
  final WebViewController _webViewCtrl = WebViewController();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupConnectivityListener();
    _setFullScreenMode();
    _loadInitialUrl();

    // Fallback: Force proceed after 15 seconds if still stuck
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && !_permissionsGranted) {
        if (kDebugMode) {
          print('Fallback: Forcing app to proceed after timeout');
        }
        setState(() {
          _permissionsGranted = true;
        });
      }
    });
  }

  void _setFullScreenMode() {
    if (AppConfig.enableFullScreen) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );

      // Disable system navigation gestures
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    }
  }

  void _exitFullScreenMode() {
    if (AppConfig.enableFullScreen) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  /// Load the initial URL (either saved or default)
  Future<void> _loadInitialUrl() async {
    try {
      final initialUrl = await _navigationService.getInitialUrl();
      setState(() {
        _currentUrl = initialUrl;
      });
      if (kDebugMode) {
        print('Loading initial URL: $initialUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading initial URL: $e');
      }
      setState(() {
        _currentUrl = AppConfig.baseUrl;
      });
    }
  }

  Future<void> _initializeApp() async {
    try {
      if (kDebugMode) {
        print('Starting permission request...');
      }

      // Check plugin health first
      final isPluginHealthy =
          await PluginHealthService.checkInAppWebViewHealth();
      if (!isPluginHealthy) {
        setState(() {
          _errorMessage =
              'WebView plugin initialization failed. Please restart the application.';
        });
        return;
      }

      // Request permissions with timeout
      final permissionsGranted = await _permissionService
          .requestAllPermissions()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              if (kDebugMode) {
                print('Permission request timed out - continuing anyway');
              }
              return true; // Allow app to continue even if permissions timeout
            },
          );

      if (kDebugMode) {
        print('Permission request completed: $permissionsGranted');
      }

      // Always set permissions as granted to allow the app to continue
      // The WebView will handle permission requests as needed
      setState(() {
        _permissionsGranted = true;
      });

      if (kDebugMode) {
        print('App initialization completed - proceeding to WebView');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Permission request failed: $e');
      }
      setState(() {
        _errorMessage = 'Failed to request permissions: $e';
        // Set permissions as granted anyway to allow the app to continue
        _permissionsGranted = true;
      });
    }
  }

  void _setupConnectivityListener() {
    _connectivityManager.setupConnectivityListener((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });

      if (!isConnected) {
        setState(() {
          _errorMessage =
              'No internet connection. Please check your network settings.';
        });
      } else if (_errorMessage?.contains('internet connection') == true) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  void _handleWebViewError(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceError error,
  ) {
    if (AppConfig.enableConsoleLogging) {
      debugPrint('WebView error: ${error.description}');
      debugPrint('Error code: ${error.type}');
      debugPrint('Request URL: ${request.url}');
      debugPrint('Request method: ${request.method}');
      debugPrint('Error type: ${error.type}');
    }

    // Handle MissingPluginException specifically
    if (error.description.contains('MissingPluginException') ||
        error.description.contains(
          'No implementation found for method evaluateJavascript',
        )) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'WebView plugin initialization error. Please restart the application.';
      });
      return;
    }

    String errorMessage = 'Failed to load the application.';

    // Provide more specific error messages based on error description
    if (error.description.contains('net::ERR_NAME_NOT_RESOLVED') ||
        error.description.contains('DNS')) {
      errorMessage =
          'DNS error: Unable to resolve server address. Please check your internet connection.';
    } else if (error.description.contains('timeout') ||
        error.description.contains('TIMEOUT')) {
      errorMessage =
          'Connection timeout: The server is taking too long to respond. Please try again.';
    } else if (error.description.contains('ERR_CONNECTION_REFUSED') ||
        error.description.contains('ERR_CONNECTION_TIMED_OUT')) {
      errorMessage =
          'Connection failed: Unable to establish connection to the server.';
    } else if (error.description.contains('ERR_SSL_PROTOCOL_ERROR') ||
        error.description.contains('SSL')) {
      errorMessage =
          'SSL/HTTPS error: There was a problem with the secure connection. Please try again.';
    } else if (error.description.contains('ERR_INTERNET_DISCONNECTED')) {
      errorMessage =
          'No internet connection detected. Please check your network settings and try again.';
    } else {
      errorMessage =
          'Failed to load the application. Error: ${error.description}';
    }

    setState(() {
      _isLoading = false;
      _errorMessage = errorMessage;
    });
  }

  void _handleLoadStart(InAppWebViewController controller, Uri? url) {
    setState(() {
      _isLoading = true;
      _progress = 0;
      _errorMessage = null;
    });

    // Add timeout for loading - increased for simulator and slower connections
    // Also add progressive timeout checks
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _isLoading) {
        if (kDebugMode) {
          print('Warning: Page taking longer than 30 seconds to load');
        }
        // Don't show error yet, just log warning
      }
    });

    Future.delayed(const Duration(seconds: 60), () {
      if (mounted && _isLoading) {
        if (kDebugMode) {
          print('Warning: Page taking longer than 60 seconds to load');
        }
        // Still don't show error, just log warning
      }
    });

    Future.delayed(const Duration(seconds: 90), () async {
      if (mounted && _isLoading) {
        if (kDebugMode) {
          print(
            'Error: Page taking longer than 90 seconds to load - checking server connectivity',
          );
        }

        // Test server connectivity before showing timeout error
        final serverReachable = await _connectivityManager
            .testServerConnectivity();

        setState(() {
          _isLoading = false;
          if (!serverReachable) {
            _errorMessage =
                'Server is currently unavailable. Please try again later or contact support if the problem persists.';
          } else {
            _errorMessage = _retryCount >= _maxRetries
                ? 'Loading timeout: The application is taking too long to load after multiple attempts. Please check your internet connection and try again.'
                : 'Loading timeout: The application is taking too long to load. Please check your internet connection and try again.';
          }
        });
      }
    });
  }

  void _handleLoadStop(InAppWebViewController controller, Uri? url) {
    setState(() {
      _isLoading = false;
    });

    // Reset retry count on successful load
    _retryCount = 0;

    // Update current URL
    if (url != null) {
      setState(() {
        _currentUrl = url.toString();
      });
    }

    // Handle page load completion
    _webViewCtrl.handleLoadStop(url);
  }

  void _handleProgressChanged(InAppWebViewController controller, int progress) {
    setState(() {
      _progress = progress / 100;
    });
  }

  void _handleReload() {
    // Check if we've exceeded max retries
    if (_retryCount >= _maxRetries) {
      if (kDebugMode) {
        print('Maximum retries exceeded, resetting retry count');
      }
      _retryCount = 0;
    }

    // Clear error state and restart loading
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progress = 0;
    });

    // Check connectivity before reloading
    _checkConnectivityAndReload();
  }

  /// Check connectivity and reload with appropriate handling
  Future<void> _checkConnectivityAndReload() async {
    try {
      final isConnected = await _connectivityManager.checkConnectivity();

      if (!isConnected) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No internet connection detected. Please check your network settings and try again.';
        });
        return;
      }

      // Increment retry count
      _retryCount++;

      if (kDebugMode) {
        print('Retry attempt $_retryCount of $_maxRetries');
      }

      // If connected, proceed with reload
      if (_webViewController != null) {
        try {
          await _webViewController!.reload();
        } catch (reloadError) {
          if (kDebugMode) {
            print('Error during reload: $reloadError');
          }
          // Fallback: reload the initial URL
          setState(() {
            _currentUrl = AppConfig.baseUrl;
          });
        }
      } else {
        // If WebView controller is null, reload the initial URL
        setState(() {
          _currentUrl = AppConfig.baseUrl;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during connectivity check: $e');
      }
      // Proceed with reload anyway
      if (_webViewController != null) {
        try {
          await _webViewController!.reload();
        } catch (reloadError) {
          if (kDebugMode) {
            print('Error during reload fallback: $reloadError');
          }
          // Fallback: reload the initial URL
          setState(() {
            _currentUrl = AppConfig.baseUrl;
          });
        }
      } else {
        setState(() {
          _currentUrl = AppConfig.baseUrl;
        });
      }
    }
  }

  /// Handle back button navigation
  Future<bool> _handleBackButton() async {
    if (_webViewController != null) {
      final canGoBack = await _webViewController!.canGoBack();
      if (canGoBack) {
        _webViewController!.goBack();
        return false; // Prevent default back behavior
      }
    }

    // If no history, ask user if they want to exit
    final shouldExit = await _showExitConfirmationDialog();
    return shouldExit;
  }

  /// Show exit confirmation dialog
  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Exit App',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Are you sure you want to exit the application?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Exit',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed
  }

  /// Clear saved URL and return to login page
  Future<void> _clearSavedUrlAndReload() async {
    // Reset retry count when resetting to login
    _retryCount = 0;

    // Clear error state and restart loading
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progress = 0;
    });

    await _navigationService.clearSavedUrl();
    setState(() {
      _currentUrl = AppConfig.baseUrl;
    });

    if (_webViewController != null) {
      _webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(AppConfig.baseUrl)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(backgroundColor: Colors.black, body: _buildMainContent()),
    );
  }

  Widget _buildMainContent() {
    // Only show permission loading screen in debug mode
    if (!_permissionsGranted && kDebugMode) {
      if (kDebugMode) {
        print(
          'Showing permission loading screen - _permissionsGranted: $_permissionsGranted',
        );
      }
      return const PermissionLoadingScreen();
    }

    if (_errorMessage != null) {
      return ErrorScreen(
        errorMessage: _errorMessage!,
        retryCount: _retryCount,
        maxRetries: _maxRetries,
        onRetry: _handleReload,
        onResetToLogin: _clearSavedUrlAndReload,
        onDebugNetwork: () async {
          await _connectivityManager.testNetworkConnectivity(
            currentUrl: _currentUrl,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
          );
          final serverReachable = await _connectivityManager
              .testServerConnectivity();
          if (kDebugMode) {
            print('Server reachable: $serverReachable');
          }
        },
      );
    }

    return Stack(
      children: [
        // Full Screen WebView
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowFileAccess: true,
            allowsInlineMediaPlayback: true,
            mediaPlaybackRequiresUserGesture: false,
            iframeAllow: 'camera; microphone',
            iframeAllowFullscreen: true,
            cacheEnabled: AppConfig.enableCache,
            supportZoom: false,
            useShouldOverrideUrlLoading: true,
            useOnLoadResource: true,
            useHybridComposition: true,
            userAgent: AppConfig.userAgent,
            // Full screen optimizations
            displayZoomControls: false,
            builtInZoomControls: false,
            // Android specific full screen settings
            mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
            safeBrowsingEnabled: false,
            allowContentAccess: true,
            allowUniversalAccessFromFileURLs: true,
            allowFileAccessFromFileURLs: true,
            // Cookie and Storage Settings for Laravel Session Management
            databaseEnabled: AppConfig.enableDatabaseStorage,
            domStorageEnabled: AppConfig.enableDomStorage,
            // Cookie settings
            thirdPartyCookiesEnabled: AppConfig.acceptThirdPartyCookies,
            // JavaScript storage settings
            javaScriptCanOpenWindowsAutomatically: true,
            // Cache settings for better performance
            cacheMode: CacheMode.LOAD_DEFAULT,
            // Network settings for better connectivity
            loadsImagesAutomatically: true,
            blockNetworkImage: false,
            blockNetworkLoads: false,
            // External link and redirect settings
            supportMultipleWindows: true,
          ),
          onWebViewCreated: (controller) {
            try {
              _webViewController = controller;
              _webViewCtrl.setController(controller);
              if (kDebugMode) {
                print('WebView controller created successfully');
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error creating WebView controller: $e');
              }
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'Failed to initialize WebView. Please restart the application.';
              });
            }
          },
          onPermissionRequest: _webViewCtrl.handlePermissionRequest,
          onCreateWindow: _webViewCtrl.handleCreateWindow,
          onLoadStart: _handleLoadStart,
          onLoadStop: _handleLoadStop,
          onProgressChanged: _handleProgressChanged,
          onReceivedError: _handleWebViewError,
          onReceivedHttpError: (controller, request, errorResponse) {
            if (AppConfig.enableConsoleLogging) {
              debugPrint('HTTP Error: ${errorResponse.reasonPhrase}');
            }
            setState(() {
              _isLoading = false;
              _errorMessage = 'Server error: ${errorResponse.reasonPhrase}';
            });
          },
          shouldOverrideUrlLoading: _webViewCtrl.handleUrlLoading,
        ),

        // Loading indicator overlay
        if (_isLoading) LoadingScreen(progress: _progress),
      ],
    );
  }

  @override
  void dispose() {
    _exitFullScreenMode();
    _webViewController?.dispose();
    _connectivityManager.dispose();
    _webViewCtrl.dispose();
    super.dispose();
  }
}
