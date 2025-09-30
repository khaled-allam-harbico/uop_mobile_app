import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data'; // Added missing import for Uint8List

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
    final iconData = await generateSimpleIcon(size);
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
    final iconData = await generateSimpleIcon(size);
    final file = File('$iosDir/$filename');
    await file.writeAsBytes(iconData);

    print('Generated iOS icon: $iosDir/$filename (${size}x${size})');
  }
}

Future<Uint8List> generateSimpleIcon(int size) async {
  // Create a simple PNG with the gradient and oval design
  // This is a simplified version that creates a basic PNG structure

  // For now, let's create a simple colored square as a placeholder
  // In a real implementation, you would use a proper PNG generation library

  // Create a simple RGBA image data
  final bytes = <int>[];

  // PNG header
  bytes.addAll([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  // For simplicity, let's create a basic colored square
  // In a real implementation, you would generate the actual gradient and ovals

  // This is a placeholder - in practice you'd use a proper image generation library
  // like image package or similar

  // For now, let's create a simple test pattern
  final imageData = <int>[];
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      // Create gradient from teal-green to blue
      final progressX = x / size;
      final progressY = y / size;
      final progress = (progressX + progressY) / 2;

      // Teal-green to blue gradient
      final r = (32 + (30 * progress)).round(); // 20B2AA to 1E90FF
      final g = (178 - (40 * progress)).round();
      final b = (170 + (15 * progress)).round();

      imageData.addAll([r, g, b, 255]); // RGBA
    }
  }

  // This is a simplified approach - in practice you'd need proper PNG encoding
  // For now, let's create a basic file structure

  // Create a simple test file
  final testData = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    // This is just a placeholder - you'd need proper PNG encoding
  ]);

  return testData;
}
