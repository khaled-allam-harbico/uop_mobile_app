import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() async {
  print('Generating app icons...');

  // Generate Android icons
  await generateAndroidIcons();

  // Generate iOS icons
  await generateIOSIcons();

  print('App icons generated successfully!');
}

Future<void> generateAndroidIcons() async {
  final androidDir = 'android/app/src/main/res';
  final sizes = {
    'mipmap-hdpi': 72,
    'mipmap-mdpi': 48,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in sizes.entries) {
    final dir = '$androidDir/${entry.key}';
    final size = entry.value;

    // Ensure directory exists
    await Directory(dir).create(recursive: true);

    // Generate icon
    final iconData = await generateIcon(size);
    final file = File('$dir/ic_launcher.png');
    await file.writeAsBytes(iconData);

    print('Generated Android icon: $dir/ic_launcher.png (${size}x${size})');
  }
}

Future<void> generateIOSIcons() async {
  final iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final sizes = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  for (final entry in sizes.entries) {
    final filename = entry.key;
    final size = entry.value;

    // Generate icon
    final iconData = await generateIcon(size);
    final file = File('$iosDir/$filename');
    await file.writeAsBytes(iconData);

    print('Generated iOS icon: $iosDir/$filename (${size}x${size})');
  }
}

Future<Uint8List> generateIcon(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

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
  return byteData!.buffer.asUint8List();
}
