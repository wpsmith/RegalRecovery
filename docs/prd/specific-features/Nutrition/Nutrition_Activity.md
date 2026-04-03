# Activity: Nutrition

**Priority:** P2

**Description:** Log meals and nutrition to support physical wellness in recovery. The focus is on awareness and healthy habits — not calorie counting, restrictive dieting, or body image. Nourishing the body is an act of self-care that directly supports emotional stability, mental clarity, and sustained sobriety.

---

## User Stories

- As a **recovering user**, I want to log my meals each day, so that I can build awareness of whether I'm actually nourishing my body or neglecting it during recovery
- As a **recovering user**, I want to track my water intake, so that I can stay hydrated — something I've historically ignored when consumed by my addiction
- As a **recovering user**, I want a simple logging experience focused on what I ate rather than how many calories it contained, so that nutrition tracking supports my recovery without triggering disordered eating patterns
- As a **recovering user**, I want to see my meal consistency over time, so that I can identify patterns like skipping meals on high-stress days or binge eating after emotional events
- As a **recovering user**, I want to understand how my eating habits correlate with my mood and recovery health, so that I can make informed choices about fueling my body
- As a **recovering user**, I want to log meals quickly without needing to weigh food or scan barcodes, so that tracking feels manageable alongside everything else I'm doing in recovery
- As a **recovering user**, I want to note how I felt before and after eating, so that I can recognize emotional eating patterns and develop healthier coping strategies
- As a **recovering user**, I want nutrition tracking to feel like caring for myself — not punishing or controlling myself — so that it strengthens my recovery rather than becoming another compulsion
- As a **recovering user with a co-addiction to eating disorders**, I want the app to focus on balanced awareness without calorie counts, weight metrics, or "good vs. bad" food language, so that this tool supports my recovery from disordered eating rather than reinforcing it
- As a **sponsor**, I want to know whether my sponsee is eating regularly (with permission), so that I can address self-neglect before it compounds into a relapse risk

---

## Meal Logging

### Entry Fields

- **Meal type** (required) — select one:
  - Breakfast
  - Lunch
  - Dinner
  - Snack
  - Other (free-text label — e.g., "post-workout shake," "late night meal")

- **Description** (required) — free-text, 300 char max, voice-to-text available
  - Simple, natural language description of what was eaten
  - Examples: "Scrambled eggs, toast, and coffee," "Leftover chicken and rice," "Granola bar"
  - No structured ingredient input, barcode scanning, or portion measurement — intentionally low friction
  - Placeholder prompts (rotating):
    - "What did you eat?"
    - "Describe your meal in a few words"

- **Date and time** (default: now, editable for backdating)

- **Eating context** (optional) — where and how the meal happened:
  - Home-cooked
  - Takeout / Restaurant
  - On-the-go / Fast food
  - Meal prepped
  - Skipped (intentional)
  - Social meal (eating with others)
  - Alone

- **Mood before eating** (optional) — emoji or 1-5 scale
  - Captures emotional state leading into the meal
  - Helps identify emotional eating patterns

- **Mood after eating** (optional) — emoji or 1-5 scale
  - Captures how the user feels after eating
  - Helps identify meals that support emotional stability vs. those that don't

- **Mindfulness check** (optional) — "Were you present during this meal?"
  - Yes — ate mindfully, paid attention to the food
  - Somewhat — partially distracted
  - No — ate while distracted, rushed, or on autopilot
  - Helps build awareness of mindful vs. mindless eating habits

- **Notes** (optional) — free-text, 500 char max, voice-to-text available
  - Suggested prompts (rotating placeholder text):
    - "How did this meal make you feel?"
    - "Did you eat because you were hungry, or for another reason?"
    - "What's one thing you could do differently next meal?"

### Quick Log

- One-tap logging from Dashboard widget or notification
- Quick log records: meal type (user selects), timestamp
- User can expand afterward to add description, mood, context, and notes
- Designed for speed — capture the fact that a meal happened, add details later if desired

---

## Hydration Tracking

- **Daily water intake tracker:**
  - Simple counter: tap "+" to add a glass/bottle of water
  - Configurable serving size: 8 oz (default), 12 oz, 16 oz, custom
  - Visual progress toward daily target

- **Daily target:**
  - Default: 8 glasses (64 oz / ~2 liters)
  - User-configurable in Settings → Nutrition → Hydration Goal
  - Progress bar or fill animation showing progress throughout the day

- **Quick log:** Single tap from Dashboard widget or notification to add one serving

- **History:** Daily water intake viewable on calendar; trend line over time

- **Hydration is intentionally simple** — no electrolyte tracking, no beverage categorization, just water intake awareness

---

## Meal History

### List View

- Browse past meal logs in reverse chronological order
- Each entry shows: meal type icon, meal type label, description (truncated), date/time, mood before/after (if logged)
- Tap any entry to view full details including context, mindfulness check, and notes
- Grouped by day with daily summary: meals logged, hydration progress

### Calendar View

- Monthly calendar with indicators on days with meal logs
- Day indicators show: number of meals logged, hydration goal met (✓/✗)
- Color coding by completeness:
  - Green: 3+ meals and hydration goal met
  - Yellow: 1-2 meals logged or hydration goal partially met
  - Gray: no meals logged
- Tap any day to view that day's full meal log and hydration

### Filter & Search

- Filter by meal type (breakfast, lunch, dinner, snack)
- Filter by eating context
- Filter by mood rating (before or after)
- Filter by mindfulness check response
- Filter by date range
- Search descriptions and notes by keyword

---

## Trends & Insights

### Meal Consistency

- **Meals per day** — bar chart (7-day, 30-day, 90-day views)
  - Breakdown by meal type (stacked bars showing breakfast, lunch, dinner, snack distribution)
  - Average meals per day over time

- **Meal regularity:**
  - "You eat breakfast X% of days" / "You skip dinner X% of days"
  - Time-of-day patterns: when does the user typically eat each meal type?
  - Gap detection: "You've skipped breakfast 5 of the last 7 days"

- **Weekly summary:**
  - Meals logged this week
  - Hydration goal met X of 7 days
  - Most common eating context
  - Comparison to previous week

### Eating Context Trends

- Distribution of eating contexts over time (pie chart)
- Shift tracking: "You're cooking at home more this month compared to last month"
- Social eating frequency: "You ate with others X times this week"

### Emotional Eating Patterns

- **Mood before/after comparison:**
  - Average mood before eating vs. after eating (tracked over time)
  - "Your mood tends to improve after meals — you may be under-eating before meals"
  - "Your mood drops after late-night snacks — consider whether these are emotional eating episodes"

- **Mood-to-meal correlation:**
  - "On days when your pre-meal mood is below 3, you're more likely to eat fast food or skip meals"
  - "On days when you eat mindfully, your post-meal mood averages X points higher"

- **Trigger cross-reference:**
  - "Your emotional eating episodes correlate with urge log entries on the same day"
  - "On days you skip meals, your urge frequency increases by X%"

### Mindfulness Trends

- Percentage of meals eaten mindfully vs. distracted over time
- Trend direction: improving, stable, declining
- "You've eaten mindfully at X% of meals this month, up from X% last month"

### Correlation Insights

- "On days you eat 3+ meals, your check-in score averages X points higher"
- "On days you meet your hydration goal, your mood rating averages X points higher"
- "Meal skipping increases in the days before a relapse — maintaining regular meals may help protect your sobriety"
- "On days you exercise, you're more likely to log meals and meet your hydration goal"

### Hydration Trends

- Daily water intake over time (bar chart)
- Days per week hydration goal is met
- Average daily intake over 30 days

---

## Dashboard Widget

- Compact card on main Dashboard showing:
  - Today's meals: icons for each meal type logged (breakfast ✓, lunch ✓, dinner pending, etc.)
  - Hydration progress: glass icon with fill level or "X of Y glasses"
  - Quick actions: "Log a Meal" button, "+" water button
- Tap widget header to open full Nutrition screen

---

## Content Safety & Eating Disorder Sensitivity

This section is critical given that eating disorders are a common co-addiction for the target audience.

### Design Principles

- **No calorie counting** — the app never asks for, calculates, or displays calorie information
- **No weight tracking** — no weight input fields, BMI calculations, or body measurements anywhere in the nutrition activity
- **No "good food / bad food" language** — no foods are labeled as healthy, unhealthy, clean, dirty, cheat, or guilty
- **No portion judgment** — no portion size metrics, no "too much / too little" feedback
- **No food photography requirements** — photo logging is intentionally excluded to avoid appearance-based food anxiety
- **No comparison** — no benchmarking against other users, dietary guidelines, or ideal intake targets (beyond hydration)
- **Focus on patterns, not prescriptions** — insights highlight consistency and emotional connection to eating, never dietary adequacy

### Eating Disorder Safeguards

- If user's addiction profile includes eating disorders as a co-addiction:
  - Mindfulness check and mood tracking remain available (these support ED recovery)
  - Meal description remains available but placeholder prompts shift to emphasize nourishment: "What did you nourish yourself with?"
  - Insights language adjusted: avoids any framing that could trigger restriction or binge cycles
  - Optional: user can disable specific insight types in Settings → Nutrition → Insight Preferences

- If concerning patterns are detected (e.g., consistently logging 0-1 meals per day for 7+ days, or logging "skipped" for the majority of meals):
  - Gentle, non-alarmist prompt: "We've noticed your meal logging has been low recently. Nourishing your body is an important part of recovery. Would you like to talk to someone about this?"
  - Options: contact counselor, view resources on nutrition in recovery, dismiss
  - No automated alerts to support network for nutrition patterns (risk of triggering shame)

---

## Platform Integrations

### Automatic Sync

- **Apple Health** (iOS) — reads nutrition data if available (meal logging, water intake)
- **Google Fit** (Android) — reads nutrition data if available

### Configuration

- Enabled via Settings → Nutrition → Connected Apps
- OAuth authentication flow for each platform
- Duplicate detection: if user manually logs a meal that also appears via sync, prompt to merge or keep both
- User can disable auto-sync at any time

### Future App Integrations (to explore)

- MyFitnessPal — meal logging (description only, not calorie data)
- Cronometer — meal logging
- Lose It! — meal logging
- Each integration would import meal descriptions and timestamps only — calorie and macro data intentionally excluded to align with the app's recovery-first, non-diet-culture philosophy

---

## Integration Points

- Feeds into Tracking System (consecutive days of logging at least one meal)
- Feeds into Analytics Dashboard (meal consistency, hydration trends, emotional eating patterns, correlation with recovery outcomes)
- Feeds into Weekly/Daily Goals — logging a meal auto-checks a physical dynamic goal if one is set
- Mood before/after data feeds into Mood Ratings trends (if user also uses Mood Ratings activity)
- Emotional eating patterns cross-referenced with Urge Logging data and FASTER Scale results
- Linked from Weekly/Daily Goals — "Eat three meals today" as a common physical dynamic goal
- Visible to support network based on community permissions (default: excluded from all support network views; user must explicitly grant access)

---

## Notifications

- **Meal reminders** (optional) — user-configured times for each meal type
  - Default: OFF for all
  - Suggested times if enabled: Breakfast 8:00 AM, Lunch 12:00 PM, Dinner 6:00 PM
  - Notification text: "Time to nourish yourself. Have you eaten [meal type] today?"

- **Hydration reminders** (optional) — periodic prompts throughout the day
  - Default: OFF
  - If enabled: customizable interval (every 1, 2, or 3 hours during waking hours)
  - Notification text: "Have you had water recently? Stay hydrated."

- **Missed meal nudge:** "You haven't logged any meals today. Your body needs fuel to support your recovery." (optional, sent at user-configured time if no meals logged, default: 2:00 PM)

- **Streak milestone:** "X consecutive days of logging meals. Taking care of your body is an act of recovery."

- **Hydration goal celebration:** "You hit your water goal today! Your body thanks you."

- All nutrition notifications independently togglable in Settings

---

## Tone & Messaging

- Nutrition framed as nourishment and self-care — never as control, discipline, or penance
- Helper text on first use: "In addiction, we often neglect or abuse our bodies. Learning to feed yourself well — consistently, mindfully, without shame — is a quiet but powerful act of recovery. This tool is here to help you notice, not to judge."
- Post-log messages (rotating):
  - "Fueled and cared for. That's what recovery looks like in the small moments."
  - "Eating well is choosing yourself. You showed up for your body today."
  - "No guilt. No grades. Just awareness. That's all this is."
  - "Your body is carrying you through recovery. Thank you for taking care of it."
- No praise for eating less or skipping meals — consistency and awareness are always the celebrated behaviors
- "Skipped" meal context treated neutrally — logged for awareness, never flagged as failure

---

## Edge Cases

- User logs multiple meals of the same type (e.g., two lunches) → Both saved independently; no validation error
- User logs a meal with description only and no optional fields → Fully valid; the description alone is valuable
- User logs "Skipped" for every meal in a day → Logged for pattern tracking; if pattern persists, gentle prompt after 7 days (see Eating Disorder Safeguards)
- User has eating disorder as co-addiction and enables nutrition tracking → Safeguarded language and adjusted insights activated automatically based on addiction profile
- User wants to track supplements or vitamins → Can include in meal description or notes; no dedicated supplement tracking feature (keeps scope focused)
- User changes hydration serving size mid-week → Historical data preserved with original serving size; new size applies going forward; weekly total recalculated in ounces/ml for consistency
- User syncs data from Apple Health that includes calorie information → Calorie data intentionally discarded during import; only meal description and timestamp retained
- Offline → Full meal and hydration logging available offline; synced when connection restored
