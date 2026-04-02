# Activity: Devotionals

**Priority:** P1

**Description:** Daily devotional reading and reflection integrated into the recovery journey.

---

## User Stories

- As a **recovering user**, I want to read a daily devotional that connects scripture to my recovery, so that my faith and sobriety work are woven together rather than separate
- As a **recovering user**, I want to receive a devotional notification each day, so that I'm prompted to spend time with God even on busy or difficult days
- As a **recovering user**, I want to write a reflection or response after reading a devotional, so that I can process what God is speaking to me and apply it to my recovery
- As a **recovering user**, I want to browse past devotionals I've read and my responses, so that I can revisit insights and see how my spiritual growth has progressed
- As a **recovering user**, I want access to devotionals that specifically address addiction, shame, temptation, and restoration, so that the content feels relevant to what I'm actually going through
- As a **recovering user**, I want to favorite devotionals that resonate deeply with me, so that I can return to them during moments of struggle or doubt
- As a **recovering user**, I want to share a devotional with my sponsor, spouse, or accountability partner, so that we can discuss it together and deepen our connection
- As a **recovering user**, I want access to premium 365-day devotional series, so that I have a sustained, structured year-long spiritual growth plan
- As a **spouse**, I want access to devotionals written for betrayed partners, so that I can process my own pain through a faith-based lens
- As a **recovering user**, I want devotionals available in both English and Spanish, so that I can engage with God in the language closest to my heart

---

## Devotional Content Tiers

### Freemium — Basic Devotionals
- 30-day rotation of daily devotionals included at no cost
- Topics cover core recovery themes: surrender, identity in Christ, freedom from shame, trusting God's plan, daily strength, forgiveness, hope
- Each devotional is self-contained — users can start on any day
- Rotation resets after 30 days; same devotionals cycle until user upgrades or new free content is added

### Premium — Extended Devotionals (unlocked forever when purchased)
- 365-day devotional series by prominent Christian recovery authors
- Structured as a year-long journey with progressive depth and themes
- Multiple series available (each purchased independently):
  - Recovery-focused series (addiction, temptation, relapse prevention, restoration)
  - Marriage and trust rebuilding series
  - Identity and shame series
  - General spiritual growth series
- New series added over time through content partnerships

### Partner/Counselor Devotionals
- Counselors and partner organizations can publish devotionals through the Content/Resources System
- Freemium partner devotionals available to all users
- Premium partner devotionals available to users who purchase the relevant pack

---

## Devotional Structure

Each devotional includes the following elements:

- **Title** — Brief, evocative title for the day's reading
- **Scripture passage** — Primary verse(s) displayed in full, with translation noted (NIV default; RVR1960/NVI for Spanish)
- **Reading** — 300-600 word reflection connecting scripture to recovery (written in warm, pastoral tone)
- **Recovery connection** — 1-2 sentences explicitly linking the devotional theme to a practical recovery principle or behavior
- **Reflection question** — A single thought-provoking question for the user to sit with (e.g., "Where in your recovery are you trying to control what only God can do?")
- **Prayer** — A short closing prayer (50-100 words) the user can read or pray aloud
- **Author attribution** — Name and brief bio of the devotional author (when applicable)

---

## Daily Devotional Flow

1. **Notification** — Push notification at user-configured time (default: 7:00 AM)
   - Notification preview shows devotional title and scripture reference
   - Tap opens directly to the devotional screen

2. **Devotional screen:**
   - Full-screen reading view with clean typography (serif font, 20pt+, generous line spacing)
   - Scripture passage displayed prominently at top
   - Reading body below
   - Recovery connection highlighted in a subtle callout box
   - Reflection question displayed with visual emphasis
   - Closing prayer at bottom

3. **Response area** (below devotional):
   - Reflection question repeated as prompt
   - Free-text input (unlimited length, voice-to-text available)
   - Optional mood tag: "How are you feeling after this reading?" (emoji or word selection)
   - Save button — response saved to devotional history

4. **Post-completion actions:**
   - Favorite (heart icon) — saves to Favorites list
   - Share — send devotional (without personal response) to support network contact, clipboard, or social media graphic
   - Audio — text-to-speech playback of the full devotional including scripture and prayer
   - Next — browse to the next devotional in the series (premium) or a random devotional (freemium)

5. **Completion confirmation:**
   - Subtle checkmark animation
   - "Devotional completed" logged to Tracking System
   - If part of a 365-day series: progress indicator ("Day 47 of 365")

---

## Devotional Library

- **Today's Devotional** — featured at top, one-tap access
- **My Favorites** — horizontal scroll of favorited devotionals
- **My History** — reverse chronological list of completed devotionals with responses
- **Browse by Series** — for premium users, view all available series with progress indicators
- **Browse by Topic** — filter devotionals by theme: shame, temptation, identity, marriage, forgiveness, surrender, gratitude, restoration, fear, hope
- **Browse by Author** — filter by devotional author
- **Search** — full-text search across devotional titles, scripture references, and body text
- **Locked content** — premium devotionals shown with lock icon and "Unlock" CTA leading to purchase flow

---

## Reading Plans

- **Freemium:** 30-day rotation (auto-assigned, restarts after completion)
- **Premium series:** User selects a series and progresses sequentially (Day 1, Day 2, etc.)
  - Missed days: devotional waits for user — no auto-advance; user can manually skip or catch up
  - Multiple series: user can have one active series at a time; switching pauses the current series and resumes where they left off when they return
- **Custom plan (future consideration):** User selects specific devotionals to create a personal reading plan

---

## History & Reflection Review

- Browse all completed devotionals by date
- Tap any past entry to see: full devotional text, user's reflection response, mood tag, date completed
- Filter by series, topic, author, or date range
- Search reflections by keyword (searches user's own response text)
- Export devotional history with reflections as PDF for personal records or therapy sessions

---

## Integration Points

- Feeds into Tracking System (consecutive days of devotional completion)
- Feeds into Analytics Dashboard (devotional engagement trends, correlation with recovery outcomes)
- Available as a step in the morning routine (after morning commitment and affirmation)
- Linked from Weekly/Daily Goals — completing a devotional auto-checks a "devotional" goal if one is set
- Linked from Prayer activity — devotional prayer can flow into a logged prayer session
- Content delivered through Content/Resources System — devotional packs follow the same freemium/premium model
- Devotional streak displayed as optional widget on main Dashboard

---

## Notifications

- Daily devotional reminder at user-configured time (default: 7:00 AM)
- Missed devotional follow-up: "You haven't read today's devotional yet. A few minutes with God can change your whole day." (sent once, configurable time, default: 12:00 PM)
- Streak milestone: "You've completed 30 consecutive days of devotionals! Your consistency is building something lasting."
- New content: "A new devotional series is available: [Series Name]. Explore it now."
- All devotional notifications independently togglable in Settings

---

## Accessibility & Localization

- Text-to-speech (TTS) for full devotional playback — accessible to visually impaired users and useful for commuters
- Dynamic font sizing support
- Scripture translations: NIV (English default), ESV, NLT, KJV selectable in Settings; RVR1960, NVI for Spanish
- All freemium devotionals available in English and Spanish at launch
- Premium devotional translation follows Content Localization Strategy outlined in the PRD

---

## Edge Cases

- User opens app after midnight but before sleeping → Devotional shown is for the current calendar day (based on user's time zone)
- User completes devotional but doesn't write a reflection → Still counts as completed; reflection prompt available later from history
- User is on Day 15 of a 365-day series and purchases a second series → Second series is queued; user chooses when to switch or can only have one active at a time
- User deletes and reinstalls app → Devotional history and progress restored from account sync
- Premium series content updated by publisher → User sees updated content on next read; completed days unaffected
- Offline → Devotionals cached for offline reading (current day + next 7 days pre-loaded); reflections saved locally and synced when connection restored
