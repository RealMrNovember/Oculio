# Copyright and Upload Pipeline

> **Bring Your Own Document (BYOD)** — Oculio stores user content but does not publish it by default.
>
> This document defines the **dual-layer shield** protecting Oculio from copyright litigation: a legal safe-harbor posture and an architectural separation between private storage and public distribution.

**Status:** Architecture specification (pre-implementation)

**Related:** `LEGAL_AND_PRIVACY.md`, `VAULT.md`, `DATA_MODEL.md`, `RISKS_AND_MITIGATIONS.md` (R4)

---

# Executive Summary

Oculio allows users to upload personal reading materials (PDF, EPUB, and other supported formats). Without explicit controls, a cloud reading platform can be misused as a piracy distribution channel.

Our defense is two independent layers:

| Layer | Mechanism | Protects against |
|-------|-----------|------------------|
| **Legal** | Hosting-provider safe harbor + DMCA Notice and Takedown | Platform liability when users infringe |
| **Architectural** | Private Vault by default; public content enters a review funnel | Oculio becoming a distribution hub |

**Principle:** *Storage is not publication.* A file in Vault is a private locker, not a broadcast.

---

# 1. Legal Shield — Safe Harbor & DMCA

> **Disclaimer:** This section describes engineering-aligned legal posture. It is not legal advice. Retain qualified counsel before launch in target jurisdictions (US DMCA, EU E-Commerce Directive, Turkey KVKK/FSEK).

---

## 1.1 Hosting Provider Status

Oculio operates as a **hosting / intermediary service provider** (in US terms: **Online Service Provider** under 17 U.S.C. § 512; in EU terms: **hosting provider** under Directive 2000/31/EC Article 14).

We:

* Provide storage and reading tools at the direction of users
* Do not proactively select, edit, or curate user-uploaded files for public distribution
* Do not operate a catalog of commercially licensed ebooks in Phase 1–2 BYOD mode
* Do not index or recommend pirated titles

We do **not** claim immunity from all liability — safe harbor requires **compliance with statutory conditions**, including a functioning takedown process and repeat-infringer policy.

---

## 1.2 User Representations (Terms of Service)

At registration and on each upload, users accept:

* They own the content **or** have lawful authorization to store and read it (license, public domain, personal work)
* They will not use Oculio to distribute infringing copies to third parties
* They indemnify Oculio for claims arising from their unlawful uploads (subject to counsel review)

Upload UI displays a concise rights affirmation:

> *"I confirm I have the right to store this file for personal use."*

---

## 1.3 DMCA Designated Agent (US)

Before US public launch:

* Register a **DMCA Designated Agent** with the US Copyright Office
* Publish agent contact on `https://oculio.app/legal/dmca` (email + postal address)
* Maintain agent registration annually

---

## 1.4 Notice and Takedown — Automated Workflow

### Intake channels

| Channel | Handler |
|---------|---------|
| `dmca@oculio.app` | Primary |
| Web form `/legal/dmca/report` | Structured intake |
| Rights-holder API (Phase 3+) | Partner publishers |

### Required notice fields (validation)

* Identification of copyrighted work
* Identification of infringing material (URL, document ID, or user handle)
* Complainant contact information
* Good-faith statement
* Accuracy statement under penalty of perjury (US)
* Physical or electronic signature

Invalid or incomplete notices → auto-reply with deficiency template; **no takedown** until complete.

### Automated processing pipeline

```
DMCA Notice received (email / form / API)
    ↓
Parse + validate required fields
    ↓
Resolve target: document_id | public_post_id | marketplace_listing_id
    ↓
┌─────────────────────────────────────────┐
│  AUTO-ACTION (within SLA target: 24h)   │
│  • Disable public access immediately   │
│  • Preserve evidence snapshot          │
│  • Log complaint in dmca_notices table │
└─────────────────────────────────────────┘
    ↓
Notify uploader (counter-notice instructions)
    ↓
Await counter-notice (10–14 business days US standard)
    ↓
Restore OR permanent removal + repeat-infringer flag
```

### Private Vault takedowns

If a notice targets a **private** Vault file:

* Oculio **does not** browse private Vaults proactively
* Action is taken **only** upon valid notice identifying the specific stored object (e.g., hash match, signed URL leak, user report with evidence)
* Response: disable access to identified object; notify user; follow counter-notice process

This aligns with passive hosting — we do not perform general content monitoring of private lockers.

---

## 1.5 Repeat Infringer Policy

| Strike | Action |
|--------|--------|
| 1 | Warning + content removed |
| 2 | 30-day public upload ban |
| 3 | Account termination; Vault export window 14 days |

Strikes expire after 12 months (configurable). Enterprise accounts subject to contract terms.

---

## 1.6 Counter-Notice Flow

1. Uploader submits counter-notice via `/legal/dmca/counter`
2. System validates identity and good-faith statement
3. Forward counter-notice to original complainant
4. If no court action filed within statutory window → restore content (public only if re-approved through review funnel)

---

## 1.7 EU / Turkey Considerations

| Jurisdiction | Mechanism |
|--------------|-----------|
| EU | Notice-and-action under DSA (Digital Services Act) for larger platforms; hosting liability Article 14 |
| Turkey | FSEK + Law No. 5651 content removal notifications; local legal contact if required |

Engineering implements **jurisdiction-agnostic** notice queue; legal team maps statutory deadlines per region.

---

# 2. Architectural Solution — Private Vault vs. Public Feed

> **This is the critical separation.** Legal safe harbor reduces liability; architecture reduces **risk surface**.

---

## 2.1 BYOD Model

**Bring Your Own Document:** Users supply files from their own lawful sources (purchased ebooks, self-authored works, licensed PDFs, public-domain texts).

Oculio provides:

* Cloud sync
* Reading engine (Flow)
* Optional social layers (Phase 2+)

Oculio does **not** provide:

* A default searchable library of commercial titles
* Torrent or shadow-library integrations
* Tools to strip DRM from third-party purchases

---

## 2.2 Visibility States

Every uploaded document has a `visibility` attribute:

| State | Code | Description |
|-------|------|-------------|
| **Private Vault** | `private` | **Default.** Personal locker only |
| **Pending Review** | `pending_review` | User requested public; in compliance funnel |
| **Public** | `public` | Approved for social / marketplace surfaces |
| **Rejected** | `rejected` | Failed review; remains private |
| **Dmca Suspended** | `dmca_suspended` | Legally disabled |

```sql
-- Extension to documents table (see DATA_MODEL.md)
visibility        ENUM DEFAULT 'private'
public_requested_at TIMESTAMPTZ NULL
review_status     ENUM NULL  -- pending, approved, rejected
reviewed_at       TIMESTAMPTZ NULL
review_notes      TEXT NULL  -- internal only
```

---

## 2.3 Private Vault — Default and Absolute

**All uploads land in Private Vault.** No opt-out required; user must explicitly initiate publication.

### Private Vault guarantees (system-enforced)

| Action | Allowed in Private Vault? |
|--------|---------------------------|
| Read on own devices | ✓ |
| Sync progress | ✓ |
| Organize in folders | ✓ |
| Share file link | ✗ |
| Post to Social Feed | ✗ |
| Gift to another user | ✗ |
| List on Marketplace | ✗ |
| Appear in search / discovery | ✗ |
| Generate public embed | ✗ |

### API enforcement

```
GET /documents/:id/share-url     → 403 if visibility = private
POST /posts (with document_id)   → 403 if visibility ≠ public
POST /gifts (with document_id)   → 403 if visibility ≠ public
```

R2 signed URLs: **user-scoped**, short TTL, no anonymous access. Object keys are non-guessable UUID paths.

### Liability posture

Private Vault content is stored **at user's direction** for personal use. Oculio does not promote, surface, or monetize private files. Terms place upload responsibility on the user.

---

## 2.4 Public Feed — Opt-In Only

Public surfaces (Phase 2+) include:

* Social Feed (quotes, reviews — **text excerpts only**, never full file)
* Reading Rooms (discussion; no file distribution)
* Marketplace (Phase 3+)
* Public collections

**Full document files never appear in the Feed.** Feed posts may reference:

* Title, author (user-provided metadata)
* Short quote excerpts (≤ 300 characters, fair-use posture — counsel review)
* Reading progress percentage

To publish **anything beyond private reading**, user triggers:

```
POST /documents/:id/request-public
```

→ `visibility = pending_review` → enters **Public Upload Pipeline** (Section 3)

Until `review_status = approved`, document remains inaccessible on public surfaces.

---

## 2.5 Architecture Diagram

```
                    ┌──────────────────────────────────────┐
                    │           User Upload (BYOD)          │
                    └──────────────────┬───────────────────┘
                                       │
                                       ▼
                    ┌──────────────────────────────────────┐
                    │     PRIVATE VAULT (default)          │
                    │  • R2 encrypted storage              │
                    │  • Owner-only ACL                    │
                    │  • No public APIs                    │
                    └──────────────────┬───────────────────┘
                                       │
                         User requests public (opt-in)
                                       │
                                       ▼
                    ┌──────────────────────────────────────┐
                    │   PUBLIC UPLOAD PIPELINE             │
                    │   (Section 3 — automated funnel)     │
                    └──────────┬─────────────┬─────────────┘
                               │             │
                          REJECT          APPROVE
                               │             │
                               ▼             ▼
                    ┌──────────────┐  ┌──────────────────┐
                    │ Stay private │  │ visibility=public │
                    │ + notify user│  │ Feed / Marketplace│
                    └──────────────┘  └──────────────────┘
```

---

## 2.6 Phase Rollout

| Phase | Copyright architecture |
|-------|------------------------|
| Phase 1 | Private Vault only; no public path; ToS + upload affirmation |
| Phase 2 | Social Feed (text excerpts); `request-public` API stub returns 501 |
| Phase 2.1 | Public Upload Pipeline live for collections / curated shares |
| Phase 3 | Marketplace requires `public` + enhanced review + publisher partnerships |

---

# 3. Technical Review Funnel — Public Upload Pipeline

> Applies **only** when `visibility` transitions to `pending_review`. Private Vault uploads skip this funnel (passive hosting).

---

## 3.1 Pipeline Overview

```
request-public
    ↓
Enqueue job: public-review-pipeline
    ↓
┌─────────────────────────────────────────────────────────┐
│ Step 1 — Metadata & Regex Scan (first N pages)          │
│ Step 2 — Cryptographic Hash Blacklist                   │
│ Step 3 — AI-Assisted Similarity Check (LLM)             │
└─────────────────────────────────────────────────────────┘
    ↓
Scoring engine → AUTO_APPROVE | AUTO_REJECT | MANUAL_REVIEW
    ↓
Update document.review_status + notify user
```

**Queue:** BullMQ `public-review-pipeline` (Redis)

**SLA:** 95% of reviews complete < 5 minutes (auto); manual queue < 48 hours

---

## 3.2 Step 1 — Metadata & Regex Scan

**Scope:** First **10 pages** (or EPUB spine equivalent ≈ 5,000 words) — sufficient for copyright page detection without full-book scan cost.

### Extraction

* PDF: text layer per page 1–10; fallback OCR on page 1 only if metadata empty
* EPUB: `content.opf` metadata + first chapter text

### Signal categories

| Category | Examples | Weight |
|----------|----------|--------|
| ISBN | `ISBN-13`, `ISBN-10`, `978-*` patterns | High |
| Copyright notices | `All rights reserved`, `Tüm hakları saklıdır`, `© 20` | High |
| Publisher strings | Known publisher list (Penguin, Simon & Schuster, Can Yayınları, İletişim, etc.) | Medium |
| DRM / retail watermarks | `Adobe DRM`, `Purchased at`, `Amazon.com` | Medium |
| License permissive | `Creative Commons`, `CC BY`, `Public Domain`, `Gutenberg` | Negative (reduces score) |
| User-declared | `author = self`, matching `user.display_name` | Negative |

### Implementation

```typescript
// services/api/src/modules/compliance/regex-scanner.service.ts
interface RegexScanResult {
  score: number;           // 0–100 infringement risk
  signals: ScanSignal[];
  isbn?: string;
  detected_publishers: string[];
}
```

Publisher list: `packages/shared/data/publishers.json` — maintained quarterly.

### Thresholds

| Score | Action |
|-------|--------|
| 0–30 | Proceed to Step 2 |
| 31–60 | Proceed with elevated scrutiny |
| 61–100 | AUTO_REJECT unless user provides license proof → manual queue |

---

## 3.3 Step 2 — Cryptographic Hash Blacklist

**Purpose:** Block byte-identical matches to known infringing distributions.

### Hash computation (on upload, all files)

```
SHA-256(full file)  → documents.sha256
MD5(full file)      → documents.md5  (legacy list compatibility)
```

Computed at ingest; stored indexed. Private files are hashed but **not** compared to blacklist until public review (or DMCA forensic request).

### Blacklist sources

| Source | Update frequency |
|--------|------------------|
| Internal: DMCA-confirmed removals | Immediate |
| Partner publisher feeds (Phase 3) | Weekly |
| Industry hash lists (where licensed) | Monthly |
| Public-domain allowlist hashes | Monthly |

### Lookup

```sql
SELECT * FROM hash_blacklist
WHERE sha256 = $1 OR md5 = $1
UNION
SELECT * FROM hash_allowlist WHERE sha256 = $1  -- public domain
```

| Result | Action |
|--------|--------|
| Blacklist hit | AUTO_REJECT + strike consideration |
| Allowlist hit (Gutenberg etc.) | Fast-track AUTO_APPROVE after Step 1 |
| No match | Proceed to Step 3 |

### Near-duplicate detection (Phase 2.1)

* MinHash / simhash on extracted text for fuzzy matches
* Not in MVP funnel — noted for roadmap

---

## 3.4 Step 3 — AI-Assisted Filtering (LLM)

**Purpose:** Detect likely commercial copyrighted works even when hashes and headers are absent (re-encoded files, stripped metadata).

### Input (minimized)

* Title + author from Step 1 metadata
* Two 500-word samples: opening passage + mid-book passage (deterministic offsets)
* **Never** send full document to LLM

### Provider

| Tier | Engine | Use |
|------|--------|-----|
| Primary | Google Gemini (JSON mode) | Classification |
| Fallback | OpenAI GPT-4o-mini | If Gemini unavailable |

### Prompt structure (conceptual)

```
You are a copyright risk classifier for a hosting platform.
Given title, author, and text samples, respond JSON:
{
  "likely_copyrighted_work": boolean,
  "matched_known_work": string | null,
  "confidence": 0.0-1.0,
  "reasoning": string
}
Do not reproduce the input text.
```

### Decision matrix

| `likely_copyrighted_work` | `confidence` | Action |
|---------------------------|----------------|--------|
| true | ≥ 0.85 | AUTO_REJECT |
| true | 0.60–0.84 | MANUAL_REVIEW |
| false | ≥ 0.80 | Proceed to scoring |
| any | < 0.60 | MANUAL_REVIEW |

### Cost controls

* Max 2 LLM calls per review
* Cache result by `sha256` for 90 days
* Premium/public review quota: 10 requests/day/user

### Data processing

* LLM calls are **not** used for model training (enterprise API terms)
* Documented in Privacy Policy
* See `LEGAL_AND_PRIVACY.md`

---

## 3.5 Scoring Engine & Final Decision

```
final_score = (
  regex_score   * 0.35 +
  hash_score    * 0.40 +
  ai_score      * 0.25
)
```

| `final_score` | Decision |
|---------------|----------|
| 0–25 | AUTO_APPROVE → `visibility = public` |
| 26–50 | MANUAL_REVIEW (trust & safety queue) |
| 51–100 | AUTO_REJECT → `visibility = private`, notify user |

Manual reviewers have internal UI: signal breakdown, approve / reject / request license.

---

## 3.6 User Appeals

Rejected users may:

1. Submit proof of license (receipt, author confirmation, CC license link)
2. Route to manual queue with priority
3. Receive decision within 5 business days

---

# 4. Data Model Extensions

> **Canonical schema:** `DATA_MODEL.md` — `documents` columns (`visibility`, `review_status`, `content_hash`, `ai_trust_score`), `users.copyright_strikes`, `dmca_notices`.

```sql
-- hash_blacklist
CREATE TABLE hash_blacklist (
  id UUID PRIMARY KEY,
  sha256 CHAR(64) NOT NULL UNIQUE,
  md5 CHAR(32),
  source VARCHAR,          -- dmca, partner, internal
  work_title VARCHAR,
  created_at TIMESTAMPTZ
);

-- hash_allowlist (public domain)
CREATE TABLE hash_allowlist (
  sha256 CHAR(64) PRIMARY KEY,
  source VARCHAR,          -- gutenberg, user_gov, etc.
  work_title VARCHAR
);

-- dmca_notices (extended fields — base table in DATA_MODEL.md)
CREATE TABLE dmca_notices (
  id UUID PRIMARY KEY,
  notice_type VARCHAR,     -- takedown, counter
  complainant JSONB,
  target_document_id UUID,
  target_user_id UUID,
  status VARCHAR,          -- received, actioned, countered, closed
  received_at TIMESTAMPTZ,
  actioned_at TIMESTAMPTZ,
  raw_notice_encrypted BYTEA
);

-- public_review_jobs
CREATE TABLE public_review_jobs (
  id UUID PRIMARY KEY,
  document_id UUID REFERENCES documents(id),
  step_results JSONB,      -- regex, hash, ai scores
  final_score INT,
  decision VARCHAR,
  decided_at TIMESTAMPTZ
);
```

---

# 5. API Endpoints (Phase 2+)

> **Canonical API:** `API_SPEC.md` — `request-public`, `status`, `dmca-report`.

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/documents/:id/request-public` | Start review funnel |
| GET | `/api/v1/documents/:id/status` | Poll parse + review status |
| POST | `/api/v1/legal/dmca-report` | File takedown notice |
| POST | `/api/v1/documents/:id/appeal` | Submit license proof |
| POST | `/internal/dmca/action` | Staff action webhook |

Phase 1: only upload with `visibility = private` enforced server-side; no `request-public`.

---

# 6. Monitoring & Audit

| Metric | Alert |
|--------|-------|
| DMCA notices / week | > 10 → legal review |
| AUTO_REJECT rate | > 40% → tune regex / false positive |
| Manual queue depth | > 50 → staffing |
| Hash blacklist size | Growth anomaly |
| Appeal overturn rate | > 20% → model calibration |

All review decisions logged with retention 3 years (legal hold override).

---

# 7. Implementation Checklist

### Phase 1 (before beta)

- [ ] ToS upload affirmation UI
- [ ] `visibility = private` enforced in API and R2 ACL
- [ ] SHA-256 computed on upload (store only; no blacklist yet)
- [ ] DMCA agent page stub + `dmca@` mailbox

### Phase 2 (social launch)

- [ ] DMCA automated workflow
- [ ] Repeat infringer strikes
- [ ] Feed posts blocked from attaching `document_id` files

### Phase 2.1 (public opt-in)

- [ ] Steps 1–3 review funnel
- [ ] Manual review admin UI
- [ ] Appeal flow

### Phase 3 (marketplace)

- [ ] Publisher hash feeds
- [ ] Enhanced review for paid listings
- [ ] Stripe content policy alignment

---

# 8. Related Documents

| Document | Relationship |
|----------|--------------|
| `VAULT.md` | Private Vault default behavior |
| `LEGAL_AND_PRIVACY.md` | Privacy, ToS, GDPR |
| `RISKS_AND_MITIGATIONS.md` | R4 copyright risk |
| `DATA_MODEL.md` | Base `documents` schema |
| `API_SPEC.md` | Upload endpoints |
| `MONETIZATION.md` | Marketplace gating |
| `SOCIAL_READING.md` | Feed excerpt-only policy |
