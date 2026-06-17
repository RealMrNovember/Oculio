# Architecture

> **Phase 1 system design.** Updated to resolve stack conflicts in original docs.

---

# High-Level Diagram

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter Mobile │     │   React Web     │
│  (Eye Reading)  │     │  (Library UI)   │
└────────┬────────┘     └────────┬────────┘
         │    HTTPS / REST       │
         └──────────┬────────────┘
                    ▼
         ┌─────────────────────┐
         │   NestJS API        │
         │   + Parse Worker    │
         └──────────┬──────────┘
                    │
      ┌─────────────┼─────────────┐
      ▼             ▼             ▼
 PostgreSQL      Redis      Cloudflare R2
```

---

# Client Applications

## Mobile — Flutter (primary)

**Platforms:** Android, iOS

**Responsibilities:**

* Eye-assisted reading engine (on-device)
* Camera + ML pipeline
* Offline document cache
* Vault sync
* Reading session capture

**Not in Phase 1:** Flutter Web, Flutter Desktop

## Web — React + Vite

**Responsibilities:**

* Auth, library browse, upload, settings
* Standard scroll reader (no eye tracking)
* Admin-style document management

**Stack:** React, TypeScript, TailwindCSS, Framer Motion

---

# Backend — NestJS

**Modules (Phase 1):**

| Module | Responsibility |
|--------|----------------|
| auth | JWT, OAuth, refresh rotation |
| users | Profile, tier |
| folders | Vault organization |
| documents | Upload metadata, CRUD |
| parsing | TXT, MD, EPUB, PDF-text → FlowDocument |
| reading | Progress + sessions |
| storage | R2 signed URLs |
| health | Probes |

**API style:** REST + OpenAPI

**Real-time:** Socket.io deferred to Phase 2 (Reading Rooms)

---

# Data Layer

## PostgreSQL

* Primary relational store
* Prisma ORM recommended
* See `DATA_MODEL.md`

## Redis

* Refresh token blocklist
* Rate limiting
* BullMQ job queue (document parsing)
* Phase 2: Socket.io adapter

## Cloudflare R2

* Raw uploaded files
* Parsed FlowDocument JSON cache (optional duplicate of Postgres JSONB)
* Signed download URLs via API

**Decision:** R2 only in Phase 1. AWS S3 reserved for multi-region Enterprise later.

---

# Document Processing Pipeline

```
Upload (multipart)
    ↓
Validate mime + size + tier limits
    ↓
Store raw file → R2
    ↓
Enqueue parse job (BullMQ)
    ↓
Worker: extract text by format
    ↓
Normalize → FlowDocument JSON
    ↓
Save flow_documents + update parse_status
```

### Format handlers

| Format | Handler | Phase |
|--------|---------|-------|
| TXT, MD | Direct read | 1 |
| EPUB | epub.js / custom parser | 1 |
| PDF (text) | pdf-parse / pdfjs | 1 |
| PDF (scanned) | OCR queue | 3 |
| DOCX | mammoth → text | 2 |
| PPTX | slide extract | 3 |

---

# Eye Tracking Architecture (on-device only)

```
Camera stream (15–24 FPS)
    ↓
Face / eye landmark detection (ML Kit / Vision)
    ↓
Gaze proxy + calibration map
    ↓
Flow Engine (scroll velocity, pause)
    ↓
Session aggregates → API (no frames)
```

See `EYE_TRACKING.md` and `TECHNICAL_CONSTRAINTS.md`.

---

# Authentication Flow

```
Login → access token (15 min) + refresh token (30 days)
    ↓
API requests with Bearer access token
    ↓
401 → POST /auth/refresh with rotation
    ↓
Refresh compromised → revoke all device tokens
```

OAuth: Google + Apple (required for iOS App Store social login rules if Google is offered)

2FA: design in Phase 1, ship Phase 2

---

# Infrastructure

| Component | Technology |
|-----------|------------|
| Containers | Docker |
| Orchestration (v1) | Docker Compose on VPS |
| Reverse proxy | Nginx |
| CDN / WAF | Cloudflare |
| CI/CD | GitHub Actions |
| Error tracking | Sentry |
| OS | Ubuntu 22.04 LTS |

See `DEPLOYMENT.md`

---

# AI Services (Phase 3+)

| Feature | Provider (candidate) |
|---------|---------------------|
| Book Universe extraction | Gemini API |
| AI Book Assistant | Gemini API |
| OCR quality tier | Google Vision / Textract |
| OCR bulk tier | Tesseract self-hosted |
| Emotion / engagement | Local heuristics first |

AI calls are server-side, async, Premium-gated, quota-limited.

---

# Phase 2 Additions (preview)

* Socket.io + Redis adapter
* Social feed service
* Notification service (FCM + APNs + email)
* Stripe billing webhooks

---

# Phase 3+ Additions (preview)

* OCR worker pool
* Book Universe graph store (JSONB or Neo4j if graphs get complex)
* Enterprise SSO (SAML/OIDC)

---

# Cross-Cutting Concerns

| Concern | Approach |
|---------|----------|
| Logging | Structured JSON (pino) |
| Secrets | Env vars, never in repo |
| Migrations | Prisma migrate |
| API versioning | `/v1` prefix |
| i18n | `locale` on user; Flutter intl |
| Feature flags | Env-based Phase 1; LaunchDarkly later |

---

# Resolved Conflicts (from original README)

| Original | Resolution |
|----------|------------|
| Flutter for web AND React | React web only; Flutter mobile only |
| R2 AND S3 both active | R2 only in Phase 1 |
| Socket.io in Phase 1 | Deferred to Phase 2 |
| Eye tracking on all platforms | Mobile native only |
| All formats in Phase 1 | TXT, MD, EPUB, text-PDF only |

---

# Document Index

* `PROJECT_STRUCTURE.md` — repo layout
* `API_SPEC.md` — endpoints
* `DATA_MODEL.md` — schema
* `GETTING_STARTED.md` — build order
