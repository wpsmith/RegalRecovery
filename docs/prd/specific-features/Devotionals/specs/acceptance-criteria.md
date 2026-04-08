# Devotionals Activity -- Acceptance Criteria

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Feature Flag:** `activity.devotionals`
**Priority:** P1 (Wave 2)

---

## Notation

Each acceptance criterion has a unique ID in the format `AC-DEV-{category}-{number}`. Categories:

- **CONTENT** -- Devotional content structure and tiers
- **READ** -- Reading and display
- **REFLECT** -- Reflections and responses
- **LIBRARY** -- Library browsing, search, and filtering
- **SERIES** -- Reading plans and series progression
- **HISTORY** -- History and reflection review
- **FAVORITE** -- Favorites management
- **SHARE** -- Sharing devotionals
- **NOTIFY** -- Notifications
- **OFFLINE** -- Offline behavior
- **I18N** -- Internationalization and accessibility
- **INTEG** -- Integration points with other systems
- **EDGE** -- Edge cases

---

## Content Structure (AC-DEV-CONTENT)

### AC-DEV-CONTENT-01: Devotional includes all required elements
**Given** a devotional exists in the system,
**When** the devotional is retrieved via API,
**Then** it contains: title, scriptureReference, scriptureText, bibleTranslation, reading (300-600 words), recoveryConnection, reflectionQuestion, prayer (50-100 words), and authorAttribution (name + bio when applicable).

### AC-DEV-CONTENT-02: Freemium tier provides 30-day rotation
**Given** a user on the free tier,
**When** they access today's devotional,
**Then** the devotional is selected from the 30-day free rotation based on the user's current day index (cycling after 30).

### AC-DEV-CONTENT-03: Freemium rotation resets after completion
**Given** a free-tier user has completed all 30 devotionals in the rotation,
**When** day 31 arrives,
**Then** the rotation restarts from day 1 of the same 30-day set.

### AC-DEV-CONTENT-04: Premium series unlocked forever on purchase
**Given** a user purchases a premium devotional series,
**When** the purchase is confirmed,
**Then** the series is permanently unlocked and accessible regardless of subscription status.

### AC-DEV-CONTENT-05: Locked premium content shows purchase CTA
**Given** a user has not purchased a premium devotional series,
**When** they browse that series in the library,
**Then** devotionals are shown with a lock icon and an "Unlock" call-to-action leading to the purchase flow.

### AC-DEV-CONTENT-06: Partner/counselor devotionals supported
**Given** a counselor or partner organization publishes devotionals through the Content/Resources System,
**When** a user browses the library,
**Then** partner devotionals are visible according to their tier (freemium visible to all, premium visible to purchasers).

---

## Reading and Display (AC-DEV-READ)

### AC-DEV-READ-01: Today's devotional accessible with one tap
**Given** a user opens the Devotional Library,
**When** the library loads,
**Then** today's devotional is featured at the top with one-tap access.

### AC-DEV-READ-02: Full-screen reading view
**Given** a user opens a devotional,
**When** the devotional screen loads,
**Then** it displays: scripture passage prominently at top, reading body below, recovery connection in a callout box, reflection question with visual emphasis, and closing prayer at bottom.

### AC-DEV-READ-03: Devotional uses user's timezone for day boundary
**Given** a user's timezone is set to America/Los_Angeles,
**When** the user opens the app at 11:30 PM PST on March 28,
**Then** the devotional shown is for March 28 (current calendar day in user's timezone).

### AC-DEV-READ-04: Audio playback via TTS
**Given** a user is viewing a devotional,
**When** they tap the audio button,
**Then** text-to-speech plays the full devotional including scripture, reading, and prayer.

### AC-DEV-READ-05: Dynamic font sizing support
**Given** a user has configured a larger font size in their device settings,
**When** they view a devotional,
**Then** all text respects the user's dynamic type settings.

---

## Reflections and Responses (AC-DEV-REFLECT)

### AC-DEV-REFLECT-01: User can write a reflection
**Given** a user has read a devotional,
**When** they enter text in the response area and tap Save,
**Then** the reflection is saved and associated with that devotional completion.

### AC-DEV-REFLECT-02: Reflection supports unlimited text
**Given** a user is writing a reflection,
**When** they type text of any length,
**Then** the input accepts unlimited characters without truncation.

### AC-DEV-REFLECT-03: Voice-to-text available for reflection
**Given** a user is in the reflection input area,
**When** they activate voice-to-text,
**Then** spoken words are transcribed into the reflection text field.

### AC-DEV-REFLECT-04: Optional mood tag on reflection
**Given** a user has completed a devotional reading,
**When** they are in the response area,
**Then** they can optionally select a mood tag ("How are you feeling after this reading?") via emoji or word selection.

### AC-DEV-REFLECT-05: Devotional completion without reflection
**Given** a user has read a devotional but does not write a reflection,
**When** they navigate away or tap Next,
**Then** the devotional is still marked as completed, and the reflection prompt remains available from history.

---

## Library (AC-DEV-LIBRARY)

### AC-DEV-LIBRARY-01: Library shows Today, Favorites, History, Series, Topic, Author sections
**Given** a user opens the Devotional Library,
**When** the library loads,
**Then** it displays sections for: Today's Devotional, My Favorites (horizontal scroll), My History (reverse chronological), Browse by Series, Browse by Topic, Browse by Author.

### AC-DEV-LIBRARY-02: Browse by topic
**Given** a user navigates to Browse by Topic,
**When** they select a topic (shame, temptation, identity, marriage, forgiveness, surrender, gratitude, restoration, fear, hope),
**Then** only devotionals tagged with that topic are returned.

### AC-DEV-LIBRARY-03: Browse by author
**Given** a user navigates to Browse by Author,
**When** they select an author,
**Then** only devotionals by that author are returned.

### AC-DEV-LIBRARY-04: Browse by series with progress
**Given** a premium user navigates to Browse by Series,
**When** the series list loads,
**Then** each series shows its name, description, total devotional count, and the user's progress indicator (e.g., "Day 47 of 365").

### AC-DEV-LIBRARY-05: Full-text search
**Given** a user enters a search query in the library,
**When** results are returned,
**Then** the search matches against devotional titles, scripture references, and body text.

---

## Series and Reading Plans (AC-DEV-SERIES)

### AC-DEV-SERIES-01: Premium series sequential progression
**Given** a user has an active premium series,
**When** they complete Day N,
**Then** Day N+1 becomes available, and the progress indicator updates.

### AC-DEV-SERIES-02: Missed days do not auto-advance
**Given** a user is on Day 15 of a 365-day series and skips a calendar day,
**When** they open the app the next day,
**Then** the devotional shown is still Day 15 (no auto-advance); user can manually skip or catch up.

### AC-DEV-SERIES-03: One active series at a time
**Given** a user has an active series (Series A at Day 15),
**When** they switch to a different series (Series B),
**Then** Series A is paused at Day 15, Series B starts (or resumes) where the user left off.

### AC-DEV-SERIES-04: Paused series resumes correctly
**Given** a user paused Series A at Day 15 and switched to Series B,
**When** they switch back to Series A,
**Then** Series A resumes at Day 15.

### AC-DEV-SERIES-05: Series progress indicator displayed
**Given** a user is on Day 47 of a 365-day series,
**When** they complete the devotional,
**Then** a progress indicator shows "Day 47 of 365" with a completion animation.

---

## History and Review (AC-DEV-HISTORY)

### AC-DEV-HISTORY-01: Browse completed devotionals by date
**Given** a user opens My History,
**When** the history loads,
**Then** completed devotionals are listed in reverse chronological order with date completed.

### AC-DEV-HISTORY-02: View past entry details
**Given** a user taps a past devotional in history,
**When** the detail view loads,
**Then** it shows: full devotional text, user's reflection response, mood tag, and date completed.

### AC-DEV-HISTORY-03: Filter history
**Given** a user is viewing their history,
**When** they apply filters,
**Then** they can filter by series, topic, author, or date range.

### AC-DEV-HISTORY-04: Search reflections by keyword
**Given** a user searches within their history,
**When** they enter a keyword,
**Then** the search matches against the user's own reflection response text.

### AC-DEV-HISTORY-05: Export devotional history as PDF
**Given** a user requests a devotional history export,
**When** the export completes,
**Then** a PDF is generated containing all completed devotionals with their reflections.

---

## Favorites (AC-DEV-FAVORITE)

### AC-DEV-FAVORITE-01: Add to favorites
**Given** a user is viewing a devotional,
**When** they tap the heart/favorite icon,
**Then** the devotional is added to their Favorites list.

### AC-DEV-FAVORITE-02: Remove from favorites
**Given** a user has a devotional in favorites,
**When** they tap the heart/favorite icon again,
**Then** the devotional is removed from their Favorites list.

### AC-DEV-FAVORITE-03: Favorites accessible from library
**Given** a user has favorited devotionals,
**When** they open the Devotional Library,
**Then** a horizontal scroll of favorited devotionals is visible in the My Favorites section.

---

## Sharing (AC-DEV-SHARE)

### AC-DEV-SHARE-01: Share devotional without personal response
**Given** a user is viewing a devotional,
**When** they tap Share,
**Then** they can share the devotional content (title, scripture, reading, prayer) to a support network contact, clipboard, or social media -- without including the user's personal reflection.

---

## Notifications (AC-DEV-NOTIFY)

### AC-DEV-NOTIFY-01: Daily devotional reminder
**Given** a user has devotional notifications enabled,
**When** the user-configured reminder time arrives (default 7:00 AM),
**Then** a push notification is sent showing the devotional title and scripture reference.

### AC-DEV-NOTIFY-02: Notification tap opens devotional
**Given** a user receives a daily devotional notification,
**When** they tap it,
**Then** the app opens directly to that day's devotional screen.

### AC-DEV-NOTIFY-03: Missed devotional follow-up
**Given** a user has not completed today's devotional by the follow-up time (default 12:00 PM),
**When** the follow-up time arrives,
**Then** a single follow-up notification is sent: "You haven't read today's devotional yet. A few minutes with God can change your whole day."

### AC-DEV-NOTIFY-04: Streak milestone notification
**Given** a user has completed 30 consecutive days of devotionals,
**When** the 30th devotional is completed,
**Then** a notification is sent: "You've completed 30 consecutive days of devotionals! Your consistency is building something lasting."

### AC-DEV-NOTIFY-05: New content notification
**Given** a new devotional series becomes available,
**When** the series is published,
**Then** a notification is sent to eligible users: "A new devotional series is available: [Series Name]. Explore it now."

### AC-DEV-NOTIFY-06: All devotional notifications independently togglable
**Given** a user opens notification settings,
**When** they view devotional notification preferences,
**Then** each notification type (daily reminder, missed follow-up, streak milestone, new content) can be independently enabled/disabled.

---

## Offline Behavior (AC-DEV-OFFLINE)

### AC-DEV-OFFLINE-01: Current day plus next 7 days cached
**Given** a user is online and views a devotional,
**When** the app caches devotional content,
**Then** the current day's devotional plus the next 7 days are pre-loaded for offline access.

### AC-DEV-OFFLINE-02: Offline reflection saved locally
**Given** a user is offline and writes a reflection,
**When** they tap Save,
**Then** the reflection is saved locally and synced when the connection is restored.

### AC-DEV-OFFLINE-03: Offline devotional reading works
**Given** a user has cached devotionals and is offline,
**When** they open the devotional screen,
**Then** the cached devotional displays fully with all content elements.

---

## Internationalization and Accessibility (AC-DEV-I18N)

### AC-DEV-I18N-01: English and Spanish at launch
**Given** a user's preferred language is Spanish,
**When** they view a freemium devotional,
**Then** the devotional is displayed in Spanish.

### AC-DEV-I18N-02: Scripture translation follows user preference
**Given** a user has selected ESV as their preferred Bible translation,
**When** they view a devotional,
**Then** the scripture passage is rendered in ESV.

### AC-DEV-I18N-03: Spanish Bible translations
**Given** a Spanish-language user has selected RVR1960 or NVI,
**When** they view a devotional,
**Then** the scripture passage is rendered in the selected Spanish translation.

---

## Integration Points (AC-DEV-INTEG)

### AC-DEV-INTEG-01: Completion logged to Tracking System
**Given** a user completes a devotional,
**When** the completion is saved,
**Then** a `DEVOTIONAL` activity is recorded in the Tracking System for consecutive-day tracking.

### AC-DEV-INTEG-02: Calendar activity dual-write
**Given** a user completes a devotional,
**When** the completion is saved,
**Then** a `CALENDAR_ACTIVITY` entry of type `DEVOTIONAL` is written for the calendar view.

### AC-DEV-INTEG-03: Analytics dashboard engagement
**Given** a user completes devotionals over time,
**When** the Analytics Dashboard loads,
**Then** devotional engagement trends are visible and correlated with recovery outcomes.

### AC-DEV-INTEG-04: Morning routine step
**Given** a user has configured devotionals as part of their morning routine,
**When** they complete the devotional,
**Then** it is marked as completed in the morning routine sequence.

### AC-DEV-INTEG-05: Goal auto-check
**Given** a user has a "devotional" goal set for the day/week,
**When** they complete a devotional,
**Then** the devotional goal is automatically checked off.

### AC-DEV-INTEG-06: Devotional streak widget
**Given** a user has a devotional streak,
**When** they view the main Dashboard,
**Then** the devotional streak is displayed as an optional widget.

### AC-DEV-INTEG-07: Prayer flow linkage
**Given** a user reads a devotional with a closing prayer,
**When** they complete the devotional,
**Then** they can optionally flow into a logged prayer session.

---

## Edge Cases (AC-DEV-EDGE)

### AC-DEV-EDGE-01: Post-midnight pre-sleep shows current day
**Given** a user opens the app at 1:00 AM in their timezone,
**When** the devotional loads,
**Then** the devotional shown is for the current calendar day (based on user's timezone), not the previous day.

### AC-DEV-EDGE-02: App reinstall restores history
**Given** a user deletes and reinstalls the app,
**When** they log in,
**Then** devotional history, progress, and series position are restored from account sync.

### AC-DEV-EDGE-03: Multiple series purchase queuing
**Given** a user is on Day 15 of Series A and purchases Series B,
**When** they view their series list,
**Then** Series B appears as available to activate; switching pauses Series A at Day 15.

### AC-DEV-EDGE-04: Premium content update by publisher
**Given** a publisher updates the content of a devotional in a series the user owns,
**When** the user reads that devotional next,
**Then** they see the updated content; previously completed days remain unaffected.

### AC-DEV-EDGE-05: Feature flag disabled
**Given** the `activity.devotionals` feature flag is disabled,
**When** a user attempts to access devotional endpoints,
**Then** the API returns 404 and the mobile UI hides the devotional entry point.
