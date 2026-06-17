# Risks and Mitigations

> **Principle:** Name risks early. Adjust scope before writing irreversible code.

---

# Critical Risks (Product Killers)

## R1 — Front-camera gaze is not precise enough

**Risk:** Smart Scroll jumps to wrong lines; users abandon app.

**Likelihood:** High without calibration and fallback.

**Impact:** Critical — core value proposition fails.

**Mitigations:**

* Treat gaze as **assistive**, not absolute (see `TECHNICAL_CONSTRAINTS.md`)
* Mandatory calibration + recalibration prompt
* Always-visible manual scroll / tap-to-pause
* Hybrid mode: auto-scroll at user WPM + gaze nudges line alignment
* Phase 0 gate before backend investment
* Marketing copy: "eye-assisted reading" not "precision eye control"

---

## R2 — Battery drain and device heat

**Risk:** Continuous camera + ML inference drains battery in 20–30 minutes.

**Likelihood:** Medium–High on mid-range Android.

**Impact:** High — reading sessions are long.

**Mitigations:**

* Run face mesh at 15–30 FPS, not camera native FPS
* Pause pipeline when Smart Pause triggers
* Offer "Power Saver Mode" (lower FPS, reduced accuracy)
* Benchmark on reference devices; publish supported device list

---

## R3 — Privacy backlash (eye / face data)

**Risk:** Users and regulators treat eye tracking as biometric surveillance.

**Likelihood:** Medium.

**Impact:** Critical — store removal, fines (GDPR, BIPA).

**Mitigations:**

* Process gaze **on-device** by default; no raw video upload
* Explicit consent before camera; easy opt-out to manual mode
* See `LEGAL_AND_PRIVACY.md`
* Data minimization: store aggregates (WPM, session length), not frame data
* Privacy policy before beta

---

## R4 — Copyright and user-uploaded content

**Risk:** Users upload pirated books; Oculio becomes distribution hub.

**Likelihood:** High at scale.

**Impact:** Legal takedowns, payment processor bans.

**Mitigations:**

* Dual-layer shield: legal safe harbor (DMCA) + architectural Private Vault default — see **`COPYRIGHT_AND_UPLOAD_PIPELINE.md`**
* Phase 1: personal Vault only — no public sharing of files
* Public opt-in content enters automated review funnel (metadata, hash blacklist, AI) before any Feed or Marketplace surface
* Terms of Service: user warrants they own rights
* Automated Notice and Takedown workflow with designated DMCA agent
* Marketplace deferred until legal review and publisher pipeline ready
* No built-in "search torrents" or book piracy integrations

---

## R5 — Scope explosion

**Risk:** README promises 15 modules; nothing ships.

**Likelihood:** High without `MVP_SCOPE.md` discipline.

**Impact:** Critical — project never launches.

**Mitigations:**

* Ruthless Phase 0 / Phase 1 gates
* Trademark features (Lumentum™, etc.) only after MVP ships
* One reading format at a time in early sprints

---

# Technical Risks

## R6 — PDF complexity

**Risk:** PDF layout, fonts, RTL, scanned pages break Flow reader.

**Likelihood:** High.

**Mitigations:**

* Phase 1: text-layer PDF only
* Clear UX for scanned PDFs → "OCR coming in Premium"
* EPUB as primary recommended format

---

## R7 — Dual web stacks (Flutter Web + React)

**Risk:** README lists Flutter for web AND React; duplicated effort.

**Likelihood:** Certain if both built.

**Mitigations:**

* **Decision:** React for web library/admin in Phase 1; Flutter mobile only
* Update `ARCHITECTURE.md` accordingly

---

## R8 — Dual object storage (R2 + S3)

**Risk:** Operational complexity, double billing, sync bugs.

**Mitigations:**

* R2 only for MVP
* S3 documented as future multi-region option

---

## R9 — OCR cost at scale

**Risk:** OCR per page via cloud APIs is expensive.

**Mitigations:**

* Premium-only feature
* Page limits per month
* Self-hosted Tesseract for bulk; cloud API for quality tier
* Queue-based processing (BullMQ + Redis)

---

## R10 — Real-time Reading Rooms

**Risk:** WebSocket fan-out, moderation, spoiler leaks, spam.

**Mitigations:**

* Defer to Phase 2
* Design `reading_rooms` schema early but do not implement

---

## R11 — Emotion Reading accuracy

**Risk:** Feature is scientifically weak; damages trust if wrong.

**Mitigations:**

* Rename internally to "Engagement Signals"
* Never label user emotions in UI without consent
* Defer to Phase 3; use reading pace + pause patterns first

---

## R12 — Anti Motion Engine

**Risk:** Text stabilization during vehicle motion conflicts with gaze scroll.

**Mitigations:**

* Defer post-MVP
* v1: suggest "listen mode" or pause when accelerometer detects high motion

---

# Operational Risks

## R13 — Solo developer bottleneck

**Mitigations:**

* Monorepo with clear module boundaries
* AI-assisted codegen for boilerplate, not architecture
* Automated CI from week 3

---

## R14 — No observability

**Mitigations:**

* Sentry (mobile + API) from Phase 1
* Structured logging (pino)
* Health checks + uptime monitor (Uptime Kuma or similar)

---

## R15 — Insecure defaults

**Mitigations:**

* Refresh token rotation, hashed at rest
* Rate limiting on auth endpoints
* Signed URLs with short TTL
* See `SECURITY.md`

---

# Business Risks

## R16 — Free tier cost

**Risk:** Free users get eye tracking + cloud storage; infra cost before revenue.

**Mitigations:**

* Free: 3 documents, 100 MB (tighten from README if needed)
* No server-side AI on free tier
* OCR Premium-only

---

## R17 — Marketplace payment compliance

**Mitigations:**

* Defer Marketplace
* Stripe Connect + KYC when implemented
* Commission 10–20% per `MONETIZATION.md`

---

## R18 — Enterprise sales before product

**Mitigations:**

* Enterprise doc is Phase 4+ sales motion
* No SSO/SAML until Phase 3

---

# Risk Register (summary)

| ID | Risk | Severity | Phase to address |
|----|------|----------|------------------|
| R1 | Gaze accuracy | Critical | Phase 0 |
| R2 | Battery / heat | High | Phase 0–1 |
| R3 | Privacy / biometric | Critical | Before beta |
| R4 | Copyright | High | Before social/market |
| R5 | Scope creep | Critical | Now |
| R6 | PDF edge cases | Medium | Phase 1 |
| R7 | Dual web stack | Medium | Now (decided) |
| R8 | Dual storage | Low | Now (decided) |
| R9 | OCR cost | Medium | Phase 3 |
| R10 | Reading Rooms | Medium | Phase 2 |
| R11 | Emotion claims | Medium | Phase 3 |
| R12 | Anti Motion | Low | Phase 4+ |

---

# Review Cadence

* Re-read this document at each phase gate
* Add new risks when scope expands
* Close risks only with evidence (tests, legal sign-off, metrics)
