# Activity: Meetings Attended

**Priority:** P1

**Description:** Log meeting attendance with optional notes.

---

## User Stories

- As a **recovering user**, I want to log each recovery meeting I attend, so that I can track my consistency and commitment to community-based recovery
- As a **recovering user**, I want to categorize meetings by type (12-step, therapy, church, etc.), so that I can see which forms of support I'm engaging with most
- As a **recovering user**, I want to add notes after a meeting, so that I can capture key takeaways, feelings, or action items while they're fresh
- As a **recovering user**, I want to see my meeting attendance history over time, so that I can identify patterns between attendance and my overall recovery health
- As a **sponsor**, I want to see whether my sponsee is attending meetings regularly, so that I can encourage consistency or address gaps early
- As a **recovering user**, I want meeting attendance to count toward my commitments and streaks, so that I'm motivated to keep showing up
- As a **recovering user**, I want to quickly log a meeting with minimal effort, so that tracking doesn't feel like a burden on top of recovery work

---

## Summary

- **Quick-log entry fields:**
  - Which meeting (name or group — free text or saved favorites)
  - Meeting type: 12-step (SA, AA, Celebrate Recovery), therapy session, group counseling, church, custom
  - Date and time
  - Duration (optional)
  - Notes (optional — free text, voice-to-text available)

- **Saved Meetings:** Users can save frequently attended meetings (name, type, day/time, location) for one-tap logging in the future

- **Attendance History:**
  - Browse past meetings by date
  - Filter by meeting type
  - View monthly/weekly attendance counts
  - Tap any past entry to see full details and notes

- **Integration Points:**
  - Feeds into Tracking System (consecutive days/weeks of meeting attendance based on user's commitment frequency)
  - Feeds into Commitments tracking (if user has a "attend X meetings per week" commitment)
  - Visible to support network (sponsor, counselor, coach) based on community permissions
  - Appears on calendar view in the Tracking System
  - Correlates with Analytics Dashboard (e.g., "Your sobriety score averages 12 points higher on weeks you attend 3+ meetings")

- **Notifications:**
  - Optional reminder before saved meeting times
  - Post-meeting prompt: "You had a meeting scheduled today. Would you like to log it?" (if not already logged)

- **Edge Cases:**
  - Multiple meetings in one day → Each logged independently
  - User attends a meeting type not in the default list → "Custom" type with free-text label
  - Meeting canceled → User can mark as "Canceled" to preserve the record without breaking commitment streaks (configurable: user chooses whether cancellations count or not)
  - Offline logging → Saved locally, synced when connection restored
