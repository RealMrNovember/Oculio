# Legal and Privacy

> **Required reading before public beta.** Eye tracking + user documents + AI = high compliance surface.

This is engineering guidance, not legal advice. Consult a lawyer before launch in your target markets.

---

# Data Categories Oculio Handles

| Category | Examples | Sensitivity |
|----------|----------|-------------|
| Account data | email, name, OAuth ids | Standard PII |
| Content data | uploaded books, notes | User intellectual property |
| Reading behavior | progress, WPM, session length | Behavioral |
| Biometric-adjacent | face landmarks, gaze calibration | **High** — may qualify as biometric in some jurisdictions |
| Payment data | Stripe tokens (Phase 2+) | PCI delegated to Stripe |

---

# Biometric / Eye Tracking Compliance

## GDPR (EU / EEA)

* Face/eye data for identification or behavioral profiling may be **special category** data in some interpretations
* Requires: explicit consent, DPIA (Data Protection Impact Assessment), data minimization
* Right to erasure must delete calibration blobs and session aggregates

## BIPA (Illinois, USA)

* If storing "biometric identifiers" (face geometry templates), written consent + retention policy required
* **Mitigation:** process frames on-device; do not store raw face templates server-side; store only user-consented calibration coefficients

## App Store / Play Store

* Declare camera usage accurately
* Privacy nutrition labels: "Reading assistance" not "Advertising"
* iOS `NSCameraUsageDescription` must explain eye-assisted reading

---

# On-Device Processing (default)

| Data | Where processed | Stored server-side? |
|------|-----------------|---------------------|
| Camera frames | Device only | **Never** |
| Gaze calibration | Device | Optional encrypted blob (user opt-in sync) |
| Session aggregates | Device → API | Yes (WPM, duration, pause count) |
| Raw landmark streams | Device only | **Never** |

---

# Consent Flow (required UX)

### First launch (before camera)

1. Explain eye-assisted reading
2. Link to Privacy Policy
3. Choice: **Enable Smart Reading** or **Manual mode only**
4. If enabled → OS camera permission

### Settings (always available)

* Disable eye assist
* Delete all reading analytics
* Export my data
* Delete account

---

# Privacy Policy Must Cover

* What data is collected
* Why (reading assistance, sync, improvement)
* Retention periods
* Third parties (Google OAuth, Apple, Cloudflare, future AI providers)
* International transfers
* Contact for DPO / privacy requests
* Children's policy (13+ or 16+ in EU — **no targeted underage**)

---

# Terms of Service Must Cover

* User owns uploaded content OR has rights to store it
* Prohibition on uploading pirated copyrighted material
* Acceptable use for social features (Phase 2+)
* Account termination
* Limitation of liability
* Governing law

---

# Copyright and Content

> **Full architecture:** `COPYRIGHT_AND_UPLOAD_PIPELINE.md` — BYOD model, Private Vault default, DMCA workflow, public review funnel.

## Phase 1 (personal Vault)

* User uploads for personal use
* Oculio is a tool, not a publisher
* Implement copyright complaint email + takedown process before scale

## Marketplace (Phase 3+)

* Requires publisher agreements or user-generated content only
* DRM considerations for sold ebooks
* Revenue share and tax (Stripe Connect KYC)
* **Do not launch Marketplace without legal review**

## OCR of scanned books

* User uploading scanned copyrighted book = same liability as upload
* Do not market OCR as "digitize any book"

---

# AI Processing (Phase 3+)

When sending document text to Gemini or other LLMs:

* Inform user in Privacy Policy
* Premium opt-in for AI features
* Do not send content to train models (use enterprise API terms)
* EU users: document legal basis (consent or legitimate interest analysis)

---

# Enterprise (Phase 4+)

* Data Processing Agreement (DPA) with corporate customers
* SSO may require SAML/OIDC
* Data residency options may be required (EU hosting)

---

# Security Alignment

See `SECURITY.md` for technical controls. Legal alignment:

| Control | Legal benefit |
|---------|---------------|
| AES-256 at rest | Security expectation |
| Signed URLs | Prevents unauthorized sharing |
| Account deletion | GDPR erasure |
| Audit logs (Enterprise) | Compliance evidence |

---

# Retention Policy (recommended)

| Data | Retention |
|------|-----------|
| Deleted account content | Purge within 30 days |
| Reading sessions | 24 months, then aggregate |
| Auth logs | 90 days |
| Refresh tokens | Until expiry or revoke |
| OCR job temp files | 24 hours |

---

# Children's Privacy

* Do not market to children under 13
* Age gate at registration (birth year or 13+ checkbox)
* No eye tracking without parental consent if allowing minors (simplest: 16+ only)

---

# Turkey (KVKK) — if targeting TR market

* Turkish privacy policy version
* Explicit consent for sensitive data processing
* Data controller registration considerations
* Local representative if required

---

# Pre-Launch Checklist

- [ ] Privacy Policy published (EN + TR if needed)
- [ ] Terms of Service published
- [ ] Camera consent copy reviewed
- [ ] DPIA drafted for eye tracking
- [ ] Account deletion flow tested end-to-end
- [ ] Data export endpoint or manual process defined
- [ ] Cookie policy for web app
- [ ] App Store privacy questionnaire completed accurately
- [ ] Copyright complaint process documented

---

# Related Documents

* `SECURITY.md`
* `RISKS_AND_MITIGATIONS.md` — R3, R4
* `TECHNICAL_CONSTRAINTS.md` — on-device processing
* `MVP_SCOPE.md` — Phase 1 compliance gate
