# API Specification

> **Phase 1 REST API.** Base URL: `https://api.oculio.app/api/v1`
>
> NestJS global prefix: `/api` + URI versioning `/v1`. Route tables below use the full public path.
>
> WebSocket endpoints deferred to Phase 2.

---

# Conventions

* JSON request/response bodies
* All routes are prefixed with `/api/v1` (e.g. `POST /api/v1/auth/login`)
* `Authorization: Bearer <access_token>` on protected routes
* Pagination: `?page=1&limit=20`
* Errors:

```json
{
  "statusCode": 400,
  "message": "Human readable message",
  "error": "Bad Request",
  "code": "DOCUMENT_LIMIT_REACHED"
}
```

* OpenAPI/Swagger at `/api/docs` (NestJS)

---

# Auth

## POST /auth/register

```json
{ "email": "user@example.com", "password": "...", "display_name": "..." }
```

→ `201` `{ access_token, refresh_token, expires_in, user }`

## POST /auth/login

→ same response shape

## POST /auth/refresh

```json
{ "refresh_token": "..." }
```

→ new token pair; old refresh token revoked (rotation)

## POST /auth/logout

```json
{ "refresh_token": "..." }
```

## POST /auth/google

```json
{ "id_token": "..." }
```

## POST /auth/apple

```json
{ "id_token": "...", "nonce": "..." }
```

## POST /auth/forgot-password

## POST /auth/reset-password

---

# Users

## GET /users/me

→ profile + tier + storage_usage summary + `copyright_strikes`

## PATCH /users/me

```json
{ "display_name": "...", "locale": "tr" }
```

## DELETE /users/me

Soft delete account; schedule storage purge after 30 days.

---

# Settings

## GET /users/me/settings

## PATCH /users/me/settings

```json
{
  "font_size": 18,
  "theme": "dark",
  "eye_assist_enabled": true,
  "smart_pause_enabled": true
}
```

---

# Folders

## GET /folders

→ tree or flat list

## POST /folders

```json
{ "name": "Fiction", "parent_id": null }
```

## PATCH /folders/:id

## DELETE /folders/:id

Moves documents to root or rejects if non-empty (v1: reject if has documents).

---

# Documents

## GET /documents

Query: `folder_id`, `format`, `parse_status`, `visibility`, `review_status`, `q` (title search)

## GET /documents/:id

→ metadata + `parse_status`, `visibility`, `review_status`, `content_hash`, `ai_trust_score` + reading_progress summary

### Document response shape (excerpt)

```json
{
  "id": "uuid",
  "title": "My Book",
  "format": "epub",
  "parse_status": "ready",
  "visibility": "private",
  "review_status": "none",
  "content_hash": "a3f2...",
  "ai_trust_score": null,
  "word_count": 84200
}
```

## POST /documents/upload

`multipart/form-data`:

* `file` — required
* `folder_id` — optional
* `title` — optional override

→ `201` document metadata; triggers async parse job

**On ingest:** server computes `content_hash` (SHA-256), sets `visibility = private`, `review_status = none`.

**Limits:** 50 MB/file (MVP), tier document count enforced

## DELETE /documents/:id

Soft delete

## GET /documents/:id/download-url

→ `{ "url": "signed R2 URL", "expires_at": "..." }` (TTL 15 min)

## GET /documents/:id/content

→ `FlowDocument` JSON when `parse_status === ready`

→ `409` if `ocr_required` with code `OCR_REQUIRED`

## POST /documents/:id/reparse

Admin/user retry after failure

---

# Copyright & Public Review (Phase 2+)

> See `COPYRIGHT_AND_UPLOAD_PIPELINE.md` for funnel architecture.
>
> Phase 1: endpoints return `501 Not Implemented` or are feature-flagged off; `visibility = private` enforced on all uploads.

## POST /api/v1/documents/:id/request-public

Initiates the public review pipeline for a **private** document owned by the authenticated user.

**Auth:** required

**Preconditions:**

* `parse_status === ready`
* `visibility === private`
* `review_status` is `none` or `rejected` (re-apply allowed after rejection)
* User `copyright_strikes < 3`

**Request body (optional):**

```json
{
  "attestation": "I confirm I have the right to publish this content."
}
```

**Actions:**

1. Set `review_status = pending`
2. Enqueue `public-review-pipeline` job (metadata regex → hash blacklist → AI trust score)
3. `visibility` remains `private` until approved

→ `202 Accepted`

```json
{
  "document_id": "uuid",
  "visibility": "private",
  "review_status": "pending",
  "message": "Your document is under review. Poll GET /documents/:id/status for updates."
}
```

**Errors:**

| Code | HTTP | When |
|------|------|------|
| `DOCUMENT_NOT_READY` | 409 | `parse_status !== ready` |
| `ALREADY_PUBLIC` | 409 | `visibility === public` |
| `REVIEW_IN_PROGRESS` | 409 | `review_status === pending` |
| `COPYRIGHT_STRIKES_EXCEEDED` | 403 | `copyright_strikes >= 3` |
| `NOT_OWNER` | 403 | document belongs to another user |

---

## GET /api/v1/documents/:id/status

Returns real-time upload, parse, and public-review status for Flutter / React clients.

**Auth:** required (owner or admin)

→ `200 OK`

```json
{
  "document_id": "uuid",
  "parse_status": "ready",
  "parse_error": null,
  "visibility": "private",
  "review_status": "pending",
  "content_hash": "a3f2b1c9...",
  "ai_trust_score": null,
  "review": {
    "stage": "hash_check",
    "progress_percent": 45,
    "estimated_completion_seconds": 120
  }
}
```

`review` object is present only when `review_status === pending`; `stage` values: `queued`, `metadata_scan`, `hash_check`, `ai_analysis`, `scoring`, `complete`.

When `review_status === approved`:

```json
{
  "visibility": "public",
  "review_status": "approved",
  "ai_trust_score": 82.50
}
```

When `review_status === rejected`:

```json
{
  "visibility": "private",
  "review_status": "rejected",
  "ai_trust_score": 12.00,
  "rejection_reason_code": "HASH_BLACKLIST_MATCH"
}
```

---

## POST /api/v1/legal/dmca-report

Accepts copyright infringement reports from rights holders, users, or internal moderation.

**Auth:** optional for external reporters; authenticated when filed from in-app report flow

**Rate limit:** 5 / hour / IP (unauthenticated), 20 / day / user (authenticated)

**Request body:**

```json
{
  "document_id": "uuid",
  "reporter_email": "rights@publisher.com",
  "copyrighted_work_title": "Example Novel",
  "infringing_description": "Full EPUB uploaded to public feed",
  "good_faith_statement": true,
  "accuracy_statement": true,
  "signature": "Jane Rights Holder"
}
```

`document_id` optional if reporter provides other identifying info (URL, username); staff resolves manually.

**Actions:**

1. Insert `dmca_notices` row (`status = open`)
2. If `document_id` resolved → disable public access immediately (`visibility = private`, `review_status = rejected`)
3. Notify document owner and legal queue
4. Increment `copyright_strikes` on upheld complaints

→ `201 Created`

```json
{
  "notice_id": "uuid",
  "status": "open",
  "document_id": "uuid",
  "message": "Notice received. We will act within 24 hours."
}
```

**Errors:**

| Code | HTTP | When |
|------|------|------|
| `INVALID_NOTICE` | 400 | missing required DMCA fields |
| `DOCUMENT_NOT_FOUND` | 404 | invalid `document_id` |

---

# Reading Progress

## GET /documents/:id/progress

## PUT /documents/:id/progress

```json
{
  "block_id": "blk_042",
  "char_offset": 120,
  "percent_complete": 34.5
}
```

Idempotent upsert.

---

# Reading Sessions

## POST /reading-sessions

```json
{
  "document_id": "...",
  "started_at": "ISO8601",
  "eye_assist_enabled": true,
  "device_model": "Pixel 7"
}
```

→ `{ session_id }`

## PATCH /reading-sessions/:id

End session + upload aggregates:

```json
{
  "ended_at": "ISO8601",
  "duration_seconds": 1800,
  "words_read_estimate": 4500,
  "pause_count": 12,
  "avg_wpm": 220
}
```

No gaze coordinates accepted server-side in Phase 1.

---

# Storage

## GET /storage/usage

→ `{ bytes_used, bytes_limit, document_count, document_limit }`

---

# Health

## GET /health

→ `{ status: "ok", db: "ok", redis: "ok", storage: "ok" }`

---

# Internal / Worker (not public)

## POST /internal/parse/:document_id

Triggered by queue worker after upload.

---

# Rate Limits (Phase 1)

| Route group | Limit |
|-------------|-------|
| POST /auth/* | 10 / min / IP |
| POST /documents/upload | 20 / hour / user |
| GET /documents/:id/download-url | 60 / hour / user |
| POST /documents/:id/request-public | 10 / day / user |
| POST /legal/dmca-report | 5 / hour / IP |
| General API | 300 / min / user |

---

# WebSocket (Phase 2 preview)

```
/ws/reading-rooms/:roomId
```

Events: `presence`, `message`, `note_shared` — not implemented in Phase 1.

---

# Mobile Offline Strategy

1. Download `FlowDocument` + cover metadata to local SQLite/Hive
2. Queue progress updates in outbox table
3. Sync on connectivity restore via `PUT /progress` batch endpoint (add in Phase 1.1)

---

# Versioning

* URL prefix `/api/v1`
* Breaking changes → `/api/v2`
* Mobile sends `X-App-Version` header for deprecation warnings

---

# Related Documents

* `DATA_MODEL.md` — `visibility`, `review_status`, `content_hash`, `ai_trust_score`, `dmca_notices`
* `COPYRIGHT_AND_UPLOAD_PIPELINE.md` — review funnel and DMCA workflow
