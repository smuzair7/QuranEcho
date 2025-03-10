# Setting Up Dart SDK in Android Studio

If you're seeing the "Dart SDK is not configured" error in Android Studio, follow these steps:

## Method 1: Through Android Studio UI

1. Open Android Studio
2. Go to File > Settings > Languages & Frameworks > Flutter
3. Set the Flutter SDK path to where you installed Flutter (e.g., C:/flutter/src/flutter)
4. Click "Apply" and "OK"
5. Restart Android Studio

## Method 2: Using the Configure Script

1. Open a terminal in the project root directory
2. Run the following command:
   ```
   dart configure_sdk.dart
   ```
3. Reopen Android Studio

## Method 3: Manual Configuration

If both methods above fail, you can manually set up the SDK:

1. Close Android Studio
2. Create `.idea/libraries` directory if it doesn't exist
3. Create `.idea/libraries/Dart_SDK.xml` file with the correct path to your Dart SDK
4. Reopen Android Studio

## Troubleshooting

If issues persist:

1. Run `flutter doctor` to verify your installation
2. Make sure the Flutter plugin is installed in Android Studio
3. Try invalidating caches (File > Invalidate Caches / Restart)

For more help, visit the Flutter documentation: https://flutter.dev/docs/get-started/editor
