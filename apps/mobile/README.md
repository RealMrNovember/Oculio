# Oculio Mobile — Phase 0

Eye-assisted reading prototype for **Android physical devices**.

## Features

- Front camera + ML Kit face detection
- Head pose (pitch / yaw / roll) as gaze proxy
- Eye open probability
- Hybrid auto-scroll (base WPM + pitch boost)
- Smart Pause: no face, head turned, eyes closed
- Debug overlay + mini camera preview

## Prerequisites

1. Flutter SDK at `C:\Users\Captain\flutter` (added to user PATH)
2. Android SDK at `C:\Users\Captain\Android\Sdk` (`ANDROID_HOME`)
3. JDK 17 at `C:\Users\Captain\jdk-17` (`JAVA_HOME`)
4. USB debugging enabled on your **physical** Android phone

## First-time setup

```powershell
cd C:\Users\Captain\CicibyteProjects\Oculio\apps\mobile
```

If Gradle wrapper or launcher icons are missing, regenerate platform scaffolding (keeps your `lib/` code):

```powershell
flutter create . --org com.oculio --project-name oculio_mobile --platforms android
```

Install dependencies:

```powershell
flutter pub get
```

Verify device is visible:

```powershell
flutter devices
```

## Run on Android (debug)

```powershell
cd C:\Users\Captain\CicibyteProjects\Oculio\apps\mobile
flutter run -d android
```

Or pick a specific device ID:

```powershell
flutter devices
flutter run -d <device_id>
```

## Build APK (install manually)

```powershell
flutter build apk --debug
```

APK path:

```
build\app\outputs\flutter-apk\app-debug.apk
```

Install via USB:

```powershell
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

## How to test Phase 0

| Test | Expected |
|------|----------|
| Hold phone at reading distance, face visible | Text scrolls at ~200 WPM |
| Tilt head down slightly | Scroll speed multiplier increases (see debug panel) |
| Turn head left/right sharply | `PAUSED — Look away` |
| Close eyes 1+ sec | `PAUSED — Eyes closed` |
| Cover camera / leave frame | `PAUSED — No face` |
| Tap text | Manual pause / resume |
| WPM slider | Changes base scroll speed |

## Troubleshooting

**Camera permission denied** — Settings → Apps → Oculio → Permissions → Camera

**`flutter.sdk not set in local.properties`** — Run any `flutter` command once; Flutter writes `android/local.properties` automatically.

**ML values stuck at zero** — Ensure good lighting; face the front camera; try `ResolutionPreset.medium` (already set).

**Build fails on minSdk** — Device must be Android 7.0+ (API 24+).

## Project layout

```
lib/
├── main.dart
├── data/sample_text.dart
├── models/tracking_state.dart
├── screens/reading_screen.dart
├── services/
│   ├── face_tracking_service.dart
│   └── flow_scroll_engine.dart
└── utils/camera_image_converter.dart
```

## Next steps (after Phase 0 gate)

See repo root `MVP_SCOPE.md` and `GETTING_STARTED.md`.
