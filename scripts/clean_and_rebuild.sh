#!/bin/bash

echo "Cleaning Flutter project..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Cleaning Android build..."
cd android
./gradlew clean
cd ..

echo "Cleaning iOS build (if on macOS)..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    cd ios
    rm -rf build/
    rm -rf Pods/
    rm -rf Podfile.lock
    pod install
    cd ..
fi

echo "Rebuilding project..."
flutter build apk --debug

echo "Clean and rebuild completed!"
