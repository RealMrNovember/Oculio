# Technical Constraints

> **Honest engineering boundaries.** Oculio's differentiation depends on knowing what phone cameras can and cannot do.

---

# The Core Constraint

**Consumer front cameras are not eye trackers.**

They are wide-angle selfie cameras running face mesh models. They estimate head pose and approximate eye direction. They do **not** provide laboratory-grade gaze coordinates.

Oculio must be designed as **eye-assisted reading**, not **eye-controlled pixel precision**.

---

# What Mobile SDKs Actually Provide

## Android (ML Kit / MediaPipe)

* Face bounding box
* ~468 face mesh landmarks (MediaPipe)
* Eye region landmarks
* Iris approximate position (lighting-dependent)
* Head yaw, pitch, roll

## iOS (Vision / ARKit face tracking)

* Similar landmark set on Face ID devices
* Reduced capability on devices without TrueDepth
* Front camera FOV differs per device

## What they do NOT provide

* Sub-degree gaze angle to screen mapping
* Calibration-free accuracy across users
* Reliable operation in bed, dark room, direct sun
* Consistent behavior with sunglasses, hijab edge cases, heavy makeup

---

# Accuracy Expectations (realistic)

| Condition | Expected line error |
|-----------|---------------------|
| Good light, calibrated, phone fixed on stand | ±1–2 lines |
| Hand-held, calibrated | ±2–4 lines |
| Walking / vehicle | Unreliable — disable or pause |
| Glasses (anti-reflective) | ±2–3 lines |
| Glasses (strong reflection) | Often fails |
| No calibration | ±4+ lines — unusable for scroll |

---

# Smart Scroll — Recommended Algorithm (v1)

**Do not** map gaze directly to "scroll to this Y pixel" in v1.

### Hybrid approach

1. **Auto-scroll** at user's measured WPM (words per minute)
2. **Gaze zone** divides screen into thirds:
   * Top third → slow scroll
   * Middle → nominal speed
   * Bottom third → speed up slightly
3. **Fixation pause** — if gaze proxy stable > 800ms, micro-pause (user re-reading line)
4. **Regression** — if gaze moves upward zone, scroll back one line
5. **Manual override** — any touch stops auto-scroll for 10s

This feels intelligent even when gaze is imprecise.

---

# Smart Pause — Reliable Signals

These work well on front camera:

| Signal | Detection method |
|--------|------------------|
| Face lost | No face for > 1.5s |
| Look away | Head yaw > 35° for > 1s |
| Eyes closed | Blink duration > 2s (sleep) |
| App background | Lifecycle event |
| Screen lock | OS event |

**Ship Smart Pause before perfect Smart Scroll** — it builds trust.

---

# Calibration (required)

### Flow

1. Explain why camera is needed (privacy copy)
2. Show 5 points on screen (corners + center)
3. User looks at each point; tap when ready
4. Build simple polynomial or affine map: landmark features → screen Y zone
5. Store calibration per device + optional cloud sync (encrypted blob)
6. Offer recalibration in settings

### Recalibration triggers

* User reports "scroll feels wrong"
* 7 days since last calibration
* Device model change detected

---

# Performance Budget

| Resource | Budget |
|----------|--------|
| Camera + ML FPS | 15–24 FPS (adaptive) |
| CPU (mid Android) | < 25% average |
| Battery (30 min session) | < 12% drain target |
| Thermal | Reduce FPS if skin temp API signals throttle |

---

# Anti Motion Engine — Why Deferred

Compensating vehicle motion while running gaze scroll creates **conflicting motion vectors**:

* Accelerometer says content should move up
* Gaze says user is reading line N
* User's head also moves with vehicle

Industry readers (e-readers in transit) mostly use **reflow + large font + manual scroll**, not stabilization.

**Phase 4+ research item.** Phase 1: detect high motion → suggest pause or audio mode.

---

# Emotion Reading — Scientific Constraint

Inferring bored / excited / frustrated from eye movement alone is **not validated** for consumer apps.

Acceptable Phase 3 approach:

* **Engagement score** from: pause frequency, regression count, session length drop, WPM variance
* Optional user self-report: "How are you feeling?"
* Never show "You are frustrated" as fact — suggest breaks instead

---

# Web Platform Constraint

Browsers cannot access continuous front-camera ML pipelines with the same performance as native.

**Phase 1 web = library management only, standard scroll reader.**

Eye-assisted reading is a **mobile native exclusive** until WebGPU + dedicated APIs mature.

---

# Desktop Constraint

Flutter desktop lacks consistent camera ML story.

Defer desktop to Phase 3+.

---

# PDF Constraint

* Text PDF: extractable
* Scanned PDF: requires OCR (Phase 3)
* Complex layout (columns, tables): reflow may break — warn user

---

# AI Constraint (Phase 3+)

* Book Universe full-graph extraction for a 400-page novel = large token cost
* Batch process chapter-by-chapter
* Cache results in `book_universe_graphs` table
* Premium-only with monthly quota

---

# Device Support Policy (recommended)

### Tier A — fully supported

Recent flagships + mid-range with Android 12+ / iOS 16+

### Tier B — supported with limitations

Older devices: eye assist off by default, manual mode

### Tier C — unsupported

No front camera, < 3 GB RAM

Publish list after Phase 0 benchmarks.

---

# App Store Claim Guidelines

### Safe claims

* "Reading that adapts to your pace"
* "Pauses when you look away"
* "Eye-assisted scroll" (with calibration)

### Avoid until proven

* "Read with only your eyes" (implies no touch ever)
* "Detects your emotions"
* "Works perfectly while walking"

---

# Fallback Hierarchy

```
1. Calibrated eye-assisted scroll (default)
       ↓ fails / user disables
2. WPM auto-scroll only
       ↓ user disables
3. Manual scroll (always available)
```

Every session must end in a readable state via level 3.

---

# Related Documents

* `EYE_TRACKING.md` — pipeline implementation
* `MVP_SCOPE.md` — what ships when
* `RISKS_AND_MITIGATIONS.md` — R1, R2, R11
