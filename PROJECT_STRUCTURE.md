# Project Structure

> **Monorepo layout** for Oculio Phase 1.

---

# Repository Root

```
Oculio/
├── apps/
│   ├── mobile/                 # Flutter — primary product
│   └── web/                    # React + Vite — library & upload
├── packages/
│   └── shared/                 # Shared TypeScript types & constants
├── services/
│   └── api/                    # NestJS backend
├── infra/
│   ├── docker/
│   │   ├── docker-compose.yml
│   │   ├── docker-compose.prod.yml
│   │   └── Dockerfile.api
│   └── nginx/
│       └── oculio.conf
├── docs/                       # Optional: relocate .md files here
├── .github/
│   └── workflows/
│       ├── api-ci.yml
│       ├── web-ci.yml
│       └── mobile-ci.yml
├── .env.example
├── README.md
└── ...                         # Planning docs at root (current state)
```

---

# apps/mobile (Flutter)

```
apps/mobile/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── router.dart
│   │   └── theme.dart
│   ├── core/
│   │   ├── api/                # Dio client, interceptors
│   │   ├── storage/            # Hive / secure storage
│   │   └── constants/
│   ├── features/
│   │   ├── auth/
│   │   ├── onboarding/
│   │   ├── library/
│   │   ├── reader/
│   │   │   ├── flow_engine/    # Scroll, render blocks
│   │   │   ├── eye_tracking/   # Camera, calibration, gaze
│   │   │   └── smart_pause/
│   │   └── settings/
│   └── shared/
│       └── widgets/
├── android/
├── ios/
├── test/
└── pubspec.yaml
```

### Key packages (target)

* `dio` — HTTP
* `flutter_riverpod` or `bloc` — state
* `go_router` — navigation
* `hive` — offline cache
* `google_mlkit_face_detection` — Android eye pipeline
* `camera` — camera stream
* `sensors_plus` — accelerometer (future Anti Motion)

---

# apps/web (React)

```
apps/web/
├── src/
│   ├── main.tsx
│   ├── app/
│   ├── features/
│   │   ├── auth/
│   │   ├── library/
│   │   ├── upload/
│   │   └── settings/
│   ├── components/
│   ├── lib/
│   │   └── api.ts
│   └── styles/
├── index.html
├── vite.config.ts
├── tailwind.config.js
└── package.json
```

Web does **not** include eye tracking in Phase 1.

---

# packages/shared

```
packages/shared/
├── src/
│   ├── types/
│   │   ├── user.ts
│   │   ├── document.ts
│   │   └── flow-document.ts
│   ├── constants/
│   │   └── tier-limits.ts
│   └── index.ts
├── package.json
└── tsconfig.json
```

Consumed by `apps/web` and `services/api`.

---

# services/api (NestJS)

```
services/api/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── common/
│   │   ├── guards/
│   │   ├── filters/
│   │   └── interceptors/
│   └── modules/
│       ├── auth/
│       ├── users/
│       ├── folders/
│       ├── documents/
│       ├── parsing/            # EPUB, PDF, TXT workers
│       ├── reading/
│       ├── storage/            # R2 SDK wrapper
│       └── health/
├── prisma/
│   └── schema.prisma
├── test/
├── package.json
└── nest-cli.json
```

### Background jobs

* BullMQ queue: `document-parse`
* Worker process: same repo, `npm run worker` or separate container

---

# infra/docker

```yaml
# docker-compose.yml services:
# - postgres:16
# - redis:7
# - api (NestJS)
# - worker (parse jobs)
# - nginx (prod only)
```

---

# Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | production-ready |
| `develop` | integration |
| `feature/*` | feature branches |
| `release/*` | release candidates |

---

# Naming Conventions

| Item | Convention |
|------|------------|
| API routes | kebab-case plural (`/reading-sessions`) |
| DB tables | snake_case plural |
| Dart files | snake_case |
| React components | PascalCase |
| Env vars | SCREAMING_SNAKE_CASE |

---

# What lives outside the repo

* Secrets (`.env`, R2 keys, JWT secrets)
* User-uploaded files (R2)
* App Store / Play Console assets
* Legal documents (host URLs in app, source in separate legal repo optional)

---

# Documentation Map (root .md files)

| File | Purpose |
|------|---------|
| README.md | Vision & product overview |
| GETTING_STARTED.md | Build order |
| MVP_SCOPE.md | Phase gates |
| ARCHITECTURE.md | System design |
| DATA_MODEL.md | Database |
| API_SPEC.md | REST API |
| PROJECT_STRUCTURE.md | This file |
| RISKS_AND_MITIGATIONS.md | Risk register |
| TECHNICAL_CONSTRAINTS.md | Eye tracking reality |
| LEGAL_AND_PRIVACY.md | Compliance |
| ROADMAP.md | Timeline |
| EYE_TRACKING.md | Pipeline detail |
| VAULT.md | Storage module |
| OCR_ENGINE.md | OCR (Phase 3) |
| ... | Feature-specific docs |
