import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/app_config.dart';
import '../services/connectivity_service.dart';

class ConnectivityManager {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    await _connectivityService.initialize();
  }

  /// Setup connectivity listener
  void setupConnectivityListener(Function(bool) onConnectivityChanged) {
    _connectivityService.connectionStatus.listen((isConnected) {
      _isConnected = isConnected;
      onConnectivityChanged(isConnected);

      if (kDebugMode) {
        print('Connectivity status changed: $isConnected');
      }
    });
  }

  /// Test network connectivity for simulator debugging
  Future<void> testNetworkConnectivity({
    required String currentUrl,
    required bool isLoading,
    String? errorMessage,
  }) async {
    if (kDebugMode) {
      print('Testing network connectivity...');
      print('Current URL: $currentUrl');
      print('Is connected: $_isConnected');
      print('Is loading: $isLoading');
      print('Error message: $errorMessage');
    }
  }

  /// Test server connectivity
  Future<bool> testServerConnectivity() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(Uri.parse(AppConfig.baseUrl));
      final response = await request.close();

      if (kDebugMode) {
        print('Server connectivity test: ${response.statusCode}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Server connectivity test failed: $e');
      }
      return false;
    }
  }

  /// Check connectivity and return result
  Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await _connectivityService
          .getConnectivityResult();
      final isConnected = connectivityResult != ConnectivityResult.none;

      if (kDebugMode) {
        print('Connectivity check result: $isConnected');
      }

      return isConnected;
    } catch (e) {
      if (kDebugMode) {
        print('Error during connectivity check: $e');
      }
      return false;
    }
  }

  /// Get connection type as string
  String getConnectionType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
    }
  }

  /// Get current connectivity result
  Future<ConnectivityResult> getConnectivityResult() async {
    return await _connectivityService.getConnectivityResult();
  }

  void dispose() {
    _connectivityService.dispose();
  }
}
