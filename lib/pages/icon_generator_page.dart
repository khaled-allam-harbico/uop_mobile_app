import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../utils/icon_generator.dart';

class IconGeneratorPage extends StatefulWidget {
  const IconGeneratorPage({super.key});

  @override
  State<IconGeneratorPage> createState() => _IconGeneratorPageState();
}

class _IconGeneratorPageState extends State<IconGeneratorPage> {
  bool _isGenerating = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Icon Generator'),
        backgroundColor: const Color(0xFF20B2AA),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview of the icon design
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF20B2AA), // Teal-green
                    Color(0xFF1E90FF), // Dodger blue
                  ],
                ),
              ),
              child: CustomPaint(
                painter: IconPainter(),
                size: const Size(200, 200),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateIcons,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20B2AA),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isGenerating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Generate App Icons',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_status, style: const TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateIcons() async {
    setState(() {
      _isGenerating = true;
      _status = 'Generating app icons...';
    });

    try {
      await IconGenerator.generateAllIcons();
      setState(() {
        _status =
            'App icons generated successfully!\nCheck the temporary directory for the generated files.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error generating icons: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
}

class IconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Create gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF20B2AA), // Teal-green
        const Color(0xFF1E90FF), // Dodger blue
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradientPaint = Paint()..shader = gradient.createShader(rect);

    // Draw background
    canvas.drawRect(rect, gradientPaint);

    // Draw receding white oval shapes
    final ovalPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Create multiple rows of ovals with perspective
    for (int row = 0; row < 5; row++) {
      final rowY = centerY + (row - 2) * (size.height / 8);
      final scale = 1.0 - (row * 0.15); // Scale decreases for perspective
      final ovalCount = 3 + row; // More ovals in back rows

      for (int i = 0; i < ovalCount; i++) {
        final progress = i / (ovalCount - 1);
        final ovalX = centerX + (progress - 0.5) * (size.width * 0.6 * scale);

        // Oval dimensions with perspective
        final ovalWidth = size.width * 0.08 * scale;
        final ovalHeight = size.height * 0.04 * scale;

        // Add slight curve to the path
        final curveOffset = (progress - 0.5) * (size.height * 0.02 * scale);
        final finalY = rowY + curveOffset;

        final ovalRect = Rect.fromCenter(
          center: Offset(ovalX, finalY),
          width: ovalWidth,
          height: ovalHeight,
        );

        canvas.drawOval(ovalRect, ovalPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
