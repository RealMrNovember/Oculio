# Deployment

> **Phase 1 target:** Single VPS + Docker Compose + Cloudflare edge.

---

# Environments

| Environment | Purpose | URL pattern |
|-------------|---------|-------------|
| local | Development | localhost |
| staging | Beta testers | staging.api.oculio.app |
| production | Live users | api.oculio.app |

---

# Production Architecture

```
Users
  ↓
Cloudflare (CDN + WAF + SSL)
  ↓
Ubuntu VPS (Nginx)
  ↓
┌─────────────────────────────────┐
│  Docker Compose                 │
│  ├── api (NestJS) × 1           │
│  ├── worker (parse jobs) × 1    │
│  ├── postgres × 1             │
│  └── redis × 1                  │
└─────────────────────────────────┘
  ↓
Cloudflare R2 (object storage)
```

Scale to multiple API replicas + managed Postgres when DAU > 5k.

---

# Server Requirements (Phase 1)

| Resource | Minimum |
|----------|---------|
| CPU | 2 vCPU |
| RAM | 4 GB |
| Disk | 40 GB SSD |
| OS | Ubuntu 22.04 LTS |
| Provider | Hetzner / DigitalOcean / AWS Lightsail |

---

# Docker Compose Services

### api

* NestJS production build
* Port 3000 internal
* Health: `GET /health`

### worker

* Same image, `npm run worker`
* Consumes BullMQ `document-parse` queue

### postgres

* Version 16
* Volume: `postgres_data`
* Backups: daily pg_dump → R2

### redis

* Version 7
* Volume: `redis_data`
* AOF persistence enabled

### nginx (host or container)

* TLS termination at Cloudflare (Full Strict)
* Proxy pass to api:3000
* Max body size: 55 MB (upload limit + overhead)

---

# Cloudflare Setup

* DNS A record → VPS IP (proxied)
* SSL: Full (Strict)
* WAF: OWASP core ruleset
* Rate limiting on `/auth/*` paths
* R2 bucket in same account
* Cache: static web assets only (not API)

---

# CI/CD — GitHub Actions

### On pull request

* API: lint + unit tests
* Web: lint + build
* Mobile: analyze + test (no IPA on PR)

### On merge to `main`

* Build + push API Docker image to GHCR
* Deploy to staging via SSH + compose pull
* Manual approval for production deploy (v1)

### Mobile releases

* `main` tag → build APK/AAB + upload to Play Internal
* iOS: Fastlane TestFlight on release tag

---

# Environment Variables (production)

```
NODE_ENV=production
DATABASE_URL=postgresql://...
REDIS_URL=redis://redis:6379
JWT_SECRET=<strong-random>
JWT_REFRESH_SECRET=<strong-random>
R2_ENDPOINT=...
R2_ACCESS_KEY=...
R2_SECRET_KEY=...
R2_BUCKET=oculio-vault
CORS_ORIGINS=https://app.oculio.app
SENTRY_DSN=...
```

Use Docker secrets or host `.env` with `chmod 600`. Never in git.

---

# Database Migrations

```
npx prisma migrate deploy
```

Run on deploy before starting new API containers.

---

# Backups

| Target | Frequency | Retention |
|--------|-----------|-----------|
| PostgreSQL | Daily | 30 days |
| R2 | Versioning enabled | 90 days |
| Redis | RDB snapshots | 7 days |

Test restore monthly.

---

# Monitoring

| Tool | Purpose |
|------|---------|
| Sentry | Errors (API + mobile) |
| Uptime Kuma / Better Stack | `/health` uptime |
| Cloudflare Analytics | Traffic, WAF blocks |
| Docker logs | pino JSON → optional Loki later |

Alerts: API down > 2 min, disk > 80%, parse queue depth > 100.

---

# Staging vs Production

* Separate R2 buckets
* Separate databases
* Staging uses test OAuth credentials
* No production user data in staging

---

# Web App Hosting

Option A (Phase 1): Cloudflare Pages — `apps/web` static build

Option B: Same VPS, Nginx serves `dist/`

Recommendation: **Cloudflare Pages** for zero-ops frontend deploy.

---

# Mobile Distribution

| Platform | Channel |
|----------|---------|
| Android | Play Console Internal → Closed → Open |
| iOS | TestFlight → App Store |

---

# Rollback

* Keep previous Docker image tag
* `docker compose up -d` with previous tag
* DB migrations: write backward-compatible migrations only in Phase 1

---

# Related Documents

* `ARCHITECTURE.md`
* `GETTING_STARTED.md`
* `SECURITY.md`
