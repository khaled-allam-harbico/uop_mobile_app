import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('WebView Test')),
        body: const TestWebView(),
      ),
    );
  }
}

class TestWebView extends StatefulWidget {
  const TestWebView({super.key});

  @override
  State<TestWebView> createState() => _TestWebViewState();
}

class _TestWebViewState extends State<TestWebView> {
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            if (_controller != null) {
              try {
                await _controller!.reload();
                print('Reload successful');
              } catch (e) {
                print('Reload failed: $e');
              }
            }
          },
          child: const Text('Test Reload'),
        ),
        Expanded(
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://www.google.com'),
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
              print('WebView created');
            },
            onLoadStop: (controller, url) {
              print('Page loaded: $url');
            },
          ),
        ),
      ],
    );
  }
}
