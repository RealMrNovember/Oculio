# Roadmap

> **Revised roadmap** with Phase 0 proof gate and realistic timelines for solo + AI development.

---

# Overview

```
Phase 0 ──► Phase 1 MVP ──► Phase 2 Social ──► Phase 3 AI ──► Phase 4 Future
(2–4 wk)     (8–12 wk)        (10–14 wk)       (12–16 wk)     (ongoing)
```

Do not start Phase N+1 until Phase N exit criteria pass.

---

# Phase 0 — Eye Reading Proof

**Duration:** 2–4 weeks

**Goal:** Prove eye-assisted reading is usable.

### Deliverables

* Flutter prototype app
* Camera + landmark pipeline
* Calibration flow
* TXT reader + Smart Scroll v0 + Smart Pause v0
* Device benchmark report

### Exit criteria

* See `MVP_SCOPE.md` — Phase 0 success / kill criteria

---

# Phase 1 — Core MVP

**Duration:** 8–12 weeks after Phase 0 pass

**Goal:** Daily-usable reading app with cloud library.

### Reading Engine

* Smart Scroll (hybrid gaze + WPM — see `TECHNICAL_CONSTRAINTS.md`)
* Smart Pause
* Infinite Flow reader UI
* Basic WPM / session stats
* Manual scroll fallback

### Documents

* TXT, Markdown, EPUB
* PDF with text layer only
* Scanned PDF → `ocr_required` state (no silent failure)

### Vault

* Upload, folders, delete, sync
* Cloudflare R2 storage
* Free tier limits enforced

### Platform

* Flutter: Android + iOS
* React web: library + upload (no eye tracking)
* NestJS API + Postgres + Redis
* Auth: email, Google, Apple

### Compliance

* Privacy policy + terms
* Camera consent flow
* Account deletion

### Exit criteria

* 20+ beta users complete 3+ reading sessions each
* Crash-free rate > 99.5%
* TestFlight + Play Internal live

---

# Phase 2 — Social Platform

**Duration:** 10–14 weeks

**Goal:** Reading becomes social without compromising Vault privacy.

### Features

* Social feed (quotes, reviews, progress, thoughts)
* Reading Rooms (WebSocket presence + chat)
* Spoiler Shield (block_id range blur)
* Book Gifting
* Push notifications (FCM, APNs)
* 2FA
* DOCX import (text extraction)

### Infrastructure

* Socket.io + Redis adapter
* Moderation tools (report, block)
* Email service (transactional)

### Exit criteria

* Reading Room supports 50 concurrent users per room
* Spoiler blur tested on EPUB chapter boundaries
* No file sharing in feed (text quotes only — copyright)

---

# Phase 3 — Artificial Intelligence

**Duration:** 12–16 weeks

**Goal:** AI adds value without bankrupting infra.

### Features

* Lumentum AI Coach (challenges, focus training)
* Engagement signals (not raw "emotion" labels)
* OCR Engine (scanned PDF, images)
* Book Universe (character tree, timeline, quotes)
* AI Book Assistant (chapter Q&A)
* Stripe Premium billing
* Ambient Reading modes

### Infrastructure

* BullMQ OCR worker pool
* Gemini API integration with quotas
* Premium tier enforcement

### Exit criteria

* OCR < 5 min for 300-page scanned PDF (Premium)
* Book Universe generates for 50k-word book < $2 API cost
* Premium conversion funnel live

---

# Phase 4 — Future Technologies

**Duration:** Ongoing R&D

### Features

* AI Character Voices (TTS per character)
* Anti Motion Engine (research)
* Flutter Desktop
* Enterprise (SSO, analytics dashboard, corporate libraries)
* Marketplace (legal review required)
* Oculio Glass / Spatial Reading / XR

### Gate

* Phase 3 profitable or funded before hardware/XR investment

---

# Parallel Workstreams (within each phase)

| Stream | Owner focus |
|--------|-------------|
| Mobile reader | 50% time |
| Backend + Vault | 25% time |
| Web library | 15% time |
| Infra + CI | 10% time |

Do not split into 4 equal tracks until team > 2 people.

---

# Milestone Calendar (example start: Month 0)

| Month | Milestone |
|-------|-----------|
| 0–1 | Phase 0 complete |
| 1–3 | Auth + Vault + TXT/EPUB |
| 3–4 | PDF text + reading sync + beta |
| 4–6 | Phase 2 social start |
| 6–9 | Phase 3 AI start |
| 9+ | Premium launch, Phase 4 R&D |

Adjust after Phase 0 results.

---

# Deferred Forever (unless strategy changes)

* Built-in pirated book catalog
* Emotion labels shown as ground truth
* Eye tracking on web without native ML APIs
* Marketplace without legal counsel

---

# Related Documents

* `MVP_SCOPE.md` — detailed scope per phase
* `GETTING_STARTED.md` — week-by-week build plan
* `RISKS_AND_MITIGATIONS.md` — phase gates
* `FUTURE_VISION.md` — long-term product vision
