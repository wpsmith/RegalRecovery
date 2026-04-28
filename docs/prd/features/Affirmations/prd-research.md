# FEATURE REQUIREMENTS DOCUMENT

**Affirmations Experience — Christian Recovery Edition**

Sexual Addiction Recovery App (Regal Recovery)

| Field | Value |
|-------|-------|
| **Document Version** | 2.0 — Major Revision |
| **Status** | Draft — Ready for Review |
| **Audience** | Product, Engineering, Pastoral Advisory, Clinical Advisory |
| **Supersedes** | affirmations.md (v1.0) |
| **Research Basis** | Carnes addiction model, Cascio et al. (2016) fMRI studies, Wood et al. (2009) backfire research, CSAT clinical guidelines, Celebrate Recovery curriculum, Reformers Unanimous principles, Proven Men Ministries framework, The Freedom Fight (Ted Roberts), Biblical counseling frameworks (CCEF/ACBC), competitive analysis of Abide, Glorify, Pray.com, YouVersion, I Am, ThinkUp |

> *PASTORAL & CLINICAL NOTICE: This feature is designed as a supplemental recovery tool rooted in Biblical truth. It is not a substitute for professional treatment, pastoral counseling, or church community. All content should be reviewed by both a Certified Sexual Addiction Therapist (CSAT) and a theologically trained pastoral advisor before release.*

---

## 1. Overview & Purpose

### 1.1 Feature Summary

The Affirmations Experience is a structured daily practice of declaring Biblical truth over one's life. Unlike generic affirmation tools, every declaration in Regal Recovery is rooted in Scripture — speaking God's Word over the lies that drive sexual addiction. This is not positive self-talk; it is the practice of replacing distorted core beliefs with the truth of who God says you are.

> *"Do not conform to the pattern of this world, but be transformed by the renewing of your mind."* — Romans 12:2 (NIV)

The feature is designed around three intersecting foundations:

- **Theological:** Identity is not self-constructed — it is received from God through Christ. Every affirmation traces to a specific Scripture and declares a truth about the user's identity in Christ, God's character, or the power of the Holy Spirit.

- **Clinical:** Users with low self-esteem (the defining characteristic of sexual addiction per Carnes) feel *worse* when exposed to overly aspirational affirmations (Wood, Perunovic & Lee, 2009). The progressive level system ensures declarations match the user's readiness, starting with permission-giving truths before moving to identity declarations.

- **Neurological:** Self-affirmation activates the ventral striatum and VMPFC — the brain's reward and self-valuation systems — and this neural activity predicts behavior change (Cascio et al., 2016, p = .030). Speaking Scripture aloud engages multiple neural pathways simultaneously.

### 1.2 Why Overtly Christian

This is not a generic spiritual recovery app. Regal Recovery serves men and women in SA (Sexaholics Anonymous) and Celebrate Recovery who identify as followers of Jesus Christ. The affirmations are:

- **Scripture-based** — every affirmation includes a specific Bible reference
- **Christ-centered** — identity truths flow from union with Christ, not self-improvement
- **Spirit-empowered** — framing emphasizes the Holy Spirit's power, not willpower
- **Gospel-grounded** — shame is addressed through the finished work of the cross, not positive thinking
- **Theologically careful** — reviewed by pastoral advisors, avoiding prosperity gospel, legalism, or cheap grace

> *Design principle: We are not teaching users to believe in themselves. We are teaching them to believe what God says about them.*

### 1.3 Feature Goals

- Provide a daily practice of declaring Biblical truth calibrated to recovery stage
- Progressively rebuild identity by countering Carnes' four distorted core beliefs with specific Scriptures
- Reduce shame-based rumination through the Gospel, not toxic positivity
- Create an immersive, worship-like experience that feels like a sacred moment, not an app task
- Support multiple entry paths (Today, Work, SOS, Evening, Widget, Notification, Post-relapse)
- Enable a pack-based content model with default, premium, and custom packs
- Integrate with the app's broader recovery ecosystem
- Deliver an SOS declaration response during active urge moments
- Maintain absolute privacy in every design and notification decision

### 1.4 What This Feature Is Not

- A substitute for Scripture reading, prayer, church, or professional treatment
- A passive content feed — every interaction requires intentional engagement
- A streak-based gamification system (streaks create shame spirals in recovery)
- Prosperity gospel or "name it and claim it" theology
- One-size-fits-all — content adapts to recovery stage and user preferences

---

## 2. Theological & Clinical Foundation

### 2.1 Carnes' Four Core Beliefs — Scripture Counter-Mapping

All affirmation content must map to countering at least one of the four core distorted beliefs identified by Dr. Patrick Carnes, but the counter-truth comes from Scripture, not self-talk:

| Core Belief (Lie) | Manifestation | Scripture Truth | Key Verses |
|---|---|---|---|
| "I am basically a bad, unworthy person" | Core shame; identity-level self-condemnation | You are a new creation in Christ; your identity is not defined by your sin | 2 Cor 5:17, Eph 2:10, Rom 8:1, Psalm 139:14 |
| "No one would love me as I am" | Secrecy, double life, fear of true intimacy | God loves you with an everlasting love; nothing can separate you from His love | Rom 8:38-39, Jer 31:3, 1 John 4:18-19, Zeph 3:17 |
| "My needs are never met by depending on others" | Isolation, avoidance, turning to fantasy | God is your provider; the body of Christ is designed for mutual dependence | Phil 4:19, Gal 6:2, Eccl 4:9-10, Heb 10:24-25 |
| "Sex is my most important need" | Sex as primary coping mechanism | God is your portion and your satisfaction; He meets needs sexual acting out never could | Psalm 73:25-26, Psalm 63:1-5, John 4:13-14, Psalm 107:9 |

### 2.2 Progressive Declaration Framework

The most critical clinical design constraint: never serve identity-level "I am in Christ" declarations to users in early recovery without a foundation. Research shows these backfire for low-self-esteem populations. Use a four-level progression rooted in Scripture:

| Level | Type | Example | When to Use | Theological Basis |
|---|---|---|---|---|
| 1 — Permission | Permission to receive truth | "It is okay for me to bring my brokenness to God. He is not surprised or disgusted. (Psalm 34:18)" | Days 1–30; post-relapse; onboarding | God draws near to the brokenhearted |
| 2 — Process | Declarations about the recovery journey | "God is doing a work in me. He who began a good work will carry it on to completion. (Phil 1:6)" | Days 14–90; stable early recovery | Sanctification is God's work in progress |
| 3 — Tempered Identity | Separating sin from personhood | "I have done sinful things, but I am not defined by my sin. In Christ, I am a new creation. (2 Cor 5:17)" | Days 60+; consistent engagement | Justification — declared righteous in Christ |
| 4 — Full Identity | Bold declarations of identity in Christ | "I am a child of God. I am chosen, holy, and dearly loved. (Col 3:12)" | Established recovery; 180+ days | Adoption — sons and daughters of God |

> *Design rule: Users should always be able to manually choose a lower level. Never lock users into higher levels based on time alone. Resistance to a specific declaration is spiritually and clinically informative — track and surface to the user's support network if consented.*

### 2.3 Theological Guardrails

All affirmation content must pass these theological checks:

- **Trinitarian** — Includes truths about the Father, Son, and Holy Spirit across the library
- **Gospel-centered** — Freedom comes through Christ's finished work, not human effort
- **Grace-based** — No legalism, performance theology, or conditional acceptance
- **Honest about suffering** — Acknowledges that recovery is hard; does not promise instant deliverance
- **Avoids prosperity framing** — "God will bless your efforts" is fine; "God will remove all your struggles" is not
- **Denominationally inclusive** — Protestant evangelical broadly; no distinctive Catholic, Orthodox, or charismatic-only content in default packs (premium packs may be denominationally specific)
- **Scripture-accurate** — All verses cited in context; no proof-texting

### 2.4 Contraindications & Escalation Triggers

Same clinical safeguards as v1, now with pastoral integration:

- **Worsening mood after practice (3+ sessions):** Surface prompt: "Would you like to connect with your pastor, counselor, or sponsor?"
- **Post-relapse window (24h):** Limit to Level 1 only. Append: "God's mercies are new every morning. (Lam 3:22-23)"
- **Acute crisis:** Bypass affirmations, route to crisis resources AND offer to contact pastor/sponsor
- **Persistent content rejection (5+ hides in session):** Gentle prompt: "Sometimes the truths we resist most are the ones the Holy Spirit is highlighting for healing. Consider sharing this with your counselor."

---

## 3. Content Library — Pack-Based Model

### 3.1 Pack Architecture

All affirmation content is organized into **packs** — themed collections of declarations. This replaces the flat category model from v1.

```
Pack
├── packId (unique identifier)
├── name ("Identity in Christ")
├── description (short blurb)
├── coverImage (high-quality artwork)
├── type: default | premium | custom
├── category (maps to core belief / theme)
├── level (primary level, but packs can span levels)
├── affirmationCount
├── price (null for default, one-time purchase for premium)
├── previewAffirmations[] (3 samples for premium preview)
└── affirmations[]
    ├── affirmationId
    ├── text (the declaration)
    ├── scriptureReference ("Romans 8:1")
    ├── scriptureText ("Therefore, there is now no condemnation...")
    ├── expansion (1-2 sentence reflection on the truth)
    ├── prayer (optional short prayer related to this truth)
    ├── level (1-4)
    ├── coreBeliefs[] (which of Carnes' 4 beliefs this counters)
    ├── tags[] (e.g., "shame", "identity", "temptation", "morning")
    └── audioAvailable (bool — does this have a narrated version)
```

### 3.2 Default Packs (Free, Included)

These ship with the app and cover the core recovery journey. Minimum 200 declarations across all default packs at launch.

| Pack Name | Affirmation Count | Levels | Core Belief Targeted | Description |
|---|---|---|---|---|
| **Identity in Christ** | 30 | 1–4 | #1 ("I am bad") | Who God says you are — from permission to full identity |
| **Freedom from Shame** | 25 | 1–3 | #1 ("I am bad") | Separating behavior from personhood through the cross |
| **Worthy of Love** | 25 | 2–4 | #2 ("No one would love me") | God's unconditional love; authenticity in relationships |
| **Not Alone** | 20 | 1–3 | #3 ("My needs aren't met") | Community, asking for help, trusting others and God |
| **Strength for Today** | 25 | 1–2 | All | Present-moment grounding; one day at a time with God |
| **Emotional Armor** | 20 | 1–3 | #4 ("Sex is my need") | Coping with cravings, triggers, and difficult emotions through the Spirit |
| **Purpose & Calling** | 20 | 2–4 | #4 ("Sex is my need") | Identity beyond addiction; God has plans for you |
| **Integrity Rebuilt** | 20 | 2–4 | All | Honesty, character, the recovery lifestyle |
| **SOS — Under Attack** | 25 | 1–2 | All | Emergency declarations during active urge/crisis. Short, powerful, grounding. |
| **Evening Rest** | 15 | 1–3 | All | Calming declarations for end of day; surrender and trust for sleep |

### 3.3 Premium Packs (One-Time Purchase)

Premium packs are purchased once and owned forever — never subscription-gated (per CLAUDE.md). They offer deeper exploration of specific themes.

| Pack Name | Price (est.) | Levels | Description |
|---|---|---|---|
| **Purity & Holiness** | $4.99 | 3–4 | For mid-to-established recovery. Healthy sexuality through a Biblical lens. |
| **Marriage Restoration** | $4.99 | 2–4 | For married users working on trust, intimacy, and rebuilding. CSAT-reviewed. |
| **Overcoming Temptation** | $4.99 | 1–3 | Specific to sexual temptation; spiritual warfare framing |
| **Psalms for Recovery** | $3.99 | 1–4 | 30 declarations drawn directly from Psalms with recovery application |
| **Proverbs Wisdom** | $3.99 | 2–4 | Practical wisdom declarations from Proverbs |
| **The Armor of God** | $4.99 | 2–4 | Ephesians 6 framework — daily declarations for each piece of armor |
| **Healing from Trauma** | $4.99 | 1–3 | For users with abuse history; gentle, permission-heavy. CSAT + pastoral review required. |
| **Freedom Fight Declarations** | $4.99 | 2–4 | Based on Ted Roberts' "The Freedom Fight" framework |
| **Celebrate Recovery Truths** | $3.99 | 1–3 | Aligned with CR's 8 principles and 12 steps |
| **Fatherhood & Manhood** | $4.99 | 3–4 | Identity as a godly man, father, husband |

> *Purity & Holiness pack: Must not be surfaced until the user has at least 60 days logged and has explicitly enabled this pack. Default: not visible. Requires dedicated pastoral + CSAT review cycle separate from other content.*

**Premium pack UX:**
- Packs show in the library with a "lock" indicator and price
- Tapping shows 3 preview affirmations + description
- Purchase via App Store / Google Play in-app purchase
- Once purchased, affirmations can be used in custom packs too
- No expiration — purchased forever

### 3.4 Custom Packs (User-Created)

Users can create their own packs starting from Day 14 (users need a foundation first).

**Creating a custom pack:**
1. Name the pack (max 50 characters)
2. Choose a cover color or photo from presets
3. Add affirmations by:
   - **Writing custom declarations** — with real-time guidance (present tense, positive framing, Scripture encouraged but not required, max 280 characters)
   - **Curating from owned packs** — browse any default or purchased premium pack and add individual affirmations to the custom pack
   - **Mixing** — a single custom pack can contain both custom-written and curated affirmations
4. Set the pack schedule (daily, specific days, on-demand only)
5. Choose whether to include this pack in daily rotation

**Custom pack constraints:**
- Maximum 20 custom packs per user
- Maximum 50 affirmations per custom pack
- Custom declarations are never reviewed by staff — make this clear: "Your own words carry special power. Make sure this feels true to you right now — even partially."
- Custom packs are local-first; cloud sync opt-in only

---

## 4. Immersive Session Experience

### 4.1 Design Philosophy

An affirmation session should feel like a sacred moment — a brief encounter with God's truth. The design borrows from contemplative prayer apps (Abide, Glorify) and meditation apps (Calm, Headspace) but is distinctly Christian in content and framing.

> *Design principle: This is a moment of worship, not a productivity feature. Every pixel should communicate: "Be still, and know that I am God." (Psalm 46:10)*

### 4.2 Session Structure

**Opening (5 seconds):**
- Screen fades to full-screen immersive mode
- Ambient audio fades in (if enabled)
- Brief centering text: "Take a breath. God is with you." (optional breathing animation)

**Declarations (core session):**
- One declaration per screen — text is the visual hero
- Scripture reference displayed below the declaration text
- Expansion text available via tap/swipe-up (1-2 sentence reflection)
- Prayer available via "Pray" button (short prayer related to this truth)
- Swipe right → next declaration
- Swipe left → previous declaration
- Heart icon → add to favorites (subtle, secondary to text)
- Hide icon → remove from rotation (subtle)
- Audio play → hear narrated version or own-voice recording
- Mic icon → record in own voice

**Closing:**
- Morning sessions end with Daily Intention: "Today, empowered by the Spirit, I choose to..."
- Evening sessions end with surrender: "Lord, I release this day to you..."
- SOS sessions end with: "The urge will pass. God is with you right now."
- Optional: "Amen" button to close (tactile spiritual completion)

### 4.3 Visual Design

- **Typography:** Large serif font (minimum 24pt) for declarations; generous line-height (1.8). Scripture reference in smaller sans-serif below.
- **Backgrounds:** Curated set of 12+ backgrounds:
  - Nature photography (mountains, sunrise, ocean, forest, fields)
  - Soft abstract gradients (warm earth tones, cool blues, gentle purples)
  - Subtle cross/light imagery (non-kitschy — editorial quality)
  - Solid muted colors for minimal mode
  - User can set default or let the app rotate
- **Color palette:** Calm, muted. No high-energy colors. Think dawn light, not neon.
- **Animation:** Subtle. Gentle parallax on background. Soft text fade transitions. Nothing jarring.
- **Dark mode:** Full support. Dark backgrounds with light text. No bright whites.

### 4.4 Audio Experience

- **Ambient audio options (5 presets):**
  - Worship instrumentals (soft piano, acoustic guitar)
  - Nature sounds (rain, ocean waves, forest birds)
  - Hymns instrumental (acoustic arrangements of classic hymns)
  - White noise / atmospheric
  - Silence
- **Volume:** Background audio at 40% by default; user-adjustable
- **Own-voice recording:**
  - Record any declaration in your own voice
  - Optional background music mixed behind voice (60% voice, 40% music by default)
  - AAC encoding, 64kbps minimum, .m4a format
  - Maximum 60 seconds per declaration
  - Recordings stored locally only — never synced to cloud without explicit opt-in
  - **CRITICAL: Audio must auto-pause immediately when headphones disconnect** (non-negotiable safety — personal recordings playing on speaker in public is a serious disclosure risk)
- **Narrated audio (premium feature):**
  - Professional narration available for premium packs
  - Male and female voice options
  - Calm, warm, unhurried delivery

### 4.5 Breathing Integration

Available on any declaration screen via a breathing icon:

- **4-7-8 pattern:** Inhale 4 seconds → Hold 7 seconds → Exhale 8 seconds
- Visual animation: expanding/contracting circle with Scripture verse in center
- Paired with grounding declaration: "The Lord is my shepherd. I lack nothing." (Psalm 23:1)
- Mandatory in SOS mode before declarations begin
- Optional in morning/evening sessions

---

## 5. Entry Paths

### 5.1 Today Tab — Daily Session

The primary daily touchpoint, presented as part of the morning routine.

- **Placement:** Card on the Today/Home screen: "Your declarations are ready"
- **Tap behavior:** Opens immersive session with today's curated 3-5 declarations
- **Selection logic:** Drawn from user's active packs, current level, 80/20 ratio (80% current level, 20% one level above), favorites prioritized, 7-day no-repeat
- **Completion:** Marked on Today screen with subtle checkmark. Never shame if skipped.
- **Evening:** Separate card: "A moment to close your day" — 1 calming declaration + day rating (1-5)

### 5.2 Work/Activities Tab — Full Experience

The dedicated affirmations section with complete access to everything.

- **Pack library:** Browse all packs (default, premium, custom), organized by theme
- **Individual pack view:** See all declarations in a pack, start a session from any pack
- **Favorites collection:** Quick access to all hearted declarations across all packs
- **Custom pack management:** Create, edit, reorder, delete custom packs
- **History:** View past sessions with dates (no streak display)
- **Progress:** Cumulative metrics (total sessions, total declarations practiced)
- **Settings:** Delivery times, track preferences, level info, audio preferences

### 5.3 SOS / FAB (Floating Action Button) — Emergency Mode

The highest-stakes entry point. Speed, calm, and spiritual grounding matter most.

- **Trigger:** User taps the SOS / FAB button from any screen in the app
- **Immediate response (0-5 seconds):**
  - Full-screen calm UI — no distracting elements
  - 4-7-8 breathing exercise begins automatically
  - Scripture: "God is our refuge and strength, an ever-present help in trouble." (Psalm 46:1)
- **After breathing (30 seconds):**
  - 3 Level 1-2 declarations from the SOS pack, one at a time
  - Large text, calming background, ambient audio
  - **Never above Level 2** regardless of user's progress
- **After declarations:**
  - "Reach out to someone" button → contact accountability partner, sponsor, or pastor
  - "I'm okay" button → gentle close
  - "Pray with me" button → opens guided prayer moment
- **Post-SOS check-in (10 minutes later):**
  - Gentle in-app notification: "How are you doing? God is still with you."
  - Not a push notification — in-app only
  - No judgment language
- **Privacy:** SOS activation is NEVER surfaced to accountability partners without explicit post-session confirmation
- **Offline:** SOS pack is always cached locally — must work without internet

### 5.4 Evening Review

- Presented as the closing moment of the evening reflection flow
- 1 calming declaration (Level 1-2, from Evening Rest pack or favorites)
- Displayed alongside the morning intention from the Daily Session
- User rates their day 1-5 (feeds mood trend data)
- Optional reflection text
- Framing: "How did today feel?" not "Did you stay sober?"

### 5.5 Widget — Home Screen

- iOS Widget (Small, Medium) and Android Widget
- Shows one declaration that rotates daily at the set morning time
- Tapping opens the app directly into the immersive session
- **Privacy:** Widget text must be non-specific enough that a glance won't disclose recovery context. Use general Scripture truths: "God is my strength and my shield. (Psalm 28:7)"
- Widget never shows: recovery-specific language, app name, anything that reveals the context

### 5.6 Notification — Direct to Session

- **Morning:** "Your daily moment is ready." (taps into morning session)
- **Evening:** "A moment to close your day." (taps into evening reflection)
- **Re-engagement (3-day gap):** "Ready when you are." (taps into single declaration)
- **Post-SOS (10 min):** "Checking in — how are you?" (in-app only)
- All notifications are 100% generic — never recovery-specific language
- Notification taps go directly to immersive session — no intermediate screens

### 5.7 Post-Relapse — Compassionate Declarations

When a user resets their sobriety date (reported relapse):

- Within 24 hours: Level locked to 1 (Permission level only)
- Auto-surface a compassionate declaration card on the Today screen: "God's mercies are new every morning. They never run out. (Lamentations 3:22-23)"
- Session includes grounding truths only — no identity declarations
- Tone: "Coming back is not failure. Coming back is repentance, and God honors repentance."
- After 24 hours: gradually resume normal level serving

---

## 6. Progress Tracking

### 6.1 Design Principle: Cumulative, Not Streak-Based

**This is a clinical requirement, not a preference.**

Streak-based gamification is contraindicated in sexual addiction recovery. A "broken streak" notification triggers the exact shame spiral that fuels the addiction cycle. All progress mechanics use cumulative totals.

> *Never show: "You broke your 14-day streak."*
> *Always show: "You have completed 47 declaration sessions — that is 47 moments you chose to stand on God's truth."*

### 6.2 Approved Progress Metrics

| Metric | Display |
|---|---|
| Total sessions completed | Cumulative count. Prominent on home screen. |
| Total declarations practiced | Cumulative count. |
| Packs explored | Count of packs the user has started |
| Favorite declarations | Count, shown as "Your personal collection" |
| Custom declarations created | Count |
| Days since last session | Shown only after 3+ day gap, as gentle re-engagement. Never as failure. |
| 30-day consistency | Calendar heat map — darker = more sessions. No empty-day callouts. |
| Mood trend over time | Line chart from evening ratings, weekly average. |

### 6.3 Milestone Acknowledgments

Celebrate cumulative milestones with brief, warm in-app moments (never push notifications):

| Milestone | Message |
|---|---|
| First session | "You showed up. That takes courage. God sees you." |
| 10th session | "10 moments of truth. That's real work." |
| 25th session | "25 sessions of standing on God's Word. You're building something." |
| 50th session | "50 times you chose truth over lies. Proverbs 4:18" |
| 100th session | "A hundred declarations of God's truth. This is what transformation looks like." |
| 250th session | "250 sessions. 'He who began a good work in you will carry it on to completion.' (Phil 1:6)" |
| First custom declaration | "Your own words, your own truth. That's powerful." |
| First audio recording | "Hearing truth in your own voice — science and Scripture agree this matters." |
| First SOS session | "Coming back in a hard moment is what courage looks like. God was with you." |
| First pack purchased | "Investing in your recovery. Well done." |

Milestone messages use growth-mindset framing. Avoid superlatives ("amazing," "perfect"). Prefer: "That is real work. You showed up. God is faithful."

### 6.4 Re-Engagement After a Gap

- **After 3 days:** Home screen gentle prompt: "Ready when you are. Here's one truth for right now." — single declaration, no session pressure
- **After 7 days:** Soft message: "Coming back is its own kind of courage. No catching up needed. (Lam 3:22-23)" — option to restart with a Level 1 session
- **After 14+ days:** "Would you like to reconnect with your accountability partner or pastor?" — never shame-based
- **Never:** Push notifications that reference missed days, broken patterns, or disappointing language

---

## 7. Privacy, Safety & Trauma-Informed Design

### 7.1 Privacy-First Architecture

Sexual addiction carries stigma beyond virtually any other condition. Every design decision must assume the user lives with constant fear of accidental disclosure.

| Requirement | Specification |
|---|---|
| Notification text | 100% generic. Never: "Time for declarations." Always: "Your daily moment is ready." |
| App icon & name | Generic — no cross, no recovery language visible. Configurable to alternative icon. |
| Audio auto-pause | ALL audio auto-pauses immediately on headphone disconnect. No exceptions. Non-negotiable. |
| Audio in notifications | Prohibited. No audio snippets in banners, lock screen, or widgets. |
| Biometric lock | Face ID / Touch ID required by default. PIN fallback. |
| Quick-hide / Boss screen | Shake gesture or dedicated button switches to neutral screen instantly. |
| Billing descriptor | Generic company name. Never app name or recovery language. |
| Local-first storage | Recordings, journal, custom declarations stored on-device by default. Cloud sync opt-in. |
| Data at rest encryption | AES-256 for all locally stored sensitive data. |
| Data in transit | TLS 1.3 minimum. |
| Widget content | General Scripture only — never recovery-specific language. |
| Sharing to partners | Session count only. Never declaration content, custom text, or hidden declarations. |

### 7.2 Crisis Protocol

When crisis signals are detected, affirmations pause and route to support:

- **Crisis mood rating (1/5) on two consecutive evenings** → crisis routing
- **Self-reported relapse with harm** → crisis routing
- **Explicit crisis language in reflections** → crisis routing

Crisis resources must include:
- Crisis Text Line (text HOME to 741741)
- SAMHSA Helpline (1-800-662-4357)
- National Suicide Prevention Lifeline (988)
- Option to contact designated pastor, counselor, or sponsor directly from the app
- Prayer: "Lord, be near to [name] right now. (Psalm 34:18)"

> *The app must never position itself as crisis intervention. It is a pointer to professional and pastoral resources.*

---

## 8. Integration with Recovery Ecosystem

| Integration | How It Works | Rationale |
|---|---|---|
| **Sobriety Counter** | Declaration Level adapts based on days in recovery. Level gates at Day 14 (L2), Day 60 (L3), Day 180 (L4). Manual override available. | Prevents backfire effect; matches content to readiness |
| **Urge Reporting** | Reporting an urge triggers SOS mode with Level 1-2 declarations + breathing | Interrupts preoccupation→ritualization at earliest point |
| **Journaling** | Morning intention appears as pre-filled journal prompt. Evening reflection links to journal. | Dual encoding: declaration → reflection deepens processing |
| **Mood Tracking** | Evening session day rating feeds mood trend chart. 3+ declining sessions trigger pastoral prompt. | Early detection of deterioration |
| **FASTER Scale** | If FASTER Scale assessment shows "Ticked Off" or "Exhausted" stage, auto-suggest relevant SOS declarations | Proactive intervention before acting out |
| **Accountability Partner** | Partner sees: sessions completed this week (count only, no content). Partner can send a pre-written encouragement that appears as a home card. | Social accountability without exposing private content |
| **Therapist/Pastor View** | With consent: practice consistency, hidden declaration count, mood trend, level progression. | Enables clinical/pastoral oversight; hidden declarations are diagnostic |
| **Calendar Activity** | Each completed session writes to the calendar activity feed as "Declarations" | Unified activity view |
| **Post-Mortem** | After a relapse post-mortem is completed, surface relevant declarations from the user's triggers | Cross-tool healing |

---

## 9. Monetization

### 9.1 Model: One-Time Pack Purchases

Per CLAUDE.md: content packs are purchased once and owned forever. They are NOT subscription-gated.

| Item | Price | Notes |
|---|---|---|
| Default packs (10) | Free | Included with app download |
| Premium packs | $3.99–$4.99 each | One-time purchase, owned forever |
| Pack bundles (3 packs) | $9.99 | ~30% discount |
| All Premium Pack bundle | $29.99 | All current + future premium packs |
| Narrated audio add-on | $1.99/pack | Professional narration for any pack |

### 9.2 Monetization Principles

- Recovery tools should never be paywalled. All clinically essential content (SOS, identity basics, shame resilience) is free.
- Premium packs offer *depth*, not *access*. A user on free packs has a complete recovery tool.
- No ads. Ever. This is a sacred space.
- No time-limited trials. Preview 3 declarations from any premium pack before purchase.
- Purchases are restored across devices via App Store / Google Play.
- The premium subscription ($20/month chatbot per CLAUDE.md) is separate — it does NOT gate pack access.

---

## 10. Accessibility

- WCAG 2.1 AA compliance minimum
- VoiceOver / TalkBack full support for all declaration cards and controls
- Dynamic Type support — text scales from smallest to largest system settings
- Minimum touch target: 44x44pt
- All audio paired with full text — audio enhances, never replaces
- Color never sole indicator of meaning
- High contrast mode support
- Reduced motion mode — disables parallax and breathing animations
- Screen reader: declarations read as "Declaration: [text]. Scripture reference: [ref]."

---

## 11. Technical Requirements

### 11.1 Level Engine

- Algorithm determines declaration Level based on: days in recovery, recent mood ratings, manual override, post-relapse state, time since last session
- Level state persists across sessions and device restarts
- Manual override: user can always select lower level; can request upgrade after 30 days at current level
- Level changes logged with timestamp for clinical dashboard
- Post-relapse: automatic lock to Level 1 for 24 hours (non-negotiable)
- SOS mode: never above Level 2 (non-negotiable)

### 11.2 Content Delivery

- Declaration selection: (1) user's favorites, (2) active packs weighted by current level with 80/20 ratio, (3) 7-day no-repeat unless favorite
- SOS pack maintained as separate, always-available local cache — must work offline
- Content library updates via CMS without app store release (hot update for default packs)
- Offline mode: minimum 30 declarations cached locally plus full SOS pack
- Premium pack content downloaded on purchase and cached locally

### 11.3 Audio

- On-device recording using device microphone
- AAC encoding, 64kbps minimum, .m4a format
- Headphone disconnect detection → immediate audio pause (AVAudioSession route-change on iOS, AudioManager focus on Android)
- Background music mixed at 40% volume relative to voice recording by default; user-adjustable
- Maximum 60 seconds per declaration recording
- Ambient audio streamed or bundled (bundle for offline reliability)

### 11.4 Pack Purchases

- iOS: StoreKit 2 for in-app purchases
- Android: Google Play Billing Library v6+
- Purchase state synced to user account (server-side receipt validation)
- Purchased packs accessible across devices
- Restore purchases flow required
- No purchase required for core recovery features

### 11.5 Data & Compliance

- HIPAA-compliant infrastructure for server-side data
- Local data encrypted at rest (AES-256) — iOS Data Protection / Android Keystore
- GDPR / CCPA compliant — full export and deletion on request within 30 days
- No declaration content or journal data used for advertising or ML training
- Anonymized aggregate analytics only (session counts, level distribution) — opt-out available

### 11.6 Feature Flag

- Feature flag: `activity.affirmations`
- Fail closed: returns 404 when disabled
- Rollout: dev → staging → 10% canary → 25% → 50% → 100%

---

## 12. Out of Scope & Future Phases

### 12.1 Out of Scope for v1

- AI-generated personalized declarations (Phase 2 — requires pastoral review pipeline)
- Video declarations or third-party narrator for default packs
- Group/community declaration sharing (Phase 3 — privacy risk)
- Wearable integration (Phase 2)
- Couples declaration exercises (Phase 3 — requires CSAT + pastoral)
- Denominationally specific packs (Catholic, Orthodox, Pentecostal) — Phase 2

### 12.2 Phase 2 Candidates

- **AI personalization:** Compose declarations from user's own language (journal entries, prayers), reviewed by AI safety + pastoral filter before delivery
- **Mood-responsive delivery:** Select declaration categories based on pre-session mood check-in
- **Apple Watch / Wear OS:** Brief declaration on wrist; haptic-triggered breathing
- **Pastor-assigned declarations:** Pastor can push specific declarations to a user's favorites with a session note
- **Denominational premium packs:** Catholic (saints, sacraments), Orthodox (theosis), Pentecostal (spiritual warfare emphasis)
- **Narrated default packs:** Professional narration for all free content

### 12.3 Open Research Questions

- What is the optimal declaration frequency for sexual addiction populations — daily, twice daily, or on-demand?
- Does own-voice recording produce measurably better outcomes than text-only at 90 days?
- How does trauma history moderate declaration response in faith-based framing?
- What is the "backfire threshold" for identity-level declarations in Christian populations specifically (vs. secular populations studied by Wood et al.)?
- Does Scripture-grounding reduce backfire compared to generic positive affirmations at equivalent levels?

---

*End of Document*

Feature Requirements Document v2.0 — Affirmations Experience (Christian Recovery Edition)
