# QuranEcho

QuranEcho is a Flutter app for Quran memorization practice, recitation review, makharij training, and progress tracking. It includes a Flutter frontend and a small Node.js backend used for login and user stats.

## Project Layout

- `lib/` Flutter app screens, services, and widgets
- `assets/` Quran data, audio, fonts, and images
- `backend/` Node.js API used by the app
- `android/` Flutter Android project files opened by Android Studio or VS Code

## Prerequisites

- Flutter SDK 3.3 or newer
- Dart SDK that matches Flutter
- Android Studio with the Flutter and Dart plugins, or VS Code with Flutter support
- Node.js 18+ for the backend

## Environment Setup

1. Copy [`.env.example`](.env.example) to [`.env`](.env).
2. Fill in your Hugging Face token and API endpoint.
3. Keep [`.env`](.env) uncommitted. It is ignored by git.

The app loads `.env` at startup through `AppConfig`, so the Flutter app will still start if the file is missing, but API features will not work until it is configured.

## Install Dependencies

From the app folder:

```bash
flutter pub get
```

From the backend folder:

```bash
cd backend
npm install
```

## Run the App

### Android device or emulator

1. Start an emulator in Android Studio, or connect a physical device with USB debugging enabled.
2. From the app folder run:

```bash
flutter run
```

### Chrome / web

```bash
flutter run -d chrome
```

### Android Studio

Open the `app/` folder in Android Studio. If Android Studio asks for the Flutter SDK, point it to your Flutter installation. The Android project is already included under `android/`, so there is no separate Android project setup required.

## Start the Backend

The Node backend listens on port `3000`.

```bash
cd backend
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
flutter analyze
flutter test
```

## First-Time Android Studio Fixes

If Android Studio complains that Dart or Flutter is not configured, open the Flutter SDK settings and point it to your installed Flutter folder. The repo already contains the generated Android project, so you only need to open the `app/` directory.
