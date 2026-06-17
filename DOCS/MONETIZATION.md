# Monetization

> **Aligned with MVP limits.** Free tier is acquisition; Premium is margin.

---

# Oculio Free

* Eye-assisted reading (mobile)
* Social Feed *(Phase 2)*
* Standard reading (manual scroll always available)
* **3 documents**
* **100 MB** total cloud storage
* TXT, Markdown, EPUB, text-layer PDF
* Basic reading stats (session time, WPM estimate)

### Not included

* OCR
* AI Coach / Book Universe
* Ambient Reading
* Unlimited storage

---

# Oculio Premium

**Monthly / annual subscription** (Stripe — Phase 3)

Unlimited:

* Document uploads (fair use: 10 GB storage cap v1)
* Cloud storage expansion tiers later
* OCR (500 pages/month launch cap)
* Lumentum AI Coach
* Engagement insights (not raw emotion labels)
* Ambient Reading environments
* Advanced statistics
* Book Universe
* Premium themes

---

# Marketplace

**Phase 3+ — requires legal review**

Users can:

* Sell books (licensed content only)
* Sell collections
* Publish research
* Share premium notes

Commission: **10% – 20%**

Payment: Stripe Connect

---

# Enterprise

Custom pricing — see `ENTERPRISE.md`

* Per-seat or site license
* SSO, analytics, corporate library
* Phase 4 sales motion

---

# Unit Economics (planning assumptions)

| Cost driver | Free tier | Mitigation |
|-------------|-----------|------------|
| R2 storage | 100 MB cap | Hard limit |
| Parse CPU | 3 docs | Queue priority lower than Premium |
| AI / OCR | None on free | Premium gate |
| Eye tracking | On-device | No server ML cost |

Target: free user infra cost < $0.05/month

---

# Upgrade Triggers (UX)

* 4th document upload → paywall
* Scanned PDF (`ocr_required`) → Premium CTA
* Book Universe teaser → Premium
* Storage > 80% → warning + upgrade

---

# Related Documents

* `MVP_SCOPE.md`
* `VAULT.md` — tier limits
* `LEGAL_AND_PRIVACY.md` — Marketplace compliance
* `OCR_ENGINE.md` — Premium OCR caps
