# Activity: Prayer

**Priority:** P1

**Description:** Log prayer sessions as a standalone recovery activity and access a curated library of prayers for personal and guided use.

---

## User Stories

- As a **recovering user**, I want to log my prayer sessions, so that I can track my consistency in spending time with God as a core part of my recovery
- As a **recovering user**, I want access to a library of curated prayers, so that I have words to pray when I don't know what to say
- As a **recovering user**, I want to browse prayers by topic (temptation, shame, marriage, gratitude), so that I can find a prayer that matches what I'm going through right now
- As a **recovering user**, I want to read step-specific prayers as I work through the 12 steps, so that each step is grounded in conversation with God
- As a **recovering user**, I want to write and save my own personal prayers, so that I can return to them and see how my prayer life has grown over time
- As a **recovering user**, I want to favorite prayers that resonate with me, so that I can access them quickly during moments of struggle or worship
- As a **recovering user**, I want a full-screen reading mode with optional audio playback, so that I can pray along without distractions
- As a **recovering user**, I want to see my prayer streak, so that I'm motivated to maintain a daily rhythm of talking to God
- As a **recovering user**, I want to log different types of prayer (personal, guided, group, scripture-based), so that my prayer life is reflected in its full variety
- As a **spouse**, I want to know that my partner is praying consistently (with permission), so that I can see spiritual effort even when other parts of recovery feel uncertain
- As a **recovering user**, I want prayer to feel like a living conversation with God — not just another checkbox — so that it deepens my relationship with Him rather than becoming routine

---

## Prayer Session Logging

### Manual Entry

- **Date and time** (default: now, editable for backdating)

- **Prayer type** (required) — select one:
  - Personal Prayer — private, unstructured time with God
  - Guided Prayer — praying along with a prayer from the library
  - Group Prayer — prayer with others (meeting, church, sponsor, accountability partner)
  - Scripture-Based Prayer — praying scripture directly (e.g., Psalms, prayers of Paul)
  - Intercessory Prayer — praying for someone else (spouse, children, sponsee, friend)
  - Listening Prayer — silent, contemplative time focused on hearing from God

- **Duration** (optional) — minutes (number input or quick-select: 5, 10, 15, 20, 30, 60)
  - Not required — some prayer moments are brief and spontaneous; logging the fact that prayer happened matters more than the length

- **Notes** (optional) — free-text, 1000 char max, voice-to-text available
  - Suggested prompts (shown as placeholder text, rotating):
    - "What did you pray about?"
    - "Did you sense God speaking to you? What did you hear?"
    - "What are you laying at His feet today?"
    - "How do you feel after spending time with God?"

- **Linked prayer** (optional) — if the user prayed a prayer from the library, they can link the session to that specific prayer for reference

- **Mood before/after** (optional) — simple emoji or 1-5 scale for each
  - Enables mood-prayer correlation insights over time

### Quick Log

- One-tap logging from Dashboard widget, Quick Action Shortcut, or notification
- Quick log records: prayer type (defaults to Personal Prayer), timestamp
- User can expand the quick log entry to add duration, notes, mood, and linked prayer afterward

---

## Prayers Content Library

### Structure

Each prayer in the library includes:
- **Title** — brief, descriptive name (e.g., "Prayer for Strength Against Temptation")
- **Body** — full prayer text, written in first person where appropriate
- **Topic tags** — one or more topics for browsing and search
- **Source attribution** — author name, book/resource title, or "Traditional" / "App Original"
- **Scripture connection** (optional) — associated verse(s) displayed alongside the prayer

### Freemium Prayers

Available to all users at no cost:

- **Step Prayers** — one prayer for each of the 12 steps, written to align with the spiritual intent of each step
- **Serenity Prayer** — full version (not just the commonly quoted opening)
- **Lord's Prayer** — with optional recovery-focused reflection notes
- **Recovery-Focused Prayers** — prayers for sobriety, freedom from shame, courage to be honest, surrender, healing from past harm
- **Daily Morning Prayer** — a prayer to start the day with intention and surrender
- **Daily Evening Prayer** — a prayer to close the day with gratitude and reflection

### Premium Prayer Packs (unlocked forever when purchased)

Each pack is a themed collection of prayers:

- **Temptation & Urges** — prayers for moments of acute temptation, urge surfing, fleeing lust, spiritual warfare
- **Shame & Identity** — prayers for freedom from shame, receiving God's love, reclaiming identity in Christ
- **Marriage Restoration** — prayers for rebuilding trust, healing betrayal wounds, loving a spouse well, reconciliation
- **Gratitude & Praise** — prayers of thanksgiving, worship, awe, and celebration of God's faithfulness
- **Forgiveness** — prayers for forgiving others, forgiving self, receiving God's forgiveness, releasing resentment
- **Fear & Anxiety** — prayers for peace, courage, trust, surrender of control
- **Grief & Loss** — prayers for processing loss (relationships, innocence, time, identity)
- **Prayers from Christian Recovery Authors** — curated prayers from partnered authors and organizations (revenue share agreements)
- **Partner Prayer Packs** — prayers from counselor and partner organization content

### Library Browsing

- **Today's Prayer** — featured prayer at top (rotates daily, drawn from user's owned packs)
- **My Favorites** — horizontal scroll of favorited prayers
- **My Personal Prayers** — user-written prayers (see below)
- **Browse by Topic** — filter by topic tags
- **Browse by Pack** — view all prayers within a specific pack
- **Browse by Step** — quick access to step prayers (1-12)
- **Search** — full-text search across prayer titles and body text
- **Locked content** — premium prayers shown with lock icon and "Unlock" CTA leading to purchase flow

---

## Full-Screen Prayer Mode

When the user selects "Pray this" on any library prayer or personal prayer:

- **Full-screen display:** Clean, distraction-free reading view
  - Large serif typography (22pt+), generous line spacing
  - Soft, calming background (subtle gradient or muted texture — user preference in Settings)
  - Scripture connection displayed at top if available
  - Prayer body centered on screen

- **Audio playback:** Text-to-speech option for the full prayer
  - Play/pause controls
  - Adjustable reading speed
  - Useful for eyes-closed prayer, commuting, or accessibility

- **Timer (optional):** If the user wants to continue praying silently after the guided prayer, a quiet timer can run in the background
  - Configurable duration or open-ended with manual stop
  - Gentle chime at completion

- **Post-prayer prompt:** After closing full-screen mode:
  - "Would you like to log this as a prayer session?" (pre-fills prayer type as Guided Prayer, links the prayer)
  - "How do you feel?" (mood tag)

---

## Personal Prayers

Users can write, save, and manage their own prayers:

- **Create:** Tap "Write a Prayer" from the library or prayer entry screen
  - Title (required, 100 char max)
  - Body (required, unlimited length)
  - Topic tags (optional — same tag list as library prayers)
  - Associated scripture (optional — Bible API lookup for verse reference)

- **Manage:** Personal prayers stored in "My Personal Prayers" section of the library
  - Edit, delete, reorder at any time
  - Favorite personal prayers for quick access

- **Share (optional):**
  - Share with support network contacts via in-app messaging
  - Share to clipboard or as styled graphic for external messaging
  - Future consideration: submit personal prayers for community review and potential inclusion in the shared library

---

## Prayer History

- Browse all logged prayer sessions in reverse chronological order
- Each entry shows: prayer type icon, type name, date/time, duration (if logged), linked prayer title (if any), mood before/after (if logged)
- Tap any entry to view full details including notes
- Filter by prayer type, date range, linked prayer, mood
- Search notes by keyword
- Export history as PDF for personal records or spiritual direction conversations

---

## Trends & Insights

- **Streak tracking:**
  - Current consecutive days with at least one prayer session logged
  - Longest prayer streak ever
  - Total days with prayer sessions (lifetime)

- **Frequency & duration:**
  - Sessions per week (line graph, 7-day / 30-day / 90-day views)
  - Average duration per session over time
  - Prayer type distribution (pie chart — personal vs. guided vs. group vs. scripture-based, etc.)

- **Time-of-day patterns:**
  - When does the user pray most often? (morning, midday, evening, late night)
  - Trend shifts over time

- **Correlation insights:**
  - "On days you pray, your check-in score averages X points higher"
  - "Your urge frequency is X% lower on days with prayer sessions"
  - "You haven't logged a prayer session in X days — consider reconnecting"
  - Mood before/after trends: "Your post-prayer mood averages X points higher than pre-prayer"

- **Spiritual dynamic balance:**
  - Prayer data contributes to the spiritual dynamic in Weekly/Daily Goals
  - Combined with devotional and scripture engagement data for a holistic spiritual health view

---

## Dashboard Widget

- Compact card on main Dashboard showing:
  - Today's prayer status: logged or not
  - Current prayer streak
  - Today's featured prayer title (tap to open in full-screen mode)
- Tap to open Prayer screen
- Quick log button directly on widget

---

## Integration Points

- Feeds into Tracking System (consecutive days with at least one prayer session logged)
- Feeds into Analytics Dashboard (prayer frequency, type distribution, correlation with recovery outcomes)
- Feeds into Weekly/Daily Goals — completing a prayer session auto-checks a spiritual dynamic goal if one is set
- Linked from Devotionals — devotional closing prayer can flow into a logged prayer session
- Linked from morning commitment flow — morning prayer can be logged directly after commitment
- Linked from Urge Logging emergency tools — "Panic Prayer" opens a random prayer from Temptation & Urges pack in full-screen mode and logs the session
- Linked from FASTER Scale — prayer suggested as intervention at every stage
- Content delivered through Content/Resources System — prayer packs follow the same freemium/premium model
- Visible to support network based on community permissions

---

## Notifications

- Daily prayer reminder at user-configured time (optional, default: OFF)
  - Suggested pairing: after morning commitment or devotional
- Missed prayer nudge: "It's been X days since you last prayed. Even a minute with God can change everything." (optional, sent after user-configured inactivity threshold, default: 3 days)
- Streak milestone: "X consecutive days of prayer. You're building something beautiful with God."
- New content: "A new prayer pack is available: [Pack Name]. Explore it now."
- All prayer notifications independently togglable in Settings

---

## Accessibility & Localization

- Text-to-speech (TTS) for all library and personal prayers — accessible for visually impaired users and useful for eyes-closed prayer
- Dynamic font sizing support in full-screen prayer mode
- Scripture translations follow user's selected Bible translation in Settings (NIV, ESV, NLT, KJV for English; RVR1960, NVI for Spanish)
- All freemium prayers available in English and Spanish at launch
- Premium prayer pack translation follows Content Localization Strategy outlined in the PRD

---

## Tone & Messaging

- Prayer framed as relationship — conversation with a loving God — not religious obligation
- Helper text on first use: "Prayer is the heartbeat of recovery. It's where you bring everything — your fears, your failures, your gratitude, your hope — to the One who already knows and still loves you. There's no wrong way to start."
- Post-session messages (rotating):
  - "Time with God is never wasted. Thank you for showing up."
  - "He heard you. He sees you. He's with you."
  - "Prayer doesn't change your circumstances first — it changes you first. And that changes everything."
- No performance pressure — a 30-second prayer and a 30-minute prayer are celebrated equally

---

## Edge Cases

- User logs a prayer session with no duration → Fully valid; duration is optional by design
- User prays a library prayer but doesn't log it → No data recorded; prayer mode can prompt logging but never forces it
- User logs multiple prayer sessions in one day → Each logged independently; all count as one day for streak purposes
- User wants to edit prayer notes after saving → Editable for 24 hours after creation; after that, read-only
- User prays offline → Full logging and library browsing available offline (library prayers cached, including current pack); synced when connection restored
- User's prayer streak breaks → Compassionate re-engagement: "Every conversation with God is a fresh start. Welcome back."
- User favorites a premium prayer then cancels subscription → Favorited prayers remain accessible as long as the pack was purchased (unlocked forever model — no subscription loss)
