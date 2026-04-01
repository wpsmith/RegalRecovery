# iOS Dummy App — Design Specification

**Date:** 2026-03-31
**Status:** Approved
**Location:** `./ios/`

---

## Overview

A dummy iOS app for Regal Recovery that showcases the P0 feature set with prepopulated data. This is purely a UI implementation — no backend, no persistence, no networking. All data is hardcoded to represent Alex, a user 270 days into recovery.

## Decisions

| Aspect | Decision |
|--------|----------|
| Scope | P0 features only |
| Persona | Alex, 270 days sober, active sponsor, full usage history |
| Visual style | Warm/branded — custom color palette with native iOS patterns |
| Navigation | 5 tabs + always-visible emergency FAB |
| Theme | Light + Dark with system toggle |
| Architecture | Single Xcode project, zero dependencies, hardcoded mock data |

---

## Project Structure

```
ios/RegalRecovery/
  RegalRecoveryApp.swift              # App entry, TabView + emergency FAB overlay
  Assets.xcassets/                    # Color sets (light/dark), app icon, images
  Theme/
    Color+RR.swift                    # Semantic color extensions from Asset Catalog
    Typography.swift                  # Font scale (largeTitle through caption)
    Components.swift                  # Reusable: RRCard, RRBadge, RRButton, RRSlider
  Models/
    MockData.swift                    # All hardcoded data for Alex (270 days)
    Types.swift                       # Structs and enums: Activity, Streak, CheckIn, etc.
  Views/
    Onboarding/
      OnboardingFlow.swift            # 4-step PageTabView
      WelcomeView.swift
      AccountSetupView.swift
      RecoverySetupView.swift
      PermissionsView.swift
    Home/
      HomeView.swift                  # Dashboard tab root
      StreakHeroCard.swift             # 270-day streak display
      QuickActionsRow.swift           # Horizontal pill buttons
      RecentActivityFeed.swift        # Last 5 logged items
      MilestoneBadgesRow.swift        # Earned badge horizontal scroll
      CommitmentsCard.swift           # Morning/evening commitment status
    Activities/
      ActivitiesListView.swift        # Categorized activity list (tab root)
      ActivityDetailView.swift        # Generic history + new entry template
      SobrietyCommitmentView.swift    # Morning 6-question + evening 4-question
      RecoveryCheckInView.swift       # 0-100 scored check-in with sparkline
      JournalView.swift               # Jotting, free-form, prompted, structured
      EmotionalJournalView.swift      # Feelings Wheel, intensity, insights, map
      TimeJournalView.swift           # Hour-by-hour timeline, needs tags
      FASTERScaleView.swift           # 6-stage interactive assessment
      PostMortemView.swift            # 6-section guided walkthrough
      UrgeLogView.swift               # 4-step quick capture
      MoodRatingView.swift            # 1-10 with emoji
      GratitudeListView.swift         # 3-item daily list
      PrayerLogView.swift             # Duration + type
      ExerciseLogView.swift           # Duration + activity type
      PhoneCallLogView.swift          # Contact, duration
      MeetingsAttendedView.swift      # Quick-log with saved meetings
      SpouseCheckInPrepView.swift     # FANOS/FITNAP tabbed flow
      StepWorkView.swift              # Step 8 in progress, 12 steps overview
      WeeklyGoalsView.swift           # 5 dynamics, completion tracking
      AffirmationLogView.swift        # Activity log of viewed affirmations
    Tools/
      ToolsView.swift                 # Grid/list of tools (tab root)
      FASTERScaleToolView.swift       # Full interactive assessment + history chart
      ThreeCirclesView.swift          # Concentric circles diagram
      MeetingFinderView.swift         # Map + list with filters
      PanicButtonView.swift           # Camera + overlays + breathing
    Content/
      ContentView.swift               # Tab root with sections
      AffirmationsView.swift          # Packs carousel + today's card + favorites
      AffirmationDeckView.swift       # Swipeable card deck
      DevotionalView.swift            # 30-day devotional, Day 24
      PrayersView.swift               # Curated prayer reading view
      ResourcesView.swift             # Crisis hotlines, SA explainer, glossary
    Settings/
      SettingsView.swift              # Tab root, grouped list
      ProfileEditView.swift           # Name, email, birth year, gender, etc.
      AddictionManagementView.swift   # Addiction type, sobriety date
      SupportNetworkView.swift        # Linked contacts with roles
      NotificationSettingsView.swift  # Toggle + time pickers
      AppearanceSettingsView.swift    # Light/Dark/System picker
      PrivacySettingsView.swift       # Permissions matrix, export, delete
      AboutView.swift                 # Version, glossary, licenses
    Emergency/
      EmergencyOverlayView.swift      # Full-screen crisis tools
      BreathingExerciseView.swift     # 4-7-8 animated circle
      EmergencyFABButton.swift        # The floating button component
```

---

## Color Palette

All colors defined as named Color Sets in `Assets.xcassets` with light/dark variants.

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `rrPrimary` | `#1B6B6D` (deep teal) | `#4ECDC4` (bright teal) | Headers, active tabs, primary buttons |
| `rrSecondary` | `#E8A838` (warm amber) | `#F0C060` (light amber) | Highlights, badges, streak accent |
| `rrBackground` | `#FAF8F5` (warm off-white) | `#121212` (true dark) | Screen backgrounds |
| `rrSurface` | `#FFFFFF` | `#1E1E1E` | Cards, sheets, list rows |
| `rrDestructive` | `#C25B56` (muted rose) | `#C25B56` | Relapse indicators, emergency FAB |
| `rrSuccess` | `#6B9F71` (sage green) | `#6B9F71` | Sobriety, completion, positive trends |
| `rrText` | `#2D2D2D` | `#E8E8E8` | Primary text |
| `rrTextSecondary` | `#6B6B6B` | `#A0A0A0` | Secondary/caption text |

---

## Navigation

### Tab Bar (5 tabs)

| Tab | Icon (SF Symbol) | Root View |
|-----|-------------------|-----------|
| Home | `house.fill` | HomeView |
| Activities | `list.bullet.clipboard.fill` | ActivitiesListView |
| Tools | `wrench.and.screwdriver.fill` | ToolsView |
| Content | `book.fill` | ContentView |
| Settings | `gearshape.fill` | SettingsView |

### Emergency FAB

- Red circle (`rrDestructive`) with `exclamationmark.shield.fill` icon
- Positioned bottom-right, 16pt above tab bar, 16pt from trailing edge
- Always visible on every tab via ZStack overlay in RegalRecoveryApp.swift
- Tap presents EmergencyOverlayView as `.fullScreenCover`
- Gentle pulse animation when idle (subtle scale 1.0 -> 1.05 -> 1.0, 2s loop)

### Emergency Overlay Contents

1. **Log Urge** — 4-step flow: intensity slider (1-10), addiction selector, trigger chips, optional notes
2. **Panic Button** — front camera feed with translucent overlay showing streak count, motivations, family photo placeholder
3. **Call Sponsor** — "James" card with tap-to-call appearance
4. **Breathing Exercise** — 4-7-8 animated expanding/contracting circle with phase labels (Inhale/Hold/Exhale)
5. **Crisis Hotline** — SA helpline (866-424-8777) card
- Header: "I'm struggling right now"
- Dismiss: X button top-right or swipe down

---

## Onboarding Flow

4-screen PageTabView, shown on first launch. "Skip to Demo" button on every screen loads Alex's data directly.

1. **Welcome** — App name "Regal Recovery", tagline "Your recovery companion", placeholder illustration, "Get Started" button
2. **Account** — Name field (prefilled "Alex"), email field, Apple/Google/Email sign-in badges
3. **Recovery Setup** — Addiction type picker (Sex Addiction selected), sobriety date (July 4, 2025), motivation multi-select (Faith, Family, Freedom checked from motivations list)
4. **Permissions** — Notification toggle, biometric lock toggle, "You're ready — Let's go" button

---

## Screen Details

### Home Tab (HomeView)

ScrollView, vertical stack:

1. **Streak Hero Card** — Full-width card, sage green gradient accent. Large "270" with "Days Sober" subtitle. Sobriety date "Since July 4, 2025". Next milestone: "30 days to 300!" pill. Coin icon (Gold tier for 270 days).

2. **Today's Commitments Card** — Two rows: Morning Commitment (checkmark, completed 6:14 AM), Evening Review (circle, pending). Tappable.

3. **Quick Actions Row** — Horizontal ScrollView of pill buttons: Log Urge, Journal, Check-In, Prayer, Mood, Gratitude. Each has SF Symbol icon + label. Tap navigates to corresponding activity entry.

4. **Recent Activity Feed** — Last 5 items:
   - "Recovery Check-in — Score: 82" (today, 6:30 AM)
   - "FASTER Scale — Green" (today, 6:20 AM)
   - "Morning Commitment — Completed" (today, 6:14 AM)
   - "Prayer — 12 min" (today, 6:00 AM)
   - "Journal — 'Reflecting on gratitude...'" (yesterday, 9:15 PM)

5. **Milestone Badges Row** — Horizontal scroll of earned badges: 1, 3, 7, 14, 30, 60, 90, 180, 270 days. Each is a small gold coin with number. Tappable to show badge detail sheet (date earned, scripture, personal note placeholder).

### Activities Tab (ActivitiesListView)

Sectioned List with `.insetGrouped` style:

**Sobriety & Commitment**
- Daily Sobriety Commitment — "Today, 6:14 AM ✓"
- Recovery Check-in — "Today, 82/100" with mini 7-day sparkline

**Journaling & Reflection**
- Journal/Jotting — "Yesterday" with snippet "Reflecting on gratitude and the conversation with James..."
- Emotional Journal — "Today, Anxious, 6/10" with amber dot
- Time Journal — "Yesterday, 14 entries" with mini timeline bar
- FASTER Scale — "Today, Green" with green dot
- Post-Mortem Analysis — "142 days ago" (dimmed, long ago)

**Self-Care & Wellness**
- Urge Log — "3 days ago, 4/10"
- Mood Rating — "Today, 7/10" with emoji
- Gratitude List — "Yesterday, 3 items"
- Prayer — "Today, 12 min"
- Exercise — "Yesterday, 30 min run"

**Connection**
- Phone Calls — "2 days ago, James (Sponsor), 18 min"
- Meetings Attended — "Saturday, SA Home Group, 1 hr"
- Spouse Check-in Prep — "5 days ago, FANOS"

**Growth**
- 12-Step Work — "Step 8 — In Progress" with progress bar 8/12
- Weekly Goals — "4 of 5 complete"
- Affirmation Log — "Today, 6:15 AM"

Each row: SF Symbol icon, activity name, last-logged summary, chevron.

### Activity Detail Views

Each activity taps into a detail view with two sections:

**History** — Date-grouped list of Alex's entries (last 30 days of mock data, ~3-10 entries per activity depending on frequency).

**New Entry** — Interactive form appropriate to the activity type. Forms are functional (sliders slide, pickers pick) but nothing persists.

Notable detail views:

**Emotional Journal Entry:**
- Feelings Wheel grid (6 primary emotions in a ring, tap to expand to secondary)
- Activity quick-select pills from the 20 needs (Acceptance, Belonging, Connection, etc.)
- Intensity slider 1-10 (with -1 and 10+ at extremes)
- Location tag (mock: "Home, Austin TX")
- History tab: emotion color timeline, intensity sparkline
- Insights tab: "You feel Anxious most on Mondays", "High intensity peaks between 8-10 PM"
- Map tab: pins on mock Austin map

**Time Journal:**
- Vertical 24-hour timeline for today
- Filled blocks: 6:00-6:30 Prayer (Peace), 6:30-7:00 Exercise (Agency), 7:00-8:00 Family breakfast (Connection), 8:00-12:00 Work (Agency), 12:00-12:30 SA meeting call (Belonging), etc.
- Each block shows activity name + need tag from the 20 needs
- Tap empty slot to quick-add
- Pattern card: "3.2 hrs Connection this week (+2.1 from last week)"

**FASTER Scale:**
- 6 stage cards stacked vertically: Forgetting Priorities, Anxiety, Speeding Up, Ticked Off, Exhausted, Relapse
- Each card: stage name, description, color (green -> yellow -> orange -> red)
- User taps the stage that describes their current state
- Alex's current: "Forgetting Priorities" (Green)
- History: 30-day dot timeline, each dot colored by stage

**Spouse Check-in Prep:**
- Tab toggle: FANOS / FITNAP
- FANOS: 5 guided sections (Feelings with Feelings Wheel, Appreciation text, Needs picker, Ownership text, Sobriety statement)
- FITNAP: 6 guided sections (Feelings with early memory prompt, Integrity/sobriety, Triggers, Needs, Amends, Positives)
- Review summary card at the end
- History of past preps

**12-Step Work:**
- 12 steps listed with completion status (Steps 1-7 complete, Step 8 in progress, 9-12 locked)
- Step 8 detail: explanation text, 10 reflection questions (3 answered), worksheet area, prayer text, progress indicator
- SA-aligned content with scripture references

### Tools Tab (ToolsView)

2x2 grid of large tappable cards:

1. **FASTER Scale** — wrench icon, current status "Green", "Take Assessment" button. Shares the same FASTERScaleView as the Activities tab — navigating here or from Activities opens the same view. Listed in both places for discoverability.

2. **3 Circles** — concentric circles icon. Visual diagram with three rings:
   - Red (inner): 4 acting-out behaviors Alex defined
   - Yellow (middle): 8 warning behaviors (isolation, late nights, skipping meetings, excessive screen time, fantasy, dishonesty, skipping prayer, avoiding sponsor)
   - Green (outer): 12 healthy behaviors (prayer, exercise, calling sponsor, meetings, journaling, scripture, date night, fellowship, service, meditation, gratitude, sleep routine)
   - Tap a circle to see its items list

3. **Meeting Finder** — Map view (mock annotation pins around Austin, TX) with 5 meetings:
   - "SA Home Group" — Saturday 9 AM, 1.2 mi, In-person (Alex's saved meeting)
   - "SA Men's Meeting" — Tuesday 7 PM, 2.8 mi, In-person
   - "SA Virtual Noon" — Daily 12 PM, Virtual
   - "Celebrate Recovery" — Friday 6:30 PM, 3.1 mi, In-person
   - "SA Step Study" — Thursday 8 PM, Virtual (Alex's saved meeting)
   - Filter chips: SA, CR, AA, Virtual, In-Person
   - "What to Expect" sheet for each meeting type
   - Alex has 3 saved meetings marked with star

4. **Panic Button** — red card, "Emergency Tools" label. Same as emergency overlay minus the urge log (since this is the tools section, urge log lives in activities).

### Content Tab (ContentView)

ScrollView with sections:

**Today's Affirmation** — Featured hero card: "I Am Accepted — I am God's child. (John 1:12)". Favorite heart button, share button.

**Affirmation Packs** — Horizontal carousel of pack cards:
- "I Am Accepted" (11) — unlocked
- "I Am Secure" (11) — unlocked
- "I Am Significant" (11) — unlocked
- "Morning Affirmations" (14) — unlocked
- "Daily Faith" (25) — unlocked
- "AA Promises" (11) — unlocked
- Tap pack -> swipeable full-screen card deck with scripture, reflection, favorite toggle

**My Favorites** — Alex's 5 favorited affirmations as compact cards

**Devotional** — "30-Day Recovery Devotional — Day 24". Today's card with title, scripture (Psalm 51:10), reflection text, "Mark Complete" button. Progress dots (24 of 30 filled).

**Prayers** — Vertical list of prayer cards:
- Morning Prayer
- Evening Prayer
- Serenity Prayer
- SA Third Step Prayer
- Prayer for My Spouse
- Prayer in Temptation
- Tap opens full-screen reading view with warm background, large text

**Resources** — Card group:
- Crisis Hotlines (SA: 866-424-8777, 988 Lifeline, RAINN)
- "What is SA?" explainer
- Glossary (FASTER, FANOS, FITNAP, PCI, 3 Circles, Arousal Template definitions)

### Settings Tab (SettingsView)

`.insetGrouped` List:

**Profile Section**
- Profile header card: avatar circle (placeholder "A"), "Alex", "270 days", "alex@example.com"
- Edit Profile -> form: name, email, birth year (1988), gender (Male), timezone (CT), Bible version (ESV picker with 8 English options)
- Addiction Management -> Sex Addiction (SA), sobriety date July 4, 2025

**Support Network Section**
- James — Sponsor — "Sees: All except journal & financial"
- Dr. Sarah — Counselor (CSAT) — "Sees: All"
- Rachel — Spouse — "Sees: All"
- Mike — Accountability Partner — "Sees: All except journal & financial"
- Each row: name, role badge, permission summary, chevron to detail

**Preferences Section**
- Notifications -> toggles: Morning Commitment (6:00 AM), Evening Review (9:00 PM), Affirmation (6:15 AM), Meeting Reminders (1 hr before)
- Quick Actions -> checkboxes for which appear in home row
- Appearance -> segmented control: Light / Dark / System

**Privacy & Data Section**
- Data Sharing -> permission matrix grid (rows: contacts, columns: data categories)
- Export My Data -> "JSON" and "PDF" buttons with mock success alert
- Delete My Account -> red button with confirmation alert ("30-day deletion window")
- Ephemeral Mode -> toggle with explanation text

**About Section**
- "Regal Recovery v1.0.0 (Demo)"
- Glossary of Terms -> list of 14 recovery terms with definitions
- Licenses

---

## Mock Data: Alex (270 Days)

### Profile
- Name: Alex
- Email: alex@example.com
- Birth year: 1988
- Gender: Male
- Timezone: America/Chicago
- Addiction: Sex Addiction (SA)
- Sobriety date: July 4, 2025
- Bible version: ESV
- Motivations: Faith, Family, Freedom

### Streak Data
- Current streak: 270 days
- Sobriety date: 2025-07-04
- Milestones earned: 1, 3, 7, 14, 30, 60, 90, 180, 270 days (9 badges)
- Next milestone: 300 days (30 days away)
- Total relapses: 2 (both early, before day 1 reset to July 4)
- Longest streak: 270 (current)

### Support Network
- James — Sponsor — linked 260 days ago
- Dr. Sarah — Counselor (CSAT) — linked 265 days ago
- Rachel — Spouse — linked 250 days ago
- Mike — Accountability Partner — linked 200 days ago

### Activity Frequency (for generating history)
- Sobriety Commitment: daily (270 entries, 98% completion)
- Recovery Check-in: daily (scores range 65-92, trending up)
- Journal: 4-5x/week
- Emotional Journal: 3-4x/week
- Time Journal: 3x/week
- FASTER Scale: 3-4x/week (mostly Green, occasional Yellow)
- Mood: daily (range 5-9, average 7.2)
- Gratitude: 4x/week (3 items each)
- Prayer: daily (8-20 min)
- Exercise: 4x/week (20-45 min)
- Phone Calls: 2-3x/week (James most frequent)
- Meetings: 2x/week (SA Home Group Saturday, Step Study Thursday)
- Spouse Check-in: weekly (alternating FANOS/FITNAP)
- Urge Log: 1-2x/month currently (was 2-3x/week early on), intensity trending down
- 12-Step Work: Step 8 in progress
- Goals: 5 weekly goals, 4 complete this week
- Affirmation: daily view logged
- Post-Mortem: 1 entry at day 0 (the relapse that started current streak)

### 3 Circles Configuration
**Red (Acting Out):** pornography, masturbation, objectifying others, visiting triggering websites
**Yellow (Warning):** isolating from others, staying up late alone, skipping meetings, excessive screen time, fantasy, dishonesty, skipping prayer, avoiding sponsor calls
**Green (Healthy):** prayer, exercise, calling sponsor, attending meetings, journaling, scripture reading, date night with Rachel, fellowship, acts of service, meditation, gratitude practice, consistent sleep routine

### Saved Meetings
1. SA Home Group — Saturday 9:00 AM — First Baptist Church, Austin TX — In-person
2. SA Step Study — Thursday 8:00 PM — Virtual (Zoom)
3. SA Virtual Noon — Daily 12:00 PM — Virtual

### Affirmation Favorites
1. "I am God's child." — John 1:12
2. "I am free from condemnation." — Romans 8:1-2
3. "I can do all things through Christ who strengthens me." — Philippians 4:13
4. "I am a new creation in Christ." — 2 Corinthians 5:17
5. "God's power is made perfect in my weakness." — 2 Corinthians 12:9

---

## iOS Technical Notes

- **Minimum target:** iOS 17 (for SwiftUI improvements, SwiftData availability)
- **No external dependencies.** Pure SwiftUI + Foundation.
- **No Info.plist camera permission needed** — panic button camera view is a placeholder rectangle, not actual AVCaptureSession
- **MapKit** used for meeting finder with hardcoded CLLocationCoordinate2D annotations (Austin, TX area)
- **Charts framework** (Swift Charts) for sparklines and trend views — ships with iOS 16+
- **SF Symbols** exclusively for icons — no custom image assets needed beyond app icon and placeholder avatar
