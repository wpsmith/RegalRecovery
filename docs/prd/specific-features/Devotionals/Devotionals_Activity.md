# Activity: Devotionals

**Priority:** P1
**Feature Flag:** `activity.devotionals`
**Wave:** 2 (P1 Features & Activities)
**Version:** 2.0.0
**Last Updated:** 2026-04-12

---

## Terminology

Throughout this document and all related specs, the following terms are used precisely:

- **Devotion** (or **devotional**): A single content item -- one day's reading consisting of scripture, reflection, recovery connection, reflection question, and prayer.
- **Devotional Series**: A curated collection of devotions intended to be read in sequence, ranging from 3 to 365 devotions in length. A series has an "about" description and an ordered outline of its devotion titles.
- **Active Series**: The one devotional series a user has selected to drive their daily devotion experience in the Devotion Activity.
- **Devotion Activity**: The daily activity where a user reads, reflects on, and completes a single devotion from their active series.

---

## User Stories

### Core Devotion Activity

- As a **recovering user**, I want to read a daily devotion that connects scripture to my recovery, so that my faith and sobriety work are woven together rather than separate.
- As a **recovering user**, I want to receive a devotion notification each day, so that I am prompted to spend time with God even on busy or difficult days.
- As a **recovering user**, I want to write a reflection or response after reading a devotion, so that I can process what God is speaking to me and apply it to my recovery.
- As a **recovering user**, I want to browse past devotions I have read and my responses, so that I can revisit insights and see how my spiritual growth has progressed.
- As a **recovering user**, I want access to devotions that specifically address addiction, shame, temptation, and restoration, so that the content feels relevant to what I am actually going through.
- As a **recovering user**, I want to favorite devotions that resonate deeply with me, so that I can return to them during moments of struggle or doubt.
- As a **recovering user**, I want to share a devotion with my sponsor, spouse, or accountability partner, so that we can discuss it together and deepen our connection.

### Devotional Series Management

- As a **recovering user**, I want to select which devotional series is active for my daily devotion activity, so that I can choose content that matches where I am in my recovery journey.
- As a **recovering user**, I want to browse all available devotional series in a settings/browsing page, so that I can discover new series and see what is free versus premium.
- As a **recovering user**, I want to see an "about" section for any devotional series that describes the series and shows an outline of all devotion titles, so that I can make an informed decision before starting or purchasing a series.
- As a **recovering user**, I want to access devotional series settings and the series catalog directly from the devotion activity screen, so that managing my series is effortless without leaving context.
- As a **recovering user**, I want access to premium devotional series of varying lengths (from 3-day topical studies to 365-day year-long journeys), so that I have both quick and sustained spiritual growth options.

### Resources Integration

- As a **recovering user**, I want to see devotional series listed in the Resources section of the app, so that I can discover devotional content while browsing other resources.
- As a **recovering user**, I want to tap a devotional series in Resources and see its about/outline page, so that I can learn about it and start or purchase it without navigating elsewhere.

### Spouse & Localization

- As a **spouse**, I want access to devotions written for betrayed partners, so that I can process my own pain through a faith-based lens.
- As a **recovering user**, I want devotions available in both English and Spanish, so that I can engage with God in the language closest to my heart.

---

## Devotional Content Tiers

### Freemium -- Basic Devotional Series

- One free 30-devotion series included at no cost ("Recovery Foundations: 30 Days").
- Topics cover core recovery themes: surrender, identity in Christ, freedom from shame, trusting God's plan, daily strength, forgiveness, hope.
- Each devotion is self-contained -- users can start on any day.
- After completing the series (or if no series is active), the rotation cycles back to day 1 of the free series.
- Additional free series may be added over time (e.g., short 3-7 day topical series for seasonal content or partner promotions).

### Premium -- Extended Devotional Series (Unlocked Forever When Purchased)

- Multiple devotional series available, each purchased independently through the Content/Resources System.
- Series range from 3 to 365 devotions in length:
  - **Short series (3-7 devotions):** Topical deep dives (e.g., "3 Days of Surrender," "7 Days Through Shame").
  - **Medium series (10-30 devotions):** Focused journeys (e.g., "21 Days of Marriage Restoration," "14 Days of Identity in Christ").
  - **Long series (90-365 devotions):** Structured year-long or quarterly journeys with progressive depth and themes.
- Categories of premium series:
  - Recovery-focused (addiction, temptation, relapse prevention, restoration)
  - Marriage and trust rebuilding
  - Identity and shame
  - General spiritual growth
  - For spouses/partners (betrayal trauma healing)
- New series added over time through content partnerships.

### Partner/Counselor Devotional Series

- Counselors and partner organizations can publish devotional series through the Content/Resources System.
- Freemium partner series available to all users.
- Premium partner series available to users who purchase the relevant pack.

---

## Devotion Structure

Each individual devotion includes the following elements:

- **Title** -- Brief, evocative title for the day's reading.
- **Scripture passage** -- Primary verse(s) displayed in full, with translation noted (NIV default; RVR1960/NVI for Spanish).
- **Reading** -- 300-600 word reflection connecting scripture to recovery (written in warm, pastoral tone).
- **Recovery connection** -- 1-2 sentences explicitly linking the devotion theme to a practical recovery principle or behavior.
- **Reflection question** -- A single thought-provoking question for the user to sit with (e.g., "Where in your recovery are you trying to control what only God can do?").
- **Prayer** -- A short closing prayer (50-100 words) the user can read or pray aloud.
- **Author attribution** -- Name and brief bio of the devotion author (when applicable).

---

## Devotional Series Structure

Each devotional series includes the following metadata:

- **Series name** -- Descriptive title (e.g., "365 Days of Recovery," "7 Days Through Shame").
- **About / Description** -- A 2-4 paragraph description of the series: its purpose, who it is for, what the user will gain, and the author's perspective. Written in warm, inviting language.
- **Author** -- Name and bio of the series author or curating organization.
- **Outline** -- A complete, ordered list of all devotion titles in the series (e.g., for a 10-day series, all 10 titles are displayed). This lets users preview the journey before committing.
- **Total devotion count** -- The number of devotions in the series (e.g., 3, 7, 10, 21, 30, 90, 365).
- **Category** -- recovery, marriage, identity, spiritual-growth, partner-healing.
- **Tier** -- Free or premium.
- **Price** -- For premium series, the one-time purchase price (USD).
- **Thumbnail image** -- Cover art for the series.
- **Language** -- en, es.

---

## Access Points

The Devotionals feature is accessible from multiple locations in the app to maximize discoverability and ease of use:

### 1. Devotion Activity (Activities Section)

The primary daily touchpoint. When a user opens the Devotion activity:

- If the user has an active series, today's devotion from that series is displayed immediately.
- If the user has no active series, the free 30-day rotation series is automatically active.
- A settings/gear icon in the activity header provides one-tap access to the **Devotional Series Browser** (see below).
- After completing a devotion, the user sees a completion confirmation with series progress.

### 2. Devotional Series in Resources (Content Tab)

Devotional series appear as a section within the Resources/Content tab:

- A "Devotional Series" row appears in the Resources list (alongside Crisis Hotlines, Glossary, Library, Videos, etc.).
- Tapping opens the **Devotional Series Browser** showing all available series.
- Each series card shows: thumbnail, name, devotion count, tier (free badge or price), and whether the user owns it.
- Tapping any series card opens its **Series Detail / About Page**.

### 3. Push Notifications

- Daily devotion reminder notification opens directly to the devotion activity.
- Missed devotion follow-up notification opens to the devotion activity.
- New series available notification opens to the series detail page.

### 4. Morning Routine Integration

- If configured as part of the morning routine, the devotion step opens the devotion activity.

### 5. Dashboard Widget

- Devotional streak displayed as optional widget on the main Dashboard.

---

## Devotional Series Browser (Settings/Browsing Page)

This page is the central hub for discovering, previewing, and managing devotional series. It is reachable from:
- The gear/settings icon in the Devotion Activity header.
- The "Devotional Series" row in the Resources section.

### Layout

1. **Active Series Card** (top, prominent)
   - Shows the currently active series with: thumbnail, name, progress indicator ("Day 12 of 30"), and a "Continue Reading" button.
   - If no premium series is active, shows the free series with its progress.
   - Tapping opens the Series Detail / About Page for the active series.

2. **Browse All Series** (below active card)
   - Grid or list of all available devotional series.
   - Each series card displays:
     - Thumbnail image
     - Series name
     - Author name
     - Devotion count (e.g., "30 devotions")
     - Tier indicator: "Free" badge (green) or price (e.g., "$9.99")
     - Ownership status: "Owned" badge if purchased, lock icon if premium and not purchased
     - Progress indicator if the user has started this series (e.g., "Day 5 of 30")
   - Filter/sort options: All, Free, Premium, By Category (recovery, marriage, identity, spiritual-growth, partner-healing), By Length (short/medium/long).

3. **Series Detail / About Page** (opened by tapping any series card)
   - **Header**: Thumbnail, series name, author, devotion count, tier/price.
   - **About section**: 2-4 paragraph description of the series.
   - **Outline section**: Scrollable list showing every devotion title in order (e.g., "Day 1: A New Beginning," "Day 2: Surrender," ... "Day 30: The Journey Ahead"). For long series, this list is virtualized.
   - **Action buttons**:
     - If free or owned: "Set as Active Series" button (or "Continue" if already started, or "Active" badge if already active).
     - If premium and not owned: "Unlock for $X.XX" purchase button leading to the purchase flow.
   - **Progress section** (if user has started this series): Progress bar, days completed, current position.

### UX Priority: Extremely Easy to Use

- One tap from the devotion activity to reach series browsing.
- One tap on a series card to see full details and outline.
- One tap to set any owned series as active.
- No deep navigation -- the Series Browser is a flat, scannable page.
- Clear visual distinction between free, premium-locked, and owned series.
- The active series is always visually prominent at the top.

---

## Daily Devotion Flow

1. **Notification** -- Push notification at user-configured time (default: 7:00 AM).
   - Notification preview shows devotion title and scripture reference.
   - Tap opens directly to the devotion screen.

2. **Devotion screen:**
   - Series context bar at top: series name, "Day X of Y" progress indicator.
   - Full-screen reading view with clean typography (serif font, 20pt+, generous line spacing).
   - Scripture passage displayed prominently at top.
   - Reading body below.
   - Recovery connection highlighted in a subtle callout box.
   - Reflection question displayed with visual emphasis.
   - Closing prayer at bottom.
   - Settings/gear icon in the header for accessing the Devotional Series Browser.

3. **Response area** (below devotion):
   - Reflection question repeated as prompt.
   - Free-text input (unlimited length, voice-to-text available).
   - Optional mood tag: "How are you feeling after this reading?" (emoji or word selection).
   - Save button -- response saved to devotion history.

4. **Post-completion actions:**
   - Favorite (heart icon) -- saves to Favorites list.
   - Share -- send devotion (without personal response) to support network contact, clipboard, or social media graphic.
   - Audio -- text-to-speech playback of the full devotion including scripture and prayer.
   - Next -- browse to the next devotion in the series (premium) or the next in rotation (freemium).

5. **Completion confirmation:**
   - Subtle checkmark animation.
   - "Devotion completed" logged to Tracking System.
   - Series progress indicator updates: "Day 12 of 30 complete."

---

## Devotional Library

The Devotional Library is accessible from the Devotion Activity and provides browsing and history:

- **Today's Devotion** -- featured at top, one-tap access.
- **My Favorites** -- horizontal scroll of favorited devotions.
- **My History** -- reverse chronological list of completed devotions with responses.
- **Browse by Series** -- view all available series with progress indicators (links to Series Browser).
- **Browse by Topic** -- filter devotions by theme: shame, temptation, identity, marriage, forgiveness, surrender, gratitude, restoration, fear, hope.
- **Browse by Author** -- filter by devotion author.
- **Search** -- full-text search across devotion titles, scripture references, and body text.
- **Locked content** -- premium devotions shown with lock icon and "Unlock" CTA leading to purchase flow.

---

## Active Series Selection & Reading Plans

### Active Series Concept

- A user always has one active series that drives the daily Devotion Activity.
- By default, the free 30-devotion series is active for all users.
- The user can change their active series at any time via the Devotional Series Browser.
- Changing the active series pauses the current series at its current position and activates the selected series (starting from where the user left off, or Day 1 if never started).

### Reading Plan Rules

- **Freemium series:** Sequential progression through the 30 devotions. After completion, the rotation restarts from Day 1.
- **Premium series:** User selects a series and progresses sequentially (Day 1, Day 2, etc.).
  - **Missed days:** The devotion waits for the user -- no auto-advance. User can manually skip or catch up.
  - **One active series at a time:** Switching pauses the current series and resumes where the user left off when they return.
  - **Series completion:** When a user finishes all devotions in a series, the series is marked "Completed." The user is prompted to select a new active series or can restart the completed series.
- **Custom plan (future consideration):** User selects specific devotions to create a personal reading plan.

---

## History & Reflection Review

- Browse all completed devotions by date.
- Tap any past entry to see: full devotion text, user's reflection response, mood tag, date completed.
- Filter by series, topic, author, or date range.
- Search reflections by keyword (searches user's own response text).
- Export devotion history with reflections as PDF for personal records or therapy sessions.

---

## Integration Points

- **Tracking System:** Feeds consecutive-day tracking (devotion streak).
- **Analytics Dashboard:** Devotion engagement trends, correlation with recovery outcomes.
- **Morning Routine:** Available as a step in the morning routine (after morning commitment and affirmation).
- **Weekly/Daily Goals:** Completing a devotion auto-checks a "devotion" goal if one is set.
- **Prayer Activity:** Devotion prayer can flow into a logged prayer session.
- **Content/Resources System:** Devotional series follow the same freemium/premium model. Series are browsable from both the Devotion Activity settings and the Resources tab.
- **Dashboard Widget:** Devotion streak displayed as optional widget.
- **Calendar:** Devotion completions appear in the calendar activity view.

---

## Notifications

- **Daily devotion reminder** at user-configured time (default: 7:00 AM). Notification preview shows devotion title and scripture reference.
- **Missed devotion follow-up:** "You haven't read today's devotion yet. A few minutes with God can change your whole day." (sent once, configurable time, default: 12:00 PM).
- **Streak milestone:** "You've completed 30 consecutive days of devotions! Your consistency is building something lasting."
- **New content:** "A new devotional series is available: [Series Name]. Explore it now."
- All devotion notifications independently togglable in Settings.

---

## Accessibility & Localization

- Text-to-speech (TTS) for full devotion playback -- accessible to visually impaired users and useful for commuters.
- Dynamic font sizing support (iOS Dynamic Type).
- Scripture translations: NIV (English default), ESV, NLT, KJV selectable in Settings; RVR1960, NVI for Spanish.
- All freemium devotions available in English and Spanish at launch.
- Premium devotion translation follows Content Localization Strategy outlined in the Content Strategy PRD.
- Series About page and Outline available in both supported languages.

---

## Offline Behavior

- **Content caching:** Current day's devotion plus the next 7 days are pre-loaded for offline access.
- **Series metadata caching:** Active series About page, outline, and progress are cached locally.
- **Offline completion:** Reflections saved locally via SwiftData and synced when connection is restored.
- **Offline browsing:** Series Browser is available offline with cached series metadata. Purchase flow requires connectivity.
- **Conflict resolution:** If same devotion completed on multiple devices, union merge (keep both records, deduplicate by devotionalId + date). Sobriety-conservative approach per project conventions.

---

## Feature Flag Requirements

- **Flag key:** `activity.devotionals`
- **Default state:** Disabled (fail closed per project conventions).
- **Behavior when disabled:**
  - API returns 404 for all devotional endpoints.
  - iOS hides the Devotion activity from the Activities section.
  - iOS hides the "Devotional Series" row from the Resources section.
  - iOS hides the "Devotions" section from the Content Tab.
- **Rollout plan:** 10% -> 50% -> 100% with 24-48 hour monitoring at each stage.
- **Kill switch:** Flag can be disabled immediately to hide the entire feature without a code deploy.

---

## Free vs Premium Model

| Aspect | Free | Premium |
|--------|------|---------|
| Series access | One 30-devotion recovery series | All purchased series (3-365 devotions) |
| Series browsing | Can browse all series and view About/Outline | Same |
| Purchase model | N/A | One-time purchase per series, unlocked forever |
| Active series selection | Free series only | Any owned series |
| Reflection & history | Full access | Full access |
| Favorites | Full access | Full access |
| Sharing | Full access | Full access |
| Offline caching | Current day + 7 days from active series | Same |
| Series Detail/About | Viewable for all series | Same |
| Series Outline | Viewable for all series (titles only, not full devotion content) | Same |

**Design principle:** Free users can see everything that exists (series names, About descriptions, outlines, devotion counts) so they understand the value before purchasing. Only the full devotion content of premium series is locked.

---

## UX Flows

### Flow 1: First-Time User Opens Devotion Activity

1. User taps "Devotional" in Activities.
2. Free 30-day series is automatically set as active.
3. Day 1 devotion is displayed.
4. After reading, user can write a reflection and save.
5. Completion is logged. Series progress shows "Day 1 of 30."

### Flow 2: User Changes Active Series

1. User taps gear icon in Devotion Activity header.
2. Devotional Series Browser opens. Active series shown at top.
3. User scrolls and taps a different owned series.
4. Series Detail / About Page opens with description and outline.
5. User taps "Set as Active Series."
6. Confirmation: "Switch to [Series Name]? Your progress in [Current Series] will be saved." User confirms.
7. Series Browser updates. New active series is at top.
8. User returns to Devotion Activity. Today's devotion is from the new series.

### Flow 3: User Discovers Series via Resources Tab

1. User navigates to Resources tab.
2. User taps "Devotional Series" row.
3. Devotional Series Browser opens (same page as from the Activity).
4. User browses, taps a premium series they do not own.
5. Series Detail page shows About, Outline, and "Unlock for $9.99" button.
6. User taps Unlock. Purchase flow completes.
7. Series is now owned. Button changes to "Set as Active Series."
8. User taps it. Series becomes active. User can navigate to Devotion Activity to start reading.

### Flow 4: User Browses Series Outline Before Purchasing

1. User opens any series (free or premium) from the Series Browser.
2. About section describes the series purpose and audience.
3. Outline section shows all devotion titles in order: "Day 1: A New Beginning," "Day 2: Surrender," etc.
4. User reads the outline to decide if this series is right for them.
5. For premium series, devotion titles are visible but tapping an individual devotion shows a lock with purchase CTA.
6. For free/owned series, tapping a devotion title opens it for reading (out of sequence -- does not affect active series progression).

---

## Data Model Concepts

### Devotional Series (System-Level)

Each series record contains:
- `seriesId` -- unique identifier
- `name` -- localized series title
- `description` -- localized About text (2-4 paragraphs)
- `authorName` -- series author
- `authorBio` -- localized author biography
- `totalDevotions` -- count of devotions in this series (3-365)
- `outline` -- ordered array of `{ day: number, title: string }` for all devotions
- `tier` -- free or premium
- `price` / `currency` -- for premium series
- `category` -- recovery, marriage, identity, spiritual-growth, partner-healing
- `thumbnailUrl` -- cover art
- `language` -- en, es
- `isPublished` -- publication status
- `publishedAt` -- publication timestamp

### Individual Devotion (System-Level)

Each devotion record contains all fields specified in the Devotion Structure section above, plus:
- `devotionalId` -- unique identifier
- `seriesId` -- parent series
- `seriesDay` -- position within the series (1-based)
- `tier` -- inherited from parent series
- `topic` -- primary theme tag
- `wordCount` -- reading word count
- Localized content fields for reading, recoveryConnection, reflectionQuestion, prayer, authorBio

### User Series Progress (User-Scoped)

Tracks each user's relationship with each series:
- `seriesId` -- which series
- `currentDay` -- next devotion to read
- `completedDays` -- count of completed devotions
- `status` -- not_started, active, paused, completed
- `startedAt` / `lastCompletedAt` / `pausedAt` -- timestamps

### User Devotion Completion (User-Scoped)

One record per completed devotion:
- `completionId` -- unique identifier
- `devotionalId` -- which devotion
- `seriesId` / `seriesDay` -- series context
- `reflection` -- user's response text (nullable)
- `moodTag` -- post-reading mood (nullable)
- `timestamp` -- immutable completion time (FR2.7)

See `specs/mongodb-schema.md` for full collection designs and indexes.

---

## Edge Cases

- **User opens app after midnight but before sleeping:** Devotion shown is for the current calendar day (based on user's timezone).
- **User completes devotion but does not write a reflection:** Still counts as completed; reflection prompt available later from history.
- **User is on Day 15 of a series and purchases a second series:** Second series appears as available to activate; switching pauses the current series at Day 15.
- **User deletes and reinstalls app:** Devotion history and progress restored from account sync.
- **Premium series content updated by publisher:** User sees updated content on next read; completed days unaffected.
- **Offline:** Devotions cached for offline reading (current day + next 7 days pre-loaded); reflections saved locally and synced when connection restored.
- **User completes all devotions in a series:** Series status changes to "completed." User is prompted to choose a new active series. If no other owned series exists, free series is reactivated.
- **User has no active series and no series progress:** Free series is auto-activated at Day 1.
- **Series with only 3 devotions:** Completion happens quickly. After completion, user is immediately prompted to select a new series.
- **User views a series outline for a 365-day series:** Outline list is virtualized/lazy-loaded to handle large lists performantly.
- **User accesses Series Browser while offline:** Cached series metadata is displayed. "Unlock" buttons for premium series are disabled with a "Requires internet" tooltip.

---

## Acceptance Criteria Reference

See `specs/acceptance-criteria.md` for the full set of testable acceptance criteria organized by category:
- AC-DEV-CONTENT -- Content structure and tiers
- AC-DEV-READ -- Reading and display
- AC-DEV-REFLECT -- Reflections and responses
- AC-DEV-LIBRARY -- Library browsing, search, and filtering
- AC-DEV-SERIES -- Series management, browsing, about/outline, active selection
- AC-DEV-HISTORY -- History and reflection review
- AC-DEV-FAVORITE -- Favorites management
- AC-DEV-SHARE -- Sharing devotions
- AC-DEV-NOTIFY -- Notifications
- AC-DEV-OFFLINE -- Offline behavior
- AC-DEV-I18N -- Internationalization and accessibility
- AC-DEV-INTEG -- Integration points with other systems
- AC-DEV-EDGE -- Edge cases

---

## Related Documents

- `specs/acceptance-criteria.md` -- Full acceptance criteria
- `specs/mongodb-schema.md` -- MongoDB collection designs
- `specs/openapi.yaml` -- REST API specification
- `specs/test-specifications.md` -- Test cases referencing ACs
- `implementation-plan.md` -- Phased build plan
- `docs/prd/04-content-strategy.md` -- Content tiers and monetization model
