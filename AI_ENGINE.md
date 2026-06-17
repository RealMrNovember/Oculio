# AI Engine

> **Phase 3 module.** Phase 1 ships basic local WPM stats only.

---

# Lumentum™ — AI Reading Coach

**Status:** Phase 3

### Input data (privacy-safe aggregates)

* Words per minute (estimated)
* Focus duration (time between pauses)
* Regression count (re-read lines)
* Attention span (session length before abandon)
* Pause frequency
* Eye fatigue proxy (blink rate increase over session — heuristic only)

### Outputs

* Daily challenges
* Speed reading exercises
* Focus training routines
* Peripheral vision exercises
* Memory exercises tied to recently read content

### Not in v1

* Server-side AI required
* Personalized coaching without Premium

---

# Engagement Signals (formerly Emotion Reading™)

**Status:** Phase 3

**Important:** Do not present raw emotion classification as scientific fact. See `TECHNICAL_CONSTRAINTS.md`.

### Approach

Combine reading behavior signals:

| Signal | Indicates |
|--------|-----------|
| WPM drop > 30% | Possible fatigue or difficult content |
| Pause frequency spike | Distraction or hard passage |
| Short session + early exit | Possible disengagement |
| Regression cluster | Confusion or re-reading for pleasure |

### User-facing copy (examples)

* "You've been reading a while — take a break?"
* "This section seems dense — want a summary?" (with AI Assistant)
* **Avoid:** "You are bored."

Optional: ask user "How's it going?" → self-report enriches model with consent.

---

# AI Book Assistant

**Status:** Phase 3

User asks about current book context:

* Who is this character?
* What does this word mean?
* Summarize this chapter.
* Explain this event.

### Architecture

```
User question + current chapter text (truncated)
    ↓
NestJS AI module
    ↓
Gemini API (context window managed)
    ↓
Streamed response to mobile
```

### Constraints

* Premium only
* Rate limit: 50 questions / day
* Send minimum necessary text (chapter scope, not whole book)
* No training on user content (enterprise API terms)
* Cache common questions per document hash optional

---

# Book Universe™

See `BOOK_UNIVERSE.md`

AI extracts structured graphs from parsed FlowDocument:

* Character tree
* Timeline
* Relationship graph
* Important quotes

Batch process per chapter; merge graphs async.

---

# AI Provider Strategy

| Use case | Provider (candidate) |
|----------|---------------------|
| Q&A, summaries, graphs | Google Gemini API |
| OCR cleanup | Gemini or local |
| Future on-device | Gemini Nano (if device supports) |

### Cost control

* Token budget per user per month
* Precompute Book Universe overnight
* Cache extraction results in DB

---

# Phase 1 Reality

Only local session stats:

* duration
* estimated WPM
* pause count

No server AI. No emotion labels. No Book Universe.

---

# Related Documents

* `BOOK_UNIVERSE.md`
* `TECHNICAL_CONSTRAINTS.md`
* `LEGAL_AND_PRIVACY.md` — AI data processing
* `ROADMAP.md` — Phase 3 timeline
