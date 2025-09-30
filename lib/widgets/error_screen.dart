import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  final int retryCount;
  final int maxRetries;
  final VoidCallback onRetry;
  final VoidCallback onResetToLogin;
  final VoidCallback onDebugNetwork;

  const ErrorScreen({
    super.key,
    required this.errorMessage,
    required this.retryCount,
    required this.maxRetries,
    required this.onRetry,
    required this.onResetToLogin,
    required this.onDebugNetwork,
  });

  @override
  Widget build(BuildContext context) {
    final isPluginError =
        errorMessage.contains('plugin') ||
        errorMessage.contains('WebView') ||
        errorMessage.contains('MissingPluginException');

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 24),

                // Error Title
                const Text(
                  'Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Error Message
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                if (isPluginError) ...[
                  // Plugin error specific actions
                  _buildButton('Restart App', Colors.blue, () {
                    SystemNavigator.pop();
                  }),
                  const SizedBox(height: 12),
                  _buildButton('Clear Cache & Restart', Colors.orange, () {
                    // This would typically clear app cache
                    SystemNavigator.pop();
                  }),
                ] else ...[
                  // Regular error actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildButton('Retry', Colors.blue, onRetry),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildButton(
                          'Reset to Login',
                          Colors.orange,
                          onResetToLogin,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildButton('Debug Network', Colors.grey, onDebugNetwork),
                ],

                // Retry count indicator
                if (!isPluginError && retryCount > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Retry attempt $retryCount of $maxRetries',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
