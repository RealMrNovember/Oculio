# Data Model

> **Phase 1 entities only.** Social and AI tables are outlined for future phases but not implemented in MVP.

---

# Design Principles

* UUID primary keys everywhere
* `created_at`, `updated_at` on all tables
* Soft delete for user content (`deleted_at`)
* Parsed document content stored separately from raw files
* Reading analytics: aggregates only, no raw gaze frames in DB

---

# Core Entities (Phase 1)

## users

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| email | VARCHAR | unique, nullable if OAuth-only |
| password_hash | VARCHAR | nullable |
| display_name | VARCHAR | |
| avatar_url | VARCHAR | nullable |
| locale | VARCHAR(10) | default `en` |
| tier | ENUM | `free`, `premium` |
| copyright_strikes | INT | default `0`; Repeat Infringer policy — see `COPYRIGHT_AND_UPLOAD_PIPELINE.md` |
| google_id | VARCHAR | nullable, unique |
| apple_id | VARCHAR | nullable, unique |
| email_verified_at | TIMESTAMPTZ | nullable |
| deleted_at | TIMESTAMPTZ | nullable |

---

## refresh_tokens

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| token_hash | VARCHAR | never store plain token |
| device_id | VARCHAR | client-generated |
| expires_at | TIMESTAMPTZ | |
| revoked_at | TIMESTAMPTZ | nullable |

---

## folders

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK |
| parent_id | UUID | nullable, FK → folders (max depth 2 in v1) |
| name | VARCHAR | |
| deleted_at | TIMESTAMPTZ | nullable |

---

## documents

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK |
| folder_id | UUID | nullable, FK |
| title | VARCHAR | |
| original_filename | VARCHAR | |
| mime_type | VARCHAR | |
| file_size_bytes | BIGINT | |
| storage_key | VARCHAR | R2 object key |
| format | ENUM | `txt`, `md`, `epub`, `pdf`, `other` |
| parse_status | ENUM | `pending`, `processing`, `ready`, `failed`, `ocr_required` |
| parse_error | TEXT | nullable |
| word_count | INT | nullable |
| visibility | ENUM | `private`, `public` — default `private`; see `COPYRIGHT_AND_UPLOAD_PIPELINE.md` |
| review_status | ENUM | `none`, `pending`, `approved`, `rejected` — default `none` |
| content_hash | CHAR(64) | SHA-256 of raw file; computed at upload |
| ai_trust_score | DECIMAL(5,2) | nullable, 0.00–100.00; set after public review funnel |
| deleted_at | TIMESTAMPTZ | nullable |

---

## flow_documents

Parsed, normalized content for the reading engine.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| document_id | UUID | FK, unique |
| version | INT | bump on re-parse |
| content_json | JSONB | `FlowDocument` schema below |
| created_at | TIMESTAMPTZ | |

---

## FlowDocument JSON Schema (v1)

```json
{
  "version": 1,
  "title": "string",
  "language": "en",
  "blocks": [
    {
      "id": "blk_001",
      "type": "paragraph",
      "text": "Plain text content...",
      "meta": { "chapter": "Chapter 1" }
    }
  ],
  "chapters": [
    { "id": "ch_1", "title": "Chapter 1", "start_block_id": "blk_001" }
  ]
}
```

All formats (TXT, MD, EPUB, PDF) normalize to this structure.

---

## reading_progress

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK |
| document_id | UUID | FK, unique per user+doc |
| block_id | VARCHAR | current block in FlowDocument |
| char_offset | INT | offset within block |
| percent_complete | DECIMAL(5,2) | 0–100 |
| last_read_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | conflict resolution |

---

## reading_sessions

Aggregate session stats (no per-frame gaze).

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK |
| document_id | UUID | FK |
| started_at | TIMESTAMPTZ | |
| ended_at | TIMESTAMPTZ | nullable |
| duration_seconds | INT | |
| words_read_estimate | INT | |
| pause_count | INT | |
| avg_wpm | DECIMAL | nullable |
| eye_assist_enabled | BOOLEAN | |
| device_model | VARCHAR | nullable |

---

## user_settings

| Column | Type | Notes |
|--------|------|-------|
| user_id | UUID | PK, FK |
| font_family | VARCHAR | |
| font_size | INT | |
| line_height | DECIMAL | |
| theme | ENUM | `light`, `dark`, `sepia` |
| eye_assist_enabled | BOOLEAN | default true |
| smart_pause_enabled | BOOLEAN | default true |
| calibration_data | JSONB | encrypted client blob, optional sync |

---

## storage_usage

| Column | Type | Notes |
|--------|------|-------|
| user_id | UUID | PK, FK |
| bytes_used | BIGINT | |
| document_count | INT | |
| updated_at | TIMESTAMPTZ | |

---

## dmca_notices

DMCA and copyright infringement reports. See `COPYRIGHT_AND_UPLOAD_PIPELINE.md`.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| document_id | UUID | FK → documents, nullable if target unresolved |
| reporter_email | VARCHAR(255) | complainant contact |
| status | ENUM | `open`, `resolved`, `counter_notice` |
| created_at | TIMESTAMPTZ | default `now()` |

Additional columns (Phase 2.1): `raw_notice_encrypted`, `actioned_at`, `target_user_id` — see copyright pipeline doc.

---

# Phase 2+ Tables (design only, do not migrate yet)

## posts

Social feed items (quote, review, progress, thought).

## reading_rooms

Live community rooms with WebSocket presence.

## spoilers

User-generated spoiler tags linked to block_id ranges.

## gifts

Gift transactions between users.

## subscriptions

Stripe subscription id, status, period.

## ocr_jobs

Queue for scanned PDF / image OCR.

## book_universe_graphs

AI-generated character/timeline JSON per document.

---

# Indexes (Phase 1)

* `documents(user_id, deleted_at)`
* `documents(user_id, folder_id)`
* `documents(content_hash)` — hash blacklist lookups
* `documents(visibility, review_status)` — public review queue
* `reading_progress(user_id, document_id)` UNIQUE
* `reading_sessions(user_id, started_at DESC)`
* `refresh_tokens(user_id, revoked_at)`
* `dmca_notices(document_id, status)`
* `dmca_notices(status, created_at DESC)`

---

# Redis Keys (Phase 1)

| Key pattern | Purpose | TTL |
|-------------|---------|-----|
| `ratelimit:auth:{ip}` | Login rate limit | 15 min |
| `session:revoked:{jti}` | Blocked access tokens | token TTL |
| `parse:job:{document_id}` | Parse job status | 1 hour |
| `review:job:{document_id}` | Public review funnel status | 1 hour |

---

# Document Visibility Rules (enforced in API)

| visibility | review_status | Meaning |
|------------|---------------|---------|
| `private` | `none` | Default Vault state (Phase 1) |
| `private` | `pending` | Public review in progress |
| `public` | `approved` | Cleared for Feed / Marketplace surfaces |
| `private` | `rejected` | Review failed; remains personal Vault only |

`ai_trust_score` is populated when `review_status` transitions from `pending` (higher = safer to publish).

---

# Tier Limits (enforced in API)

| Tier | Documents | Storage | Formats |
|------|-----------|---------|---------|
| free | 3 | 100 MB | txt, md, epub, pdf-text |
| premium | unlimited | 10 GB | + OCR when available |

Adjust numbers in sync with `MONETIZATION.md`.

---

# ER Diagram (Phase 1)

```
users ──┬── folders ── documents ── flow_documents
        │                    │
        │                    └── dmca_notices
        ├── reading_progress ┘
        ├── reading_sessions
        ├── user_settings
        ├── storage_usage
        └── refresh_tokens
```

---

# PostgreSQL Enum Definitions

```sql
CREATE TYPE document_visibility AS ENUM ('private', 'public');
CREATE TYPE document_review_status AS ENUM ('none', 'pending', 'approved', 'rejected');
CREATE TYPE dmca_notice_status AS ENUM ('open', 'resolved', 'counter_notice');
```

---

# Related Documents

* `COPYRIGHT_AND_UPLOAD_PIPELINE.md` — BYOD, review funnel, DMCA workflow
* `API_SPEC.md` — `request-public`, `status`, `dmca-report` endpoints
