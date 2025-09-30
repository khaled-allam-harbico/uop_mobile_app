import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class IconGenerator {
  static Future<void> generateAppIcon({
    required int size,
    required String outputPath,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Create gradient background (teal-green to blue)
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF20B2AA), // Teal-green
        const Color(0xFF1E90FF), // Dodger blue
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    final gradientPaint = Paint()..shader = gradient.createShader(rect);

    // Draw background
    canvas.drawRect(rect, gradientPaint);

    // Draw receding white oval shapes
    final ovalPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Calculate oval parameters for perspective effect
    final centerX = size / 2;
    final centerY = size / 2;

    // Create multiple rows of ovals with perspective
    for (int row = 0; row < 5; row++) {
      final rowY = centerY + (row - 2) * (size / 8);
      final scale = 1.0 - (row * 0.15); // Scale decreases for perspective
      final ovalCount = 3 + row; // More ovals in back rows

      for (int i = 0; i < ovalCount; i++) {
        final progress = i / (ovalCount - 1);
        final ovalX = centerX + (progress - 0.5) * (size * 0.6 * scale);

        // Oval dimensions with perspective
        final ovalWidth = size * 0.08 * scale;
        final ovalHeight = size * 0.04 * scale;

        // Add slight curve to the path
        final curveOffset = (progress - 0.5) * (size * 0.02 * scale);
        final finalY = rowY + curveOffset;

        final ovalRect = Rect.fromCenter(
          center: Offset(ovalX, finalY),
          width: ovalWidth,
          height: ovalHeight,
        );

        canvas.drawOval(ovalRect, ovalPaint);
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    // Save the image
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
  }

  static Future<void> generateAllIcons() async {
    final tempDir = await getTemporaryDirectory();
    final iconDir = Directory('${tempDir.path}/app_icons');
    await iconDir.create(recursive: true);

    // Generate different sizes for Android
    final androidSizes = [48, 72, 96, 144, 192];
    for (final size in androidSizes) {
      await generateAppIcon(
        size: size,
        outputPath: '${iconDir.path}/ic_launcher_${size}.png',
      );
    }

    // Generate different sizes for iOS
    final iosSizes = [20, 29, 40, 60, 76, 83, 1024];
    for (final size in iosSizes) {
      await generateAppIcon(
        size: size,
        outputPath: '${iconDir.path}/ios_icon_${size}.png',
      );
    }

    print('App icons generated in: ${iconDir.path}');
  }
}
