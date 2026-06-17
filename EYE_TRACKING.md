# Eye Tracking Pipeline

> **On-device only.** No camera frames leave the phone in Phase 1.

---

# Pipeline Overview

```
Camera (15–24 FPS)
    ↓
Face Detection
    ↓
Eye Landmark Detection
    ↓
Gaze Proxy (head pose + iris offset)
    ↓
Calibration Map
    ↓
Flow Engine (Smart Scroll + Smart Pause)
    ↓
Session Aggregates → API (WPM, pauses — no coordinates)
```

---

# Platform Implementations

## Android

**Primary:** Google ML Kit Face Detection

**Secondary / higher fidelity:** MediaPipe Face Landmarker

| Capability | ML Kit | MediaPipe |
|------------|--------|-----------|
| Face detect | ✓ | ✓ |
| Dense mesh | Limited | ✓ 468 points |
| Iris estimate | Approximate | Better |
| Battery | Lower | Higher |
| Integration | Easier Flutter plugin | More setup |

**Recommendation:** Start ML Kit; switch to MediaPipe if accuracy insufficient in Phase 0.

## iOS

**Primary:** Apple Vision Framework (`VNDetectFaceLandmarksRequest`)

**Enhanced:** ARKit face tracking on TrueDepth devices

| Device | Approach |
|--------|----------|
| Face ID iPhones | Vision + optional ARKit |
| Older iPhones | Vision only; may need relaxed accuracy |

---

# Gaze Proxy (not true gaze)

Raw landmarks are converted to a **gaze proxy score**, not screen coordinates:

```
gaze_proxy_y = f(head_pitch, iris_offset_y, calibration_coefficients)
```

Mapped to screen zones:

| Zone | Screen region | Scroll effect |
|------|---------------|---------------|
| upper | Top 33% | Decrease velocity |
| center | Middle 33% | Nominal velocity |
| lower | Bottom 33% | Increase velocity |

See `TECHNICAL_CONSTRAINTS.md` for why direct pixel mapping is avoided.

---

# Calibration

### Required before first Smart Scroll session

1. User holds phone at comfortable reading distance
2. Display 5 calibration dots (4 corners + center)
3. User looks at dot → taps "Next"
4. Record landmark feature vector per dot
5. Fit affine / polynomial mapping
6. Store in `user_settings.calibration_data` (encrypted, optional cloud sync)

### Recalibration

* Settings → Recalibrate
* Auto-prompt after 7 days or on user complaint

---

# Smart Scroll

### Hybrid algorithm (v1)

1. Base auto-scroll at user's rolling average WPM
2. Gaze zone modulates velocity (±20%)
3. Fixation > 800ms → micro-pause
4. Upward zone regression → scroll back one line
5. Touch anywhere → pause auto-scroll 10s

### States

```
IDLE → READING → PAUSED → READING
         ↑          │
         └──────────┘ (Smart Pause triggers)
```

---

# Smart Pause

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Face lost | > 1.5s | Pause scroll |
| Head yaw (look away) | > 35° for > 1s | Pause |
| Long blink / eyes closed | > 2s | Pause |
| App to background | immediate | Pause |
| Screen locked | immediate | Pause |

Resume: face detected + head forward → 0.5s delay → resume

---

# Anti Motion Engine

**Status:** Deferred (Phase 4 R&D)

Phase 1 fallback:

* Accelerometer variance > threshold → show "Motion detected — pause reading?"
* Optional: disable eye assist in high motion

---

# Reading Analytics (local → server)

### Collected per session

* duration_seconds
* words_read_estimate
* pause_count
* avg_wpm
* eye_assist_enabled
* regression_count (estimated from upward zone events)

### NOT collected

* Video frames
* Per-frame landmark coordinates
* Continuous gaze trace

---

# Performance Tuning

| Parameter | Default | Power saver |
|-----------|---------|-------------|
| ML FPS | 24 | 15 |
| Camera resolution | 720p | 480p |
| Face detect skip | Every frame | Every 2nd frame |

Reduce FPS when:

* Battery < 20%
* Thermal throttling detected
* User enables Power Saver

---

# Failure Modes

| Symptom | Cause | UX |
|---------|-------|-----|
| Scroll jumps | Bad calibration | Prompt recalibrate |
| Never scrolls | Face not detected | Check lighting; manual mode |
| Constant pause | Glasses reflection | Suggest angle change or manual |
| Overheating | Sustained ML | Reduce FPS; warning toast |

---

# Flutter Module Layout

```
features/reader/eye_tracking/
├── camera_service.dart
├── landmark_detector.dart      # Platform abstraction
├── android_mlkit_detector.dart
├── ios_vision_detector.dart
├── calibration_controller.dart
├── gaze_proxy.dart
├── smart_pause_controller.dart
└── eye_tracking_controller.dart
```

---

# Testing Plan (Phase 0)

* 5 devices minimum (3 Android, 2 iOS)
* Lighting: office, dim, window backlight
* Accessories: glasses on/off
* Metrics: line error, pause false positive rate, battery %/30min

---

# Related Documents

* `TECHNICAL_CONSTRAINTS.md` — accuracy limits
* `MVP_SCOPE.md` — Phase 0 gate
* `LEGAL_AND_PRIVACY.md` — biometric consent
* `AI_ENGINE.md` — Lumentum uses session aggregates (Phase 3)
