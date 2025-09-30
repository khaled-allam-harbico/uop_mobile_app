import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'config/app_config.dart';
import 'pages/webview_page.dart';
import 'services/plugin_health_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    try {
      // Check plugin health before proceeding
      final isPluginHealthy =
          await PluginHealthService.checkInAppWebViewHealth();

      if (!isPluginHealthy) {
        print('Warning: InAppWebView plugin health check failed');
      }

      // Initialize InAppWebView plugin properly
      await InAppWebViewController.setWebContentsDebuggingEnabled(
        AppConfig.enableWebViewDebugging,
      );

      // Additional initialization to ensure plugin is ready
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    } catch (e) {
      // Handle the case where the plugin might not be fully initialized
      print('Warning: Could not enable WebView debugging: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const WebViewPage(),
    );
  }
}
