import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

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
  // Create a new image with the specified size
  final image = img.Image(width: size, height: size);
  
  // Define colors
  final tealGreen = img.ColorRgba8(32, 178, 170, 255); // #20B2AA
  final dodgerBlue = img.ColorRgba8(30, 144, 255, 255); // #1E90FF
  final white = img.ColorRgba8(255, 255, 255, 255);
  
  // Fill with gradient background (teal-green to blue)
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      // Calculate gradient progress from top-left to bottom-right
      final progressX = x / (size - 1);
      final progressY = y / (size - 1);
      final progress = (progressX + progressY) / 2;
      
      // Interpolate between teal-green and blue
      final r = (tealGreen.r + (dodgerBlue.r - tealGreen.r) * progress).round();
      final g = (tealGreen.g + (dodgerBlue.g - tealGreen.g) * progress).round();
      final b = (tealGreen.b + (dodgerBlue.b - tealGreen.b) * progress).round();
      
      final color = img.ColorRgba8(r, g, b, 255);
      image.setPixel(x, y, color);
    }
  }
  
  // Draw receding white oval shapes
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
      final ovalWidth = (size * 0.08 * scale).round();
      final ovalHeight = (size * 0.04 * scale).round();
      
      // Add slight curve to the path
      final curveOffset = (progress - 0.5) * (size * 0.02 * scale);
      final finalY = rowY + curveOffset;
      
      // Draw oval
      drawOval(image, ovalX.round(), finalY.round(), ovalWidth, ovalHeight, white);
    }
  }
  
  // Encode to PNG
  return Uint8List.fromList(img.encodePng(image));
}

void drawOval(img.Image image, int centerX, int centerY, int width, int height, img.Color color) {
  final halfWidth = width ~/ 2;
  final halfHeight = height ~/ 2;
  
  for (int y = centerY - halfHeight; y <= centerY + halfHeight; y++) {
    for (int x = centerX - halfWidth; x <= centerX + halfWidth; x++) {
      // Check if point is inside ellipse
      final dx = (x - centerX) / halfWidth;
      final dy = (y - centerY) / halfHeight;
      final distance = dx * dx + dy * dy;
      
      if (distance <= 1.0 && x >= 0 && x < image.width && y >= 0 && y < image.height) {
        image.setPixel(x, y, color);
      }
    }
  }
}
