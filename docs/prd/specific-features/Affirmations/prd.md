# FEATURE REQUIREMENTS DOCUMENT

**Declarations of Truth — Affirmations Experience**

Recovery App Feature | Daily Spiritual Practice & Crisis Response Module

| Field | Value |
|-------|-------|
| **Version** | 2.0 — Pack-Based Architecture |
| **Status** | Draft — For Review |
| **Date** | April 2026 |
| **Priority** | P0 — Core Recovery Activity |
| **Audience** | Product, Engineering, UX, Clinical Advisors, Pastoral Advisory |
| **Feature Flag** | `activity.affirmations` |
| **Wave** | Wave 1 (Core P0) |
| **Source** | prd-research.md (v2.0), affirmations.md (v1.0) |

> *PASTORAL & CLINICAL NOTICE: This feature is a supplemental recovery tool rooted in Biblical truth. It is not a substitute for professional treatment, pastoral counseling, or church community. All content requires review by a CSAT and a theologically trained pastoral advisor before release.*

---

## 1. Executive Summary

Declarations of Truth is a structured daily practice of speaking Scripture-based truth over the lies that drive sexual addiction. Users engage with themed packs of declarations — free, premium, and self-curated — through an immersive, worship-like session experience accessible from multiple entry points throughout the app.

The feature is clinically calibrated using Carnes' four core beliefs framework, with a progressive level system that prevents backfire in early recovery. It is overtly Christian: every declaration is rooted in specific Scripture, framed through the Gospel, and empowered by the Holy Spirit.

**Key differentiators from v1:**
- Pack-based content model (default, premium, custom) replaces flat categories
- Multiple entry paths (Today, Work, SOS/FAB, Evening, Widget, Notification, Post-relapse)
- Immersive session experience designed as a sacred moment, not a task
- One-time pack purchases (not subscription-gated)
- Comprehensive analytics and clinical insight tracking

---

## 2. User Personas

### 2.1 Primary Personas

| Persona | Profile | Recovery Stage | Key Needs |
|---------|---------|----------------|-----------|
| **Alex** | 34, married, 45 days sober. Celebrate Recovery attendee. Evangelical. Uses app daily. | Early-to-mid recovery (Level 2) | Morning routine, accountability with wife, SOS during commute temptation |
| **Marcus** | 28, single, 7 days sober. Post-relapse. Deep shame. New to recovery. | Early recovery / post-relapse (Level 1) | Permission-level truths, no judgment, compassionate re-entry, crisis support |
| **Diego** | 42, married, 200 days sober. Small group leader. Has purchased premium packs. | Established recovery (Level 4) | Deep identity declarations, custom pack curation, marriage restoration content |
| **Sarah** | 31, single woman, 90 days sober. Attends SA. Trauma history. | Mid recovery (Level 2-3) | Gentle content, trauma-sensitive, shame resilience, evening calming |
| **Pastor James** | Counselor/Sponsor. Oversees 5 recovery group members. | Support network role | View practice consistency, mood trends, hidden declaration count (with consent) |

### 2.2 Anti-Persona

| Anti-Persona | Why They Are Not Served |
|---|---|
| **Casual self-help user** | This is not a generic affirmation app. Content assumes Christian faith and addiction recovery context. |
| **Content creator/influencer** | No social sharing of sessions. No public profiles. Privacy is paramount. |

---

## 3. User Stories

### 3.1 Daily Practice

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-AFF-001 | As a user, I want to receive a curated morning declaration session so that I start my day grounded in truth. | P0 | Session contains 3-5 declarations from active packs at my current level; 80/20 ratio; no repeat within 7 days unless favorite; completes with Daily Intention prompt. |
| US-AFF-002 | As a user, I want to complete an evening reflection with a calming declaration so that I close my day in peace. | P0 | 1 declaration (Level 1-2) + morning intention recall + day rating (1-5) + optional reflection text. |
| US-AFF-003 | As a user, I want to set my preferred morning and evening times so that declarations fit my schedule. | P1 | Times configurable in settings; notification delivered at chosen time; default morning 7:00 AM, evening 9:00 PM. |
| US-AFF-004 | As a user, I want to skip a session without penalty so that I never feel shamed for missing a day. | P0 | No streak counter. No "missed day" language. Skip logged internally only. Cumulative total unchanged. |
| US-AFF-005 | As a user, I want the Daily Intention I write in the morning to appear in my journal so that my declarations connect to my daily reflection. | P1 | Intention text stored as journal entry; pre-fills journal prompt; evening reflection surfaces it. |

### 3.2 SOS / Crisis Mode

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-AFF-010 | As a user experiencing an urge, I want to tap the SOS button and immediately see a calming screen with a breathing exercise so that I can interrupt the temptation cycle. | P0 | Response within 0-5 seconds. Full-screen calm UI. 4-7-8 breathing animation. Scripture: Psalm 46:1. Mandatory before declarations. |
| US-AFF-011 | As a user in SOS mode, I want to see grounding declarations (Level 1-2 only) so that the content matches my crisis state. | P0 | 3 declarations from SOS pack. Never above Level 2. Large text. Calming background and audio. |
| US-AFF-012 | As a user after SOS mode, I want the option to reach out to my accountability partner, sponsor, or pastor so that I don't have to face this alone. | P0 | "Reach out to someone" button → contact list. "Pray with me" button → guided prayer. "I'm okay" → gentle close. |
| US-AFF-013 | As a user, I want a gentle check-in 10 minutes after SOS so that someone cares about how I'm doing. | P1 | In-app notification only (not push). "How are you doing? God is still with you." No judgment. |
| US-AFF-014 | As a user, I want SOS mode to work offline so that I can access it anywhere. | P0 | SOS pack cached locally. Full functionality without internet. |
| US-AFF-015 | As a user, I want SOS activation to remain private unless I choose to share it so that I am never involuntarily exposed. | P0 | SOS never surfaced to partners without explicit post-session confirmation. |

### 3.3 Pack Management

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-AFF-020 | As a user, I want to browse all available packs organized by theme so that I can find content relevant to my recovery needs. | P0 | Pack library shows default (free), premium (locked with price), and custom packs. Organized by theme/category. |
| US-AFF-021 | As a user, I want to preview 3 declarations from a premium pack before purchasing so that I know what I'm buying. | P1 | Preview shows pack description, cover image, 3 sample declarations, price, purchase button. |
| US-AFF-022 | As a user, I want to purchase a premium pack once and own it forever so that I'm never locked out of content I paid for. | P0 | One-time IAP via App Store / Google Play. No subscription gating. Restore purchases across devices. |
| US-AFF-023 | As a user, I want to create custom packs by writing my own declarations and/or curating from packs I own so that I can build a personal collection. | P1 | Custom pack creation available from Day 14+. Max 20 packs, 50 declarations each. Mix custom-written + curated. Name, cover, schedule. |
| US-AFF-024 | As a user, I want to add any declaration from any owned pack to my custom pack so that I can mix and match across themes. | P1 | Browse owned packs → tap "Add to custom pack" → select target pack. Declaration appears in custom pack with source attribution. |
| US-AFF-025 | As a user, I want to write my own declarations with real-time guidance so that my custom content is therapeutically sound. | P1 | Guidance: present tense, positive framing, Scripture encouraged, max 280 chars. Warning: "Your words carry power. Make sure this feels at least partially true right now." |
| US-AFF-026 | As a user, I want to choose which packs are included in my daily rotation so that my sessions reflect my current focus. | P1 | Toggle per pack: "Include in daily rotation" on/off. At least 1 pack must be active. |
| US-AFF-027 | As a user, I want to start a session from any specific pack on demand so that I can do a focused session when I want. | P1 | "Start session" button on pack detail view. Session draws only from that pack. |

### 3.4 Immersive Experience

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-AFF-030 | As a user, I want the session to feel like a sacred moment with full-screen immersive design so that I can be fully present with God's truth. | P0 | Full-screen mode. Large serif typography (24pt+). Calming background. No status bar distractions. Fade-in transition. |
| US-AFF-031 | As a user, I want to swipe through declarations one at a time so that I can sit with each truth. | P0 | One declaration per screen. Swipe right → next. Swipe left → previous. Progress indicator (dots). |
| US-AFF-032 | As a user, I want to see the Scripture reference and optionally expand to read the full verse and a reflection so that the truth is grounded in God's Word. | P0 | Scripture ref visible below declaration. Tap/swipe-up reveals: full verse text, 1-2 sentence expansion, optional prayer. |
| US-AFF-033 | As a user, I want to choose from calming background options (nature, gradients, cross imagery) so that the visual experience supports my practice. | P1 | 12+ backgrounds. User sets default or "rotate." Categories: nature, abstract, cross/light, solid. |
| US-AFF-034 | As a user, I want ambient audio during my session (worship instrumentals, nature sounds, hymns, silence) so that the audio environment supports focus. | P1 | 5 presets: worship piano, nature, hymns instrumental, atmospheric, silence. Volume default 40%. User-adjustable. |
| US-AFF-035 | As a user, I want to pause on any declaration and enter a breathing exercise so that I can regulate when overwhelmed. | P1 | Breathing icon on every card. 4-7-8 pattern with visual animation. Scripture in center. Returns to same declaration after. |
| US-AFF-036 | As a user, I want to tap "Pray" on any declaration to see a short prayer related to that truth so that declarations naturally flow into prayer. | P1 | "Pray" button. Displays 1-2 sentence prayer. Dismissible. Does not advance session. |
| US-AFF-037 | As a user, I want an "Amen" button to close my session so that it feels like a completed spiritual act. | P2 | Optional "Amen" button on final screen. Tapping closes session with gentle fade-out. Session marked complete. |

### 3.5 Favorites & Curation

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-AFF-040 | As a user, I want to favorite any declaration so that it appears more often in my sessions. | P0 | Heart icon on every card (subtle, secondary to text). Favorited declarations prioritized in selection algorithm. |
| US-AFF-041 | As a user, I want to hide any declaration so that it never appears again. | P0 | Hide icon (subtle). Hidden declarations never surfaced. No explanation required. |
| US-AFF-042 | As a user, I want a gentle prompt after hiding 3+ declarations so that I consider whether resistance signals a growth area. | P1 | After 3 hides: "Sometimes the truths we resist most are the ones the Holy Spirit is highlighting for healing. Consider sharing this with your counselor." Shown once per week max. |
| US-AFF-043 | As a user, I want to view my favorites collection across all packs so that I have quick access to my most meaningful declarations. | P1 | Favorites view in Work/Activities tab. Shows all favorited declarations grouped by source pack. Start session from favorites. |

### 3.6 Audio & Recording

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-AFF-050 | As a user, I want to record any declaration in my own voice so that hearing truth in my own words has deeper therapeutic impact. | P1 | Mic icon on every card. Record → preview → save. Max 60 sec. AAC 64kbps .m4a. Background music mixable. |
| US-AFF-051 | As a user, I want my audio to auto-pause immediately when headphones disconnect so that my recordings are never accidentally played aloud. | P0 | AVAudioSession route-change (iOS) / AudioManager (Android). Zero-delay pause. Non-negotiable safety requirement. |
| US-AFF-052 | As a user, I want my recordings stored locally only unless I explicitly opt into cloud sync so that my voice data is private. | P0 | Local-first storage. Cloud sync opt-in in settings. Never synced by default. Never shared with partners. |
| US-AFF-053 | As a user, I want to choose background music for my recording (worship, nature, hymns, atmospheric, silence) so that the audio experience is personalized. | P1 | 5 background options. Mixed at 40% behind voice by default. User-adjustable. |

### 3.7 Progress & Milestones

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-AFF-060 | As a user, I want to see my cumulative progress (total sessions, total declarations, packs explored) so that I see evidence of my commitment without streak pressure. | P0 | Cumulative totals only. No streak counters. No "days in a row." No broken-streak language. |
| US-AFF-061 | As a user, I want to see a 30-day consistency heat map so that I can observe patterns without feeling judged for gaps. | P1 | Calendar heat map. Darker = more sessions. No empty-day callouts. No color-coding that implies failure. |
| US-AFF-062 | As a user, I want milestone celebrations at key cumulative totals so that my effort is acknowledged. | P1 | Milestones at 1, 10, 25, 50, 100, 250 sessions + first custom + first audio + first SOS + first pack purchased. Growth-mindset framing only. |
| US-AFF-063 | As a user who hasn't practiced in 3+ days, I want a gentle re-engagement prompt so that I'm welcomed back without shame. | P1 | 3 days: "Ready when you are." 7 days: "Coming back is courage." 14+ days: "Reconnect with your partner or pastor?" Never shame. |

### 3.8 Sharing & Accountability

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-AFF-070 | As a user, I want my accountability partner to see only my session count (not content) so that I have social accountability without privacy risk. | P0 | Partner view: "Sessions this week: 5." No declaration text, no custom content, no hidden declarations, no audio. |
| US-AFF-071 | As a user with a therapist/pastor, I want to consent to sharing my practice consistency, mood trend, hidden count, and level progression so that my advisor has clinical insight. | P1 | Granular opt-in per relationship. Revocable. Audit log of shared events visible to user. |
| US-AFF-072 | As an accountability partner, I want to send a pre-written encouragement to my partner so that they feel supported. | P2 | Partner selects from pre-written messages. Appears as a card on user's home screen. |

### 3.9 Post-Relapse

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-AFF-080 | As a user who just reported a relapse, I want to see compassionate Level 1 declarations only for 24 hours so that I'm not overwhelmed by identity truths I can't receive right now. | P0 | Level locked to 1. Auto-append: "God's mercies are new every morning. (Lam 3:22-23)." No identity-level declarations. |
| US-AFF-081 | As a user post-relapse, I want a compassionate declaration card on my Today screen so that the app meets me where I am. | P0 | Card: "Coming back is not failure. Coming back is repentance, and God honors repentance." Single tap → Level 1 session. |
| US-AFF-082 | As a user, I want the 24-hour relapse window to automatically expire so that I'm not stuck at Level 1 indefinitely. | P0 | After 24 hours from sobriety reset timestamp, normal level serving resumes. No user action required. |

### 3.10 Widget & Notifications

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-AFF-090 | As a user, I want a home screen widget showing today's declaration so that truth meets me outside the app. | P2 | iOS (Small, Medium) + Android widget. Rotates daily at morning time. Tap → immersive session. |
| US-AFF-091 | As a user, I want widget content to be privacy-safe so that a glance never reveals my recovery context. | P0 | Widget shows general Scripture only. No recovery language. No app name visible. |
| US-AFF-092 | As a user, I want tappable notifications that go directly into the immersive session so that there's no friction between notification and practice. | P1 | Deep link: notification tap → immersive session. No intermediate screens. |

---

## 4. User Journeys

### 4.1 Journey: First-Time User (Alex, Day 1)

```
Onboarding → Recovery context ("How long in recovery?") → Sets Level 1
  → Track selection (default: standard Christian)
  → Set morning/evening times
  → Privacy setup (biometric lock)
  → FIRST DECLARATION: Level 1 permission truth
    "It is okay to bring your brokenness to God. (Psalm 34:18)"
  → "Amen" → Welcome to your daily practice
  → Today screen shows: "Your declarations are ready" card
```

### 4.2 Journey: Morning Session (Alex, Day 45)

```
Notification: "Your daily moment is ready." (7:00 AM)
  → Tap → App opens to immersive session
  → Opening: "Take a breath. God is with you." + breathing animation (5 sec)
  → Declaration 1/3: Level 2 from "Identity in Christ" pack
    "God is doing a work in me. Phil 1:6" [Heart] [Hide] [Pray] [Audio]
    → Alex taps [Pray] → reads short prayer → dismisses
    → Swipe right →
  → Declaration 2/3: Level 2 from "Freedom from Shame" pack
    → Swipe right →
  → Declaration 3/3: Level 3 from favorites (one-level-up 20% rule)
    → Alex taps [Heart] to add to favorites
    → Swipe right →
  → Daily Intention: "Today, empowered by the Spirit, I choose to ___"
    → Alex types: "be honest with my wife about my day"
    → [Amen] → session complete
  → Today screen: checkmark on declarations card
  → Intention stored in journal
```

### 4.3 Journey: SOS Mode (Marcus, Day 7, post-relapse)

```
Marcus browsing phone → triggered → taps SOS FAB
  → IMMEDIATE: Full-screen calm. Psalm 46:1.
  → 4-7-8 breathing animation (30 seconds, mandatory)
  → Declaration 1/3: Level 1 SOS pack
    "God is your refuge right now. This moment will pass. (Psalm 46:1)"
  → Declaration 2/3: Level 1 SOS pack
  → Declaration 3/3: Level 1 SOS pack
  → Options: [Reach out to someone] [Pray with me] [I'm okay]
    → Marcus taps [Reach out] → selects sponsor → calls
  → 10 min later: in-app notification "How are you doing? God is still with you."
  → SOS NOT shared with anyone (Marcus did not confirm sharing)
```

### 4.4 Journey: Custom Pack Creation (Diego, Day 200)

```
Diego → Work/Activities tab → Affirmations → My Packs → [+ New Pack]
  → Names pack: "Morning Armor"
  → Chooses cover: sunrise gradient
  → [Add declarations]:
    → [Browse Owned Packs] → "Armor of God" premium pack
      → Selects "I put on the breastplate of righteousness. (Eph 6:14)"
      → Selects "I take up the shield of faith. (Eph 6:16)"
    → [Browse Owned Packs] → "Identity in Christ" default pack
      → Selects "I am a child of God. (Col 3:12)"
    → [Write Custom]
      → Types: "Lord, strengthen me for today's battles. In Jesus' name."
      → Guidance appears: "Scripture reference (optional):"
      → Types: "Ephesians 6:10"
      → [Save]
  → Sets schedule: Daily
  → Toggles: "Include in daily rotation" → ON
  → [Save Pack] → "Morning Armor" appears in My Packs
```

### 4.5 Journey: Post-Relapse Re-Entry (Marcus, Day 1 reset)

```
Marcus reports sobriety reset
  → System: Level locked to 1 for 24 hours
  → Today screen: compassionate card appears
    "God's mercies are new every morning. (Lam 3:22-23)"
    "Coming back is not failure. Coming back is repentance."
    [Receive truth] →
  → Level 1 session: 3 permission-level declarations
    "It is okay to start again. God is not angry. (Psalm 103:8-12)"
  → No identity-level declarations served
  → After 24 hours: Level gradually resumes based on recovery days
```

### 4.6 Journey: Evening Review (Sarah, Day 90)

```
Notification: "A moment to close your day." (9:00 PM)
  → Tap → Evening session
  → 1 calming declaration from "Evening Rest" pack (Level 2)
    "You are safe in God's hands tonight. (Psalm 4:8)"
  → Morning intention recall:
    "This morning you said: 'I choose to be kind to myself today.'"
  → "How did today feel?" → Sarah selects 4/5
  → Optional reflection: Sarah types a sentence
  → [Amen] → session complete
  → Day rating feeds mood trend chart
```

### 4.7 Journey: Premium Pack Purchase (Diego)

```
Diego → Pack Library → "Marriage Restoration" [Locked - $4.99]
  → Tap → Preview screen:
    → Cover art, description, 30 declarations
    → 3 sample declarations visible
    → "These declarations are designed for users rebuilding trust..."
    → [Purchase $4.99] → App Store sheet
  → Purchase confirmed
  → Pack unlocked → all 30 declarations accessible
  → Declarations now available for custom pack curation
  → [Start Session] or [Add to Rotation]
```

---

## 5. Analytics & Tracking

### 5.1 Product Analytics Events

All events are anonymized. No declaration content, custom text, or personal data in analytics. Opt-out available.

| Event | Properties | Purpose |
|-------|------------|---------|
| `affirmation.session.started` | `sessionType` (morning/evening/sos/on-demand), `entryPath` (today/work/sos/notification/widget/post-relapse), `packId` (if on-demand), `level` | Session engagement by entry path |
| `affirmation.session.completed` | `sessionType`, `entryPath`, `declarationCount`, `durationSeconds`, `level`, `usedBreathing` (bool), `usedPrayer` (bool) | Session completion rates, engagement depth |
| `affirmation.session.skipped` | `sessionType`, `entryPath` | Skip rates by type |
| `affirmation.session.abandoned` | `sessionType`, `declarationIndex` (which card they left on), `durationSeconds` | Drop-off analysis |
| `affirmation.declaration.viewed` | `affirmationId`, `packId`, `level`, `durationOnCard` (seconds) | Per-declaration engagement, dwell time |
| `affirmation.declaration.favorited` | `affirmationId`, `packId`, `level` | Most resonant content |
| `affirmation.declaration.hidden` | `affirmationId`, `packId`, `level` | Content rejection patterns (clinical signal) |
| `affirmation.declaration.expanded` | `affirmationId`, `expandedSection` (verse/reflection/prayer) | Depth of engagement |
| `affirmation.sos.triggered` | `entryPath` (fab/urge-report/faster-scale), `daysSober` | Crisis frequency |
| `affirmation.sos.completed` | `breathingCompleted` (bool), `reachedOut` (bool), `prayedWith` (bool), `durationSeconds` | SOS effectiveness |
| `affirmation.sos.postCheckin` | `rating` (1-5, optional), `responded` (bool) | Post-SOS wellbeing |
| `affirmation.pack.viewed` | `packId`, `packType` (default/premium/custom) | Pack discovery |
| `affirmation.pack.purchased` | `packId`, `price`, `bundleId` (if bundle) | Revenue, conversion |
| `affirmation.pack.purchaseAbandoned` | `packId`, `step` (preview/store-sheet) | Purchase funnel drop-off |
| `affirmation.custom.packCreated` | `affirmationCount`, `hasCustomWritten` (bool), `hasCurated` (bool) | Custom pack adoption |
| `affirmation.custom.declarationWritten` | `hasScripture` (bool), `charCount` | Custom content patterns |
| `affirmation.audio.recorded` | `affirmationId`, `durationSeconds`, `backgroundMusic` (enum) | Audio adoption |
| `affirmation.audio.played` | `affirmationId`, `isOwnVoice` (bool), `isNarrated` (bool) | Audio engagement |
| `affirmation.audio.headphoneDisconnect` | (none — safety event) | Safety monitoring |
| `affirmation.level.changed` | `previousLevel`, `newLevel`, `trigger` (automatic/manual/post-relapse) | Level progression |
| `affirmation.milestone.achieved` | `milestoneType`, `count` | Engagement depth |
| `affirmation.evening.dayRating` | `rating` (1-5) | Mood tracking (feeds mood trend) |
| `affirmation.reEngagement.shown` | `gapDays` (3/7/14+), `entryPath` | Re-engagement effectiveness |
| `affirmation.reEngagement.accepted` | `gapDays` | Re-engagement conversion |
| `affirmation.notification.tapped` | `notificationType` (morning/evening/reengagement/postsos) | Notification effectiveness |
| `affirmation.widget.tapped` | (none) | Widget engagement |
| `affirmation.sharing.partnerViewed` | `dataType` (sessionCount) | Accountability engagement |
| `affirmation.sharing.therapistViewed` | `dataTypes[]` (consistency/mood/hidden/level) | Clinical engagement |

### 5.2 Clinical Tracking (Non-Analytics — Stored Per-User)

These are stored in the user's private data for clinical dashboard use. Not anonymized — they are the user's personal recovery data.

| Metric | Storage | Clinical Use |
|--------|---------|-------------|
| Session history (type, date, time, duration) | MongoDB `affirmationSessions` | Practice consistency for therapist/pastor view |
| Level history (level, date, trigger) | MongoDB `affirmationProgress.levelHistory` | Level progression tracking |
| Hidden declaration count (rolling 30-day) | MongoDB `affirmationHidden` | Clinical signal — resistance to specific truths |
| Hidden declarations by core belief | Aggregation | Pattern analysis — which lies are most defended |
| Evening mood ratings (1-5, rolling) | MongoDB `affirmationSessions` (evening type) | Mood trend for deterioration detection |
| Consecutive declining mood count | Computed | Triggers pastoral/clinical prompt at 3+ |
| SOS frequency (rolling 30-day) | Aggregation | Crisis frequency for clinical oversight |
| Post-relapse session engagement | Computed | Recovery re-engagement patterns |
| Custom declaration themes | Not analyzed | Privacy — never analyzed by system |
| Favorite declaration patterns | Aggregation | Content effectiveness (which truths resonate) |

### 5.3 Key Product Metrics (KPIs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Daily Active Declaration Users (DADU)** | 60% of active app users | Users completing at least 1 session/day |
| **Morning session completion rate** | > 70% | Started sessions that reach "Amen" / all started |
| **SOS completion rate** | > 85% | SOS sessions completing breathing + all 3 declarations |
| **Evening reflection participation** | > 40% | Users completing evening session / total active users |
| **Pack purchase conversion** | > 8% | Users purchasing at least 1 premium pack / total users |
| **Custom pack creation rate** | > 15% | Users creating at least 1 custom pack / users past Day 14 |
| **Audio recording adoption** | > 10% | Users recording at least 1 declaration / total active users |
| **7-day retention (affirmations)** | > 65% | Users completing 5+ sessions in first 7 days |
| **30-day retention (affirmations)** | > 45% | Users completing 15+ sessions in first 30 days |
| **SOS → reach-out rate** | > 25% | SOS sessions where user taps "Reach out" |
| **Re-engagement conversion (3-day)** | > 40% | Users completing a session after 3-day gap prompt |
| **Mood improvement correlation** | Positive trend | Average evening rating improvement over 30/60/90 days |
| **Hide-to-therapist pipeline** | Track | Users who see hidden prompt → connect with therapist |

### 5.4 A/B Testing Opportunities

| Test | Hypothesis | Metrics |
|------|-----------|---------|
| 3 vs 5 declarations per morning session | Shorter sessions increase completion but reduce depth | Completion rate, dwell time, evening rating |
| Background rotation vs user-chosen | User choice increases ownership; rotation increases variety | Session duration, return rate |
| Prayer button visibility (always vs on-tap) | Always visible increases prayer engagement | Prayer expansion rate, session duration |
| "Amen" close vs auto-close | Spiritual closure increases satisfaction | Return rate, evening rating, qualitative feedback |
| SOS breathing duration (30s vs 60s) | Longer breathing is more effective but may lose users | SOS completion rate, post-SOS rating, reach-out rate |

---

## 6. Integrations

### 6.1 Internal App Integrations

| System | Integration Type | Direction | Details |
|--------|-----------------|-----------|---------|
| **Sobriety Counter** | Level gating | Read | Days sober determines max available level. Day 14 → L2, Day 60 → L3, Day 180 → L4. Relapse resets to L1 for 24h. |
| **Urge Reporting** | SOS trigger | Event → Action | `urge.reported` event triggers SOS affirmation mode |
| **FASTER Scale** | Contextual trigger | Read | "Ticked Off" or "Exhausted" stage → auto-suggest SOS declarations |
| **Journaling** | Content bridging | Write | Morning intention stored as journal entry. Evening reflection links to journal. |
| **Mood Tracking** | Data feed | Write | Evening day rating (1-5) writes to mood trend system |
| **Calendar Activity** | Dual-write | Write | Each completed session → `calendarActivities` entry (type: "declarations") |
| **Accountability Partner** | Summary sharing | Read (partner) | Session count this week (number only). Encouragement messages (partner → user). |
| **Therapist/Pastor View** | Clinical dashboard | Read (advisor) | With consent: consistency, mood trend, hidden count, level progression |
| **Post-Mortem** | Cross-referencing | Read | After post-mortem completion, surface declarations relevant to identified triggers |
| **Feature Flags** | Gating | Read | `activity.affirmations` controls feature visibility. Fail closed → 404. |
| **Notifications** | Scheduling | Write | Morning/evening reminders, re-engagement, post-SOS check-in |
| **Widget** | Content delivery | Read | Today's declaration for home screen widget |

### 6.2 External Integrations

| System | Integration | Details |
|--------|------------|---------|
| **App Store / Google Play** | In-app purchases | StoreKit 2 (iOS), Google Play Billing v6+ (Android). Receipt validation server-side. |
| **CMS (Contentful / custom)** | Content updates | Default pack updates delivered without app store release (hot update) |
| **Crisis Resources** | Deep links | Crisis Text Line (741741), SAMHSA (1-800-662-4357), 988 Lifeline. Direct dial/text from app. |

### 6.3 Integration Event Flow

```
User reports urge → urge.reported event
  → SOS Affirmation Mode activates (0-5 sec)
  → Breathing exercise → 3 Level 1-2 declarations
  → Session completes → affirmation.sos.completed event
  → Calendar activity dual-write
  → 10 min → post-SOS in-app check-in
  → If mood declining 3+ sessions → clinical escalation event
  → Therapist/pastor view updated (if consent granted)
```

---

## 7. Accessibility Requirements

### 7.1 Standards

- **WCAG 2.1 AA** compliance minimum across all affirmation screens
- **Section 508** compliance for US federal accessibility

### 7.2 Detailed Requirements

| Area | Requirement | Priority |
|------|-------------|----------|
| **Screen Reader** | VoiceOver (iOS) / TalkBack (Android) full support. Declarations read as: "Declaration: [text]. Scripture reference: [ref]. Tap to expand reflection." | P0 |
| **Dynamic Type** | All text scales from smallest to largest system text size settings. Declaration cards reflow correctly at all sizes. | P0 |
| **Touch Targets** | Minimum 44x44pt for all interactive elements (heart, hide, pray, audio, breathing). | P0 |
| **Color** | Color never sole indicator of meaning. Heat map uses pattern + color. Progress uses numbers + visual. | P0 |
| **Audio + Text** | All narrated/recorded audio paired with visible text. Audio enhances, never replaces. | P0 |
| **High Contrast** | Full support for high contrast / increased contrast modes on both platforms. | P1 |
| **Reduced Motion** | Setting disables: parallax backgrounds, breathing animations (replaced with static), fade transitions (replaced with instant). | P1 |
| **Keyboard Navigation** | Full keyboard navigation support for iPad with external keyboard. | P1 |
| **Switch Control** | All session interactions accessible via Switch Control (iOS) / Switch Access (Android). | P1 |
| **Caption Support** | If narrated audio is added, closed captions displayed in sync. | P2 |
| **Reading Level** | All UI text and declaration guidance at 8th-grade reading level max. | P0 |
| **Swipe Alternatives** | Tap-based navigation available as alternative to swipe gestures (next/previous buttons). | P0 |

### 7.3 Accessibility Testing

- Automated: axe-core in CI for all web views
- Manual: VoiceOver/TalkBack walkthrough for every session flow
- User testing: Include users with visual impairments in beta
- Dynamic Type: Test at every system size (xSmall through AX5)

---

## 8. Technical Requirements

### 8.1 API Endpoints (27 total)

See `specs/openapi.yaml` for full specification. Summary:

| Group | Endpoints | Methods |
|-------|-----------|---------|
| Sessions | `/activities/affirmations/session/morning`, `/session/evening` | GET, POST |
| SOS | `/activities/affirmations/sos`, `/sos/{sosId}/complete` | POST |
| Library | `/activities/affirmations/library`, `/library/{affirmationId}` | GET |
| Favorites | `/activities/affirmations/favorites`, `/favorites/{id}` | GET, POST, DELETE |
| Hidden | `/activities/affirmations/hidden`, `/hidden/{id}` | GET, POST, DELETE |
| Custom | `/activities/affirmations/custom`, `/custom/{id}` | GET, POST, PATCH, DELETE |
| Audio | `/activities/affirmations/{id}/audio` | GET, POST, DELETE |
| Progress | `/activities/affirmations/progress` | GET |
| Settings | `/activities/affirmations/settings` | GET, PATCH |
| Level | `/activities/affirmations/level`, `/level/override` | GET, POST |
| Sharing | `/activities/affirmations/sharing/summary` | GET |

### 8.2 Data Architecture

See `specs/mongodb-schema.md` for full specification. Collections:

| Collection | Purpose | Estimated Size/User/Year |
|------------|---------|--------------------------|
| `affirmationsLibrary` | Curated pack content (system-managed) | Shared — ~5 MB total |
| `affirmationSessions` | Completed session records | ~50 KB |
| `affirmationFavorites` | User favorites | ~5 KB |
| `affirmationHidden` | Hidden declarations | ~3 KB |
| `affirmationCustom` | User-written declarations | ~20 KB |
| `affirmationAudioRecordings` | Audio metadata (files on-device) | ~5 KB metadata |
| `affirmationSettings` | Per-user preferences | ~1 KB |
| `affirmationProgress` | Cumulative metrics and level history | ~10 KB |

### 8.3 Performance Requirements

| Metric | Target |
|--------|--------|
| Session load time (morning/evening) | < 500ms (cached), < 2s (cold) |
| SOS mode response time | < 500ms from tap to full-screen |
| Declaration card transition | < 100ms (swipe animation) |
| Audio recording start | < 300ms from mic tap to recording |
| Headphone disconnect → pause | < 100ms |
| Library browsing (pack list) | < 1s |
| Pack purchase confirmation | < 3s (after App Store/Play confirmation) |
| Offline session load | < 200ms (local cache) |
| Widget update | Within 1 min of morning time |

### 8.4 Offline Requirements

| Feature | Offline Support |
|---------|----------------|
| Morning session | Full (30+ declarations cached) |
| Evening session | Full |
| SOS mode | Full (SOS pack always cached) |
| Library browsing | Owned packs only |
| Favorites | Full |
| Custom packs | Full (local-first) |
| Audio playback | Full (local recordings) |
| Audio recording | Full |
| Progress viewing | Full (local state) |
| Premium purchase | Requires internet |
| CMS content update | Requires internet |

### 8.5 Security Requirements

| Requirement | Specification |
|-------------|---------------|
| Authentication | Cognito JWT (Bearer token) on all API calls |
| Tenant isolation | `tenantId` on every document, enforced at API layer |
| Data encryption (rest) | AES-256 — iOS Data Protection / Android Keystore |
| Data encryption (transit) | TLS 1.3 minimum |
| Audio storage | On-device only by default. AES-256 encrypted. |
| Biometric lock | Required by default. Face ID / Touch ID / PIN. |
| Purchase validation | Server-side receipt validation (StoreKit 2 / Play Billing) |
| HIPAA | Compliant infrastructure for all server-side data |
| GDPR/CCPA | Full export + deletion within 30 days on request |
| Feature flag | `activity.affirmations` — fail closed (404 when disabled) |

### 8.6 Platform Requirements

| Platform | Minimum Version | Framework |
|----------|----------------|-----------|
| iOS | 17.0+ | Swift + SwiftUI + SwiftData |
| Android | API 26+ (Android 8.0) | Kotlin + Jetpack Compose (placeholder) |
| Backend | Go 1.26+ on AWS Lambda (ARM64) | MongoDB Atlas, Valkey cache |
| IAP | StoreKit 2 (iOS), Play Billing v6+ (Android) | Server-side receipt validation |

---

## 9. Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-AFF-001 | Feature flag `activity.affirmations` fail-closed | 404 when disabled |
| NFR-AFF-002 | Immutable timestamps (FR2.7) | `createdAt` never modified on session/custom/audio records |
| NFR-AFF-003 | Calendar activity dual-write | Every completed session writes to `calendarActivities` |
| NFR-AFF-004 | Cumulative progress only | Zero streak-based metrics anywhere in code, UI, or notifications |
| NFR-AFF-005 | Audio headphone disconnect pause | < 100ms response time. Tested on both platforms. |
| NFR-AFF-006 | Post-relapse Level 1 lock | Automatic, 24-hour window, non-overridable |
| NFR-AFF-007 | SOS Level 2 cap | Never serve Level 3-4 in SOS mode, regardless of user state |
| NFR-AFF-008 | Healthy Sexuality double-gate | 60+ days AND explicit opt-in required |
| NFR-AFF-009 | Test coverage | >= 80% overall; 100% on level engine, clinical safeguards, privacy, audio safety |
| NFR-AFF-010 | API response time (p95) | < 500ms for all endpoints |
| NFR-AFF-011 | Offline-first | Core sessions, SOS, favorites, custom packs fully functional offline |
| NFR-AFF-012 | Notification text | 100% generic — never recovery-specific language |
| NFR-AFF-013 | Widget text | General Scripture only — never recovery-specific |
| NFR-AFF-014 | No ads | Zero advertising in the affirmations experience. Ever. |

---

## 10. Out of Scope (v1)

- AI-generated personalized declarations (Phase 2)
- Video declarations or third-party narrator for default packs
- Group/community declaration sharing (Phase 3)
- Wearable integration (Phase 2)
- Couples declaration exercises (Phase 3)
- Denominationally specific packs (Catholic, Orthodox, Pentecostal) — Phase 2
- Narrated default packs (Phase 2)
- Pastor-assigned declarations (Phase 2)
- Mood-responsive delivery (Phase 2)

---

## 11. Dependencies

| Dependency | Status | Blocks |
|------------|--------|--------|
| Sobriety counter (days sober API) | Wave 1 — In progress | Level engine |
| Urge reporting (SOS trigger event) | Wave 1 — In progress | SOS mode entry |
| FASTER Scale (stage detection) | Wave 2 — Not started | Contextual trigger |
| Journal (intention storage) | Wave 1 — In progress | Morning intention bridge |
| Mood tracking (trend system) | Wave 2 — Implemented | Evening rating feed |
| Calendar activity dual-write | Wave 0 — Complete | Session recording |
| Feature flag infrastructure | Wave 0 — Complete | Feature gating |
| Notification infrastructure (SNS/SQS) | Wave 0 — Complete | Session reminders |
| In-app purchase infrastructure | Not started | Premium pack purchases |
| CMS for content updates | Not started | Hot content updates |
| Accountability partner system | Wave 2 — Not started | Session count sharing |
| Therapist/pastor dashboard | Wave 3 — Not started | Clinical view |

---

## 12. Success Criteria

| Criteria | Measurement | Target |
|----------|-------------|--------|
| Feature adopted by active users | DADU / active users | > 60% within 30 days of GA |
| Morning session completion | Completion rate | > 70% |
| SOS mode used in crisis | SOS sessions / urge reports | > 50% of urge reports include SOS |
| Premium revenue | Monthly pack revenue | > $500 MRR within 90 days of launch |
| User retention improvement | 30-day app retention with vs without affirmations | > 15% improvement |
| Clinical signal effectiveness | Users prompted → therapist connections | > 10% of prompted users connect |
| Zero privacy incidents | Privacy breach count | 0 |
| Accessibility audit | WCAG 2.1 AA violations | 0 critical, < 5 minor |

---

*End of Document*

Feature Requirements Document v2.0 — Declarations of Truth (Affirmations Experience)
