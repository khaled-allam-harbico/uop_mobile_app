import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';

class FileUploadService {
  static final FileUploadService _instance = FileUploadService._internal();
  factory FileUploadService() => _instance;
  FileUploadService._internal();

  InAppWebViewController? _webViewController;
  final ImagePicker _imagePicker = ImagePicker();

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
    _injectFileUploadScript();
  }

  /// Inject JavaScript to handle file uploads
  Future<void> _injectFileUploadScript() async {
    if (_webViewController == null) return;

    try {
      await _webViewController!.evaluateJavascript(
        source: '''
        // Override file input behavior for better WebView compatibility
        (function() {
          // Store original createElement function
          const originalCreateElement = document.createElement;
          
          // Override createElement to intercept file inputs
          document.createElement = function(tagName) {
            const element = originalCreateElement.call(document, tagName);
            
            if (tagName.toLowerCase() === 'input') {
              // Add event listener when type is set to 'file'
              const originalSetAttribute = element.setAttribute;
              element.setAttribute = function(name, value) {
                originalSetAttribute.call(this, name, value);
                
                if (name === 'type' && value === 'file') {
                  // Add click handler for file inputs
                  element.addEventListener('click', function(e) {
                    // Prevent default behavior
                    e.preventDefault();
                    e.stopPropagation();
                    
                    // Trigger custom file picker
                    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                      window.flutter_inappwebview.callHandler('openFilePicker', {
                        accept: element.accept || '*/*',
                        multiple: element.multiple || false,
                        capture: element.capture || null
                      });
                    }
                  });
                }
              };
            }
            
            return element;
          };
          
          // Override existing file inputs
          const existingFileInputs = document.querySelectorAll('input[type="file"]');
          existingFileInputs.forEach(function(input) {
            input.addEventListener('click', function(e) {
              e.preventDefault();
              e.stopPropagation();
              
              if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                window.flutter_inappwebview.callHandler('openFilePicker', {
                  accept: input.accept || '*/*',
                  multiple: input.multiple || false,
                  capture: input.capture || null
                });
              }
            });
          });
          
          console.log('File upload script injected successfully');
        })();
        ''',
      );

      if (AppConfig.enableConsoleLogging) {
        debugPrint('File upload script injected');
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error injecting file upload script: $e');
      }
    }
  }

  /// Handle file picker request from JavaScript
  Future<dynamic> handleFilePicker(Map<String, dynamic> params) async {
    try {
      final String? accept = params['accept'];
      final bool multiple = params['multiple'] ?? false;
      final String? capture = params['capture'];

      if (AppConfig.enableConsoleLogging) {
        debugPrint(
          'File picker requested - accept: $accept, multiple: $multiple, capture: $capture',
        );
      }

      // Determine source based on capture parameter
      ImageSource source = ImageSource.gallery;
      if (capture == 'camera' || capture == 'environment') {
        source = ImageSource.camera;
      } else if (capture == 'user') {
        source = ImageSource.camera;
      }

      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        if (AppConfig.enableConsoleLogging) {
          debugPrint('Image selected: ${image.path}');
        }

        // Convert image to base64 and inject into file input
        await _injectFileIntoInput(image);
        return {'success': true, 'path': image.path};
      } else {
        if (AppConfig.enableConsoleLogging) {
          debugPrint('No image selected');
        }
        return {'success': false, 'message': 'No image selected'};
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error in file picker: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Inject selected file into the active file input
  Future<void> _injectFileIntoInput(XFile image) async {
    if (_webViewController == null) return;

    try {
      // Read file as bytes
      final Uint8List bytes = await image.readAsBytes();

      // Convert to base64
      final String base64 = base64Encode(bytes);

      // Get file extension
      final String extension = image.path.split('.').last.toLowerCase();

      // Determine MIME type
      String mimeType = 'image/jpeg';
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      }

      // Inject the file into the active file input
      await _webViewController!.evaluateJavascript(
        source:
            '''
        (function() {
          // Find the active file input
          const activeElement = document.activeElement;
          const fileInputs = document.querySelectorAll('input[type="file"]');
          let targetInput = null;
          
          // If active element is a file input, use it
          if (activeElement && activeElement.type === 'file') {
            targetInput = activeElement;
          } else {
            // Otherwise, find the first visible file input
            for (let input of fileInputs) {
              if (input.offsetParent !== null) {
                targetInput = input;
                break;
              }
            }
          }
          
          if (targetInput) {
            // Create a new File object
            const base64Data = '$base64';
            const byteCharacters = atob(base64Data);
            const byteNumbers = new Array(byteCharacters.length);
            for (let i = 0; i < byteCharacters.length; i++) {
              byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            const byteArray = new Uint8Array(byteNumbers);
            
            // Create file with proper name
            const fileName = 'camera_capture_${DateTime.now().millisecondsSinceEpoch}.$extension';
            const file = new File([byteArray], fileName, { type: '$mimeType' });
            
            // Create a new FileList-like object
            const dataTransfer = new DataTransfer();
            dataTransfer.items.add(file);
            
            // Set the files
            targetInput.files = dataTransfer.files;
            
            // Trigger change event
            const event = new Event('change', { bubbles: true });
            targetInput.dispatchEvent(event);
            
            console.log('File injected into input:', fileName);
            return { success: true, fileName: fileName };
          } else {
            console.error('No file input found');
            return { success: false, error: 'No file input found' };
          }
        })();
        ''',
      );

      if (AppConfig.enableConsoleLogging) {
        debugPrint('File injected into input successfully');
      }
    } catch (e) {
      if (AppConfig.enableConsoleLogging) {
        debugPrint('Error injecting file into input: $e');
      }
    }
  }

  /// Add JavaScript handler for file picker
  void addJavaScriptHandler() {
    if (_webViewController == null) return;

    _webViewController!.addJavaScriptHandler(
      handlerName: 'openFilePicker',
      callback: (args) async {
        if (args.isNotEmpty && args[0] is Map) {
          return await handleFilePicker(Map<String, dynamic>.from(args[0]));
        }
        return {'success': false, 'error': 'Invalid parameters'};
      },
    );
  }

  /// Re-inject file upload script for dynamically created inputs
  Future<void> reinjectFileUploadScript() async {
    await _injectFileUploadScript();
  }

  void dispose() {
    _webViewController = null;
  }
}
