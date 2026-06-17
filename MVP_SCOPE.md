# MVP Scope

> **Rule:** Ship a reading app that works reliably before building the universe.

This document defines what we build first, what we defer, and what we never promise in v1.

---

# Phase 0 — Technical Proof (2–4 weeks)

Goal: Validate that eye-assisted reading is usable on real devices.

## In Scope

* Flutter mobile app (Android first, iOS second)
* Front-camera pipeline: face detect → eye landmarks → gaze proxy
* Calibration screen (3–5 point gaze mapping)
* Single TXT / Markdown reader with **Smart Scroll v0**
* **Smart Pause v0** (look-away detection via face lost / head turn)
* Local-only storage (no backend)
* Manual scroll fallback always available
* Basic reading session metrics (time, estimated line, pause count)

## Out of Scope

* Cloud, auth, social, AI, PDF, EPUB, payments
* Anti Motion Engine
* Emotion Reading
* Any trademarked module branding in UI (use internal codenames)

## Success Criteria

* 70%+ of test users complete 5-minute reading without rage-quitting
* Smart Scroll keeps user within ±2 lines of intended line in good lighting
* Battery drain < 15% per 30 min reading session on mid-range Android
* Fallback to manual scroll works in < 1 tap

## Kill Criteria (pivot signals)

* Gaze proxy cannot stay within ±3 lines for majority of users even after calibration
* Camera permission rejection rate > 40% in onboarding
* Thermal throttling kills camera within 10 minutes on 30%+ of test devices

---

# Phase 1 — Core Product (MVP, 8–12 weeks)

Goal: A real product one person can use daily.

## In Scope

### Reading Engine (Oculio Flow — internal codename)

* Smart Scroll (calibrated gaze proxy + auto-scroll assist)
* Smart Pause (look-away, app background, screen lock)
* Infinite Reading UI (continuous vertical text flow)
* Reading speed display (estimated WPM from scroll + fixation heuristics)
* Typography controls (font, size, line height, theme)
* Offline reading for downloaded documents

### Documents

* **TXT** and **Markdown** — native, full Flow support
* **EPUB** — parse to reflowable text stream, full Flow support
* **PDF (text-layer only)** — extract text, reflow to Flow format
* PDF scanned pages → show "OCR required" placeholder (not silent failure)

### Vault (v1)

* Upload / download / delete documents
* Folder structure (flat folders, max 2 levels in v1)
* 50 MB per file limit (MVP)
* 500 MB total storage (Free tier aligns with MONETIZATION.md)
* Signed URLs for download
* AES-256 at rest (server-side)

### Backend (minimal)

* Auth: email + password, Google, Apple
* JWT + refresh token rotation
* User profile
* Document metadata + storage keys
* Reading progress sync (last position, % complete)
* REST API only (no WebSocket yet)

### Mobile

* Flutter Android + iOS
* Onboarding: permissions, calibration, first document
* Library screen, Flow reader, settings

### Web (read-only admin / library)

* React + Vite: login, library, upload, reading progress view
* **No eye tracking on web in Phase 1** — standard scroll only

## Explicitly Deferred to Phase 2+

* Social feed, Reading Rooms, Spoiler Shield, Gifting
* Lumentum AI Coach, Emotion Reading, Book Universe
* OCR pipeline (except "coming soon" UX for scanned PDFs)
* Anti Motion Engine
* Marketplace, Enterprise
* Desktop Flutter builds
* PPTX, DOCX full rendering (convert server-side later)
* Voice notes, image annotations
* 2FA (design now, ship Phase 2)

---

# Phase 1 Non-Goals

* Selling third-party books (legal complexity)
* Real-time collaborative reading
* AI chat inside books
* Hardware / AR / XR
* Native desktop apps

---

# Feature Truth Table (Phase 1)

| Feature | User-facing name | Phase 1 reality |
|---------|------------------|-----------------|
| Eye Tracking | Smart Reading | Gaze **proxy** via front camera, requires calibration |
| Smart Scroll | Smart Scroll | Assistive scroll; manual override always on |
| Smart Pause | Smart Pause | Pause on face lost / head away / background |
| Infinite Reading | Flow Reading | Vertical continuous text |
| Anti Motion | — | **Not shipped** |
| Emotion Reading | — | **Not shipped** |
| Lumentum | — | **Not shipped** (basic WPM stats only) |
| Vault | My Library | Cloud sync, TXT/MD/EPUB/text-PDF |
| OCR | — | **Not shipped** |
| Social | — | **Not shipped** |

---

# Quality Bar for Phase 1 Launch

* Crash-free sessions > 99.5%
* API p95 < 300 ms (excl. upload)
* Upload success rate > 99%
* Auth flows pass OWASP mobile checklist
* Privacy policy + consent for camera and reading analytics published
* App Store / Play Store metadata does not overclaim gaze accuracy

---

# Team Assumption (solo + AI)

With one developer and AI assistance:

* Phase 0: 2–4 weeks
* Phase 1: 8–12 weeks
* Do not parallelize social + AI + eye tracking in the same sprint

---

# Document Map

* How to build → `GETTING_STARTED.md`
* Risks → `RISKS_AND_MITIGATIONS.md`
* Eye tracking limits → `TECHNICAL_CONSTRAINTS.md`
* Schema → `DATA_MODEL.md`
* API → `API_SPEC.md`
* Repo layout → `PROJECT_STRUCTURE.md`
