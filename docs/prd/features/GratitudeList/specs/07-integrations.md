# Gratitude List: Integrations Specification

**Spec ID:** GL-IN-001
**Version:** 1.0
**Status:** Draft
**Traces to:** Gratitude_List_Activity.md > Integration Points, Relationship to Evening Commitment Review, Dashboard Widget, Notifications

---

## 1. Evening Commitment Review Integration

### Cross-Reference Rule

- If user has completed a Gratitude List entry today, the evening review displays:
  > "You already captured X gratitude items today. Would you like to add more or skip this question?"
- Two actions: "Add More" (navigates to GratitudeEntryView) or "Skip"
- Evening review gratitude prompt response saved ONLY in commitment review history, NOT in gratitude history
- Evening review does NOT advance gratitude streak

### Implementation

- Query `RRGratitudeEntry` for today's entries at evening review render time
- Sum total items across today's entries for the count

---

## 2. Dashboard Widget

### Layout (compact card on Today screen)

```
┌─ Gratitude Widget ──────────────────┐
│ 🌿 Gratitude              [+]      │
│ Streak: 12 days                     │
│ "My sponsor's patience and wisdom"  │
│                    — 2 days ago      │
└─────────────────────────────────────┘
```

### Behavior

- Shows: today's status (done/not done), current streak, one random past item
- Random past item rotates daily (deterministic from day hash)
- Tap card → navigate to GratitudeEntryView (if not done) or GratitudeHistoryView (if done)
- "+" button → navigate directly to GratitudeEntryView

### Status Display

- If entry exists today: green checkmark + "Done"
- If no entry today: neutral "Not yet" with leaf icon

---

## 3. Tracking System Integration

| Feed | Data | Trigger |
|------|------|---------|
| Daily activity completion | Entry saved today (boolean) | On save |
| Streak calculation | Consecutive days with entries | On save, on day change |
| Recovery plan scoring | Gratitude entry counts toward daily score | Via TodayViewModel |

---

## 4. Analytics Dashboard Integration

| Metric | Source | Display |
|--------|--------|---------|
| Gratitude streak | Computed from entry dates | Streak card |
| Category distribution | Aggregated category tags | Pie/bar chart |
| Correlation with check-in | Join gratitude dates with check-in scores | Insight card |
| Correlation with urges | Join gratitude dates with urge log counts | Insight card |

---

## 5. Goals Integration

- If user has a goal with type "gratitude" or category "emotional" or "spiritual":
  - Completing a gratitude entry auto-checks the goal for the day
  - Goal progress tracked in `RRGoal` model

---

## 6. Community Permissions

| Role | Default Access | Configurable |
|------|---------------|--------------|
| Spouse | Visible (if permission granted) | Yes |
| Counselor/Coach | Visible (if permission granted) | Yes |
| Sponsor | NOT visible by default | Yes |
| Accountability Partner | NOT visible by default | Yes |

- Mood tags and category tags NEVER shared with support network
- Only gratitude text visible to permitted roles

---

## 7. Notifications

| Notification | Default | Trigger | Message Template |
|-------------|---------|---------|-----------------|
| Daily reminder | OFF | User-configured time | "Take a moment to notice the good. What are you grateful for today?" |
| Missed entry nudge | OFF, 3-day threshold | X days without entry | "It's been X days since your last gratitude entry. Even one thing you're thankful for can shift your perspective." |
| Streak milestone | ON | 7, 14, 30, 60, 90, 180, 365 days | "X days of gratitude in a row. You're rewiring how you see the world." |

- All notifications independently togglable in Settings
- Respect system notification permissions and quiet hours

---

## 8. Acceptance Criteria

| ID | Criterion | Test Reference |
|----|-----------|----------------|
| GL-IN-AC1 | Evening review shows gratitude count if entries exist today | `TestGratitude_GL_IN_AC1_EveningReviewCrossRef` |
| GL-IN-AC2 | Evening review response does NOT count toward gratitude streak | `TestGratitude_GL_IN_AC2_EveningReviewExcluded` |
| GL-IN-AC3 | Dashboard widget shows streak and random past item | `TestGratitude_GL_IN_AC3_DashboardWidget` |
| GL-IN-AC4 | Dashboard widget taps navigate correctly | `TestGratitude_GL_IN_AC4_WidgetNavigation` |
| GL-IN-AC5 | Gratitude entry completion feeds daily plan scoring | `TestGratitude_GL_IN_AC5_PlanScoring` |
| GL-IN-AC6 | Streak milestone notifications fire at correct thresholds | `TestGratitude_GL_IN_AC6_StreakNotifications` |
| GL-IN-AC7 | Missed entry nudge respects user-configured threshold | `TestGratitude_GL_IN_AC7_MissedNudge` |
| GL-IN-AC8 | Community permissions respected for gratitude visibility | `TestGratitude_GL_IN_AC8_CommunityPermissions` |
