# Affirmations Experience -- Acceptance Criteria

**Version:** 1.0.0
**Date:** 2026-04-08
**Status:** Draft
**PRD Source:** `docs/prd/specific-features/Affirmations/affirmations.md`
**Priority:** P1 (Wave 1)
**Feature Flag:** `activity.affirmations`

---

## Naming Convention

Each criterion has a unique ID: `AFF-{category}-{number}`

- **FR** = Functional Requirement
- **AC** = Acceptance Criterion (behavioral, Given/When/Then)
- **NFR** = Non-Functional Requirement
- **EC** = Edge Case

---

## 1. Content Library & Level Engine

### AFF-FR-001: Four-Level Progressive Framework

All affirmations are classified into exactly one of four clinical levels:

| Level | Name | Example | Earliest Availability |
|-------|------|---------|-----------------------|
| 1 | Permission | "It is OK for me to talk to others about what I think and feel." | Day 0 (default) |
| 2 | Process | "I am working my recovery. I am striving for progress, not perfection." | Day 14 |
| 3 | Tempered Identity | "I have done bad things, but I am not a bad person." | Day 60 |
| 4 | Full Identity | "I am worthy of love and acceptance, exactly as I am." | Day 180 |

### AFF-AC-001: Level 1 Available Immediately

**Given** a new user who has just completed onboarding,
**When** their first affirmation session loads,
**Then** only Level 1 affirmations are served.

### AFF-AC-002: Level 2 Unlocks at Day 14

**Given** a user whose sobriety counter reaches 14 days,
**When** the level engine evaluates their next session,
**Then** Level 2 affirmations become available for the 20% growth slot and Level 2 becomes selectable as the primary level.

### AFF-AC-003: Level 3 Unlocks at Day 60

**Given** a user whose sobriety counter reaches 60 days,
**When** the level engine evaluates their next session,
**Then** Level 3 affirmations become available.

### AFF-AC-004: Level 4 Unlocks at Day 180

**Given** a user whose sobriety counter reaches 180 days,
**When** the level engine evaluates their next session,
**Then** Level 4 affirmations become available.

### AFF-AC-005: Manual Override to Lower Level

**Given** a user currently at Level 3,
**When** they choose to set their level to Level 1 or Level 2 in settings,
**Then** the level engine immediately serves content at the selected lower level and the override is logged with a timestamp.

### AFF-AC-006: Manual Upgrade Request After 30 Days

**Given** a user who has been at their current level for at least 30 days,
**When** they request a level upgrade in settings,
**Then** the next level is unlocked regardless of sobriety day count, and the upgrade is logged with a timestamp.

### AFF-AC-007: Manual Upgrade Blocked Before 30 Days

**Given** a user who has been at their current level for fewer than 30 days,
**When** they attempt to request a level upgrade,
**Then** the request is denied with a message indicating the minimum time remaining at the current level.

### AFF-FR-002: Ten Content Categories

The content library supports exactly 10 categories with the following minimum launch counts:

| Category | Min Count | Levels | Clinical Focus |
|----------|-----------|--------|----------------|
| Self-Worth & Identity | 30 | 1-4 | Counters core belief #1 |
| Shame Resilience | 25 | 1-3 | Separates behavior from personhood |
| Healthy Relationships | 25 | 2-4 | Counters core belief #2 |
| Connection & Asking for Help | 20 | 1-3 | Counters core belief #3 |
| Emotional Regulation | 20 | 1-3 | Coping with cravings, triggers |
| Purpose & Meaning | 20 | 2-4 | Counters core belief #4 |
| Integrity & Honesty | 20 | 2-4 | Rebuilding character |
| Daily Strength | 20 | 1-2 | Present-moment grounding |
| Healthy Sexuality | 15 | 3-4 | Therapist-reviewed; mid-recovery only |
| SOS / Crisis | 25 | 1-2 | Emergency urge moments |

### AFF-AC-008: Minimum 200 Affirmations at Launch

**Given** the content library at launch,
**When** the total affirmation count is queried,
**Then** there are at least 200 curated affirmations distributed across all 10 categories meeting the minimum counts above.

### AFF-FR-003: Affirmation Tagging Schema

Every affirmation document must contain the following tags:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `level` | Integer (1-4) | Yes | Clinical progression level |
| `coreBeliefs` | Array of Integer (1-4) | Yes | Which of Carnes' 4 core beliefs this counters (1-4 values) |
| `category` | Enum | Yes | One of the 10 content categories |
| `recoveryStage` | Enum | Yes | early, middle, established |
| `track` | Enum | Yes | standard, faithBased |

### AFF-AC-009: 80/20 Level Serving Rule

**Given** a user at Level 2,
**When** a session of 3 affirmations is assembled,
**Then** approximately 80% of affirmations are drawn from Level 2 and approximately 20% from Level 3 (one level above). For a 3-card session, this means 2 cards at current level and 1 card at one level above.

### AFF-AC-010: Level 4 User Gets 100% Level 4

**Given** a user at Level 4 (the highest level),
**When** a session is assembled,
**Then** all affirmations are drawn from Level 4 since there is no level above.

### AFF-AC-011: 7-Day No-Repeat Window

**Given** an affirmation was served to a user within the last 7 days,
**When** the content engine selects affirmations for a new session,
**Then** that affirmation is excluded from selection unless it is in the user's Favorites.

### AFF-AC-012: Favorites Prioritized in Sessions

**Given** a user has favorited 3 or more affirmations,
**When** a daily session is assembled,
**Then** favorited affirmations are given priority weighting in the selection algorithm over non-favorited affirmations at the same level.

### AFF-AC-013: Hidden Affirmations Never Resurface

**Given** a user has hidden an affirmation,
**When** any future session is assembled or the user browses the library,
**Then** that affirmation is permanently excluded from all content delivery for that user.

### AFF-AC-014: Faith-Based Track Selection

**Given** a user selects the faith-based track during onboarding or in settings,
**When** sessions are assembled,
**Then** affirmations tagged with `track=faithBased` are served. The user can switch tracks at any time in settings.

### AFF-AC-015: Default Track Is Standard

**Given** a new user who has not made a track selection,
**When** their first session loads,
**Then** the standard (secular) track is used by default.

### AFF-AC-016: Healthy Sexuality Category Off by Default

**Given** a new user regardless of sobriety day count,
**When** the content engine selects affirmations,
**Then** the Healthy Sexuality category is excluded from all sessions.

### AFF-AC-017: Healthy Sexuality Requires 60 Days AND Explicit Opt-In

**Given** a user with 60+ sobriety days who has explicitly enabled the Healthy Sexuality category in settings,
**When** sessions are assembled,
**Then** Healthy Sexuality affirmations (Level 3-4 only) become eligible for inclusion.

### AFF-AC-018: Healthy Sexuality Blocked Under 60 Days

**Given** a user with fewer than 60 sobriety days,
**When** they attempt to enable the Healthy Sexuality category,
**Then** the toggle is disabled with a message explaining the 60-day minimum requirement.

### AFF-AC-019: Favorite an Affirmation

**Given** a user viewing an affirmation card or browsing the library,
**When** they tap the heart/favorite icon,
**Then** the affirmation is added to their Favorites collection and `isFavorite` is set to true for that user-affirmation pair.

### AFF-AC-020: Hide an Affirmation

**Given** a user viewing an affirmation card or browsing the library,
**When** they tap the hide icon,
**Then** the affirmation is immediately hidden, removed from the current session, and permanently excluded from future delivery. No explanation is required from the user.

---

## 2. Morning Session

### AFF-AC-021: Three Affirmations Shown Sequentially

**Given** an authenticated user opening their morning session,
**When** the session loads,
**Then** three affirmations are displayed one per screen in sequential order, navigable by swiping left/right.

### AFF-AC-022: Daily Intention Prompt After Affirmations

**Given** a user who has viewed all three morning affirmations,
**When** they advance past the third card,
**Then** a Daily Intention screen appears with the prompt "Today I choose to..." and a free-text input field.

### AFF-AC-023: Daily Intention Stored in Journal

**Given** a user who completes the Daily Intention prompt,
**When** they submit their intention,
**Then** the intention text is saved and also appears as a pre-filled prompt in the journal module.

### AFF-AC-024: User-Selected Delivery Time

**Given** a user who has set a morning session delivery time in settings,
**When** the scheduled time arrives,
**Then** a push notification is sent with text "Your daily moment is ready."

### AFF-AC-025: Default Morning Delivery Time

**Given** a new user who has not configured a morning delivery time,
**When** the system schedules their first notification,
**Then** the default delivery time from onboarding is used.

### AFF-AC-026: Skip Without Penalty

**Given** a user who receives a morning session notification,
**When** they dismiss or ignore it without opening the session,
**Then** no penalty is applied, no streak counter is affected, and the skip is logged internally only (not visible to the user).

### AFF-AC-027: No Visible Streak Counter

**Given** a user on any affirmation screen (morning, evening, or library),
**When** they look for streak information,
**Then** no consecutive-day streak counter is displayed anywhere in the affirmations feature. Only cumulative session counts are shown.

### AFF-AC-028: Session Duration 3-5 Minutes

**Given** a user completing a full morning session (3 affirmations + daily intention),
**When** the session flow is measured,
**Then** the estimated completion time is 3-5 minutes.

### AFF-AC-029: Swipe Navigation Between Cards

**Given** a user viewing an affirmation card in a session,
**When** they swipe left,
**Then** the next affirmation card is displayed with a smooth transition.
**When** they swipe right,
**Then** the previous card is displayed (if not on the first card).

### AFF-AC-030: Morning Session Notification Text

**Given** a morning session notification is sent,
**When** the notification appears on the lock screen or notification center,
**Then** the text reads "Your daily moment is ready." with no recovery-specific language.

### AFF-AC-031: Morning Session Offline

**Given** a user with no internet connection,
**When** they open the morning session,
**Then** the session loads from the locally cached affirmation pool (minimum 30 affirmations cached at all times).

### AFF-AC-032: Affirmation Card Interaction -- Favorite

**Given** a user viewing an affirmation card during a morning session,
**When** they tap the heart icon,
**Then** the affirmation is favorited without interrupting the session flow.

### AFF-AC-033: Affirmation Card Interaction -- Hide

**Given** a user viewing an affirmation card during a morning session,
**When** they tap the hide icon,
**Then** the affirmation is hidden and immediately replaced with a different eligible affirmation.

### AFF-AC-034: Daily Intention Skippable

**Given** a user on the Daily Intention screen,
**When** they tap skip or dismiss,
**Then** the session completes without recording an intention. No penalty or prompt to reconsider.

### AFF-AC-035: Morning Session Completion Logged

**Given** a user who views all three affirmation cards (regardless of whether they complete the Daily Intention),
**When** the session ends,
**Then** the session is logged as completed with a timestamp, contributing to cumulative session count.

---

## 3. Evening Reflection

### AFF-AC-036: Evening Session Structure

**Given** an authenticated user opening their evening reflection,
**When** the session loads,
**Then** one affirmation (level-appropriate, calming) is displayed alongside their morning Daily Intention text (if one was recorded).

### AFF-AC-037: Day Rating 1-5 Scale

**Given** a user in the evening reflection session,
**When** the rating prompt appears,
**Then** the user selects a day rating on a 1-5 scale with compassionate, non-evaluative labels (e.g., "How did today feel?" not "Did you stay sober today?").

### AFF-AC-038: Day Rating Feeds Mood Trend Chart

**Given** a user who submits an evening day rating,
**When** the rating is saved,
**Then** it populates the mood trend chart in the Insights section using the same 1-5 scale as the Mood Ratings activity.

### AFF-AC-039: Optional Free-Text Reflection

**Given** a user in the evening reflection,
**When** they see the reflection prompt,
**Then** a free-text input is available but not required. The user can submit the rating without writing anything.

### AFF-AC-040: Compassionate Non-Evaluative Framing

**Given** any text displayed in the evening reflection,
**When** the user reads the prompts and labels,
**Then** all language uses compassionate, non-evaluative framing. No references to sobriety success/failure, no judgment about the day's rating.

### AFF-AC-041: Audio Option for Evening Affirmation

**Given** a user in the evening reflection who has an audio recording for the displayed affirmation,
**When** the session loads,
**Then** the audio version auto-plays with ambient background (if the user has enabled auto-play in settings).

### AFF-AC-042: Evening Session Without Morning Intention

**Given** a user who skipped the morning session or did not record a Daily Intention,
**When** they open the evening reflection,
**Then** the session displays the evening affirmation without the intention section. No shame messaging about missing the morning session.

### AFF-AC-043: User-Selected Evening Delivery Time

**Given** a user who has set an evening reflection delivery time in settings,
**When** the scheduled time arrives,
**Then** a push notification is sent with text "A moment to close your day."

### AFF-AC-044: Default Evening Time

**Given** a new user who has not configured an evening delivery time,
**When** the system schedules notifications,
**Then** the default is 9:00 PM in the user's local timezone.

### AFF-AC-045: Evening Reflection Skippable

**Given** a user who receives the evening notification,
**When** they dismiss or ignore it,
**Then** no penalty is applied and no shame-based follow-up is sent.

### AFF-AC-046: Evening Reflection Offline

**Given** a user with no internet connection,
**When** they open the evening reflection,
**Then** the session loads from locally cached affirmations and the morning intention (stored locally). Ratings and reflections are queued for sync.

### AFF-AC-047: Evening Reflection Completion Logged

**Given** a user who submits a day rating (with or without free-text reflection),
**When** the evening session ends,
**Then** the session is logged as completed with a timestamp, contributing to cumulative session count.

### AFF-AC-048: Evening Audio with Ambient Background

**Given** a user who has enabled the audio option for evening reflections,
**When** the evening session auto-plays audio,
**Then** ambient background sound plays at the configured volume ratio behind the affirmation audio.

---

## 4. SOS Mode

### AFF-AC-049: SOS Trigger from Any Screen

**Given** a user on any screen within the app,
**When** they tap the SOS / Urge button,
**Then** SOS Mode activates immediately and transitions to the full-screen calm UI.

### AFF-AC-050: Immediate Response Within 5 Seconds

**Given** SOS Mode is triggered,
**When** the calm UI loads,
**Then** the transition completes within 0-5 seconds, displaying a full-screen calm interface with a Level 1 or Level 2 affirmation from the SOS category and a 4-7-8 breathing exercise animation.

### AFF-AC-051: SOS Affirmations Never Above Level 2

**Given** a user at any level (including Level 3 or 4) who triggers SOS Mode,
**When** the SOS affirmation is selected,
**Then** only Level 1 or Level 2 affirmations from the SOS/Crisis category are served, regardless of the user's current progression level.

### AFF-AC-052: 4-7-8 Breathing Animation

**Given** SOS Mode has loaded,
**When** the initial affirmation is displayed,
**Then** a guided 4-7-8 breathing exercise animation plays: inhale 4 seconds, hold 7 seconds, exhale 8 seconds, with visual cues.

### AFF-AC-053: Post-Breathing Additional Affirmations

**Given** a user who completes the breathing exercise in SOS Mode,
**When** the breathing exercise ends,
**Then** two additional Level 1-2 affirmations are displayed sequentially.

### AFF-AC-054: Accountability Partner Reach-Out Button

**Given** a user in SOS Mode after the breathing exercise,
**When** the additional affirmations are displayed,
**Then** a "Reach out to your accountability partner" button is visible and functional.

### AFF-AC-055: SOS Accountability Reach-Out Requires Confirmation

**Given** a user who taps "Reach out to your accountability partner" during SOS Mode,
**When** the action is initiated,
**Then** a confirmation dialog appears before any notification is sent to the partner. The user must explicitly confirm.

### AFF-AC-056: SOS Activation Never Auto-Shared

**Given** a user who triggers SOS Mode,
**When** SOS Mode activates and runs,
**Then** no notification or data is sent to accountability partners, sponsors, or therapists unless the user explicitly confirms sharing during or after the session.

### AFF-AC-057: Post-SOS Check-In at 10 Minutes

**Given** a user who completes an SOS session,
**When** 10 minutes have elapsed since the session ended,
**Then** a gentle in-app notification is sent: "How are you feeling now?" This is the only follow-up.

### AFF-AC-058: Post-SOS Check-In No Judgment Language

**Given** the post-SOS check-in notification or screen,
**When** the user reads the check-in prompt,
**Then** no judgment language is used. No references to success or failure. Only compassionate inquiry.

### AFF-AC-059: SOS Mode Works Offline

**Given** a user with no internet connection,
**When** they trigger SOS Mode,
**Then** the SOS experience loads fully from the locally cached SOS affirmation pool and breathing animation assets.

### AFF-AC-060: SOS Session Logged

**Given** a user who completes an SOS session,
**When** the session ends,
**Then** the session is logged locally with a timestamp, contributing to cumulative session count. The log includes session type "SOS."

### AFF-AC-061: SOS Calm UI Design

**Given** SOS Mode activates,
**When** the full-screen calm UI is displayed,
**Then** the interface uses a calming color palette (no high-contrast or energetic colors), minimal UI elements, and large readable text (minimum 22pt).

### AFF-AC-062: SOS Does Not Interrupt Breathing with Notifications

**Given** a user in the SOS breathing exercise,
**When** system or app notifications arrive,
**Then** notifications are suppressed or silenced until the breathing exercise completes.

### AFF-AC-063: SOS Mode Dismissable

**Given** a user in any phase of SOS Mode,
**When** they choose to exit,
**Then** they can dismiss SOS Mode at any point without penalty. Partial sessions are still logged.

### AFF-AC-064: SOS Triggered by Urge Report Integration

**Given** a user who logs an urge via the Urge Reporting feature,
**When** the urge report is submitted,
**Then** the user is prompted to enter SOS Mode with affirmations and breathing. The prompt is optional; the user can decline.

### AFF-AC-065: Post-SOS Check-In Response Logged

**Given** a user who responds to the 10-minute post-SOS check-in,
**When** they provide a response,
**Then** the response is logged locally and feeds into mood trend data.

---

## 5. Custom Affirmations

### AFF-AC-066: Custom Creation Available from Day 14

**Given** a user whose sobriety counter is at 14 days or more,
**When** they navigate to the custom affirmation creation screen,
**Then** the creation flow is accessible.

### AFF-AC-067: Custom Creation Blocked Before Day 14

**Given** a user whose sobriety counter is below 14 days,
**When** they attempt to access custom affirmation creation,
**Then** access is denied with a message explaining that custom creation unlocks at Day 14 to ensure a foundation of curated content first.

### AFF-AC-068: Directed Abstraction Prompts Provided

**Given** a user in the custom affirmation creation flow,
**When** the creation screen loads,
**Then** evidence-based directed abstraction prompts are displayed (e.g., "Something I did well today was ___. This shows I am...") to guide affirmation writing.

### AFF-AC-069: Present Tense Positive Framing Guidance

**Given** a user writing a custom affirmation,
**When** they type in the creation field,
**Then** real-time tips are displayed encouraging present tense ("I am," "I choose," "I have") and positive framing. Examples are provided.

### AFF-AC-070: No Negation Validation

**Given** a user writing a custom affirmation that contains negation patterns (e.g., "I am not addicted," "I don't..."),
**When** they attempt to save,
**Then** a gentle suggestion is shown recommending positive reframing (e.g., "Try framing what you ARE rather than what you're not"). The user can override and save anyway.

### AFF-AC-071: Not Reviewed by Staff Disclosure

**Given** a user in the custom affirmation creation flow,
**When** they view the creation screen,
**Then** a clear notice is displayed: "Your own words carry extra power. Make sure this feels true to you -- even partially -- right now." with an indication that custom affirmations are not reviewed by staff.

### AFF-AC-072: User Chooses Rotation Inclusion

**Given** a user who saves a custom affirmation,
**When** the save confirmation appears,
**Then** the user is asked whether to include this affirmation in their daily session rotation alongside curated affirmations. Default: included.

### AFF-AC-073: Custom Affirmation Max Length

**Given** a user writing a custom affirmation,
**When** the text exceeds the maximum character limit (500 characters),
**Then** input is truncated or rejected with a character counter indicating the limit.

### AFF-AC-074: Custom Affirmation Editable Within 24 Hours

**Given** a custom affirmation created less than 24 hours ago,
**When** the user edits the text,
**Then** the update is saved. The `createdAt` timestamp remains immutable; only `modifiedAt` changes.

### AFF-AC-075: Custom Affirmation Read-Only After 24 Hours

**Given** a custom affirmation created more than 24 hours ago,
**When** the user attempts to edit it,
**Then** the edit is blocked with a message that the affirmation is now permanent. The user can still hide or unfavorite it.

### AFF-AC-076: Custom Affirmation Deletable

**Given** a custom affirmation,
**When** the user deletes it,
**Then** the affirmation is permanently removed from their library and rotation.

### AFF-AC-077: Custom Affirmation Favoriteable

**Given** a custom affirmation,
**When** the user taps the favorite icon,
**Then** it is added to Favorites and prioritized in daily sessions like curated affirmations.

### AFF-AC-078: Custom Affirmation Hideable

**Given** a custom affirmation the user has included in rotation,
**When** the user hides it,
**Then** it is removed from rotation but remains in their custom affirmation list (marked as hidden). It can be un-hidden.

---

## 6. Audio Recording

### AFF-AC-079: Record Any Affirmation in Own Voice

**Given** a user viewing any affirmation (curated or custom),
**When** they tap the microphone/record button,
**Then** the recording flow begins: choose background, tap to record, preview, save.

### AFF-AC-080: Five Preset Ambient Backgrounds

**Given** a user in the recording flow at the background selection step,
**When** the background options are displayed,
**Then** exactly 5 preset ambient background options are available (e.g., nature sounds, soft tones, rain, ocean, silence).

### AFF-AC-081: AAC Encoding 64kbps M4A Format

**Given** a user who completes an audio recording,
**When** the recording is saved,
**Then** the file is encoded as AAC at 64kbps minimum in .m4a container format.

### AFF-AC-082: Maximum Recording Length 60 Seconds

**Given** a user recording an affirmation,
**When** the recording reaches 60 seconds,
**Then** recording stops automatically. A timer is visible during recording showing elapsed time and the 60-second limit.

### AFF-AC-083: Auto-Pause on Headphone Disconnect (CRITICAL)

**Given** a user playing an audio affirmation (own-voice or ambient) through headphones,
**When** Bluetooth or wired headphones disconnect,
**Then** all audio playback pauses immediately (within 500ms). This is a non-negotiable safety requirement to prevent accidental public disclosure.

### AFF-AC-084: Auto-Pause Implementation -- iOS

**Given** an iOS device playing affirmation audio through headphones,
**When** headphones disconnect,
**Then** the app responds to `AVAudioSession.routeChangeNotification` with reason `.oldDeviceUnavailable` and pauses playback immediately.

### AFF-AC-085: Auto-Pause Implementation -- Android

**Given** an Android device playing affirmation audio through headphones,
**When** headphones disconnect,
**Then** the app responds to `AudioManager` audio focus change and pauses playback immediately.

### AFF-AC-086: Background Music Volume Ratio

**Given** a user playing an audio recording with ambient background,
**When** playback begins,
**Then** background music plays at 60% volume relative to voice recording by default.

### AFF-AC-087: Background Music Volume User-Adjustable

**Given** a user playing an audio recording with ambient background,
**When** they adjust the background music volume slider,
**Then** the background volume updates in real time relative to voice volume.

### AFF-AC-088: Local-Only Storage by Default

**Given** a user who saves an audio recording,
**When** the recording is stored,
**Then** it is saved to local device storage only. No cloud sync occurs unless the user has explicitly opted in to cloud audio backup.

### AFF-AC-089: Cloud Sync Opt-In

**Given** a user in settings who enables cloud audio sync,
**When** the setting is toggled on,
**Then** a clear disclosure explains that audio recordings will be encrypted and synced to the cloud. Existing recordings are queued for upload.

### AFF-AC-090: Audio Plays in Sessions When Favorited

**Given** a user whose favorited affirmation has an associated audio recording,
**When** that affirmation appears in a morning or evening session,
**Then** the audio version is available for playback (auto-play if user has enabled it, or manual play button visible).

### AFF-AC-091: Manual Playback Available Anytime

**Given** a user viewing any affirmation that has an associated audio recording,
**When** they tap the play button,
**Then** the audio recording plays with the selected ambient background.

### AFF-AC-092: Recording Preview Before Save

**Given** a user who has just finished recording,
**When** the recording flow advances to the preview step,
**Then** the user can play back the recording with background music, re-record, or save.

### AFF-AC-093: Delete Audio Recording

**Given** a user who has an audio recording for an affirmation,
**When** they choose to delete the recording,
**Then** the audio file is permanently removed from local storage (and cloud if synced). The affirmation text remains.

### AFF-AC-094: Audio Not Shared with Partners

**Given** an accountability partner or therapist viewing a user's affirmation data,
**When** they access shared information,
**Then** audio recordings are never included in shared data. Only session counts and metadata are shareable.

### AFF-AC-095: No Audio in Notifications

**Given** any push notification related to affirmations,
**When** the notification is displayed on the lock screen, notification center, or widget,
**Then** no audio snippets, previews, or playback controls are included.

---

## 7. Progress & Milestones

### AFF-FR-004: Cumulative Not Streak-Based (Clinical Requirement)

All progress metrics must use cumulative totals. Consecutive-day streak counting is prohibited in the affirmations feature. A broken practice pattern must never be framed as failure.

### AFF-AC-096: Total Sessions Displayed

**Given** an authenticated user on the affirmations home or progress screen,
**When** the progress metrics load,
**Then** the total cumulative session count is displayed prominently (e.g., "47 affirmation sessions -- that is 47 moments you chose recovery").

### AFF-AC-097: Total Affirmations Practiced Displayed

**Given** an authenticated user on the progress screen,
**When** the metrics load,
**Then** the total number of individual affirmations practiced (across all sessions) is displayed.

### AFF-AC-098: 30-Day Consistency Heat Map

**Given** an authenticated user on the progress screen,
**When** they view the consistency visualization,
**Then** a 30-day calendar heat map is displayed where darker colors indicate more sessions on that day. Days with no sessions have no special callout or failure indicator.

### AFF-AC-099: No Empty-Day Callouts on Heat Map

**Given** the 30-day consistency heat map,
**When** a day has zero sessions,
**Then** it is displayed as a neutral color (no red, no X, no empty-circle indicator). No attention is drawn to missed days.

### AFF-AC-100: Milestone -- First Session

**Given** a user who completes their very first affirmation session,
**When** the session ends,
**Then** a brief, warm in-app milestone acknowledgment is shown with growth-mindset framing.

### AFF-AC-101: Milestone -- 10th Session

**Given** a user who completes their 10th cumulative session,
**When** the session ends,
**Then** a milestone acknowledgment is shown. No push notification; in-app only.

### AFF-AC-102: Milestone -- 25th, 50th, 100th, 250th Sessions

**Given** a user who reaches the 25th, 50th, 100th, or 250th cumulative session,
**When** the milestone threshold is crossed,
**Then** a corresponding in-app milestone acknowledgment is shown.

### AFF-AC-103: Milestone -- First Custom Affirmation

**Given** a user who creates their first custom affirmation,
**When** the custom affirmation is saved,
**Then** a milestone acknowledgment is shown celebrating their personal contribution to their practice.

### AFF-AC-104: Milestone -- First Audio Recording

**Given** a user who saves their first audio recording,
**When** the recording is saved,
**Then** a milestone acknowledgment is shown.

### AFF-AC-105: Milestone -- First SOS Session

**Given** a user who completes their first SOS session,
**When** the SOS session ends,
**Then** a milestone acknowledgment is shown: "Coming back in a hard moment is courage."

### AFF-AC-106: Growth-Mindset Milestone Framing

**Given** any milestone acknowledgment message,
**When** the text is displayed,
**Then** it uses growth-mindset language. No superlatives ("amazing," "perfect," "incredible"). Preferred phrasing: "That is real work. You showed up."

### AFF-AC-107: Re-Engagement After 3 Days

**Given** a user who has not completed an affirmation session for 3 days,
**When** they open the app,
**Then** the home screen shows a gentle prompt: "Ready when you are. Here is one affirmation for right now." with a single affirmation card (no full session pressure).

### AFF-AC-108: Re-Engagement After 7 Days

**Given** a user who has not completed a session for 7 days,
**When** they open the app,
**Then** a soft in-app message is shown: "Coming back is an act of courage. No catching up needed." with an option to restart with a fresh Level 1 session.

### AFF-AC-109: Re-Engagement After 14+ Days

**Given** a user who has not completed a session for 14 or more days,
**When** they open the app,
**Then** an optional prompt to reconnect with their accountability partner or therapist is shown. The prompt is dismissible. No shame-based language.

### AFF-AC-110: Never Shame-Based Re-Engagement Notifications

**Given** any re-engagement notification or prompt,
**When** the text is composed,
**Then** it never references missed streaks, days away, disappointing language, or any framing that could induce guilt.

### AFF-AC-111: Re-Engagement Push Notification

**Given** a user who has not completed a session for 3+ days,
**When** a re-engagement push notification is sent,
**Then** the text reads "Ready when you are." with no recovery-specific language. Maximum one notification per gap period.

### AFF-AC-112: Milestone Not Sent as Push Notification

**Given** a milestone threshold is crossed,
**When** the system evaluates notification delivery,
**Then** milestone acknowledgments are shown in-app only. No push notifications for milestones.

### AFF-AC-113: Mood Trend Over Time

**Given** an authenticated user on the progress/insights screen,
**When** they view mood trend data,
**Then** a line chart of evening ratings averaged weekly is displayed.

### AFF-AC-114: Favorite Affirmations Count

**Given** an authenticated user on the progress screen,
**When** metrics load,
**Then** the total number of favorited affirmations is shown, framed as personal library size with encouraging language.

### AFF-AC-115: Days Since Last Session (Internal Only)

**Given** a user who has a gap in sessions,
**When** the re-engagement logic evaluates their status,
**Then** days-since-last-session is used internally to trigger re-engagement prompts but is never displayed as a visible metric to the user.

---

## 8. Clinical Safeguards

### AFF-AC-116: Worsening Mood 3+ Sessions -- Therapist Prompt

**Given** a user whose evening day rating has declined for 3 or more consecutive sessions,
**When** the mood trend is evaluated,
**Then** a compassionate prompt is surfaced suggesting the user connect with their therapist or sponsor. The prompt is dismissible and shown once.

### AFF-AC-117: Post-Relapse Window -- Level 1 Only

**Given** a user who has reported a relapse within the last 24 hours,
**When** any affirmation session is assembled,
**Then** only Level 1 affirmations are served regardless of the user's normal level.

### AFF-AC-118: Post-Relapse Compassionate Grounding Message

**Given** a user in the 24-hour post-relapse window,
**When** their affirmation session loads,
**Then** a compassionate grounding message is appended (e.g., "A setback is not the end of your story. You are here, and that matters.").

### AFF-AC-119: Post-Relapse Window Duration

**Given** a user who reported a relapse,
**When** 24 hours have elapsed since the relapse report,
**Then** the post-relapse restrictions are lifted and normal level-based serving resumes.

### AFF-AC-120: Acute Crisis Language Detection

**Given** a user who enters crisis-level language in a free-text field (evening reflection, custom affirmation, or Daily Intention),
**When** crisis keywords are detected,
**Then** the affirmation flow is bypassed and the user is routed directly to crisis resources.

### AFF-AC-121: Crisis Routing Resources

**Given** a user routed to crisis resources,
**When** the crisis screen is displayed,
**Then** the following resources are presented:
- Crisis Text Line: text HOME to 741741
- SAMHSA Helpline: 1-800-662-4357
- Option to contact their designated therapist directly
- Option to contact their designated sponsor directly

### AFF-AC-122: Persistent Rejection -- 5+ Hides in One Session

**Given** a user who hides 5 or more affirmations within a single session,
**When** the 5th hide is recorded,
**Then** the session is flagged internally and an optional prompt is surfaced: "Sometimes the affirmations that feel most wrong point to where healing is needed. You might want to explore this with a therapist." The prompt is dismissible.

### AFF-AC-123: Persistent Rejection Prompt Frequency

**Given** a user who has already seen the persistent rejection prompt,
**When** they trigger the 5-hide threshold again,
**Then** the prompt is shown at most once per week.

### AFF-AC-124: Hidden Affirmation Insight Prompt

**Given** a user who has hidden 3 or more affirmations total (across all sessions),
**When** the threshold is first crossed,
**Then** a non-intrusive insight prompt is offered: "Sometimes the affirmations that feel most wrong point to where healing is needed. You might want to explore this with a therapist." Shown once per week maximum, dismissible.

### AFF-AC-125: Crisis Mood Rating Escalation

**Given** a user who selects a crisis-level mood rating (1/5) on two consecutive evenings,
**When** the second crisis rating is submitted,
**Then** the affirmation experience pauses and routes to crisis support resources.

### AFF-AC-126: Post-Relapse with Self-Harm -- Crisis Route

**Given** a user who reports a relapse with harm involvement,
**When** the report is processed,
**Then** the affirmation feature bypasses normal flow and routes directly to crisis resources.

### AFF-AC-127: Clinical Safeguards Work Offline

**Given** a user offline who triggers a clinical safeguard (post-relapse level restriction, crisis routing),
**When** the safeguard is evaluated,
**Then** locally cached crisis resources and level restrictions are applied without requiring network connectivity.

### AFF-AC-128: Therapist Dashboard -- Hidden Count

**Given** a therapist with user consent viewing the therapist dashboard,
**When** they review a user's affirmation data,
**Then** the total count of hidden affirmations is visible as a diagnostic signal.

### AFF-AC-129: Safeguard Overrides Logged

**Given** any clinical safeguard that modifies normal affirmation delivery (post-relapse level lock, crisis routing, persistent rejection flag),
**When** the safeguard activates,
**Then** the event is logged with a timestamp for clinical review.

### AFF-AC-130: App Never Positions Itself as Crisis Intervention

**Given** any crisis routing screen or message,
**When** crisis resources are displayed,
**Then** a clear disclaimer states that the app is a pointer to professional resources, not a substitute for crisis intervention.

---

## 9. Privacy & Safety

### AFF-AC-131: Generic Notification Text Only

**Given** any push notification related to the affirmations feature,
**When** the notification is displayed,
**Then** it uses generic, non-recovery-specific text only (e.g., "Your daily moment is ready," "A moment to close your day"). Never "Time for recovery" or similar.

### AFF-AC-132: Audio Auto-Pause on Headphone Disconnect

**Given** any audio playback (own-voice recording, ambient music, evening auto-play),
**When** headphones (Bluetooth or wired) disconnect,
**Then** all audio pauses immediately (within 500ms). This criterion duplicates AFF-AC-083 intentionally due to its critical safety importance.

### AFF-AC-133: Biometric Lock Default

**Given** a new user during onboarding,
**When** the privacy setup step is reached,
**Then** biometric authentication (Face ID / Touch ID) is enabled by default with PIN fallback available.

### AFF-AC-134: Quick-Hide / Boss Screen

**Given** a user actively using any affirmation screen,
**When** they perform a shake gesture or tap the dedicated quick-hide button,
**Then** the app instantly switches to a neutral-looking screen that does not reveal the app's recovery-related purpose.

### AFF-AC-135: Local-First Storage

**Given** sensitive affirmation data (audio recordings, journal reflections, mood ratings, custom affirmations),
**When** the data is saved,
**Then** it is stored on-device by default. Cloud sync requires explicit opt-in per data type.

### AFF-AC-136: AES-256 Encryption at Rest

**Given** all locally stored affirmation data (recordings, reflections, ratings, custom content),
**When** the data is written to device storage,
**Then** it is encrypted using AES-256 (iOS Data Protection / Android Keystore).

### AFF-AC-137: TLS 1.3 for API Communication

**Given** any API communication between the affirmation feature and the backend,
**When** a network request is made,
**Then** TLS 1.3 is the minimum transport security version.

### AFF-AC-138: No Affirmation Content Shared to Partners

**Given** an accountability partner viewing shared data,
**When** they access a user's affirmation information,
**Then** only session completion counts are visible. No affirmation text, custom content, audio recordings, journal reflections, or mood ratings are shared.

### AFF-AC-139: Notification Sender Name Generic

**Given** any notification from the affirmations feature,
**When** the notification appears on the device,
**Then** the sender name is the generic app display name only. No recovery-specific label.

### AFF-AC-140: No Audio Preview in Notifications

**Given** any notification related to affirmations,
**When** the notification is displayed on lock screen, notification center, or widget,
**Then** no audio snippets, previews, or playback controls are included.

### AFF-AC-141: Billing Descriptor Generic

**Given** a user who purchases premium features related to affirmations,
**When** the charge appears on their payment statement,
**Then** the billing descriptor uses a generic company name. No app name or recovery-related language.

### AFF-AC-142: Data Export on Request

**Given** a user who requests a full data export (GDPR/CCPA),
**When** the export is processed,
**Then** all affirmation data (sessions, ratings, custom content, audio metadata) is included in the export within 30 days.

### AFF-AC-143: Data Deletion on Request

**Given** a user who requests account deletion (GDPR/CCPA),
**When** the deletion is processed,
**Then** all affirmation data is permanently deleted from servers and local caches within 30 days.

### AFF-AC-144: No Data Used for Advertising or Third-Party ML

**Given** any affirmation content, journal data, or personal recordings,
**When** the data exists in any form,
**Then** it is never used for advertising purposes or third-party machine learning training.

### AFF-AC-145: Anonymized Aggregate Analytics Only

**Given** affirmation usage data collected for product improvement,
**When** analytics are processed,
**Then** only anonymized, aggregate data (session counts, level distribution) is used. User opt-out is available in settings.

---

## 10. Integration

### AFF-AC-146: Sobriety Counter Drives Level Gating

**Given** the user's sobriety counter value,
**When** the level engine evaluates available levels,
**Then** the sobriety day count determines which levels are unlocked: Day 0 = L1, Day 14 = L2, Day 60 = L3, Day 180 = L4.

### AFF-AC-147: Sobriety Reset Resets Level Availability

**Given** a user whose sobriety counter resets (due to relapse report),
**When** the level engine re-evaluates,
**Then** only Level 1 is available until the sobriety counter reaches the next gate threshold again (subject to the 30-day manual override rule).

### AFF-AC-148: Urge Report Triggers SOS Prompt

**Given** a user who submits an urge report via the Urge Reporting feature,
**When** the urge is logged,
**Then** the user is prompted to enter SOS Mode with affirmations and breathing exercise. The prompt is optional.

### AFF-AC-149: Morning Intention Appears in Journal

**Given** a user who completes a Daily Intention during the morning session,
**When** they open the Journal feature,
**Then** the intention text appears as a pre-filled journal prompt for that day.

### AFF-AC-150: Evening Rating Feeds Mood Trend Chart

**Given** a user who submits an evening day rating,
**When** the mood trend chart is viewed in the Insights section,
**Then** the affirmation evening ratings are included in the mood data visualization.

### AFF-AC-151: Accountability Partner Sees Session Count Only

**Given** an accountability partner with granted permissions,
**When** they view the user's affirmation data,
**Then** they see only the number of sessions completed this week. No affirmation text, ratings, reflections, or audio content.

### AFF-AC-152: Partner Can Send Pre-Written Encouragement

**Given** an accountability partner viewing a user's session count,
**When** they send a pre-written encouragement message,
**Then** the message appears as a home screen card in the user's app.

### AFF-AC-153: Therapist View -- Consistency

**Given** a therapist with user consent,
**When** they view the therapist dashboard,
**Then** the user's affirmation practice consistency (session frequency over time) is visible.

### AFF-AC-154: Therapist View -- Hidden Count

**Given** a therapist with user consent,
**When** they view the therapist dashboard,
**Then** the total count of hidden affirmations is visible as a diagnostic signal.

### AFF-AC-155: Therapist View -- Mood Trend

**Given** a therapist with user consent,
**When** they view the therapist dashboard,
**Then** the mood trend derived from evening ratings is visible.

### AFF-AC-156: Therapist View -- Level Progression

**Given** a therapist with user consent,
**When** they view the therapist dashboard,
**Then** the user's level progression history (with timestamps of level changes) is visible.

### AFF-AC-157: Therapist View Requires Explicit Consent

**Given** a user who has not granted therapist access,
**When** a therapist attempts to view their data,
**Then** no data is returned. All therapist views require explicit per-relationship opt-in.

### AFF-AC-158: Data Sharing Granular and Revocable

**Given** a user who has granted data sharing to a partner or therapist,
**When** they revoke permission in settings,
**Then** the shared data is immediately inaccessible to that party. Revocation does not affect the relationship connection.

### AFF-AC-159: Evening Reflection Links to Journal Entry

**Given** a user who writes a free-text reflection during the evening session,
**When** the reflection is saved,
**Then** a link to the evening reflection is accessible from the journal module for that date.

### AFF-AC-160: Affirmation Completion Feeds Daily Recovery Plan

**Given** a user who completes an affirmation session,
**When** the daily recovery plan scoring is calculated,
**Then** the completed affirmation session contributes to the plan score and auto-checks the affirmation goal if configured.

---

## 11. Feature Flag & Non-Functional Requirements

### AFF-NFR-001: Feature Flag `activity.affirmations`

All affirmation endpoints and UI are gated behind the `activity.affirmations` feature flag. When the flag is disabled, all API endpoints return 404. Fail closed: unknown or errored flag state is treated as disabled.

### AFF-NFR-002: Immutable Timestamps (FR2.7)

All affirmation session `createdAt` timestamps are immutable once set. Updates modify only `modifiedAt`. This applies to sessions, custom affirmations, audio recordings, and reflections.

### AFF-NFR-003: 24-Hour Edit Window for Custom Affirmations

Custom affirmations are editable within 24 hours of `createdAt`. After 24 hours, the text becomes read-only. Users can still hide, favorite, or delete.

### AFF-NFR-004: Calendar Activity Dual-Write

**Given** any affirmation session is completed (morning, evening, or SOS),
**When** the session is saved,
**Then** a denormalized entry is written to the calendarActivities collection with `activityType=AFFIRMATION`.

### AFF-NFR-005: WCAG 2.1 AA Compliance

All affirmation screens must meet WCAG 2.1 AA standards:
- VoiceOver / TalkBack full support on all cards and controls
- Dynamic type support (all text scales with system text size settings)
- Minimum touch target size: 44x44pt
- All audio content paired with full text display
- Color is never the sole indicator of meaning

### AFF-NFR-006: Minimum 22pt Typography on Affirmation Cards

All affirmation text on cards must render at minimum 22pt with generous line-height (1.6) for legibility.

### AFF-NFR-007: Offline-First Architecture

The affirmation feature must work without internet connectivity:
- Minimum 30 affirmations cached locally at all times
- SOS pool maintained as a separate always-available local cache
- Sessions, ratings, and reflections saved locally and synced on reconnection
- Conflict resolution: union merge for session logs, LWW for preferences

### AFF-NFR-008: Content Library Hot Update

Affirmation content library updates are delivered via CMS without requiring an app store release.

### AFF-NFR-009: Tenant Isolation

All affirmation data is scoped by `tenantId`. Queries enforce tenant isolation at the API layer.

### AFF-NFR-010: Compassionate Error Messages

All error messages and empty states in the affirmation feature use compassionate, non-judgmental language. Gaps in practice are never framed as failure. Crisis-level states are met with warmth and immediate resource routing.

---

## Acceptance Criteria Summary

| Section | Range | Total ACs | P0 | P1 | P2 |
|---------|-------|-----------|----|----|-----|
| 1. Content Library & Level Engine | AFF-AC-001 to AFF-AC-020 | 20 | 14 | 6 | 0 |
| 2. Morning Session | AFF-AC-021 to AFF-AC-035 | 15 | 8 | 7 | 0 |
| 3. Evening Reflection | AFF-AC-036 to AFF-AC-048 | 13 | 6 | 7 | 0 |
| 4. SOS Mode | AFF-AC-049 to AFF-AC-065 | 17 | 12 | 5 | 0 |
| 5. Custom Affirmations | AFF-AC-066 to AFF-AC-078 | 13 | 5 | 8 | 0 |
| 6. Audio Recording | AFF-AC-079 to AFF-AC-095 | 17 | 8 | 9 | 0 |
| 7. Progress & Milestones | AFF-AC-096 to AFF-AC-115 | 20 | 8 | 12 | 0 |
| 8. Clinical Safeguards | AFF-AC-116 to AFF-AC-130 | 15 | 12 | 3 | 0 |
| 9. Privacy & Safety | AFF-AC-131 to AFF-AC-145 | 15 | 10 | 5 | 0 |
| 10. Integration | AFF-AC-146 to AFF-AC-160 | 15 | 6 | 9 | 0 |
| 11. Feature Flag & NFRs | AFF-NFR-001 to AFF-NFR-010 | 10 | 8 | 2 | 0 |
| **Total** | | **170** | **97** | **73** | **0** |
