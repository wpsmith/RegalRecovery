# Activity: Weekly/Daily Goals

**Priority:** P1

**Description:** Set and track short-term recovery goals across all five dynamics of holistic recovery.

---

## User Stories

- As a **recovering user**, I want to set daily and weekly goals for my recovery, so that I have clear, actionable steps to focus on each day
- As a **recovering user**, I want my goals organized across the five dynamics (spiritual, physical, emotional, intellectual, relational), so that I maintain balance in my recovery and don't neglect any area
- As a **recovering user**, I want to see which dynamics have goals and which are empty, so that I can notice blind spots and intentionally round out my recovery work
- As a **recovering user**, I want my active commitments and activities to auto-populate as daily goals, so that I don't have to re-enter the same tasks every day
- As a **recovering user**, I want to add one-off goals on any given day without changing my recurring settings, so that I can stay flexible and responsive to what each day requires
- As a **recovering user**, I want to check off goals as I complete them throughout the day, so that I feel a sense of progress and momentum
- As a **recovering user**, I want to review my goal completion at the end of each day and week, so that I can reflect on what I accomplished and where I fell short
- As a **recovering user**, I want to see my goal completion rate over time, so that I can track whether I'm building consistency or losing ground
- As a **sponsor**, I want to see my sponsee's goal completion patterns, so that I can encourage them in areas of strength and address areas they're consistently skipping
- As a **recovering user**, I want a gentle nudge when a dynamic has no goals for the day or week, so that I'm prompted to think about areas I might be avoiding

---

## Five Dynamics of Holistic Recovery

Goals are categorized across five dynamics, encouraging the user to maintain balance in their recovery:

### 1. Spiritual
Prayer, scripture reading, devotionals, step work, church attendance, meditation on God's Word, worship, service

### 2. Physical
Exercise, nutrition, sleep hygiene, self-care, medical appointments, hydration, rest

### 3. Emotional
Journaling, emotional journaling, therapy sessions, mood awareness, gratitude practice, processing feelings, crying, creative expression

### 4. Intellectual
Recovery reading, podcasts, personal development, learning new skills, creative pursuits, professional growth

### 5. Relational
Sponsor calls, spouse check-ins, meetings attendance, service work, community connection, quality time with family, amends work, accountability conversations

---

## Goal Creation

- **Goal text:** Free-text description of the goal (required, 200 char max)
- **Dynamic tag:** Assign to one or more of the five dynamics (required)
- **Scope:** Daily or Weekly
- **Recurrence (optional):**
  - One-time (default for manually added goals)
  - Daily (repeats every day)
  - Specific days of the week (e.g., Mon/Wed/Fri)
  - Weekly (repeats once per week on a chosen day)
- **Priority (optional):** High, Medium, Low — used for sorting within the goal list
- **Notes (optional):** Additional context or intention behind the goal (free-text, 500 char max)

---

## Auto-Population

Configurable via Settings → Daily Goals:

### From Commitments
- Daily goals can auto-populate with the user's active commitments that are due that day
- Examples: "Call sponsor," "Attend meeting," "Exercise," "Daily prayer"
- Each commitment appears as a pre-filled goal tagged to the appropriate dynamic

### From Activities
- Daily goals can auto-populate with activities the user wants to complete that day
- Examples: "Morning commitment," "Recovery check-in," "Journaling," "Prayer," "Affirmation"
- Each activity appears as a pre-filled goal tagged to the appropriate dynamic

### Configuration
- User toggles which commitments and/or activities auto-populate as goals
- Auto-populated goals appear alongside any manually added goals
- Auto-populated goals are visually distinguished (subtle icon or label indicating "from commitments" or "from activities")
- User can remove an auto-populated goal on any given day without changing the auto-populate settings
- User can add manual goals on any given day without affecting auto-populate configuration

---

## Daily Goals View

- **Today's Goals screen:**
  - Goals grouped by dynamic, each dynamic shown as a collapsible section with its icon
  - Each goal has a checkbox for completion
  - Tap a goal to expand: view notes, edit, remove, change dynamic tag
  - Progress summary at top: "4 of 7 goals completed today"
  - Dynamic balance indicator: visual bar or ring showing completion per dynamic (e.g., Spiritual 2/2 ✓, Physical 0/1 ✗, Emotional 1/1 ✓, Intellectual 0/0 —, Relational 1/3)

- **Dynamic gap nudge:**
  - If a dynamic has no goals for today: subtle inline prompt — "You don't have any [physical] goals today. Would you like to add one?"
  - Non-intrusive — dismissible, not repeated if dismissed for the same dynamic on the same day
  - Configurable: user can disable nudges per dynamic or entirely in Settings

- **Quick add:** Floating "+" button to add a new goal at any time during the day

---

## Weekly Goals View

- **This Week's Goals screen:**
  - Goals grouped by dynamic
  - Each goal shows: completion status, due day (if specific), notes
  - Weekly progress summary: "12 of 18 goals completed this week"
  - Dynamic balance for the week: completion percentage per dynamic
  - Tap any goal to mark complete, edit, or remove

- **Week navigation:** Swipe or arrows to view past weeks' goals and completion

---

## End-of-Day Review

- Prompted at user-set time (default: evening, can be combined with evening commitment review)
- Shows today's goals with completion status
- Uncompleted goals: option to mark as "Carried to tomorrow," "Skipped," or "No longer relevant"
- Reflection prompt (optional): "What made today's goals easy or hard to complete?"
- Free-text input with voice-to-text available
- Completion confirmation with dynamic balance summary

---

## End-of-Week Review

- Prompted on user's chosen review day (default: Sunday evening)
- Shows the full week's goals with completion status across all five dynamics
- Weekly stats:
  - Total goals set vs. completed
  - Completion rate (percentage)
  - Strongest dynamic (highest completion rate)
  - Weakest dynamic (lowest completion rate or no goals set)
  - Comparison to previous week: "Your relational goal completion improved from 50% to 75% this week"
- Reflection prompts (optional):
  - "What was your biggest win this week?"
  - "What dynamic needs more attention next week?"
- Option to pre-set next week's goals during the review

---

## Trends & Insights

- **Completion rate over time:** Line graph showing daily and weekly goal completion rates (7-day, 30-day, 90-day views)
- **Per-dynamic trends:** Separate trend lines or stacked bar chart for each dynamic
- **Consistency score:** Based on percentage of days with at least one goal completed across 3+ dynamics
- **Correlation insights:**
  - "On days you complete all your spiritual goals, your check-in score averages 15 points higher"
  - "Weeks with no relational goals have a 2x higher urge frequency"
- **Streaks:** Consecutive days with all goals completed; consecutive weeks with 80%+ completion
- **Dynamic balance history:** How the user's attention across dynamics has shifted over time

---

## History

- Browse past daily and weekly goals by date
- Tap any day or week to see full goal list, completion status, notes, and reflection
- Filter by dynamic, completion status, or date range
- Search goals by text
- Export as CSV or PDF for therapy sessions or personal review

---

## Integration Points

- Feeds into Tracking System (consecutive days of completing at least one goal; configurable streak rules)
- Feeds into Analytics Dashboard (completion rates, dynamic balance, correlation with recovery outcomes)
- Action plan items from Post-Mortem Analysis can auto-populate as goals
- Commitments System goals cross-referenced — completing a goal tied to a commitment also marks the commitment as done
- Activities completed through their native flows (e.g., journaling, prayer) automatically check off the corresponding auto-populated goal
- Visible to support network (sponsor, counselor, coach) based on community permissions

---

## Notifications

- Morning: "You have X goals for today. Here's your plan:" (optional, configurable time)
- Midday nudge: "You've completed X of Y goals so far today. Keep going!" (optional)
- Evening: End-of-day review prompt
- Weekly: End-of-week review prompt
- Dynamic gap: "You haven't set any [emotional] goals this week. Recovery is strongest when it's balanced." (optional, once per week max per dynamic)
- All goal-related notifications independently togglable in Settings

---

## Edge Cases

- User sets no goals for a day → No penalty; gentle prompt: "Would you like to set some goals for today?" on Dashboard
- User completes a goal via its native activity flow (e.g., finishes journaling) → Auto-populated goal auto-checked; manual goals require manual check-off
- User changes auto-populate settings mid-day → Changes take effect the following day; today's goals unchanged
- User sets a recurring goal then disables it → Future occurrences removed; past completion data preserved
- User has goals in only one dynamic for an extended period → Weekly review highlights the imbalance; nudge frequency increases slightly (max once per review)
- Offline → Full goal creation, editing, and completion available offline; synced when connection restored
