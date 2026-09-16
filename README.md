# QuranEcho

QuranEcho is a Flutter app for Quran memorization practice, recitation review, makharij training, and progress tracking. It includes a Flutter frontend and a small Node.js backend used for login and user stats.

## Project Layout

- `apps/mobile/` Flutter application, Android project, screens, services, and assets
- `services/api/` Node.js API for authentication and user statistics
- `services/speech/` Optional Python speech-recognition service
- `docs/` Development and IDE setup notes

## Prerequisites

- Flutter SDK 3.3 or newer
- Dart SDK that matches Flutter
- Android Studio with the Flutter and Dart plugins, or VS Code with Flutter support
- Node.js 18+ for the backend

## Environment Setup

1. Copy [`apps/mobile/.env.example`](apps/mobile/.env.example) to `apps/mobile/.env`.
2. Fill in your Hugging Face token and API endpoint.
3. Keep [`.env`](.env) uncommitted. It is ignored by git.

The app loads `.env` at startup through `AppConfig`, so the Flutter app will still start if the file is missing, but API features will not work until it is configured.

## Install Dependencies

From the repository root:

```bash
cd apps/mobile
flutter pub get
```

From the repository root, install the API dependencies:

```bash
cd services/api
npm install
```

## Run the App

### Android device or emulator

1. Start an emulator in Android Studio, or connect a physical device with USB debugging enabled.
2. From the mobile app folder run:

```bash
cd apps/mobile
flutter run
```

### Chrome / web

```bash
cd apps/mobile
flutter run -d chrome
```

### Android Studio

Open the `apps/mobile/` folder in Android Studio. If Android Studio asks for the Flutter SDK, point it to your Flutter installation. The Android project is already included under `apps/mobile/android/`.

## Start the Backend

The Node backend listens on port `3000`.

```bash
cd services/api
npm start
```

The app’s `ApiService` first tries the common local backend URLs:

- `http://10.0.2.2:3000` for Android emulator
- `http://localhost:3000` for desktop or web
- a configured LAN IP for a physical device

## Useful Notes

- Recitation and makharij features call the Hugging Face endpoint configured in `.env`.
- The app uses `shared_preferences` to cache the backend URL it successfully connected to.
- If you change packages or the `.env` file, rerun `flutter pub get` and restart the app.

## Optional Checks

```bash
cd apps/mobile
flutter analyze
flutter test
```

## First-Time Android Studio Fixes

If Android Studio complains that Dart or Flutter is not configured, follow [`docs/android-studio.md`](docs/android-studio.md). Open `apps/mobile/` as the Flutter project.
