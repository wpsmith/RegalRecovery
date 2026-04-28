# Streak Token System: Functional Requirements Specification

**Addendum to the Multi-Fellowship Sobriety Chip System FRD**

---

## Executive summary and design thesis

This specification defines the **Streak Token system**, a second reward layer that operates **alongside** (never replacing) the Sobriety Chip system in a B2C mobile addiction recovery app. The two systems serve distinct psychological functions: **sobriety chips** mark the duration of substance abstinence (the AA tradition), while **Streak Tokens** mark the *positive recovery actions* a user takes — meetings attended, journaling done, meditations completed, sponsor calls made, gratitude practiced, step work, exercise, and other recovery-capital-building behaviors.

The system implements two parallel tracks: a **Time-Based Track** for consecutive engagement streaks (1 week → 2+ years annually) and a **Cumulative Action-Count Track** for total lifetime actions (1, 5, 10, 25, 50, 75, 100, 150, 200, then every +50 thereafter). Each track is earned per habit, not globally, and both tracks are wrapped in an architecture informed by Try Dry (parallel non-resetting cumulative counters), Duolingo (auto-applied streak freezes, Big-Red-Button server protection), Headspace (toggleable visibility), Apple Fitness (streak break reframed as a "longest run" award), and Fitbit (thematic milestone naming at high counts).

The single most important architectural decision is this: **a sobriety reset (relapse) must NOT zero out a user's Streak Tokens, and a missed action day must not trigger shame.** The Abstinence Violation Effect (Marlatt & Gordon, 1985), the What-the-Hell Effect (Polivy & Herman, 1985), and shame-driven hiding (Randles & Tracy, 2013) are the dominant relapse-priming pathways for this population. The behaviors tracked by habit tokens — meditation, journaling, meeting attendance, exercise, sponsor calls — are precisely the **protective behaviors that mediate recovery** (Marlatt's relapse-prevention model; SAMHSA TIP guidance). They are valuable during *and immediately after* a relapse, arguably more than at any other time. Resetting habit streaks on a sobriety relapse compounds shame, weaponizes the Abstinence Violation Effect, removes evidence of resilience precisely when self-efficacy is most fragile (Shiffman et al. 1996), and disincentivizes returning to the app when re-engagement is most clinically important. This independence is non-negotiable.

The system is built on the **canonical contingency-management evidence base** (Petry, Higgins, Lussier meta-analysis n>100 RCTs) for token reinforcement in SUD treatment and grounded in Self-Determination Theory (Ryan & Deci) and the Recovery Capital framework (Cloud & Granfield, 2008; White & Cloud, 2008). It explicitly rejects the gamification anti-patterns documented in Duolingo, Snapchat Snapstreaks, and Habitica Boss Quests — patterns that produce documented harm in vulnerable populations. Critically, the system is bounded by a clinical safety layer: panic-button access, peer/sponsor outreach, and crisis resources are **never gated by tokens or streak status**.

**Three north-star design principles govern every requirement:** Compassion over compulsion. Resilience over perfection. User control over surveillance.

---

## 1. System scope, vocabulary, and relationship to sobriety chips

### 1.1 Three non-overlapping reward pillars

The app contains three reward systems, each answering a different psychological question and each anchored to a different behavioral-science pillar:

| Reward family | Question answered | Behavioral pillar | Resets on relapse? |
|---|---|---|---|
| **Sobriety chips** (existing) | "How long since I last used?" | Loss aversion + identity / AA tradition | **Yes** (canonical) |
| **TIME-based streak tokens** (new) | "How consistently am I practicing this habit?" | Goal-gradient + endowed progress | **No** (per-habit, independent) |
| **COUNT-based streak tokens** (new) | "How much have I practiced over my lifetime?" | Cumulative mastery / IKEA effect | **Never** (lifetime, irrevocable) |

The chip system retains primacy as the "hero metric" on the home screen because it is the user's clinical anchor and matches AA/NA cultural expectations. Streak tokens occupy a secondary, *resilience-oriented* role — they are the **safety net of identity** so a user who has just relapsed still has visible, undamaged evidence of their ongoing recovery work.

### 1.2 Per-habit independence

Mirroring Nomo's multi-clock architecture, **each habit has its own independent TIME streak and its own independent COUNT total.** A missed meditation day does not break a journaling streak. A relapse on alcohol does not break a meeting-attendance streak. Independence is the structural enforcement of the principle that recovery is multi-dimensional and one dimension's setback should not erase another dimension's progress.

### 1.3 Vocabulary

The user-facing language deliberately avoids the word "streak" in shame-loaded contexts. Recommended terms:

- **Action Token** — the atomic unit awarded for completing a single recovery action.
- **Engagement Streak** — the consecutive-day tracker (Track 1).
- **Lifetime Actions** — the never-resetting cumulative counter (Track 2).
- **Grace Day** — an auto-applied missed-day forgiveness credit (see §5).
- **Milestone Marker** — a celebration artifact awarded at threshold crossings.

The product may rebrand these in the UI layer (e.g., "Recovery Stones," "Wayfinder Marks," "Capital Points") provided the underlying data semantics defined here are preserved.

### 1.4 Non-goals

This system does not provide clinical advice, does not replace meeting attendance, does not enforce specific habit definitions, does not gate features on payment in ways that create shame (e.g., paid streak repair or purchasable Grace Days), and does not introduce any variable-ratio (slot-machine) reward mechanics.

---

## 2. Trackable habit categories

Habits are organized into six categories drawn from 12-step (AA/NA), SMART Recovery, Refuge Recovery, Recovery Dharma, MAT, and CBT/Relapse Prevention literature (Marlatt & Gordon, SAMHSA TIP NBK601489). The app ships with a **curated preset library** mapped to these categories, plus **fully first-class custom habits** with identical token mechanics.

Each action category maps to a Recovery Capital domain per Cloud & Granfield (2008) and a SAMHSA recovery dimension (Health, Home, Purpose, Community).

### 2.1 Spiritual / mindfulness / contemplative

| Action | Capital domain | SAMHSA dimension |
|---|---|---|
| Meditation (any tradition) | Personal | Health |
| Prayer / 11th-step practice | Personal | Health |
| Reading recovery literature (*Daily Reflections*, *Just for Today*, Recovery Dharma book, etc.) | Personal (human capital) | Purpose |
| Gratitude list (3–5 items) | Personal | Purpose |
| Daily affirmations / intention-setting | Personal | Health |
| HALT check-in (Hungry/Angry/Lonely/Tired) | Personal | Health |

### 2.2 Connection / community / accountability

| Action | Capital domain | SAMHSA dimension |
|---|---|---|
| Recovery meeting attendance (in person or online; AA, NA, SMART, Refuge Recovery, Recovery Dharma, Celebrate Recovery) | Social/Community | Community |
| Sponsor or mentor contact | Social | Community |
| "Call a fellow" / peer recovery contact | Social | Community |
| Service work (chairing, sponsoring, H&I commitments) | Community | Purpose |
| Family or loved-one connection | Social | Community |
| Online recovery community participation | Community | Community |
| Helped a peer in the community feed | Community | Community |

### 2.3 Cognitive / educational / step-work

| Action | Capital domain | SAMHSA dimension |
|---|---|---|
| Step-work writing (4th, 8th, 10th step) | Personal (human capital) | Purpose |
| Daily 10th-step "spot-check" inventory | Personal | Purpose |
| SMART Recovery worksheets (ABC / DISARM / Cost-Benefit / Change Plan / Hierarchy of Values) | Personal | Purpose |
| Recovery Dharma Inquiries | Personal | Purpose |
| Coping-skill practice / CBT skill rehearsal | Personal | Health |
| Reading clinical or recovery literature | Personal (human capital) | Purpose |

### 2.4 Therapeutic / clinical

| Action | Capital domain | SAMHSA dimension |
|---|---|---|
| Therapy or counseling appointment | Personal/Social | Health |
| Psychiatry or med-management appointment | Personal | Health |
| **MAT medication adherence** (buprenorphine/Suboxone, naltrexone/Vivitrol, methadone, disulfiram, acamprosate) | Personal | Health |
| Other prescribed medications | Personal | Health |
| Group therapy / IOP / PHP attendance | Personal/Social | Health |
| Drug-test compliance (where relevant) | Personal | Health |

### 2.5 Physical health / self-care

| Action | Capital domain | SAMHSA dimension |
|---|---|---|
| Sleep (target ≥ 7 hrs) | Personal | Health |
| Regular meals / nutrition (HALT "Hungry") | Personal | Health |
| Hydration | Personal | Health |
| Exercise / movement | Personal | Health |
| Outdoor or sunlight time | Personal | Health |
| ADLs / hygiene (especially relevant in early recovery) | Personal | Health |

### 2.6 Relapse-prevention / self-monitoring

| Action | Capital domain | SAMHSA dimension |
|---|---|---|
| Trigger logging | Personal | Health |
| Urge / craving log (SMART's Urge Log) | Personal | Health |
| Urge-surfing practice | Personal | Health |
| Coping-skill use log (DEADS / DENTS / distraction) | Personal | Health |
| Mood / emotion check-in | Personal | Health |
| Logged a daily check-in (mood, urges, sleep) | Personal | Health |

### 2.7 Custom habits

Users can enable/disable categories, add custom categories, and define their own daily targets. **Autonomy-supportive defaults** (SDT) are required: no category is mandatory.

### 2.8 Habit definition schema

Each habit has a configurable **frequency definition**: daily, weekdays-only, *N* times per week, every *N* days, or quantitative (e.g., "drink water 8×"). Streak math must respect the configured cadence — a 3×/week habit does not break on Tuesday if the user never committed to Tuesday. Quantitative habits with goal values (sleep ≥ 7 hrs, exercise ≥ 30 min) support a per-habit **partial-credit threshold** (default 70% of target counts as completion).

---

## 3. Track 1 — Time-Based Engagement Streak Tokens

### 3.1 Definition

A Time-Based Engagement Streak counts **consecutive days** (or consecutive committed periods, per habit cadence) on which the user has completed at least their self-defined "minimum daily engagement" (configurable: a single action by default; can be set higher by the user). Each action category may also have its own independent streak if the user enables per-category streaks (off by default to reduce anxiety load).

### 3.2 Milestone schedule

Tokens are awarded at the following thresholds, each with a distinct visual artifact:

| Tier | Milestones |
|---|---|
| **Early-density** (weekly) | 1 week, 2 weeks, 3 weeks |
| **Monthly** | 1 month, 2 months, 3 months, 4 months, 5 months, 6 months, 7 months, 8 months, 9 months, 10 months, 11 months |
| **Annual gateway** | 1 year, 18 months |
| **Sustained** | 2 years, then annually thereafter (3, 4, 5… indefinitely) |

The tight early spacing (weekly for the first three weeks, monthly through year one) reflects the **goal-gradient hypothesis** (Hull 1932; Kivetz, Urminsky & Zheng 2006): early progress is most motivating in proportional terms (Day 1 → Day 7 is +600%; Day 365 → Day 396 is +8.5%). It also aligns with relapse-prevention research (Marlatt; AA "90 in 90") that prioritizes dense reinforcement during the highest-risk window.

### 3.3 Month-boundary calculation

The "month" boundary is calendar-based: a 1-month token awards on the same day-of-month as the streak start date, rolling forward (e.g., March 15 → April 15). For starts on Jan 31, the system rolls to the last day of the next month (Feb 28/29). This matches the chip system's FR-MS-2 convention and user intuition.

### 3.4 Thematic naming at scale

Research on cumulative-counter scaling (Fitbit's thematic distance badges; Peloton's Century Club / Millennium Club; Trophy.so's milestone-fatigue findings) shows that **purely numerical milestones lose motivational meaning past mid-range values**. The system uses purely numerical naming through 11 months (where users are still anchoring to calendar time), then transitions to **thematic, story-laden names** for year-plus milestones. Recommended schema (engineering-flexible):

- **1 year:** "First Orbit" or "Anniversary Stone"
- **18 months:** "Half Path"
- **2 years:** "Second Orbit"
- **3+ years:** Named after recovery-capital concepts (e.g., "Keystone," "Beacon," "Cornerstone") or natural/seasonal metaphors. Avoid AA-collision names.

### 3.5 Token award mechanics

When a user crosses a milestone threshold:

1. The token is **persisted** with timestamp, milestone level, and snapshot of the engagement streak at award.
2. A **celebration screen** triggers in-app, using White-Hat framing (Yu-kai Chou Octalysis): emphasis on Epic Meaning ("This is who you are becoming") and Development & Accomplishment ("Look at what you've built"). **Never** uses scarcity or loss framing.
3. Celebration is **private by default**. Users can opt to share to a recovery pod, sponsor, or external channel — never auto-posted.
4. Token is permanently displayed in the user's Token Gallery. **Tokens cannot be lost or revoked** under any condition (including relapse, account inactivity, or streak break).

### 3.6 Visibility controls

Per Headspace's anti-anxiety design pattern, the user can fully **disable Engagement Streak tracking** from settings. When disabled, the streak counter is removed from all surfaces; the user retains full access to Track 2 cumulative tokens, action logging, and all clinical features. This setting is **prominently surfaced during onboarding**, not buried.

### 3.7 Backdating and honesty

Users may log an action up to **48 hours retroactively** with the entry timestamp shown transparently. This supports honest recording (a clinical good per Marlatt's Relapse Prevention) and accommodates real life (forgot to log Tuesday's meeting). Backdating beyond 48 hours is prevented to protect data integrity, but the user can still log the historical entry for personal records (the streak does not retroactively rescue beyond the window).

---

## 4. Track 2 — Cumulative Action-Count Tokens

### 4.1 Definition

The Cumulative Action-Count counter is a **lifetime tally** of total actions completed across all enabled categories. This counter **never decreases** under any circumstance — no relapse, no streak break, no account event resets it. It is the user's permanent recovery-capital portfolio.

### 4.2 Milestone schedule

Tokens awarded at:

| Tier | Milestones |
|---|---|
| **Foundation** | 1, 5, 10, 25, 50, 75, 100 actions |
| **Sustaining** | 150, 200, 250, 300, 350, 400, 450, 500 actions |
| **Indefinite** | Every +50 actions (550, 600, 650… without ceiling) |

**Recommended insertion:** A **30-action milestone** between 25 and 50, aligning with the AA/NA "30-day chip" cultural anchor. The 1 → 5 → 10 → 25 → 30 → 50 sequence preserves all behavioral properties while honoring 12-step convention.

This spacing implements **endowed progress** (Nunes & Drèze 2006: pre-filled progress increases completion 19% → 34%) at tier 1, **goal gradient** through the tight 25/50/75/100 sequence, and **diminishing-returns plateau** at the +50 widening (which deliberately reduces loss-aversion intensity at high tenure, since each individual day matters less when the streak is long).

### 4.3 Anti-meaninglessness scaling at high counts

Research on Fitbit's lifetime distance badges, Peloton's Millennium Club, and Trophy.so's milestone-fatigue literature establishes that **pure numerical milestones lose meaning past ~500 events**. The system addresses this with three mechanisms:

**Thematic transposition above 500.** Numerical labels persist in the data model, but the user-facing name shifts to evocative themes. Recommended schema (the "journey" metaphor):

| Count | Thematic name |
|---|---|
| 100 | "Century Mark" |
| 250 | "Keystone" |
| 500 | "Cornerstone" |
| 750 | "Lighthouse" |
| 1,000 | "Beacon" or "Millennium" |
| 1,000+ | Named in 250-event increments using recovery-capital metaphors (Foundation, Pillar, Bridge, Compass, Horizon) or seasonal/cosmic metaphors |

The product team should curate ~20 thematic names extending to 5,000+, with editorial restraint — every name must feel earned, not generated.

**Cadence expansion at ultra-high counts.** Above 2,000 cumulative actions, milestone cadence may expand from +50 to +100, then to +250 above 5,000. This prevents the "every action is a milestone" effect that Trophy.so identifies as engagement erosion. The product brief specifies "+50 indefinitely" — this spec recommends treating that as the **floor** at which milestones can be awarded, with the option to expand cadence at scale to preserve meaning. Final cadence is a tunable parameter.

**Per-category sub-milestones.** In addition to the global cumulative counter, each action category accumulates its own lifetime count with its own milestones (e.g., "100 meetings logged," "250 journal entries," "50 sponsor calls"). This gives long-tenure users continued meaningful progression *within* meaningful sub-narratives, rather than chasing a single ever-larger global number.

### 4.4 No reset under any condition

This is non-negotiable and must be enforced at the data layer. A relapse, sobriety reset, account pause, subscription lapse, or extended inactivity must leave Track 2 untouched. This is the clinical-design firewall against the Abstinence Violation Effect: **the user's lifetime work is permanent record**, and they can see it grow even on their hardest day.

### 4.5 Display hierarchy

The Lifetime Actions counter is the **dominant** numeric on the Streak Token home screen, larger and more prominent than the Engagement Streak counter. This deliberate hierarchy enacts the acquisitional framing: the user's eyes go first to what they have *built*, not to what they could *lose*.

---

## 5. Streak-break handling and Grace Day economy

### 5.1 Streak-break decision logic

When a user misses a day of their minimum daily engagement, the system applies the following logic in order:

1. **Big Red Button (server-issue protection).** If the missed day coincides with documented app downtime, server outage, or device sync failure, the streak is automatically protected (Duolingo's BRB pattern, which has reportedly preserved 2M+ streaks).
2. **Grace Day auto-application.** If the user has Grace Day credits available, one is silently consumed to preserve the streak. **No "you almost lost your streak" notification fires.** The grace use is logged transparently in the user's history (queryable in settings) but never surfaced as a near-miss alarm.
3. **Active streak ends; lifetime preserved.** If no Grace Day is available, the current Engagement Streak resets to 0 — but the **Lifetime Actions counter (Track 2) is unaffected**, the user's earned Milestone Markers are unaffected, and the user's "Longest Engagement Streak" record is preserved and surfaced.
4. **Soft re-entry flow.** The next time the user opens the app, the home screen displays a compassionate re-entry message, **not** a "0" or red indicator. Default copy pattern: *"Welcome back. Your [N] previous days of work are part of you. Today is yours."* The previous-best record is shown; the current count begins at the user's next completed action (framed as "Day 1 of your next chapter," not "Day 1 of your reset").

### 5.2 Grace Day economy

- **Default grant at signup:** 2 Grace Days, immediately available (Duolingo evidence: 2 freezes is the empirical retention sweet spot).
- **Regeneration:** 1 Grace Day per 7 consecutive days of engagement, capped at 2 in inventory by default (5 for users who reach the 100-day milestone, mirroring Duolingo's Streak Society).
- **Bonus grant:** +3 Grace Days at every 100-day cumulative milestone (Track 2), reinforcing that consistent action *earns* forgiveness rather than punishing inconsistency.
- **Application:** Always automatic. Users may *view* their Grace Day balance in settings but cannot manually trigger application. This prevents the user from being forced into an active "did I slip?" UI moment, which is a documented shame trigger.
- **Never purchasable.** Grace Days must not be tied to subscriptions, in-app purchases, ads, or any paywall. Recovery support is non-monetizable on this dimension.
- **Partner gifting:** Accountability partners may **gift** a Grace Day to each other as a positive social interaction. If the recipient is at inventory cap, the gift is held in a pending tray and auto-applied to the next eligible miss.

### 5.3 Retroactive logging window

A **24–48 hour retroactive logging window** allows the user to mark yesterday's habit today and preserve the streak. Beyond that, the user can still log the historical entry for personal records but the streak does not retroactively rescue.

### 5.4 Partial credit

For users with multiple daily habits, completing **at least 60% of selected daily habits** (configurable per user) maintains a "habit-day" streak indicator. This honors James Clear's "missing once is an accident, missing twice is the start of a new habit" principle without all-or-nothing rigidity (which the What-the-Hell Effect literature directly identifies as harmful).

For quantitative habits, the configured partial-credit threshold (default 70% of target) determines whether a partial completion counts toward the streak. Six hours of sleep with a 7-hour goal at 70% threshold → counts.

### 5.5 Streak repair

A one-time "your effort still counts" reinstatement is offered within 72 hours of a streak's end, framed as supportive: *"You've been consistent — would you like to count yesterday and keep going?"* No payment, no advertisement, no friction. Limited to one repair per streak per ~14 days to preserve streak meaningfulness.

### 5.6 Pause / Vacation mode

User-initiated pause that **suspends** streaks (does not advance, does not break) for hospitalization, travel, treatment, illness, planned breaks. Modeled on watchOS 11's pause-rings feature. Maximum continuous pause 30 days before user must confirm continuation; pause history visible in Trophy Cabinet as "rest period."

### 5.7 Reframe vocabulary

Throughout the system, replace "streak broken / lost / failed" with "starting fresh / new chapter / rest day / new beginning." This is a cross-cutting copy rule, not a one-off.

---

## 6. User stories

**The newcomer building first habits.** *As a user with three weeks of sobriety, I want to earn a 3-week meditation token even though my sobriety chip is at 3 weeks too — so I can see my recovery practice as more than just abstinence duration.*

**The relapsing user whose habits survive.** *As a user who relapsed yesterday, I want my meditation, journaling, and meeting-attendance streaks to remain intact when I log the relapse — so I have evidence that my recovery work is more than my last drink.*

**The lifetime-count collector.** *As a user celebrating my 100th meeting, I want a permanent count token that I'll never lose — so I can look back across years and see real cumulative effort.*

**The privacy-conscious accountability user.** *As a user with an accountability sponsor, I want to share* that I attended a meeting today *without sharing* what I journaled *— so I can be accountable without surrendering all privacy.*

**The MAT patient.** *As a user on MAT, I want my Suboxone adherence tracked privately, with neutral lock-screen notification text — so I'm not outed by a glance at my phone.*

**The casual user.** *As a casual user, I want one clean number on my home screen, not a wall of badges — so the app feels supportive, not gamified.*

**The achievement-oriented user.** *As an achievement-hunter user, I want to see my full token grid, projected next-earn dates, and per-habit stats — so I can engage with the depth I want.*

**The streak-breaker.** *As a user who broke my 47-day journaling streak, I want supportive language ("47 days of journaling — that effort is permanent. Want to start a new chapter?") rather than punitive language ("STREAK LOST").*

**The crisis user.** *As a user going through a hard week, I want a Crisis Mode that suppresses streak-at-risk pings and surfaces support resources instead.*

**The traveler.** *As a user traveling across time zones, I want my day boundary to follow my chosen rule, and I want a clear "your day ends in X hours" indicator so I'm not blindsided by a missed day at altitude.*

---

## 7. Visual theming

### 7.1 Three-axis differentiation framework

To remain visually cohesive while functionally distinct from sobriety chips, the system uses a **shape × material × color** framework with shared lighting, typography, and motion vocabulary across all three reward families.

| Family | Shape language | Material | Color progression |
|---|---|---|---|
| **Sobriety chips** | Round / coin (echoes AA medallions) | Warm metallic, embossed text | AA-inspired warm metals; per-tier sequence with "inspired by tradition" disclaimer |
| **TIME tokens** | Hexagonal or shield (geometric, "time-locked") | Enameled metal with engraved duration label | Cool spectrum progressing with duration: sky-blue (weeks) → indigo (months) → violet (years) |
| **COUNT tokens** | Faceted gemstone / polygonal crystal ("accumulated facets") | Translucent, internal light, rendered with refraction | Single hue family (recommended teal / cyan); facet count and saturation increase with tier |

Shape is the primary differentiator (works for color-blind users; uses pre-attentive perception). Material is the secondary differentiator. Color is the tertiary tier-progression signal *within* each family.

### 7.2 Cohesion rules

All three families share: identical lighting model, identical typographic system for labels (numerals + period unit), identical celebration vocabulary (subtle particle burst, scaled haptic, optional sound), identical earned-vs-locked treatment (full color when earned, monochrome silhouette preview when not).

### 7.3 Trophy Cabinet

Three horizontally scrollable shelves: **Chips · Time · Count**. Each shelf shows earned tokens with full rendering and unearned tokens as ghost previews (Apple Fitness Awards pattern). Long-press a token reveals when it was earned, the habit it relates to, and an optional shareable card. The Cabinet is reachable from the Profile/Achievements tab — **never pushed to the home screen** for casual users.

### 7.4 Discreet / anti-stigma mode

The app provides a **"low-profile" theme** that uses neutral iconography and language throughout. In this mode the app icon, lock-screen notifications, and shared visuals never reference substances, AA/NA, or recovery vocabulary. Habit names default to user-customizable neutral labels ("morning routine" rather than "Suboxone").

### 7.5 Accessibility

Every token exposes a VoiceOver/TalkBack label of the form *"Token: [milestone name], [habit], earned [date], [shape and color description]"*. Color is never the sole indicator; shape + label always paired. WCAG AA contrast minimum. All animations respect `prefers-reduced-motion`; static fallback art required for every animated token. Dynamic Type tested at AX5 with no clipping.

---

## 8. Data model

### 8.1 New entities

```
Habit {
  id, user_id, 
  category (enum: spiritual|connection|cognitive|therapeutic|physical|relapse_prevention|custom),
  name, custom_label_override,
  frequency_def (daily|weekdays|Nx_per_week|every_N_days|quantitative),
  quantitative_target (numeric, optional),
  partial_credit_threshold (default 0.70),
  sensitivity_tier (enum: TIER_1|TIER_2|TIER_3),
  sharing_settings_json,
  created_at, archived_at
}

HabitEntry {
  id, habit_id,
  occurred_at_utc, occurred_at_user_tz,
  source (enum: manual|integration|partner_gift),
  value (boolean | numeric),
  note_id_optional (FK, encrypted),
  was_backdated (bool),
  backdated_within_grace_window (bool),
  recorded_at_utc
}

HabitStreak {
  id, habit_id,
  current_streak_days,
  current_streak_started_at,
  longest_streak_days,
  longest_streak_ended_at,
  last_completed_day,
  paused_state (bool),
  paused_until (timestamp, optional)
}

StreakToken {
  id, habit_id,
  track (enum: TIME|COUNT),
  tier_value (e.g., "1_week", "100_actions"),
  earned_at,
  earned_via (enum: organic|gifted|partial_credit),
  revoked (always false — enforced at data layer),
  shareable_asset_id
}

GraceDayLedger {
  id, user_id,
  source (enum: signup_grant|earned|bonus|partner_gift),
  available_count,
  max_inventory (default 2; 5 at 100-day milestone),
  granted_at,
  used_at (optional),
  used_for_habit_id (optional)
}

LifetimeCounter {
  id, habit_id (nullable for global),
  total_actions (monotonically non-decreasing, enforced),
  last_incremented_at
}
```

### 8.2 Interaction with existing chip system entities

The streak token data model **does not share any cascade-delete or cascade-update relationships** with the sobriety chip system's Tracker, Event, or ChipAward entities. A relapse log event (Event.type = RELAPSE or RESET) on a sobriety Tracker **must not** modify any LifetimeCounter, StreakToken, HabitStreak.longest_streak_days, or GraceDayLedger entry.

### 8.3 Permanence invariants (enforced at data layer with automated tests)

- A relapse log event MUST NOT modify any LifetimeCounter, StreakToken, HabitStreak.longest_count, or GraceDayLedger entry.
- LifetimeCounter values MUST be monotonically non-decreasing for the lifetime of the account.
- Awarded StreakTokens MUST NOT be deletable except by explicit user account deletion (full GDPR/data-rights operation).
- StreakToken.revoked field MUST always be false; no code path may set it to true.
- Sobriety chip resets and Streak Token data MUST NOT share any cascade-delete or cascade-update relationships.

### 8.4 Sensitivity tiers (privacy defaults)

Each habit carries a **sensitivity tier** determining defaults for cloud sync, sharing, lock-screen notification scrubbing, and analytics inclusion:

**Tier 1 — Highly Sensitive** (MAT adherence, drug-test logs, 12-step meeting attendance, sponsor identity and call logs, therapy/psychiatry attendance, step-work content, trigger and urge logs, relapse events): default **on-device only**, no cloud sync without explicit per-habit opt-in; **never** included in analytics; lock-screen notification content always scrubbed; eligible for 42 CFR Part 2-equivalent consent treatment if shared externally.

**Tier 2 — Moderately Sensitive** (recovery-framed reading, Refuge/Recovery Dharma–labeled meditation, HALT, service-work logs, recovery-framed coping skills, recovery-framed gratitude): default cloud-sync on, sharing off, analytics opt-in.

**Tier 3 — Lower Sensitivity** (sleep, hydration, nutrition, exercise, outdoor time, generic mindfulness, generic journaling): default cloud-sync on, sharing per user preference, analytics aggregated and anonymized.

### 8.5 Time handling

All `occurred_at` stored UTC; the user's "day" boundary is computed from `user_timezone` plus an optional `late_night_cutoff` (default 0:00, configurable up to 04:00 for night-shift workers). DST transitions: a 23-hour or 25-hour day still counts as 1 day.

### 8.6 Privacy defaults

Token data is local-first where possible; cloud sync is opt-in. Account creation is not required for basic Streak Token functionality — consistent with the chip system's FR-PRI-1 no-account default.

---

## 9. Notification logic

### 9.1 Combined notification budget

A **hard combined cap of 3 notifications/day across all systems** (chip system + streak token system) by default, surfaced to the user as a visible budget they can tighten. Independent per-channel toggles for: sobriety milestone notifications, habit reminders, streak-at-risk warnings, accountability-partner activity, community/encouragement, daily reflection content.

### 9.2 Smart batching and timing

Non-urgent items are batched into one morning ritual prompt and one evening reflection prompt. Defaults to user-configured "good times" and learns from open patterns over time. Default quiet hours **22:00 → 07:00**, never overridable by gamification notifications (only crisis-resource and partner-tempted-alert categories may break quiet hours, and only with explicit prior opt-in).

### 9.3 Streak-at-risk warnings

**Opt-in, never default.** When enabled, the warning fires once at a user-configurable lead time (default 4 hours before day rollover). Copy must be neutral and supportive: *"You can keep your meditation streak today — want to take 2 minutes?"* — never *"Don't break your streak!"* or *"Don't let [mascot] down."* The warning includes a one-tap completion path and a one-tap "use a freeze" path. Loss-aversion framing is prohibited as the only nudge.

### 9.4 Streak-end notification

Mandatory reframe. Replace *"Streak broken"* with *"47 days of journaling — that effort is permanent. Ready for a new chapter?"* Always pair with a one-tap restart action and a link to the count-track totals (which are intact).

### 9.5 Notification copy standards

All notifications related to streaks, tokens, or engagement must comply with these copy rules:

- **Prohibited:** "You broke your streak," "You failed," "Don't lose," "Last chance," "You're slipping," "Your streak is in danger," guilt-tripping mascot language, red/alarm color coding for missed days.
- **Required tone:** Motivational Interviewing-aligned (Miller & Rollnick) — non-confrontational, autonomy-supportive, eliciting. Examples: *"Your evening check-in is ready when you are,"* *"A few minutes today supports the work you've already done,"* *"Welcome back — want to reflect together, or just start fresh today?"*
- **Adaptive frequency:** If a user ignores engagement notifications for 7+ days, streak-related notifications **stop entirely** (Duolingo's adaptive notification pattern). Crisis and safety notifications continue.
- **Time-window safety:** Aggressive engagement nudges are suppressed during documented high-risk windows (late nights, holidays, user-flagged trigger times). Trauma-informed notification logic is required.

### 9.6 Recovery-specific lock-screen rules

Notifications must never mention substance names, never use craving language, never use shame-inducing or guilt-trip framing, and (in low-profile mode) never use recovery vocabulary on the lock screen. Habit names from Tier 1 sensitivity are **always scrubbed from lock-screen text** ("Time for your morning task" not "Time for your Suboxone"). This aligns with the chip system's FR-NOT-4 (no PHI in push payloads).

### 9.7 Crisis Mode

A user-toggleable "Going through it" mode that suppresses streak-at-risk warnings, hides gamification surfaces, and elevates support resources (sponsor call, crisis line, meeting finder, breathing exercise, urge-surfing tool). Auto-suggested for the 7–14 days following a logged relapse.

---

## 10. Social, sharing, and celebration

### 10.1 Default-private architecture

All habit data is **private by default**. Sharing is opt-in per habit, per audience, per content type. No public leaderboards on habit tokens under any circumstances — Headspace's deliberate avoidance of competitive surfaces and 12-step anonymity traditions both mandate this.

### 10.2 Anonymity

Username-based identifiers; real names never required. Profile photos optional. Substance type never appears in any shared/exported asset unless the user explicitly opts in.

### 10.3 Per-habit, per-audience visibility

Each habit has independent visibility toggles for: private (default for Tier 1 sensitivity), accountability sponsor only, accountability circle (small named group), opt-in friends.

Sponsor view is **engagement summary, not content**: "checked in today ✓, attended meeting ✓, met daily habits ✓" — never the journal text or HALT details.

### 10.4 Encouragement primitive

Lightweight tap-to-send "I see you" / "well done" (Peloton high-five model, Strava kudos pattern). No comments by default to prevent trolling and over-engagement. No public reaction counts.

### 10.5 Cooperative challenges

Optional invitation-based shared habit challenges ("we both meditate 7 days"). Modeled on Habitica Collection Quests (cooperative) **never** Boss Quests (where one person's miss damages the party — explicitly disallowed in recovery). Failure modes never shame either party; missed-day language is "took a rest day," never "let down the team."

### 10.6 Streak-break visibility

A broken streak is **auto-hidden from social view**. The partner sees today's box empty but never sees "STREAK BROKEN — was 47 days." Soft-reset language ("starting fresh," "new chapter") is used in any social surface.

### 10.7 Relapse disclosure

User-initiated only. The app may *suggest* "Would you like to let your accountability partner know?" but **never** auto-broadcasts a relapse event.

### 10.8 Shareable cards

Users can manually generate a shareable image celebrating a milestone. Generated cards expose only neutral content (e.g., "100 days of self-care") and never include Tier 1 habit details, substance names, or recovery-program identifiers unless the user explicitly opts in per share. All metadata stripped (no GPS, no device ID) — consistent with chip system's FR-SHA-2.

### 10.9 Celebration UX

Three-tier escalation aligned with the chip system's FR-CEL-1:

| Tier | Milestones | Celebration |
|---|---|---|
| **Small** | Weekly tokens, first few count tokens (1, 5, 10) | Subtle haptic + brief animation |
| **Medium** | Monthly tokens, mid-count tokens (25, 50, 75, 100) | Confetti, optional sound |
| **Ceremonial** | Annual tokens, high-count tokens (250, 500, 1000) | Extended animation, journaling prompt, share invitation, reflection question |

Haptics, sound, and motion are individually toggleable. Sound is **off by default**. Reduced-motion accessibility setting replaces animations with a static reveal. Cultural sensitivity requirements from chip system FR-CEL-4 apply (no alcohol metaphors, no religious symbology, no gendered defaults).

### 10.10 Honest-logging reward

A specific token category rewards **logging on hard days** — including days the user records a slip, a strong urge, or a difficult emotional state. This makes radical honesty the rewarded behavior (Try Dry's "log even on drinking days" pattern) and structurally counters the hide-from-shame relapse pathway.

---

## 11. Interaction with relapse events

### 11.1 What resets, what doesn't

| On a logged relapse | Behavior |
|---|---|
| Sobriety chip(s) | Reset (per AA/NA convention; per user expectation) |
| Sobriety chip *history* | **Preserved.** Prior best streaks shown as "Journey." |
| TIME-based habit streak tokens | **Not reset.** Streaks for meditation, journaling, meetings, exercise, etc. continue uninterrupted. |
| COUNT-based habit tokens | **Never reset under any circumstances.** |
| Earned tokens (any track) | **Never revoked.** |
| Per-habit user override | User may manually reset a specific habit ("didn't journal during my relapse week") via long-press / settings — never automatic. |

### 11.2 Soft-fail relapse flow

When a user logs a sobriety relapse (in the chip system), the Streak Token system must:

1. Display a screen affirming honesty: *"Thank you for being honest with yourself. Honesty is recovery."*
2. Surface the user's pre-written lapse plan (created during onboarding per Marlatt's Relapse Prevention model).
3. Offer one-tap connection to peer, sponsor, coach, or crisis resource.
4. Show — explicitly and prominently — that **all Streak Tokens, Lifetime Actions, Milestone Markers, and Grace Days are preserved**. Copy: *"Your [N] lifetime actions and [M] earned milestones are unchanged. They are part of you."*
5. Frame the next sober day as "Day 1 of your next chapter," never "Day 1 of your reset."
6. Engage a **7–14 day supportive window**: softened tone, suppressed streak-at-risk pings, elevated support content, Crisis Mode auto-suggested.

### 11.3 Why habit streaks survive relapse — the clinical case

The behaviors tracked by habit tokens — meditation, journaling, meeting attendance, exercise, sponsor calls — are precisely the **protective behaviors that mediate recovery** (Marlatt's relapse-prevention model; SAMHSA TIP guidance). They are valuable during *and immediately after* a relapse, arguably more than at any other time. Resetting habit streaks on a sobriety relapse compounds shame, weaponizes the **Abstinence Violation Effect** (Larimer, Palmer & Marlatt 1999), removes evidence of resilience precisely when self-efficacy is most fragile (Shiffman et al. 1996), and disincentivizes returning to the app at the moment when re-engagement is most clinically important.

---

## 12. Compulsion safeguards and verification

### 12.1 Anti-compulsion controls

Because people in recovery for one addiction face elevated cross-addiction risk (Clark & Zack, 2023):

- A **daily token cap** prevents in-app obsessive farming (e.g., max 5 unique action categories logged per day toward Lifetime Actions).
- A **session-time soft warning** at 30 minutes suggests real-world recovery action: *"You've been here a while. Want to take this energy to a meeting or call a friend?"*
- **No variable-ratio reward schedules** (slot-machine mechanics). All rewards are fixed and predictable per logged action.
- **No purchasable progression.** Tokens, Grace Days, and milestones cannot be bought.
- A **weekly reflection summary** emphasizes real-world recovery actions over in-app engagement metrics.

### 12.2 Trust model

Default action logging is **self-report**, consistent with the autonomy-supportive design ethos. The system does not interrogate users to verify each action, because clinical experience shows that distrust frames undermine the therapeutic alliance.

### 12.3 Optional verification (premium / clinical tier)

For users in formal treatment, employer plans, or contingency-management programs (where verified behavior unlocks real-world rewards per WEconnect's clinically validated model), the system supports optional verification mechanisms: GPS confirmation for meetings, URL/QR confirmation for online meetings, partner-confirmation for sponsor calls. Verification is opt-in per user and per category. Self-report tokens and verified tokens are visually distinguished but both count toward all milestones.

### 12.4 Quality-over-quantity safeguards

To prevent the Duolingo-documented pattern of users speed-running easy actions to maintain streaks:

- Per-category daily caps prevent farming a single trivial action.
- A weekly **reflection prompt** asks the user to rate which actions felt most meaningful — surfacing intrinsic motivation over token-chasing.
- The home screen's hierarchy emphasizes **lifetime breadth** (variety of categories engaged) alongside total count, not just raw numbers.

### 12.5 Clinical alignment monitoring

At a system level, product analytics should monitor for warning signs that streaks have weaponized — e.g., declining session quality at high streak counts, declining variety of actions, users logging at 11:59 PM consistently, or correlation between high streaks and relapse events. These are KPIs of *harm*, not retention.

---

## 13. Onboarding and education requirements

### 13.1 Lapse-vs-relapse education

During onboarding, the app must explicitly teach Marlatt's lapse-vs-relapse distinction in plain language: *"Recovery is rarely a straight line. Slips happen. This app is designed so that a slip doesn't have to become a setback. We will never make you feel ashamed for missing a day. Your work is preserved."* This sets expectations that inoculate against the What-the-Hell Effect *before* the first slip occurs.

### 13.2 Streak-disable awareness

Onboarding must surface the option to disable Engagement Streaks entirely, with neutral framing: *"Some people find streaks motivating. Others find them stressful. You can turn them off anytime — your tokens and progress will work either way."*

### 13.3 Lapse plan creation

During onboarding, the user is invited (not required) to write a brief lapse plan — what they will do, who they will contact, what they will tell themselves — that the app will surface on relapse logging. This is direct application of Relapse Prevention clinical practice.

### 13.4 Identity framing

Onboarding language anchors tokens to identity, not abstinence: *"Tokens are evidence of who you are becoming. They mark every action you take to build your recovery — meetings, calls, journaling, gratitude, exercise, service. They never disappear."*

---

## 14. Privacy and security

### 14.1 Pseudo-labeling

Every habit supports a user-chosen neutral display label that overrides the canonical name on all surfaces (including the home screen, partner views, and lock-screen notifications). "Suboxone" → "morning routine."

### 14.2 Notification content scrubbing

Lock-screen notification text for any Tier 1 habit is automatically scrubbed to a neutral phrase regardless of the habit's display label.

### 14.3 Data retention and export

Per-habit retention policy; auto-deletion of Tier 1 entry contents after configurable windows (counts persist for streak math, free-text notes do not). User-initiated export and delete (GDPR Art. 15/17, CCPA/CPRA, and 42 CFR Part 2-aligned consent flows). Account deletion produces verifiable data destruction.

### 14.4 Third-party SDK disclosure

Per-habit policy on whether telemetry from that habit category is permitted to reach analytics or advertising SDKs, with a clear privacy dashboard. Tier 1 habits **must not** transmit any data to third-party SDKs (this directly addresses the Huckvale, Torous & Larsen JAMA 2019 finding that 29 of 36 mental-health apps shared data with Facebook/Google undisclosed).

### 14.5 Biometric/GPS verification

Off by default. Available as opt-in for users who want clinical-grade contingency-management-style verification, but the app never requires it and never gates token earning behind it for individual consumer users.

---

## 15. Edge cases

| Edge case | Required handling |
|---|---|
| User crosses time zones mid-streak | Day boundary follows `user_timezone` + `late_night_cutoff`. Show "your day ends in X hrs" indicator on travel days. Provide explicit "I traveled" repair flow. |
| Daylight Saving Time | Internal UTC; 23-hr or 25-hr local day still counts as 1 day; never penalize. |
| Multiple logs same day (boolean habit) | Subsequent taps show "already done today" with no double-count. |
| Multiple logs same day (quantitative habit) | Auto-increment toward goal; surface progress bar. |
| Backdated logging | Allowed within 24–48 hr for streak math; allowed indefinitely for personal historical records (clearly UI-distinguished; won't rescue streaks beyond the grace window). |
| Habit deletion | **Soft archive only.** Earned tokens persist in Trophy Cabinet. Restore option always available. |
| New habit added mid-journey | Count starts at 0. Optional import from Apple Health / Google Fit only for verifiable categories (exercise, sleep, mindfulness). Self-reported bulk historical import is **prohibited** to preserve token meaningfulness. |
| Account pause / vacation | Streaks suspended (not broken, not advanced). 30-day max before confirmation. |
| Multi-device sync | Cloud-backed account (Tier 1 habits encrypted at rest). Last-write-wins per day with explicit conflict UI on simultaneous edits. |
| Day boundary at 11:59 PM vs 12:01 AM | Local day boundary respected; configurable late-night cutoff (up to 04:00) available for night-shift / night-owl users. |
| Habit category change | Treated as edit, not new habit. Streak and history preserved. |
| Quantitative goal change mid-streak | New goal applies prospectively only; historical entries judged against the goal at the time they were logged. |
| Habit frequency change | New cadence applies prospectively only; current streak does not retroactively recompute. |
| Habit conflicts with frequency definition | A 3×/week habit does not break on un-committed days. Streak math respects the cadence. |
| Account deletion | Verifiable data destruction; export available pre-deletion; Tier 1 data destroyed first. |
| Notifications during Crisis Mode | All gamification notifications suppressed; only safety/support categories permitted. |
| Partner-gifted freeze when at inventory cap | Held in pending tray; auto-applied to next eligible miss; user notified. |
| Long sober time (10+ years) high token counts | UI accommodates counts like "3,847 actions" without truncation; widget fonts auto-scale. |
| Family / shared device | Multi-profile mode with per-profile biometric unlock — consistent with chip system. |
| Screen reader user | Custom VoiceOver/TalkBack labels per token including shape and color descriptors. |
| Color-blind user | Shape is primary differentiator (round chip vs. hexagonal TIME token vs. faceted COUNT token); color never sole indicator. WCAG AA contrast minimum. |
| Widget refresh budget | Widget snapshot updated on event write, not live computation; iOS WidgetKit ~40 timeline reloads/day budget respected. |
| Custom habit promoted to public library | Optional, anonymous, opt-in. Never automatic. |
| App not opened on milestone day | Token awarded by event-log calculation; local notification fires regardless of app state. Celebration UX appears on next open. |
| Device clock manipulation | Server-time check on next online event; suspicious jumps logged in audit but **not punished** (recovery context). |

---

## 16. Explicit design prohibitions (red lines)

The following are prohibited by design and must be enforced in code review:

1. No "Day 0" or visibly reset streak display after any event.
2. No shame, loss, or guilt language in any user-facing copy.
3. No red/alarm color coding for missed days or low engagement states.
4. No public broadcast of streak loss, missed days, or relapse events.
5. No financial value, premium gating, or unlockable content tied to streak length.
6. No variable-ratio (slot-machine) reward schedules.
7. No scarcity, urgency, or FOMO triggers in notifications.
8. No leaderboards comparing recovery duration or token counts across users.
9. No anthropomorphized guilt-tripping characters ("[mascot] is sad you missed a day").
10. No gating of crisis features behind tokens, streaks, or subscriptions.
11. No purchasable Grace Days, tokens, or milestone progression.
12. No Hook Model "investment loops" optimizing DAU at the expense of clinical outcomes.
13. No social streaks (Snapchat-style streaks visible-to-and-coupled-with another user).
14. No Habitica-style Boss Quests where one person's miss damages the group.

---

## 17. Acceptance criteria

The Streak Token system is acceptable for release when **all** of the following are demonstrably true:

1. **Independence:** A logged relapse on the user's primary substance does not modify any habit's TIME streak or COUNT total. Verified by automated test covering all six habit categories.
2. **Permanence:** No COUNT token is ever revoked under any user action, system action, relapse, account event, or admin action. Verified by data-model invariant.
3. **Monotonicity:** LifetimeCounter values are monotonically non-decreasing across all account-lifetime states except explicit user-initiated full data deletion. Verified by automated test.
4. **Sensitivity gating:** Tier 1 habits never appear in lock-screen notification text by default; never sync to cloud without explicit per-habit opt-in; never transmit data to third-party SDKs. Verified by a privacy-test suite covering all canonical Tier 1 habits.
5. **Notification budget:** Combined daily notification volume (chip system + streak token system) does not exceed the user's configured budget (default 3) regardless of how many milestones, partners, or streak-at-risk events fire on the same day. Verified by simulation.
6. **Copy compliance:** No notification, in-app message, or shared asset contains the phrases "streak broken," "streak lost," "streak failed," "don't let [X] down," substance names by default, or guilt/shame framing. Verified by automated copy lint plus human review.
7. **Trauma-informed relapse flow:** The relapse-logging flow follows SAMHSA's six principles (safety, trust, peer support, collaboration, empowerment, cultural humility), surfaces support resources before any reflection prompts, and offers — never assumes — partner notification. Verified by clinical-advisor walkthrough.
8. **Grace Day auto-application:** A simulated 1-day miss with Grace Days available silently preserves the streak with no near-miss notification. Verified by integration test.
9. **Soft re-entry:** A simulated 1-day miss with 0 Grace Days resets the current streak but preserves the longest-streak record, all Lifetime Actions, all milestones, and all grace-day-earned records. Verified by integration test.
10. **Pause / vacation mode:** Suspends all streaks without breaking them for up to 30 days; clearly visible in Trophy Cabinet as "rest period." Verified by integration test.
11. **Visual differentiation:** Sobriety chips (round), TIME tokens (hexagonal/shield), and COUNT tokens (faceted gem) are distinguishable in <500 ms by users in moderated usability testing, with at least 90% accuracy across color-blind users. Verified by user testing (n ≥ 12, including ≥ 3 with color-vision deficiencies).
12. **Per-habit independence:** Missing one habit's daily window does not affect any other habit's streak. Verified by automated test across all preset and custom habits.
13. **No paid streak repair:** No screen, flow, or marketing offer permits monetary payment to restore a streak, freeze a streak, or recover a relapse-affected counter. Verified by code audit and App Store / Play Store metadata review.
14. **Anonymity-preserving sharing:** No shareable asset contains real name, substance, recovery program identifier, or Tier 1 habit content unless the user has explicitly opted in for that specific share.
15. **Time-zone correctness:** A user crossing time zones, observing DST, or configuring a late-night cutoff up to 04:00 experiences day boundaries that match their settings, with no false streak breaks. Verified by simulation across all 24 UTC offsets and both DST transitions.
16. **Earned-only freezes:** No code path permits a Grace Day to be acquired by payment. Verified by code audit.
17. **Crisis Mode:** Suppresses all gamification notifications; surfaces support resources prominently; auto-suggested in the 7–14 day supportive window after a logged relapse.
18. **Streak-disable option:** Users can fully disable the TIME-based streak display per habit and globally. Tokens still accumulate silently.
19. **Onboarding completeness:** Onboarding includes the lapse-vs-relapse education screen, the streak-disable option, and the lapse-plan creation prompt, all surfaced before first action logging.
20. **Compulsion guard:** Daily token cap prevents more than 5 unique action categories from counting toward Lifetime Actions in a single day. Session-time warning fires at 30 minutes.

---

## Conclusion: tokens as evidence, not currency

The deepest design insight in this specification is a single reframe: **Streak Tokens should not function as currency the user can lose, but as evidence the user accumulates of who they are becoming.** Currency triggers loss aversion, sunk-cost thinking, and — in this population — the Abstinence Violation Effect cascade that is the dominant relapse pathway. Evidence, by contrast, is permanent, identity-affirming, and structurally protected from shame. Every architectural decision — the never-resetting Lifetime counter, the auto-applied Grace Days, the soft-fail relapse flow, the prohibition of public leaderboards, the dominance of the cumulative count over the streak count in the UI — flows from this single reframe.

The TIME track provides the goal-gradient pull that drives short-term consistency. The COUNT track provides the cumulative-mastery validation that drives long-term identity. Together, running parallel to the chip system, they tell the user three different true things at once: *how long since you last used*, *how consistent you've been lately*, and *how much practice you have already accumulated in the bank.* No one of these can be fully erased by a bad week.

The sobriety chip says how long since you used. The Streak Tokens say how much you have built. Both matter; only one of them should ever go back to zero.
