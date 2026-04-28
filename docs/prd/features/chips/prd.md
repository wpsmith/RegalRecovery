# Functional requirements for a multi-fellowship chip system

**This document specifies the functional requirements for a sobriety chip/milestone system in a B2C mobile addiction recovery app, designed to support 20+ Anonymous fellowships plus a generalized scheme for any other addiction.** The core architectural decision is a **parallel-clocks data model** (each addiction is a first-class tracker) combined with a **fellowship-themed visual layer** that respects the chip traditions, colors, and symbology of each program — while never claiming endorsement (Tradition 6). Recovery is non-linear: 40–60% of people experience at least one relapse and average five recovery attempts, so reset, lapse, and grace mechanics are not edge cases — they are core flows. The requirements below assume an iOS + Android native app with offline-first behavior, anonymous-by-default accounts, and trauma-informed copy reviewed against SAMHSA and ISSUP language guidance.

This FRD is organized as: scope and goals, fellowship coverage matrix, milestone definitions, visual theming, user stories, data model, notifications, social and celebration, reset/relapse, privacy, edge cases, and acceptance criteria.

---

## 1. Scope, principles, and non-goals

The chip system tracks a user's sobriety/abstinence milestones across one or more addictions, represented visually as **chips, key tags, or medallions** styled to match the user's chosen fellowship tradition — or a generic "universal" theme when no fellowship applies. **The system must work for fellowships that do not traditionally use chips at all** (FA, WA), for fellowships that recognize only annual anniversaries (GA, EA, CoDA), and for fellowships with codified monthly color schemes (NA, AA, CA).

Five non-negotiable design principles govern every requirement:

1. **No fellowship endorsement.** Per Tradition 6, no fellowship has officially licensed its logo or chip designs to consumer apps. Use generic shapes and color conventions; surface a disclosure that designs are inspired by — not affiliated with — the named program.
2. **Recovery is non-linear.** Reset is expected. Milestones earned are *never* deleted on reset; only the active streak counter resets.
3. **Anonymity is safety, not preference.** Stigma around addiction (especially SAA, SLAA, CMA, sex/porn recovery) makes anonymity protective. Default to no-account, on-device-only operation.
4. **Compassionate copy throughout.** Reviewed against SAMHSA's recovery language guidance; avoid "clean/dirty," "addict" as identity, "fail," "fall off the wagon."
5. **Loss-aversion is dangerous in recovery.** Streak weaponization triggers the "What-the-Hell Effect" — a slip becomes a relapse because the user feels they've "ruined it." Safety valves (lapse/relapse distinction, grace period, milestone preservation) are mandatory, not optional.

**Non-goals**: This system does not provide clinical advice, does not replace 12-step meeting attendance, does not enforce a specific abstinence definition, and does not gate features on payment in ways that create shame (e.g., paid streak revival).

---

## 2. Fellowship coverage and chip-tradition matrix

The system supports **20 named fellowships plus a "Custom/Other" generic profile**. Each fellowship has a stored *tradition profile* that determines milestone schedule, available chip types, default colors, default symbols, and centrality weighting. The matrix below codifies the requirement.

| Fellowship | Token type | Monthly colored chips? | Annual medallions? | Default centrality | Default abstinence definition |
|---|---|---|---|---|---|
| **AA** | Plastic chips + bronze | Yes (white/red/gold/green/blue/bronze) | Yes | High | Alcohol |
| **NA** | Plastic key tags + bronze | Yes (white/orange/green/red/blue/yellow/glow/gray/black) | Yes | Very high | All mind-altering substances |
| **CA** | Key tags + bronze (NA-style) | Yes (NA-style) | Yes | High | All mind-altering substances |
| **CMA** | Chips + bronze | Yes (red/green/gold) | Yes | High | Meth + alcohol + non-prescribed meds |
| **MA** | Plastic/wood + bronze (3rd party) | Loose | Yes | Medium | Marijuana |
| **HA** | Silver key chains + bronze | Silver early-time | Yes | Medium | All mind-altering substances |
| **PA** | Key tags + medallions | Yes (NA-style) | Yes | Medium | All mood/mind-altering substances |
| **NicA** | Plastic chips | Loose | Yes | Low | All nicotine forms |
| **GA** | Bronze only | **No** | Yes (all bronze, monthly pins year 1 sometimes) | Annual-only | Gambling |
| **OA** | Aluminum + bronze/silver | Loose | Yes (bronze yr 1/5/10+; silver yr 2-4) | Medium | Personal food plan |
| **DA** | Plastic chips (informal) | **No** | Loose | Low | New unsecured debt |
| **EA** | Pins + medallions | **No** | Yes (Roman numeral pins yr 1–40) | Low (annual-only) | Emotional patterns (personalized) |
| **FA** | **None** | **No** | **No** (verbal only) | Absent | Strict food plan (90-day key milestone) |
| **WA** | **None** | **No** | **No** | Absent | Personal "bottom lines" |
| **CoDA** | Bronze | **No** | Yes (Roman→Arabic at yr 30) | Annual-only | Codependent patterns (personal) |
| **ACA** | Aluminum + bronze | Loose | Yes (yr 1–40) | Low | Laundry-list traits (personal) |
| **Al-Anon** | Bronze + Pink Cloud Chip | **No** | Yes (variable) | Variable / often absent | Date of first meeting (no abstinence) |
| **SA** | Chips + medallions | Loose (white desire) | Yes | Medium | Group-defined (strict) |
| **SAA** | Plastic chips + key rings + bronze | Yes (Desire chip) | Yes | High | Personal "inner circle" behaviors |
| **SLAA** | Plastic chips + bronze + Step chips | Yes (white 1-day) | Yes (blank bronze) | High | Personal "three circles" |
| **Custom/Other** | Generic universal theme | User-configurable | Yes | User-configurable | User-defined |

**Functional requirements driven by this matrix:**

- **FR-FEL-1**: The system must support tradition profiles for all 20 named fellowships plus a Custom profile. Profiles are read-only at runtime (versioned in app config), allowing remote update without app release.
- **FR-FEL-2**: For fellowships marked "None" (FA, WA), the chip UI must default to **off**; the user can opt in to a generic milestone theme. The default is verbal-recognition-only with optional date tracker.
- **FR-FEL-3**: For "annual-only" fellowships (GA, EA, CoDA, Al-Anon), monthly chips must be hidden by default and exposed only via "Advanced milestones" toggle. Anniversary medallions are the primary milestone surface.
- **FR-FEL-4**: For SA (heteronormative sobriety definition), SLAA, SAA, OA, FA — where abstinence is personally defined — the user must be able to write their own abstinence definition during onboarding, stored as free-text and surfaced at relapse-confirmation time ("Your definition: [text]. Did this happen?").
- **FR-FEL-5**: Disclosure copy at first chip view: "Chip designs are inspired by traditions in the recovery community. This app is not affiliated with, endorsed by, or licensed by any 12-step fellowship."
- **FR-FEL-6**: Users with co-occurring fellowships (e.g., AA + NA + SAA, common in practice) can run simultaneous trackers, each with its own tradition profile.

---

## 3. Milestone schedule and definitions

The user-facing milestone schedule is the standardized superset across fellowships, fitted to the user's request:

**Standard milestones**: Commitment Chip (Day 0 / Surrender), 1 month, 2 months, 3 months, 4 months, 5 months, 6 months, 7 months, 8 months, 9 months, 10 months, 11 months, 1 year, 18 months, 2 years, then annually.

**Functional requirements:**

- **FR-MS-1**: Day 0 (Commitment/Surrender Chip) is awarded the moment the user creates a tracker, regardless of past sober time. This mirrors AA's "white chip" / NA's "welcome key tag" / SAA's "desire chip" tradition — *the act of asking is the first milestone*.
- **FR-MS-2**: The "month" boundary is calendar-based: a 1-month chip awards on the same day-of-month as the start date, rolling forward (e.g., March 15 → April 15). For starts on Jan 31, the system rolls to the last day of the next month (Feb 28/29). This matches user intuition.
- **FR-MS-3**: Each fellowship's tradition profile may **add or hide** milestones from this base set. Examples:
  - NA profile *adds*: 24-hour, 60-day, 90-day key tags (in addition to monthly chips).
  - AA profile *adds*: 24-hour desire chip, 60-day, 90-day chips.
  - GA profile *hides*: all monthly chips except 1-year and beyond.
  - FA profile shows only: 90-day key milestone + annual.
  - SLAA profile *adds*: 1-week chip, 12 Step-completion chips (independent of time).
- **FR-MS-4**: After year 2, annual milestones are mandatory. After year 30, CoDA-style profiles render the year in Arabic rather than Roman numerals (per CoDA 2016 vote).
- **FR-MS-5**: Users can define **custom milestones** at any tracker (e.g., "100 days," "first sober birthday," "wedding anniversary sober"). Custom milestones are awarded in their own visual lane, distinguishable from fellowship traditional chips.
- **FR-MS-6**: Step-completion chips (SLAA tradition, optionally exposed to other fellowships) award when the user marks each of the 12 Steps complete — independent of time. These are stored in a parallel `stepChips` collection.

---

## 4. Chip visual theming requirements

Each tradition profile defines a **theme bundle**: shape (round chip / dog-tag key tag / medallion), color per milestone, default symbol, and edge-text.

**Functional requirements:**

- **FR-VIS-1**: The system ships with at minimum these default color palettes, configurable per fellowship:
  - **AA palette**: white = Day 0/24hr, red = 30 days, gold/yellow = 60 days, green = 90 days, purple = 4 months, pink = 5 months, dark blue = 6 months, copper = 7 months, red = 8 months, purple = 9 months, gold = 10 months, bronze = 1 year+. Edge text option: "To Thine Own Self Be True"; reverse: Serenity Prayer.
  - **NA palette** (key-tag shape, not chip): white = Welcome, orange = 30 days, green = 60 days, red = 90 days, blue = 6 months, yellow = 9 months, glow-effect = 1 year, gray = 18 months, black = multi-year. Reverse text: "Just for Today."
  - **CA palette**: NA-style colors with CA logo (triangle); motto: "Hope, Faith, Courage."
  - **CMA palette**: Red Day 1, green 30 days, gold annual; pyramid logo with "Unity, Service, Recovery."
  - **HA palette**: Silver monochrome for early time (30/60/90/6mo/9mo); bronze annual.
  - **OA palette**: Bronze yr 1/5/10/15/20+; silver-tone yr 2/3/4/6/7/8/9/11/12/13/14/16/17/18/19; "One Day at a Time" / "I put my hand in yours…"
  - **CoDA palette**: Bronze annuals only; "To Thine Own Self Be True" (shared with AA); Roman→Arabic at yr 30.
  - **Al-Anon palette**: Bronze annuals; optional "Pink Cloud" chip for early-recovery euphoria; butterfly imagery.
  - **SLAA palette**: White-and-gold 1-day chip; lifesaver ring symbol; "You Are Not Alone."
  - **SAA palette**: Desire chip prominent; user's individual abstinence definition surfaced in chip detail view.
  - **Universal palette** (Custom/Other and FA/WA opt-in): Neutral color spectrum, abstract geometric symbol, no fellowship-specific text.
- **FR-VIS-2**: Chip shape varies by tradition — round poker-chip (AA), dog-tag with notch (NA, CA, PA), bronze medallion (annuals across fellowships), key chain (HA), aluminum disc (OA, ACA). The shape is a property of the tradition profile.
- **FR-VIS-3**: Chips render in three contexts: a **gallery view** (collected chips, similar to Nomo's chip cabinet), an **active counter view** (current chip large, next chip teased), and a **detail view** (front, back, milestone date, journal entry, optional share).
- **FR-VIS-4**: The Commitment Chip (Day 0) is **always given** regardless of fellowship and visually denotes "I am here" rather than "I am sober N days." Copy: *"This is the chip you take by showing up. Welcome."*
- **FR-VIS-5**: For symbolism, the system must avoid trademarked logos. Use abstract approximations: AA's "circle and triangle" → generic three-element geometric mark; NA's diamond-in-circle → generic concentric mark; SLAA's lifesaver → ring-with-notch. Any text that is in public domain (Serenity Prayer, "Just for Today," "One Day at a Time," "To Thine Own Self Be True") may be displayed.
- **FR-VIS-6**: Glow-in-dark NA 1-year tag is rendered with a subtle animated luminosity in dark mode — recognizable to NA members without external lighting. Cultural hat-tip without literal copy.
- **FR-VIS-7**: Accessibility — every chip exposes a VoiceOver label of the form *"Chip: [milestone name], [fellowship], earned [date], [color description]"* so users with screen readers and color-blind users can identify milestones independently of color.
- **FR-VIS-8**: All chip animations respect `prefers-reduced-motion`; static fallback art is required for every animated chip.

---

## 5. User stories

Eleven primary user stories drive the feature set. They are grouped by user type.

**Newcomer in a single fellowship.** *As a newcomer to AA, I want to take a Commitment Chip immediately on signup so my recovery starts the moment I downloaded the app — and I want it to look like the white chip my home group uses, so I feel recognized.* This story drives FR-MS-1, FR-VIS-1, and the no-account onboarding.

**Member with co-occurring addictions.** *As someone in AA for alcohol, NA for opioids, and SAA for compulsive behavior, I want three independent trackers — each themed to the right tradition — so a slip in one doesn't reset the others and so I'm not forced to pick a primary identity.* This is the parallel-clocks model and is the single most-requested missing feature in market-leading apps.

**Annual-only fellowship member.** *As a CoDA member, I want monthly chip noise hidden by default and only my annual "CoDA birthday" celebrated, because that's how my meetings work.* Drives FR-FEL-3.

**No-chip fellowship member.** *As a Food Addicts in Recovery (FA) member, I don't want chips at all — just a private 90-day milestone marker, since chips aren't part of FA culture.* Drives FR-FEL-2.

**Personalized abstinence user (SAA, SLAA, OA, WA, EA).** *As an SLAA member, my sobriety is defined by my "three circles" and only I know what's in them; I need to write my own abstinence definition and have the relapse flow check against MY definition, not a generic one.* Drives FR-FEL-4 and the relapse confirmation flow.

**The relapse user.** *I had a slip last night. I want to log it without losing all my journal entries, without seeing "Day 1 again" in big red letters, and with the choice to call it a "lapse" (one moment) or a "relapse" (sustained return) — because they feel different.* Drives the lapse-vs-relapse split (Section 9).

**The privacy-paranoid user.** *I'm a public figure. I want this app to work entirely on-device, with a Face ID lock, no signup, no cloud sync, and a generic home-screen icon that doesn't broadcast that I'm in recovery.* Drives Section 10 in full.

**The accountability-partner user.** *I want my sponsor to see my alcohol streak but not my SLAA inner-circle data — and I want to revoke their access instantly if needed.* Drives the per-tracker permissions matrix.

**The mid-recovery installer.** *I have 274 days clean and just downloaded this. I want to set my real start date and have all my retroactive milestones appear in the gallery without faking my way through 274 days.* Drives FR-MS-2 and date editing.

**The traveler.** *I'm flying from New York to Tokyo on day 89. I don't want to lose or double-count day 90 because of timezone math.* Drives Section 11 timezone requirements.

**The relapse returner.** *I was 4 years sober, then relapsed for 8 months. I'm restarting. I want my old 4-year medallion preserved in history (for me, not the public) and a fresh tracker to begin.* Drives the immutable history requirement and tracker re-entry flow.

---

## 6. Data model

The data model is **event-sourced**: a tracker is the projection of an immutable event log, never a mutable counter. This handles timezone moves, clock manipulation, retroactive edits, and audit transparency.

```
User {
  id (anonymous UUID), createdAt,
  defaultTimezone (IANA),
  biometricLockEnabled, lockTimeoutSeconds,
  notificationPreferences { quietHoursStart, quietHoursEnd, dailyCap=3, ... },
  syncEnabled (default false), syncEncryptionKey (E2E)
}

Tracker {
  id, userId,
  fellowshipProfile (enum: AA|NA|CA|CMA|MA|HA|PA|NicA|GA|OA|DA|EA|FA|WA|CoDA|ACA|AlAnon|SA|SAA|SLAA|Custom),
  label (e.g., "Alcohol", "Compulsive eating"),
  customAbstinenceDefinition (free text, optional),
  startDate (UTC instant),
  trackerTimezone (IANA, separate from device TZ),
  isHidden, isPaused,
  sharingPolicy { partnerIds[], visibleFields[], communityVisibility },
  createdAt, archivedAt
}

Event {
  id, trackerId,
  type (enum: START | RESET | LAPSE | RELAPSE | PAUSE | RESUME | DATE_CORRECTION | STEP_COMPLETED),
  occurredAt (UTC instant), localDate, localTimezone,
  note (encrypted free text), isPrivate,
  triggers[] (optional structured data: stress, location, people),
  recordedAt (UTC instant — when logged, possibly later than occurredAt)
}

ChipAward {
  id, trackerId, milestoneKey (e.g., "30_days", "1_year", "step_4"),
  awardedAt, fellowshipProfile (snapshot), 
  earnedInStreakStartingAt (immutable — preserved across resets),
  visualTheme (snapshot of palette/shape at award time)
}

AccountabilityPartner {
  id, userId, partnerHandle, status (invited|accepted|revoked),
  perTrackerPermissions { trackerId: { seeStreak, seeRelapses, seeJournal, seeMilestones } },
  createdAt, revokedAt
}
```

**Key data model requirements:**

- **FR-DM-1**: All timestamps stored as UTC instants. Streak calculation is "current time minus most-recent RESET/RELAPSE event time, expressed in tracker's stored timezone."
- **FR-DM-2**: ChipAward records are **immutable**. A reset never deletes prior awards; the gallery view groups them by "streak attempt" so the user sees their full recovery history.
- **FR-DM-3**: A tracker carries its own timezone, set at creation, separate from device TZ. On detected device-TZ change, prompt user explicitly: *"You appear to be in [Tokyo]. Should we shift your day boundary to local midnight there, or keep it at [New York] midnight?"*
- **FR-DM-4**: Date-correction events allow the user to edit the start date with a soft confirmation. The audit log preserves the prior value. Future-dated events are flagged as suspect on backup restore.
- **FR-DM-5**: Cached derived values (current streak, longest streak, total days, milestones earned) are recomputed on every event write and stored for fast widget/notification rendering. Source of truth remains the event log.
- **FR-DM-6**: Step-completion events are independent of time-based events; resetting time does not reset step chips. (The 12 Steps don't un-happen.)
- **FR-DM-7**: All events and notes are encrypted at rest using a key derived from device biometric / passcode (iOS Keychain / Android Keystore).

---

## 7. Notification logic

Notifications are the highest-leverage and highest-risk feature. Recovery-context push design must avoid loss-aversion shame triggers and respect that **3 notifications/day is the empirically-supported maximum** for wellbeing.

**Notification types and timing:**

- **Daily commitment prompt** at user-chosen time (default 8 AM local) — "Take today's commitment chip. One day at a time." Local notification, scheduled by the device.
- **Pre-milestone anticipation** — 1 day before a major chip (30 days, 1 year, etc.): *"Tomorrow is your 1-year medallion. We see you."*
- **Milestone-day celebration** — On the day a chip is awarded: *"Your [chip name] is ready. Tap to receive it."* Note: chip is awarded by calculation regardless of app open; the notification merely invites the celebration UX.
- **End-of-day reflection** (optional, off by default) — *"Want to log how today went?"*
- **Accountability partner activity** (server push) — *"Your partner sent encouragement."* No PHI in payload — content fetched after unlock.
- **At-risk craving prompt** (off by default) — User-scheduled high-risk windows (e.g., Friday evenings) trigger a coping-tool nudge, never a streak warning.

**Notification requirements:**

- **FR-NOT-1**: Hard cap of 3 push notifications per day per user, configurable down to zero. Excludes user-initiated foreground alerts.
- **FR-NOT-2**: All notification copy reviewed against SAMHSA language guidance. Banned phrases include: "Don't break your streak," "Day 1 again," "fail," "fall off the wagon." Approved tone: *"Whenever you're ready," "We're rooting for you," "It's tough today. We see you."*
- **FR-NOT-3**: All notifications respect iOS Focus modes and Android DND at the system level. The app **must not** mark notifications as Time Sensitive or Critical except for explicit user-configured panic-button replies.
- **FR-NOT-4**: Push payloads contain no PHI. Lock-screen text reads "New message" or "Milestone ready" — never "Sponsor Mike asked about your relapse" or "30 days alcohol-free!"
- **FR-NOT-5**: Local notifications are preferred for milestones, daily prompts, and streak reminders (privacy: server never knows the streak). Server push is reserved for accountability partner messages and community.
- **FR-NOT-6**: User can configure quiet hours separately from system DND (default 10 PM–8 AM local).
- **FR-NOT-7**: After a relapse event is logged, all motivation/streak notifications are paused for 24 hours. Only a single supportive check-in fires the next morning: *"Yesterday was hard. Today is new. Whenever you're ready."*

---

## 8. Social, sharing, and celebration

**Sharing requirements:**

- **FR-SHA-1**: Sharing is **opt-in per event**, never automatic. The default state of every milestone is private.
- **FR-SHA-2**: Generated share images strip all metadata (no GPS, no device ID), include user-toggleable watermark/branding, and offer aesthetic templates that do not visually identify the app to glancing observers.
- **FR-SHA-3**: In-app community is organized by **milestone-cohort within fellowship** (e.g., "AA + 30 days," "NA + 1 year," "SAA + Day 1"). Users can browse without posting; participation is never required.
- **FR-SHA-4**: Anonymous handles (no real names); human moderation; report/block flows; rate-limit posting to prevent spam.
- **FR-SHA-5**: Accountability partners are bidirectional-consent: invite → accept. Per-tracker permission matrix: streak / relapses / journal / milestones, each independently toggleable. User can revoke instantly; revocation is immediate (not at next sync).
- **FR-SHA-6**: Cross-tracker community matching — for users with co-occurring addictions, surface a "multi-fellowship" community optionally.

**Celebration UX:**

- **FR-CEL-1**: Three-tier escalation. Small celebration at days 1/7/30 (subtle haptic + brief animation). Medium at 90/180/270 days (confetti, optional sound). Ceremonial at 1 year, 18 months, and each annual (extended animation, journaling prompt, share invitation, reflection question).
- **FR-CEL-2**: Haptics, sound, and motion are individually toggleable. Sound is **off by default**.
- **FR-CEL-3**: Reduced-motion accessibility setting replaces animations with a static reveal.
- **FR-CEL-4**: Cultural sensitivity — celebration imagery avoids alcohol metaphors ("cheers," wine glasses), specific religious symbology, and gendered defaults. Localized for at minimum English, Spanish, French, Portuguese, German, Russian, Japanese, Korean, Thai, Arabic, simplified Chinese (matching the I Am Sober language baseline of 11).
- **FR-CEL-5**: After a milestone celebration, the system prompts a journaling reflection (optional): *"What helped you get to [chip name]?"* Stored privately, surfaceable at future moments of doubt.

---

## 9. Reset, lapse, and relapse handling

This section is the most safety-critical in the FRD. The system distinguishes between **slip/lapse** (a brief, single return), **relapse** (sustained return), and **reset** (the user choosing to start over) — each with different consequences for the streak counter.

**FR-RST-1: Three-state event model.**
- **LAPSE** — A single moment of using; logged as a journal-augmented event but **does not reset the streak counter** by default. The user's streak continues. (Inspired by Try Dry's "Drank as planned" status, Loosid's "salt shaker," Reframe's slip course, and the recovery-community lapse-vs-relapse literature.) The user can override and force a reset if they choose.
- **RELAPSE** — A sustained return to use. Resets the active streak counter to zero. Preserves all prior chip awards in history.
- **RESET** — User-initiated wipe of the active streak (e.g., "I've been lying to myself for two weeks"). Identical effect to RELAPSE but with different copy framing.

**FR-RST-2: Compassionate confirmation flow.** Triggering any reset-equivalent event opens a two-step modal:
- Step 1: *"What happened? Take your time."* Three options: "A single slip (lapse)," "A longer return (relapse)," "I want to reset on my own terms." Plus a fourth "Cancel — go back."
- Step 2: Surface the user's *own* abstinence definition (for personalized fellowships) and the reset's consequences in plain language: *"This will start your streak over. Your previous [N] days and your [list of chips] are kept in your history forever. Are you sure?"*
- Both buttons descriptive ("Yes, log relapse" / "Not yet"); **no destructive red styling**; modal includes a soft icon (heart, hand, not warning).

**FR-RST-3: Undo window.** A 60-second undo toast after a reset: *"Reset logged. Undo?"*. After 60 seconds the event is permanent.

**FR-RST-4: Streak preservation valves.** The system implements at least one safety valve per tradition profile:
- **Lapse-vs-relapse distinction** (default for substance fellowships).
- **Grace period of 6 hours past local midnight** — daily commitment can be logged late without losing the day.
- **Null day** — user marks a day "not applicable" (illness, travel, surgery) without breaking streak. Available to FA/WA/personalized fellowships where the abstinence boundary is fuzzy.
- **No streak-freeze tokens.** Earned/spent freeze mechanics resemble pay-to-restore patterns and are inappropriate in recovery context.

**FR-RST-5: Post-reset state.** After a reset event:
- Active streak = 0; new streak start = event timestamp.
- Prior chips remain visible in gallery, grouped under "Previous attempts."
- Longest-streak ever and total-sober-days-ever counters continue to be displayed.
- Notification cadence is paused 24 hours; next prompt is supportive non-streak copy.
- The relapse event opens an optional trigger-tagging UI: *"What was happening? (optional, private)"* with structured tags (stress, location, people) for later reflection. Never required.

**FR-RST-6: Language register.** Every reset-flow string is reviewed against ISSUP and SAMHSA terminology lists. Banned: "fail," "ruined," "back to square one," "broke your streak," "you lost." Approved: "starting over," "today is new," "your history is preserved," "we're still here."

**FR-RST-7: The "What-the-Hell" guard.** When the user logs a lapse, the system explicitly states: *"One slip is not a relapse. Many people in recovery have lapses on the way to long-term sobriety. Your streak continues unless you tell us otherwise."* This directly counters the cognitive trap of "I already messed up, may as well keep using."

---

## 10. Privacy and security

- **FR-PRI-1**: **No-account default.** The app is fully functional with no signup. Account creation is optional and only required for cross-device sync, accountability partners, and community.
- **FR-PRI-2**: **Local-first storage.** All trackers, events, journals, and chips live on-device by default. Cloud sync is opt-in and end-to-end encrypted (server stores opaque blobs only).
- **FR-PRI-3**: **Biometric lock** with passcode fallback. Lock engages on backgrounding within configurable seconds (0/15/60/300). Lock is suspended during active panic-button or coping-tool flows.
- **FR-PRI-4**: **Stealth icon.** User can replace the home-screen icon with a generic alternative (calendar, weather, notes-style) so the app's purpose is not visible to onlookers. iOS supports alternate app icons natively.
- **FR-PRI-5**: **Quick-blur gesture.** Long-press anywhere blurs the active screen; tap to unblur. Useful when someone walks behind the user.
- **FR-PRI-6**: **Per-tracker visibility.** Each tracker independently configurable: visible in widget / notifications / community / accountability partners. A user can hide their SAA tracker from a widget while showing alcohol publicly.
- **FR-PRI-7**: **Generic widget mode.** Widgets show the streak count and a generic icon; the addiction label is hidden by default and exposed only on tap inside the app.
- **FR-PRI-8**: **Granular partner permissions matrix** as specified in the data model.
- **FR-PRI-9**: **Self-serve data export** (JSON + human-readable PDF) and **self-serve account deletion** with 30-day soft-delete + crypto-shred — meeting GDPR Art. 15/17 and CCPA requirements.
- **FR-PRI-10**: **Compliance posture.** App is **not HIPAA-covered** in default B2C distribution (consumer-direct, no covered-entity contract). However: FTC Health Breach Notification Rule applies; GDPR, CCPA/CPRA, Washington My Health My Data Act apply by user residency; 42 CFR Part 2 applies if the app is later integrated with an SUD treatment provider (handled via separate B2B SKU).
- **FR-PRI-11**: **Push payload sanitization.** No PHI ever in lock-screen text or push data. Server-side message content fetched only after unlock.

---

## 11. Edge cases

| Edge case | Required handling |
|---|---|
| User crosses time zones mid-streak | Tracker keeps its stored TZ; explicit prompt before changing day boundary. Never silent. |
| Device clock manipulation (forward/back) | Server-time check on next online event; suspicious jumps logged in audit but **not punished** (recovery context). |
| App not opened on milestone day | Chip awarded by event-log calculation; a local notification fires regardless of app state. Celebration UX appears on next open. |
| Account restored from backup | Recompute all derived values from event log; flag future-dated events as suspect. |
| Daylight saving transitions | 23-hour and 25-hour days both count as one day; never penalize. |
| User installs mid-recovery | Date editor permits any past start date with audit-logged confirmation; retroactive chips populate gallery. |
| Long sober time (10+ years) | UI accommodates "3,847 days" without truncation; widget fonts auto-scale. |
| Family / shared device | Multi-profile mode with per-profile biometric unlock. |
| Screen reader user | Custom VoiceOver/TalkBack labels per chip and milestone, including color descriptors. |
| Color-blind user | Color is never the sole indicator of streak status; icon + label always paired. WCAG AA contrast minimum. |
| Dynamic Type at AX5 | All chip and counter UI tested at largest accessibility size; no clipping, no horizontal scroll. |
| Localization to RTL languages | Chip layouts mirrored; Roman numerals stay Roman; date formatting locale-correct. |
| Widget refresh budget | Widget snapshot updated on event write, not live computation; iOS WidgetKit ~40 timeline reloads/day budget respected. |
| User deletes a tracker | 30-day undo window before permanent deletion of that tracker's events; chips not transferable. |
| Step-completion chip on personalized abstinence | Step chips are always available for fellowships that define a 12-Step program (not all do — Al-Anon, ACA, CoDA each have variant Steps; tradition profile carries the variant). |
| Two-spirit / non-heteronormative SA member | Onboarding allows user to overwrite the SA default abstinence definition with their own — system never enforces SA's group-defined heteronormative standard. |
| FA member who occasionally weighs/measures food differently | Null-day mechanic available; 90-day continuous-abstinence calculation visible separately from total-day count. |
| Returning user with prior 4-year sobriety, now post-relapse | Tracker history shows prior ChipAwards permanently; new tracker entry begins fresh; gallery groups awards by "streak attempt." |

---

## 12. Acceptance criteria summary

The chip system is acceptable for release when **all** of the following are demonstrably true in user testing with real fellowship members across at least 6 fellowships (target: AA, NA, SAA, OA, GA, CoDA):

The tracker supports parallel multi-addiction with no streak cross-contamination. Each fellowship's profile renders chip shapes and colors that members of that fellowship recognize as authentic-feeling without claiming endorsement. Day 0 commitment chip is awarded immediately on tracker creation. The lapse-vs-relapse distinction is presented before any reset, with compassionate copy and a 60-second undo. All prior chips are preserved across resets and visible in a "previous attempts" history. The app functions fully offline with no signup required. Biometric lock, stealth icon, and per-tracker privacy are all available. Notifications cap at 3/day with no PHI in payloads. Self-serve data export and account deletion work end-to-end. Screen reader users can identify every chip without seeing color. The app supports at least 11 languages with culturally-reviewed celebration imagery. Annual-only fellowships (GA, EA, CoDA, Al-Anon) do not surface monthly chip noise. No-chip fellowships (FA, WA) opt-in to a generic universal theme rather than being forced into AA-style chips. Personalized-abstinence fellowships (SAA, SLAA, OA, SA, WA, EA) allow user-written abstinence definitions that surface in the relapse confirmation flow. The reset flow has been reviewed against SAMHSA/ISSUP terminology and contains no banned language.

## Conclusion

The defining technical decision for this system is treating each addiction as an independent, event-sourced tracker themed by a swappable fellowship profile — the architecture that lets a single app honor NA's codified key-tag tradition, AA's Sister Ignatia–rooted chip tradition, FA's deliberate absence of tokens, and CoDA's annual-only "birthdays" without forcing any of them into a one-size-fits-all model. The defining product decision is that **safety valves around relapse are not optional features but core flows**: the lapse-vs-relapse distinction, immutable milestone history, compassionate confirmation modals, and the explicit "What-the-Hell" guard exist because 40–60% of users will need them, and weaponized streak design — common in habit-tracking and language-learning apps — actively harms recovery. The market opportunity is the multi-fellowship architecture itself: I Am Sober gates 10 trackers behind a paywall, Nomo offers unlimited but ignores fellowship traditions, and no current app combines the parallel-clocks data model with fellowship-authentic theming and trauma-informed reset flows. Building this combination is novel, defensible, and meaningfully more useful to people in co-occurring recovery — who today are forced to pick a primary identity or run multiple apps. The chip system, done right, is not a gamification layer. It is a digital echo of the moment a meeting hands a newcomer a white chip and the room applauds: recognition, witness, and the quiet promise that showing up matters.