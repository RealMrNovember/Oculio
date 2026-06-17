# Vault

> **Personal Cloud Library** — secure document storage and sync.

---

# Purpose

Vault is the user's private document library:

* Upload and organize reading materials
* Sync reading progress across devices
* Serve parsed content to Oculio Flow reader

Vault is **private by default**. Public sharing requires opt-in, compliance review, and approval — see **`COPYRIGHT_AND_UPLOAD_PIPELINE.md`**. Phase 2 Social surfaces carry text excerpts only, never full file distribution.

---

# Supported Formats

## Phase 1

| Format | Support | Notes |
|--------|---------|-------|
| TXT | Full Flow | Native |
| Markdown | Full Flow | Strip minimal markup |
| EPUB | Full Flow | Reflow to FlowDocument |
| PDF (text layer) | Full Flow | Extract and reflow |
| PDF (scanned) | Blocked | `ocr_required` — see OCR_ENGINE.md Phase 3 |

## Phase 2+

| Format | Support |
|--------|---------|
| DOCX | Text extraction |
| PPTX | Slide text extraction |
| Images | OCR pipeline |
| Voice Notes | Playback + transcript (Phase 3) |

---

# Storage Architecture

```
Cloudflare R2
└── oculio-vault/
    └── users/
        └── {user_id}/
            ├── raw/
            │   └── {document_id}/{original_filename}
            └── parsed/
                └── {document_id}/flow_v{version}.json
```

PostgreSQL holds metadata; R2 holds blobs.

---

# Storage Limits

| Tier | Documents | Total storage | Max file size |
|------|-----------|---------------|---------------|
| Free | 3 | 100 MB | 50 MB |
| Premium | Unlimited | 10 GB | 100 MB |

Enforced in API before upload starts. See `MONETIZATION.md`.

---

# Upload Flow

```
Client selects file
    ↓
Client checks local size + tier limits (cached from GET /storage/usage)
    ↓
POST /documents/upload (multipart)
    ↓
API validates mime + virus scan hook
    ↓
Store raw → R2
    ↓
Enqueue parse job
    ↓
Client polls or receives push (Phase 2) for parse_status
    ↓
parse_status = ready → open in Flow reader
```

---

# Folder Structure

* Max depth: 2 levels in Phase 1 (folder → subfolder)
* Documents can live at root or in any folder
* Deleting folder with documents → rejected in v1 (move first)

---

# Security

| Control | Implementation |
|---------|----------------|
| Encryption at rest | R2 server-side AES-256 |
| Encryption in transit | TLS 1.2+ |
| Access | JWT + ownership check on every request |
| Download | Signed URLs, 15 min TTL |
| Sharing | Not in Phase 1 |

### Secure sharing (Phase 2+)

* Time-limited share links
* Password-protected links optional
* Revoke at any time

---

# Offline Support (Mobile)

1. Download FlowDocument JSON + metadata to local DB (Hive)
2. Optional: cache raw file for offline re-parse
3. Reading progress queued offline → sync on reconnect
4. Conflict: server `updated_at` wins (v1)

---

# Parse Status States

| Status | User sees |
|--------|-----------|
| pending | "Preparing..." |
| processing | "Processing document..." |
| ready | Opens in reader |
| failed | Error + retry button |
| ocr_required | "Scanned PDF — OCR coming soon" + upgrade CTA |

---

# Deletion

* Soft delete in DB (`deleted_at`)
* R2 objects purged by nightly job after 30 days
* User "delete account" → full purge within 30 days (GDPR)

---

# Related Documents

* `DATA_MODEL.md` — documents, flow_documents tables
* `API_SPEC.md` — upload endpoints
* `ARCHITECTURE.md` — parse pipeline
* `OCR_ENGINE.md` — scanned content (Phase 3)
* `COPYRIGHT_AND_UPLOAD_PIPELINE.md` — BYOD, Private Vault vs Public Feed, DMCA & review funnel
* `LEGAL_AND_PRIVACY.md` — user content liability
