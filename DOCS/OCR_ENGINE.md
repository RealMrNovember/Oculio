# OCR Engine

> **Phase 3 feature.** Phase 1 detects scanned PDFs and surfaces `ocr_required` — no silent broken reading.

---

# Purpose

Convert non-text content into FlowDocument format:

* Scanned PDF pages
* Photographed book pages
* Image uploads (PNG, JPG)
* Low-quality document scans

---

# Phase 1 Behavior (pre-OCR)

When PDF parser finds no text layer:

1. Set `parse_status = ocr_required`
2. Show user-friendly message in app
3. Offer Premium waitlist / notify-me (optional)
4. Do **not** show empty reader or garbage text

---

# Supported Input (Phase 3)

| Input | Priority |
|-------|----------|
| Scanned PDF | P0 |
| PNG / JPG images | P1 |
| DOCX embedded images | P2 |
| Handwritten notes | P3 (low accuracy expected) |

---

# OCR Pipeline

```
Document flagged ocr_required
    ↓
Split PDF into page images (300 DPI target)
    ↓
Image preprocessing
    ├── Deskew
    ├── Contrast normalization
    └── Noise reduction
    ↓
OCR engine (tiered)
    ↓
Text block detection
    ↓
Paragraph / reading order reconstruction
    ↓
Language detection
    ↓
Normalize → FlowDocument JSON
    ↓
parse_status = ready
```

---

# Engine Tiers

| Tier | Engine | Use case | Cost |
|------|--------|----------|------|
| Bulk | Tesseract 5 (self-hosted) | Premium batch jobs | Low |
| Quality | Google Cloud Vision / AWS Textract | Complex layouts, multi-column | High |
| AI cleanup | Gemini (optional) | Fix OCR errors, structure chapters | Medium |

**Default:** Tesseract for 80% of pages; escalate to cloud API on low confidence score.

---

# Confidence Scoring

Per page OCR confidence:

* < 0.70 → retry with preprocessing variant
* < 0.50 after retry → flag page for manual review UI (Phase 3.1)
* > 0.85 → accept

Store per-page confidence in parse metadata for support debugging.

---

# Job Queue

```
ocr_jobs table + BullMQ queue: document-ocr
```

| Field | Notes |
|-------|-------|
| document_id | FK |
| status | queued, processing, done, failed |
| pages_total | |
| pages_done | progress for UI |
| engine_used | tesseract / vision |
| cost_cents | internal tracking |

Worker pool: 1–2 workers Phase 3 launch; scale with queue depth.

---

# Premium Gating

| Tier | OCR |
|------|-----|
| Free | Not available |
| Premium | 500 pages / month (adjust after cost modeling) |

---

# Cost Controls

* Page count estimate before job starts → user confirm
* Hard monthly cap per user
* Cache OCR result by document hash (re-upload same file = instant)
* Downscale images > 300 DPI before OCR

---

# Languages

Launch: English + Turkish

Phase 3.1: major European languages

Tesseract `traineddata` per language; auto-detect via `franc` or API.

---

# Quality UX

* Progress bar: "Processing page 42 of 300"
* Notify when complete (push Phase 3)
* Side-by-side: original scan + extracted text (debug / trust)
* User can report bad page

---

# Legal Note

OCR does not grant copyright to scanned books. User must own rights. See `LEGAL_AND_PRIVACY.md`.

---

# Related Documents

* `VAULT.md` — ocr_required status
* `ARCHITECTURE.md` — worker infrastructure
* `MONETIZATION.md` — Premium OCR access
* `MVP_SCOPE.md` — Phase 1 vs Phase 3 scope
