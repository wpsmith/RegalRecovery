# Gratitude List: Trends & Insights Specification

**Spec ID:** GL-TI-001
**Version:** 1.0
**Status:** Draft
**Traces to:** Gratitude_List_Activity.md > Trends & Insights

---

## 1. Screen: `GratitudeTrendsView`

### Layout

```
ScrollView
  VStack(spacing: 24)
    ┌─ Streak Card ──────────────────────┐
    │ 🔥 Current Streak: 12 days        │
    │ Best: 28 days · Total: 94 days    │
    └────────────────────────────────────┘

    ┌─ Category Breakdown ───────────────┐
    │ [30d] [90d] [All Time]             │
    │ ┌──────────────────────────────┐   │
    │ │  Donut/Bar Chart             │   │
    │ │  Family: 34%                 │   │
    │ │  Recovery: 22%               │   │
    │ │  Faith: 18%                  │   │
    │ │  ...                         │   │
    │ └──────────────────────────────┘   │
    │ "Your top source: Family"          │
    └────────────────────────────────────┘

    ┌─ Volume Trends ────────────────────┐
    │ Avg items per entry: 3.2           │
    │ Days/week with entries:            │
    │ ┌──────────────────────────────┐   │
    │ │  Line graph (8 weeks)        │   │
    │ └──────────────────────────────┘   │
    └────────────────────────────────────┘

    ┌─ Correlation Insights ─────────────┐
    │ 💡 "On days you complete a         │
    │    gratitude list, your check-in   │
    │    score averages 8 points higher" │
    │                                    │
    │ 💡 "Your urge frequency is 40%     │
    │    lower on days with gratitude"   │
    └────────────────────────────────────┘
```

---

## 2. Streak Tracking

### Computed Properties (ViewModel)

```swift
struct GratitudeStreakData {
    let currentStreak: Int          // Consecutive days with >= 1 entry
    let longestStreak: Int          // All-time best
    let totalDaysWithEntries: Int   // Lifetime count
}
```

### Rules

- A "day" is defined by the user's local calendar (midnight to midnight)
- Multiple entries on the same day count as 1 day for streak purposes
- Only entries saved via the Gratitude List activity count (NOT evening review prompts)
- Streak breaks at midnight if no entry exists for the previous day

---

## 3. Category Breakdown

### Time Periods

- 30-day, 90-day, All Time (segmented control)
- Counts category tags across all items in all entries within the period
- Items with no category excluded from breakdown (but counted in total)

### Shift Tracking

Compare current 30-day to previous 30-day:
- "Compared to last month, you're expressing more gratitude for Recovery (+15%) and less for Work (-8%)"
- Only shown if sufficient data (>= 10 entries in each period)

---

## 4. Volume Trends

- **Average items per entry:** mean item count across all entries in period
- **Days per week:** line graph showing 8-week rolling count of days-with-entries per week
- Requires minimum 2 weeks of data to render graph

---

## 5. Correlation Insights

Cross-reference with other activity data:

| Insight | Data Source | Threshold |
|---------|-------------|-----------|
| Check-in score correlation | `RRCheckIn.score` on gratitude days vs non-gratitude days | >= 14 days of each |
| Urge frequency correlation | `RRUrgeLog` count on gratitude days vs non-gratitude days | >= 14 days of each |
| Inactivity warning | Days since last entry + mood trend | >= 3 days inactive |

### Display Rules

- Only show insights with statistically meaningful sample sizes
- Insights computed on-device from local SwiftData
- Phrased positively ("X% lower" not "X% higher risk")

---

## 6. Acceptance Criteria

| ID | Criterion | Test Reference |
|----|-----------|----------------|
| GL-TI-AC1 | Current streak counts consecutive days with >= 1 entry | `TestGratitude_GL_TI_AC1_CurrentStreak` |
| GL-TI-AC2 | Longest streak tracks all-time best | `TestGratitude_GL_TI_AC2_LongestStreak` |
| GL-TI-AC3 | Total days counts lifetime unique days | `TestGratitude_GL_TI_AC3_TotalDays` |
| GL-TI-AC4 | Multiple entries same day count as 1 streak day | `TestGratitude_GL_TI_AC4_MultipleEntriesSameDay` |
| GL-TI-AC5 | Category breakdown shows distribution for selected period | `TestGratitude_GL_TI_AC5_CategoryBreakdown` |
| GL-TI-AC6 | Shift tracking compares current vs previous 30-day | `TestGratitude_GL_TI_AC6_ShiftTracking` |
| GL-TI-AC7 | Volume trend shows average items per entry | `TestGratitude_GL_TI_AC7_AvgItemsPerEntry` |
| GL-TI-AC8 | Check-in correlation shown with >= 14 days data | `TestGratitude_GL_TI_AC8_CheckInCorrelation` |
| GL-TI-AC9 | Inactivity warning after user-configured threshold | `TestGratitude_GL_TI_AC9_InactivityWarning` |
| GL-TI-AC10 | Evening review entries do NOT count toward streak | `TestGratitude_GL_TI_AC10_EveningReviewExcluded` |
