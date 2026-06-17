# Getting Started

> **Build order:** Prove eye reading → backend skeleton → Vault → EPUB/PDF → polish.

This is the step-by-step plan to go from zero code to Phase 1 MVP.

---

# Prerequisites

## Tools

* Flutter SDK 3.x (stable)
* Node.js 20 LTS
* Docker Desktop
* PostgreSQL client (optional, Docker is enough)
* Android Studio + physical Android device (emulator camera is insufficient for eye tests)
* Xcode + physical iPhone (for iOS phase)
* Git

## Accounts (Phase 1)

* Cloudflare account (R2 + CDN + WAF)
* Google Cloud (OAuth + optional Gemini later)
* Apple Developer (Sign in with Apple, TestFlight)
* GitHub (repo + Actions)

Defer until Phase 2+: Stripe, SendGrid, Sentry paid tier.

---

# Step 1 — Repository Bootstrap (Day 1)

```
oculio/
├── apps/
│   ├── mobile/          # Flutter
│   └── web/             # React + Vite
├── packages/
│   └── shared/          # Types, constants, API client
├── services/
│   └── api/             # NestJS
├── infra/
│   ├── docker/
│   └── nginx/
└── docs/                # Move .md files here later (optional)
```

See `PROJECT_STRUCTURE.md` for full layout.

### Commands

1. `git init`
2. Create monorepo folders
3. `flutter create apps/mobile`
4. `npm create vite@latest apps/web -- --template react-ts`
5. `nest new services/api`
6. Add root `docker-compose.yml` (Postgres + Redis + API)

---

# Step 2 — Phase 0 Eye Prototype (Week 1–2)

**Do this before any backend work.**

### Mobile tasks

1. Camera permission flow + privacy explanation screen
2. Integrate `google_mlkit_face_detection` (Android) / Vision (iOS)
3. Extract eye landmarks → compute gaze proxy (head pose + iris offset)
4. Build calibration UI (user looks at dots on screen)
5. Map gaze proxy to vertical screen zone → scroll velocity
6. TXT reader with infinite scroll + Smart Pause
7. Log session data locally (JSON) for analysis

### Validation

* Test on 5+ real devices, varied lighting
* Test with glasses / no glasses
* Document failure modes in `TECHNICAL_CONSTRAINTS.md`

**Gate:** Do not proceed to Phase 1 backend until Phase 0 success criteria in `MVP_SCOPE.md` are met or scope is adjusted.

---

# Step 3 — Backend Skeleton (Week 3)

1. NestJS modules: `auth`, `users`, `health`
2. PostgreSQL + Prisma (or TypeORM) — see `DATA_MODEL.md`
3. JWT access (15 min) + refresh (30 days) with rotation
4. Google / Apple OAuth
5. Docker Compose local stack
6. OpenAPI/Swagger at `/api/docs`

---

# Step 4 — Vault v1 (Week 4–5)

1. R2 bucket + IAM-style keys
2. `documents` module: upload, list, delete, signed download URL
3. File validation: mime, size, extension allowlist
4. Virus scan hook (ClamAV container or defer with size limits)
5. Mobile: pick file → upload → open in reader
6. Web: drag-drop upload + library grid

---

# Step 5 — Document Parsing (Week 6–7)

1. **TXT / MD** — direct read
2. **EPUB** — parse spine → HTML → plain blocks → Flow segments
3. **PDF** — `pdf.js` or `pdf_text` extraction; detect scanned pages
4. Normalize all formats to internal `FlowDocument` JSON (see `DATA_MODEL.md`)
5. Store parsed cache in R2 or Postgres JSONB

---

# Step 6 — Reading Sync (Week 8)

1. `reading_progress` API: position, percent, last_read_at
2. Mobile offline queue → sync on reconnect
3. Conflict rule: latest `updated_at` wins (v1)

---

# Step 7 — Polish & Launch Prep (Week 9–12)

1. Onboarding flow (see `USER_EXPERIENCE.md`)
2. Error states, empty library, upload failures
3. Privacy policy, terms, camera consent copy
4. App icons, splash, store screenshots
5. GitHub Actions: lint, test, build APK/IPA
6. Staging deploy on Ubuntu VPS (see `DEPLOYMENT.md`)
7. TestFlight + Play Internal Testing

---

# Development Commands (target state)

```bash
# Infrastructure
docker compose -f infra/docker/docker-compose.yml up -d

# API
cd services/api && npm run start:dev

# Web
cd apps/web && npm run dev

# Mobile
cd apps/mobile && flutter run
```

---

# Environment Variables (API)

```
DATABASE_URL=
REDIS_URL=
JWT_SECRET=
JWT_REFRESH_SECRET=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
APPLE_CLIENT_ID=
R2_ENDPOINT=
R2_ACCESS_KEY=
R2_SECRET_KEY=
R2_BUCKET=
CORS_ORIGINS=
```

Never commit `.env`. Use `.env.example` in repo.

---

# Decision Log (locked for Phase 1)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Mobile framework | Flutter | Single codebase, good camera plugins |
| Web framework | React + Vite | Eye tracking N/A on web v1; fast UI for library |
| Backend | NestJS | Modular, TypeScript, Swagger |
| Database | PostgreSQL | Relational integrity for users/docs |
| Cache / sessions | Redis | Refresh tokens, rate limits |
| Object storage | Cloudflare R2 only | S3-compatible, no egress fees; drop AWS S3 dual-write |
| Real-time | Defer | REST sufficient for Phase 1 |
| AI provider | Defer | Cost + scope; basic stats are local |

---

# What NOT to do early

* Do not build social feed "because it's easy"
* Do not integrate Gemini before Vault works
* Do not support DOCX/PPTX in v1
* Do not claim "emotion detection" from eye data
* Do not run Flutter web + React web for the same product surface
* Do not optimize Anti Motion before Smart Scroll works standing still

---

# Next Documents

* `MVP_SCOPE.md` — what ships when
* `RISKS_AND_MITIGATIONS.md` — what can go wrong
* `TECHNICAL_CONSTRAINTS.md` — eye tracking honesty
* `LEGAL_AND_PRIVACY.md` — before public beta
