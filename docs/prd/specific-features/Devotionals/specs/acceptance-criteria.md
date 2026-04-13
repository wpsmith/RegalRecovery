# Devotionals Activity -- Acceptance Criteria

**Version:** 2.0.0
**Date:** 2026-04-12
**Status:** Draft
**Feature Flag:** `activity.devotionals`
**Priority:** P1 (Wave 2)

---

## Notation

Each acceptance criterion has a unique ID in the format `AC-DEV-{category}-{number}`. Categories:

- **CONTENT** -- Devotion content structure and tiers
- **READ** -- Reading and display
- **REFLECT** -- Reflections and responses
- **LIBRARY** -- Library browsing, search, and filtering
- **SERIES** -- Series management, browsing, about/outline, active selection
- **HISTORY** -- History and reflection review
- **FAVORITE** -- Favorites management
- **SHARE** -- Sharing devotions
- **NOTIFY** -- Notifications
- **OFFLINE** -- Offline behavior
- **I18N** -- Internationalization and accessibility
- **INTEG** -- Integration points with other systems
- **EDGE** -- Edge cases

---

## Content Structure (AC-DEV-CONTENT)

### AC-DEV-CONTENT-01: Devotion includes all required elements
**Given** a devotion exists in the system,
**When** the devotion is retrieved via API,
**Then** it contains: title, scriptureReference, scriptureText, bibleTranslation, reading (300-600 words), recoveryConnection, reflectionQuestion, prayer (50-100 words), and authorAttribution (name + bio when applicable).

### AC-DEV-CONTENT-02: Freemium tier provides a 30-devotion series
**Given** a user on the free tier,
**When** they access today's devotion,
**Then** the devotion is selected from the free 30-devotion series based on the user's current day in the series.

### AC-DEV-CONTENT-03: Free series rotation resets after completion
**Given** a free-tier user has completed all 30 devotions in the free series,
**When** day 31 arrives,
**Then** the series restarts from Day 1 of the same 30-devotion set.

### AC-DEV-CONTENT-04: Premium series unlocked forever on purchase
**Given** a user purchases a premium devotional series,
**When** the purchase is confirmed,
**Then** the series is permanently unlocked and accessible regardless of subscription status.

### AC-DEV-CONTENT-05: Locked premium content shows purchase CTA
**Given** a user has not purchased a premium devotional series,
**When** they browse that series in the Series Browser,
**Then** the series card shows a price indicator, and the Series Detail page shows an "Unlock for $X.XX" call-to-action leading to the purchase flow.

### AC-DEV-CONTENT-06: Partner/counselor devotional series supported
**Given** a counselor or partner organization publishes a devotional series through the Content/Resources System,
**When** a user browses the Series Browser,
**Then** partner series are visible according to their tier (freemium visible to all, premium visible to purchasers).

### AC-DEV-CONTENT-07: Devotional series range from 3 to 365 devotions
**Given** a devotional series exists in the system,
**When** the series metadata is retrieved,
**Then** totalDevotions is between 3 and 365 (inclusive).

---

## Reading and Display (AC-DEV-READ)

### AC-DEV-READ-01: Today's devotion accessible with one tap
**Given** a user opens the Devotion Activity,
**When** the activity loads,
**Then** today's devotion from the active series is displayed immediately.

### AC-DEV-READ-02: Full-screen reading view
**Given** a user opens a devotion,
**When** the devotion screen loads,
**Then** it displays: series context bar (series name, "Day X of Y"), scripture passage prominently at top, reading body below, recovery connection in a callout box, reflection question with visual emphasis, and closing prayer at bottom.

### AC-DEV-READ-03: Devotion uses user's timezone for day boundary
**Given** a user's timezone is set to America/Los_Angeles,
**When** the user opens the app at 11:30 PM PST on March 28,
**Then** the devotion shown is for March 28 (current calendar day in user's timezone).

### AC-DEV-READ-04: Audio playback via TTS
**Given** a user is viewing a devotion,
**When** they tap the audio button,
**Then** text-to-speech plays the full devotion including scripture, reading, and prayer.

### AC-DEV-READ-05: Dynamic font sizing support
**Given** a user has configured a larger font size in their device settings,
**When** they view a devotion,
**Then** all text respects the user's dynamic type settings.

### AC-DEV-READ-06: Settings access from devotion activity
**Given** a user is viewing a devotion or is in the Devotion Activity,
**When** they tap the settings/gear icon in the activity header,
**Then** the Devotional Series Browser opens.

---

## Reflections and Responses (AC-DEV-REFLECT)

### AC-DEV-REFLECT-01: User can write a reflection
**Given** a user has read a devotion,
**When** they enter text in the response area and tap Save,
**Then** the reflection is saved and associated with that devotion completion.

### AC-DEV-REFLECT-02: Reflection supports unlimited text
**Given** a user is writing a reflection,
**When** they type text of any length,
**Then** the input accepts unlimited characters without truncation.

### AC-DEV-REFLECT-03: Voice-to-text available for reflection
**Given** a user is in the reflection input area,
**When** they activate voice-to-text,
**Then** spoken words are transcribed into the reflection text field.

### AC-DEV-REFLECT-04: Optional mood tag on reflection
**Given** a user has completed a devotion reading,
**When** they are in the response area,
**Then** they can optionally select a mood tag ("How are you feeling after this reading?") via emoji or word selection.

### AC-DEV-REFLECT-05: Devotion completion without reflection
**Given** a user has read a devotion but does not write a reflection,
**When** they navigate away or tap Next,
**Then** the devotion is still marked as completed, and the reflection prompt remains available from history.

---

## Library (AC-DEV-LIBRARY)

### AC-DEV-LIBRARY-01: Library shows Today, Favorites, History, Series, Topic, Author sections
**Given** a user opens the Devotional Library,
**When** the library loads,
**Then** it displays sections for: Today's Devotion, My Favorites (horizontal scroll), My History (reverse chronological), Browse by Series (link to Series Browser), Browse by Topic, Browse by Author.

### AC-DEV-LIBRARY-02: Browse by topic
**Given** a user navigates to Browse by Topic,
**When** they select a topic (shame, temptation, identity, marriage, forgiveness, surrender, gratitude, restoration, fear, hope),
**Then** only devotions tagged with that topic are returned.

### AC-DEV-LIBRARY-03: Browse by author
**Given** a user navigates to Browse by Author,
**When** they select an author,
**Then** only devotions by that author are returned.

### AC-DEV-LIBRARY-04: Browse by series with progress
**Given** a user navigates to Browse by Series,
**When** the series list loads,
**Then** each series shows its name, description, total devotion count, and the user's progress indicator (e.g., "Day 47 of 365").

### AC-DEV-LIBRARY-05: Full-text search
**Given** a user enters a search query in the library,
**When** results are returned,
**Then** the search matches against devotion titles, scripture references, and body text.

---

## Series Management (AC-DEV-SERIES)

### AC-DEV-SERIES-01: Premium series sequential progression
**Given** a user has an active premium series,
**When** they complete Day N,
**Then** Day N+1 becomes available, and the progress indicator updates.

### AC-DEV-SERIES-02: Missed days do not auto-advance
**Given** a user is on Day 15 of a series and skips a calendar day,
**When** they open the app the next day,
**Then** the devotion shown is still Day 15 (no auto-advance); user can manually skip or catch up.

### AC-DEV-SERIES-03: One active series at a time
**Given** a user has an active series (Series A at Day 15),
**When** they switch to a different series (Series B),
**Then** Series A is paused at Day 15, Series B starts (or resumes) where the user left off.

### AC-DEV-SERIES-04: Paused series resumes correctly
**Given** a user paused Series A at Day 15 and switched to Series B,
**When** they switch back to Series A,
**Then** Series A resumes at Day 15.

### AC-DEV-SERIES-05: Series progress indicator displayed
**Given** a user is on Day 47 of a 365-devotion series,
**When** they complete the devotion,
**Then** a progress indicator shows "Day 47 of 365" with a completion animation.

### AC-DEV-SERIES-06: Series Browser accessible from Devotion Activity
**Given** a user is in the Devotion Activity,
**When** they tap the settings/gear icon in the activity header,
**Then** the Devotional Series Browser opens showing the active series prominently at top and all available series below.

### AC-DEV-SERIES-07: Series Browser accessible from Resources tab
**Given** a user is in the Resources section of the Content Tab,
**When** they tap the "Devotional Series" row,
**Then** the Devotional Series Browser opens (same page as from the Devotion Activity).

### AC-DEV-SERIES-08: Series Browser shows free vs premium distinction
**Given** a user opens the Devotional Series Browser,
**When** the series list loads,
**Then** each series card displays: thumbnail, name, author, devotion count, tier indicator ("Free" badge or price), ownership status ("Owned" badge or lock icon), and progress if started.

### AC-DEV-SERIES-09: Series Detail About section
**Given** a user taps any series card in the Series Browser,
**When** the Series Detail page loads,
**Then** it displays: header (thumbnail, name, author, devotion count, tier/price), an About section with 2-4 paragraph description, and action buttons appropriate to ownership status.

### AC-DEV-SERIES-10: Series Detail Outline section
**Given** a user taps any series card in the Series Browser,
**When** the Series Detail page loads,
**Then** an Outline section shows all devotion titles in order (e.g., "Day 1: A New Beginning," "Day 2: Surrender," ... "Day N: [Title]").

### AC-DEV-SERIES-11: Set active series from Series Detail
**Given** a user is viewing the Series Detail page for an owned series that is not currently active,
**When** they tap "Set as Active Series,"
**Then** the selected series becomes active, the previously active series is paused, and a confirmation is shown.

### AC-DEV-SERIES-12: Purchase flow from Series Detail
**Given** a user is viewing the Series Detail page for a premium series they do not own,
**When** they tap "Unlock for $X.XX,"
**Then** the in-app purchase flow is initiated, and upon successful purchase, the series is permanently unlocked and the button changes to "Set as Active Series."

### AC-DEV-SERIES-13: Free series auto-activated for new users
**Given** a new user opens the Devotion Activity for the first time,
**When** they have no active series,
**Then** the free 30-devotion series is automatically set as active at Day 1.

### AC-DEV-SERIES-14: Series completion prompts new selection
**Given** a user completes the final devotion in their active series,
**When** the completion is saved,
**Then** the series status is set to "completed" and the user is prompted to select a new active series from the Series Browser.

### AC-DEV-SERIES-15: Outline visible for locked premium series
**Given** a user views the Series Detail page for a premium series they have not purchased,
**When** the Outline section loads,
**Then** all devotion titles are visible (not locked), but tapping an individual title shows a lock indicator and purchase CTA (the full devotion content is locked, not the titles).

### AC-DEV-SERIES-16: Series Browser filter and sort
**Given** a user opens the Devotional Series Browser,
**When** they apply filters,
**Then** they can filter by: All, Free, Premium, Category (recovery, marriage, identity, spiritual-growth, partner-healing), and Length (short 3-7, medium 10-30, long 90-365).

---

## History and Review (AC-DEV-HISTORY)

### AC-DEV-HISTORY-01: Browse completed devotions by date
**Given** a user opens My History,
**When** the history loads,
**Then** completed devotions are listed in reverse chronological order with date completed.

### AC-DEV-HISTORY-02: View past entry details
**Given** a user taps a past devotion in history,
**When** the detail view loads,
**Then** it shows: full devotion text, user's reflection response, mood tag, and date completed.

### AC-DEV-HISTORY-03: Filter history
**Given** a user is viewing their history,
**When** they apply filters,
**Then** they can filter by series, topic, author, or date range.

### AC-DEV-HISTORY-04: Search reflections by keyword
**Given** a user searches within their history,
**When** they enter a keyword,
**Then** the search matches against the user's own reflection response text.

### AC-DEV-HISTORY-05: Export devotion history as PDF
**Given** a user requests a devotion history export,
**When** the export completes,
**Then** a PDF is generated containing all completed devotions with their reflections.

---

## Favorites (AC-DEV-FAVORITE)

### AC-DEV-FAVORITE-01: Add to favorites
**Given** a user is viewing a devotion,
**When** they tap the heart/favorite icon,
**Then** the devotion is added to their Favorites list.

### AC-DEV-FAVORITE-02: Remove from favorites
**Given** a user has a devotion in favorites,
**When** they tap the heart/favorite icon again,
**Then** the devotion is removed from their Favorites list.

### AC-DEV-FAVORITE-03: Favorites accessible from library
**Given** a user has favorited devotions,
**When** they open the Devotional Library,
**Then** a horizontal scroll of favorited devotions is visible in the My Favorites section.

---

## Sharing (AC-DEV-SHARE)

### AC-DEV-SHARE-01: Share devotion without personal response
**Given** a user is viewing a devotion,
**When** they tap Share,
**Then** they can share the devotion content (title, scripture, reading, prayer) to a support network contact, clipboard, or social media -- without including the user's personal reflection.

---

## Notifications (AC-DEV-NOTIFY)

### AC-DEV-NOTIFY-01: Daily devotion reminder
**Given** a user has devotion notifications enabled,
**When** the user-configured reminder time arrives (default 7:00 AM),
**Then** a push notification is sent showing the devotion title and scripture reference.

### AC-DEV-NOTIFY-02: Notification tap opens devotion
**Given** a user receives a daily devotion notification,
**When** they tap it,
**Then** the app opens directly to that day's devotion screen.

### AC-DEV-NOTIFY-03: Missed devotion follow-up
**Given** a user has not completed today's devotion by the follow-up time (default 12:00 PM),
**When** the follow-up time arrives,
**Then** a single follow-up notification is sent: "You haven't read today's devotion yet. A few minutes with God can change your whole day."

### AC-DEV-NOTIFY-04: Streak milestone notification
**Given** a user has completed 30 consecutive days of devotions,
**When** the 30th devotion is completed,
**Then** a notification is sent: "You've completed 30 consecutive days of devotions! Your consistency is building something lasting."

### AC-DEV-NOTIFY-05: New content notification
**Given** a new devotional series becomes available,
**When** the series is published,
**Then** a notification is sent to eligible users: "A new devotional series is available: [Series Name]. Explore it now."

### AC-DEV-NOTIFY-06: All devotion notifications independently togglable
**Given** a user opens notification settings,
**When** they view devotion notification preferences,
**Then** each notification type (daily reminder, missed follow-up, streak milestone, new content) can be independently enabled/disabled.

---

## Offline Behavior (AC-DEV-OFFLINE)

### AC-DEV-OFFLINE-01: Current day plus next 7 days cached
**Given** a user is online and views a devotion,
**When** the app caches devotion content,
**Then** the current day's devotion plus the next 7 days from the active series are pre-loaded for offline access.

### AC-DEV-OFFLINE-02: Offline reflection saved locally
**Given** a user is offline and writes a reflection,
**When** they tap Save,
**Then** the reflection is saved locally via SwiftData and synced when the connection is restored.

### AC-DEV-OFFLINE-03: Offline devotion reading works
**Given** a user has cached devotions and is offline,
**When** they open the devotion screen,
**Then** the cached devotion displays fully with all content elements.

### AC-DEV-OFFLINE-04: Series Browser available offline with cached data
**Given** a user has previously loaded the Devotional Series Browser while online,
**When** they open the Series Browser while offline,
**Then** cached series metadata (names, descriptions, outlines, progress) is displayed. Purchase buttons are disabled with "Requires internet" indicator.

---

## Internationalization and Accessibility (AC-DEV-I18N)

### AC-DEV-I18N-01: English and Spanish at launch
**Given** a user's preferred language is Spanish,
**When** they view a freemium devotion,
**Then** the devotion is displayed in Spanish.

### AC-DEV-I18N-02: Scripture translation follows user preference
**Given** a user has selected ESV as their preferred Bible translation,
**When** they view a devotion,
**Then** the scripture passage is rendered in ESV.

### AC-DEV-I18N-03: Spanish Bible translations
**Given** a Spanish-language user has selected RVR1960 or NVI,
**When** they view a devotion,
**Then** the scripture passage is rendered in the selected Spanish translation.

### AC-DEV-I18N-04: Series About and Outline localized
**Given** a user's preferred language is Spanish,
**When** they view a Series Detail page,
**Then** the About description and Outline titles are displayed in Spanish (where translations are available).

---

## Integration Points (AC-DEV-INTEG)

### AC-DEV-INTEG-01: Completion logged to Tracking System
**Given** a user completes a devotion,
**When** the completion is saved,
**Then** a `DEVOTIONAL` activity is recorded in the Tracking System for consecutive-day tracking.

### AC-DEV-INTEG-02: Calendar activity dual-write
**Given** a user completes a devotion,
**When** the completion is saved,
**Then** a `CALENDAR_ACTIVITY` entry of type `DEVOTIONAL` is written for the calendar view.

### AC-DEV-INTEG-03: Analytics dashboard engagement
**Given** a user completes devotions over time,
**When** the Analytics Dashboard loads,
**Then** devotion engagement trends are visible and correlated with recovery outcomes.

### AC-DEV-INTEG-04: Morning routine step
**Given** a user has configured devotions as part of their morning routine,
**When** they complete the devotion,
**Then** it is marked as completed in the morning routine sequence.

### AC-DEV-INTEG-05: Goal auto-check
**Given** a user has a "devotion" goal set for the day/week,
**When** they complete a devotion,
**Then** the devotion goal is automatically checked off.

### AC-DEV-INTEG-06: Devotion streak widget
**Given** a user has a devotion streak,
**When** they view the main Dashboard,
**Then** the devotion streak is displayed as an optional widget.

### AC-DEV-INTEG-07: Prayer flow linkage
**Given** a user reads a devotion with a closing prayer,
**When** they complete the devotion,
**Then** they can optionally flow into a logged prayer session.

### AC-DEV-INTEG-08: Resources tab integration
**Given** the `activity.devotionals` feature flag is enabled,
**When** a user views the Resources section of the Content Tab,
**Then** a "Devotional Series" row is visible that opens the Devotional Series Browser.

---

## Edge Cases (AC-DEV-EDGE)

### AC-DEV-EDGE-01: Post-midnight pre-sleep shows current day
**Given** a user opens the app at 1:00 AM in their timezone,
**When** the devotion loads,
**Then** the devotion shown is for the current calendar day (based on user's timezone), not the previous day.

### AC-DEV-EDGE-02: App reinstall restores history
**Given** a user deletes and reinstalls the app,
**When** they log in,
**Then** devotion history, progress, and series position are restored from account sync.

### AC-DEV-EDGE-03: Multiple series purchase queuing
**Given** a user is on Day 15 of Series A and purchases Series B,
**When** they view the Series Browser,
**Then** Series B appears as available to activate; switching pauses Series A at Day 15.

### AC-DEV-EDGE-04: Premium content update by publisher
**Given** a publisher updates the content of a devotion in a series the user owns,
**When** the user reads that devotion next,
**Then** they see the updated content; previously completed days remain unaffected.

### AC-DEV-EDGE-05: Feature flag disabled
**Given** the `activity.devotionals` feature flag is disabled,
**When** a user attempts to access devotion endpoints,
**Then** the API returns 404 and the mobile UI hides the Devotion activity entry point, the Devotions section in the Content Tab, and the Devotional Series row in Resources.

### AC-DEV-EDGE-06: Series completion triggers new selection
**Given** a user completes the final devotion in their active series,
**When** the completion is saved,
**Then** the series status changes to "completed" and the user is prompted to select a new active series. If no other owned series exists, the free series is reactivated.

### AC-DEV-EDGE-07: Large series outline performance
**Given** a devotional series contains 365 devotions,
**When** a user views the Outline section of the Series Detail page,
**Then** the outline renders performantly using virtualized/lazy-loaded list with no perceptible lag.

### AC-DEV-EDGE-08: Series Browser offline with no cached data
**Given** a user has never loaded the Devotional Series Browser while online,
**When** they attempt to open the Series Browser while offline,
**Then** a helpful empty state is shown: "Connect to the internet to browse devotional series."
