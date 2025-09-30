import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request all required permissions for the app
  Future<bool> requestAllPermissions() async {
    try {
      // Request permissions sequentially to avoid conflicts
      final cameraResult = await _requestCameraPermission();
      final microphoneResult = await _requestMicrophonePermission();
      final platformResult = await _requestPlatformSpecificPermissions();

      // Always return true to allow the app to continue
      // Individual permissions will be requested by the WebView as needed
      print(
        'Permission results - Camera: $cameraResult, Microphone: $microphoneResult, Platform: $platformResult',
      );
      return true;
    } catch (e) {
      print('Permission request error: $e');
      // Return true to allow the app to continue even if some permissions fail
      return true;
    }
  }

  /// Request camera permission
  Future<bool> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      print('Camera permission error: $e');
      return false;
    }
  }

  /// Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      print('Microphone permission error: $e');
      return false;
    }
  }

  /// Request platform-specific permissions
  Future<bool> _requestPlatformSpecificPermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      return await _requestIOSPermissions();
    }
    return true;
  }

  /// Request Android-specific permissions
  Future<bool> _requestAndroidPermissions() async {
    try {
      // Request storage permission (for Android < 11)
      final storageStatus = await Permission.storage.request();

      // For Android 11+ (API 30+), manageExternalStorage requires special handling
      // We'll skip this for now as it's not essential for basic functionality
      final bool manageStorageStatus = true;

      // Only try to request manageExternalStorage if we're on Android 11+
      if (Platform.isAndroid) {
        try {
          // Check if we can request this permission
          final status = await Permission.manageExternalStorage.status;
          if (status.isDenied) {
            // For Android 11+, this permission requires manual user action
            // We'll skip it for now and let the app continue
            print(
              'manageExternalStorage permission requires manual setup on Android 11+',
            );
          }
        } catch (e) {
          print('manageExternalStorage permission error: $e');
        }
      }

      return storageStatus.isGranted && manageStorageStatus;
    } catch (e) {
      print('Android permissions error: $e');
      return false;
    }
  }

  /// Request iOS-specific permissions
  Future<bool> _requestIOSPermissions() async {
    try {
      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    } catch (e) {
      print('iOS permissions error: $e');
      return false;
    }
  }

  /// Check if all required permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    try {
      final permissions = [Permission.camera, Permission.microphone];

      if (Platform.isAndroid) {
        permissions.add(Permission.storage);
        // Skip manageExternalStorage for now as it requires manual setup
      } else if (Platform.isIOS) {
        permissions.add(Permission.photos);
      }

      final statuses = await Future.wait(
        permissions.map((permission) => permission.status),
      );

      return statuses.every((status) => status.isGranted);
    } catch (e) {
      print('Permission check error: $e');
      return false;
    }
  }

  /// Get a list of denied permissions
  Future<List<Permission>> getDeniedPermissions() async {
    try {
      final permissions = [Permission.camera, Permission.microphone];

      if (Platform.isAndroid) {
        permissions.add(Permission.storage);
        // Skip manageExternalStorage for now
      } else if (Platform.isIOS) {
        permissions.add(Permission.photos);
      }

      final deniedPermissions = <Permission>[];

      for (final permission in permissions) {
        try {
          final status = await permission.status;
          if (status.isDenied || status.isPermanentlyDenied) {
            deniedPermissions.add(permission);
          }
        } catch (e) {
          print('Error checking permission status: $e');
        }
      }

      return deniedPermissions;
    } catch (e) {
      print('Get denied permissions error: $e');
      return [];
    }
  }

  /// Open app settings if permissions are permanently denied
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }
}
