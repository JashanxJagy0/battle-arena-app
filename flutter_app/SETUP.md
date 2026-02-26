# Battle Arena — Flutter App Setup

## Prerequisites

- **Flutter SDK** 3.x (with Dart ≥ 3.0.0)
- **Android SDK** (API level 34 recommended)
- **JDK 17** (required for Gradle 8.x)

Verify your setup:

```bash
flutter doctor
```

## Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project (or use an existing one).
2. Add an Android app with package name `com.battlearena.app`.
3. Download the generated `google-services.json` file.
4. Copy it to `android/app/google-services.json`:

```bash
cp /path/to/downloaded/google-services.json android/app/google-services.json
```

> **Note:** A placeholder file is provided at `android/app/google-services.json.example`. The real `google-services.json` is gitignored to prevent accidental commits of secrets.

## Fonts

Placeholder font files are included for `Orbitron`. For production quality, download the Orbitron font family from [Google Fonts](https://fonts.google.com/specimen/Orbitron) and replace:

- `assets/fonts/Orbitron-Regular.ttf`
- `assets/fonts/Orbitron-Bold.ttf`

The `google_fonts` package is also included as a dependency and can load Orbitron at runtime as a fallback.

## Environment Configuration

API and WebSocket URLs are configured via compile-time environment variables. Defaults point to the Android emulator localhost (`10.0.2.2:3000`).

To override at build time:

```bash
flutter build apk --dart-define=API_BASE_URL=https://your-api.example.com/api/v1 \
                   --dart-define=WS_BASE_URL=https://your-api.example.com
```

## Build Commands

### Install dependencies

```bash
flutter pub get
```

### Build debug APK

```bash
flutter build apk --debug
```

### Build release APK (single fat APK)

```bash
flutter build apk --release
```

### Build release APK split by ABI (recommended for distribution)

```bash
flutter build apk --release --split-per-abi
```

This produces separate, smaller APKs for `arm64-v8a` and `armeabi-v7a`.

## Signing Configuration for Release Builds

For signed release builds, create a keystore and pass the signing properties:

1. Generate a keystore (if you don't have one):

```bash
keytool -genkey -v -keystore ~/battle-arena-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias battle-arena
```

2. Build with signing properties:

```bash
flutter build apk --release \
  -PRELEASE_STORE_FILE=$HOME/battle-arena-release.jks \
  -PRELEASE_STORE_PASSWORD=your_store_password \
  -PRELEASE_KEY_ALIAS=battle-arena \
  -PRELEASE_KEY_PASSWORD=your_key_password
```

Or add these properties to `android/key.properties` (this file is gitignored):

```properties
RELEASE_STORE_FILE=/path/to/keystore.jks
RELEASE_STORE_PASSWORD=your_store_password
RELEASE_KEY_ALIAS=battle-arena
RELEASE_KEY_PASSWORD=your_key_password
```

> **Security:** Never commit signing credentials. The `key.properties` file is already listed in `.gitignore`.
