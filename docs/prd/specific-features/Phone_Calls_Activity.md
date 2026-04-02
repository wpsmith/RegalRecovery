# Activity: Phone Calls

**Priority:** P1

**Description:** Log recovery-related phone calls — both made and received. The point is staying connected. Isolation is one of the greatest threats to recovery, and consistent phone contact with support people is one of the simplest and most effective defenses against it.

---

## User Stories

- As a **recovering user**, I want to log recovery phone calls I make and receive, so that I can track how consistently I'm staying connected to my support network
- As a **recovering user**, I want to track whether I actually connected with someone or just attempted the call, so that I can see both my effort and my actual support contact rate
- As a **recovering user**, I want to see my phone call streak, so that I'm motivated to pick up the phone every day even when I don't feel like it
- As a **recovering user**, I want to categorize calls by contact type (sponsor, accountability partner, counselor), so that I can see which relationships I'm investing in and which I'm neglecting
- As a **recovering user**, I want to log calls quickly with minimal friction, so that tracking doesn't become an excuse to avoid making the call in the first place
- As a **recovering user**, I want to see how my call frequency correlates with my recovery health, so that I have data-driven motivation to keep reaching out
- As a **recovering user**, I want to log received calls too, so that I get credit for being available and responsive when someone in my network reaches out to me
- As a **sponsor**, I want to see whether my sponsee is making daily phone calls, so that I can address isolation before it becomes dangerous
- As a **recovering user**, I want a gentle nudge when I haven't made a call in a few days, so that I'm reminded to break through the inertia of isolation before it takes hold
- As a **recovering user**, I want logging a call to feel like celebrating connection — not documenting compliance — so that I associate reaching out with something positive

---

## Call Logging

### Entry Fields

- **Direction** (required) — Made or Received
  - Made: user initiated the call
  - Received: someone in the user's recovery network called them

- **Contact type** (required) — who the call was with:
  - Sponsor
  - Accountability Partner
  - Counselor
  - Coach
  - Support Person (fellow recovery member, church friend, trusted person)
  - Custom (free-text label for contacts outside standard categories)

- **Contact name** (optional) — free-text, 50 char max
  - Not required — some users may prefer anonymity in their logs
  - If entered, name is saved for future quick-select

- **Connected** (required) — Did you actually talk?
  - Yes — a conversation happened
  - No — call attempted but no answer, voicemail left, or missed call
  - For outgoing calls: tracks both the effort of reaching out AND whether a conversation happened
  - For incoming calls: "No" would indicate a missed call the user is logging for awareness

- **Date and time** (default: now, editable for backdating)

- **Duration** (optional) — minutes (number input or quick-select: 5, 10, 15, 20, 30, 60)
  - Not required — the act of calling matters more than the length

- **Notes** (optional) — free-text, 500 char max, voice-to-text available
  - Suggested prompts (rotating placeholder text):
    - "What did you talk about?"
    - "How did you feel after the call?"
    - "What made you pick up the phone today?"
    - "Is there anything you need to follow up on?"

### Quick Log

- One-tap logging from Dashboard widget, Quick Action Shortcut, or notification
- Quick log records: direction (defaults to Made), contact type (defaults to last used), connected (defaults to Yes), timestamp
- User can expand the quick log entry afterward to add name, duration, and notes
- Quick log designed for post-call capture — log it right after you hang up

---

## Saved Contacts

- Users can save frequently called recovery contacts for faster logging:
  - Contact name
  - Contact type (Sponsor, Accountability Partner, etc.)
  - Phone number (optional — enables "Call Now" button that deep-links to phone dialer)
- Saved contacts appear as quick-select options during call logging
- Maximum 10 saved contacts
- Managed via Settings → Phone Calls → Saved Contacts
- Saved contacts are also accessible from the Emergency Tools overlay for crisis calls

---

## Call History

### List View

- Browse past call logs in reverse chronological order
- Each entry shows: direction icon (↗ Made / ↙ Received), contact type, contact name (if entered), connected status (✓ or ✗), date/time, duration (if logged)
- Tap any entry to view full details including notes
- Color coding: Connected calls in standard text; Attempted-but-not-connected calls in muted gray with "Attempted" label

### Filter & Search

- Filter by direction (Made / Received / Both)
- Filter by contact type
- Filter by connected status (Connected / Not Connected / Both)
- Filter by date range
- Search notes by keyword

### Calendar View

- Monthly calendar with indicators on days with logged calls
- Day indicators show: number of calls, connected vs. attempted
- Tap any day to view that day's call log entries

---

## Trends & Insights

### Call Frequency

- **Calls per day/week** — bar chart (7-day, 30-day, 90-day views)
  - Separate bars for Made vs. Received
  - Connected vs. Attempted breakdown within each bar

- **Weekly summary:**
  - Total calls this week (made + received)
  - Connection rate: X% of calls resulted in actual conversation
  - Most contacted person/type this week
  - Comparison to previous week

- **Monthly summary:**
  - Average calls per week this month
  - Contact type distribution (pie chart)
  - Direction distribution (Made vs. Received)

### Connection Rate

- Percentage of outgoing calls that resulted in actual conversation
- Tracked over time — "Your connection rate has improved from 60% to 82% over the last 30 days"
- Insight: "You're reaching out more AND connecting more. That's real growth."

### Contact Type Distribution

- Which types of support contacts the user calls most and least
- Balance indicator: "You've called your sponsor 12 times this month but your accountability partner only twice. Consider spreading your support."
- Gap detection: "You haven't called your counselor between sessions in 3 weeks"

### Correlation Insights

- "On days you make at least one phone call, your urge frequency is X% lower"
- "Your average check-in score is X points higher on days with phone contact"
- "The last 3 times you went 5+ days without a call, your FASTER Scale reached T (Ticked Off) within the following week"
- "You tend to make the most calls on Mondays and the fewest on Fridays"

### Isolation Warning

- If no calls logged for a user-configurable number of consecutive days (default: 3 days):
  - In-app prompt: "It's been X days since you last connected with someone by phone. Isolation is addiction's favorite weapon. Who could you call right now?"
  - Options: quick-dial saved contacts, open phone dialer, dismiss
  - Optionally shared with support network (configurable)

---

## Dashboard Widget

- Compact card on main Dashboard showing:
  - Today's call status: number of calls logged today (or "No calls yet today")
  - Current call streak (consecutive days with at least one call logged)
  - Quick actions: "Log a Call" button, "Call [Sponsor Name]" button (if saved contact exists)
- Tap widget header to open full Phone Calls screen

---

## Relationship to Person Check-ins

- **Phone Calls** and **Person Check-ins** are related but distinct activities:
  - **Phone Calls** tracks the act of calling — frequency, direction, connection rate, consistency
  - **Person Check-ins** tracks interpersonal check-in conversations — the substance and depth of the interaction
- A phone call and a person check-in can be logged from the same conversation, but they serve different purposes
- Cross-reference: "You logged a call with your sponsor today. Would you also like to log a person check-in?" (optional prompt, dismissible)
- Both feed into the Tracking System independently

---

## Integration Points

- Feeds into Tracking System (consecutive days with at least one call logged — connected or attempted)
- Feeds into Analytics Dashboard (call frequency, connection rate, contact distribution, correlation with recovery outcomes)
- Feeds into Weekly/Daily Goals — logging a call auto-checks a relational dynamic goal if one is set
- Feeds into Commitments tracking — if user has a "make X calls per day/week" commitment, call logs count toward fulfillment
- Linked from Urge Logging action plan — "Call My Sponsor" and "Text Accountability Partner" buttons; post-call prompt to log the call
- Linked from Emergency Tools overlay — crisis contact buttons deep-link to phone dialer; post-call prompt to log
- Saved contacts accessible from Emergency Tools for rapid crisis calling
- Linked from Person Check-ins — cross-reference prompt after logging a call
- Visible to support network (sponsor, counselor, coach) based on community permissions

---

## Notifications

- **Daily call reminder** (optional) — user-configured time, default: OFF
  - Suggested use: set for a time the user is likely free (lunch break, commute, evening)
  - Notification text: "Have you connected with someone today? A quick call can make all the difference."

- **Missed call streak nudge:** "You haven't logged a call in X days. Breaking isolation starts with one call. Who could you reach out to?" (sent after user-configured inactivity threshold, default: 3 days)

- **Streak milestone:** "X consecutive days of phone contact. Staying connected is one of the bravest things you can do in recovery."

- **Commitment reminder:** If user has a daily call commitment that hasn't been fulfilled by a certain time: "You haven't logged your daily call yet. Your sponsor is just a phone call away."

- All phone call notifications independently togglable in Settings

---

## Tone & Messaging

- Phone calls framed as lifelines — not obligations
- Helper text on first use: "Addiction thrives in isolation. Every phone call you make — even a short one — is an act of rebellion against the lie that you're alone. The point isn't what you talk about. The point is that you reached out."
- Post-log messages (rotating):
  - "Connected. That's what recovery looks like."
  - "Picking up the phone takes more courage than most people realize. Well done."
  - "You didn't isolate today. That matters more than you know."
  - "Even the calls that don't connect show that you're fighting for your recovery."
- Attempted-but-not-connected calls celebrated equally — the effort to reach out is the behavior being reinforced, not just the outcome
- No shaming for low call volume — gentle encouragement only

---

## Edge Cases

- User logs a call with no duration → Fully valid; duration is optional by design
- User logs a call as "Not Connected" → Still counts toward daily streak (the effort matters); connection rate tracked separately
- User receives a non-recovery call and wants to log it → Custom contact type allows logging any call the user considers meaningful to their recovery
- User makes multiple calls to the same person in one day → Each logged independently; all entries preserved
- User wants to log a text conversation instead of a phone call → Phone Calls activity is specifically for voice calls; text-based support interactions are captured via Person Check-ins or in-app messaging; helper text clarifies the distinction
- User backdates a call from yesterday → Backdating allowed; streak recalculated to include the original date
- User deletes a saved contact → Contact removed from quick-select; historical call logs referencing that contact are preserved
- Offline → Full logging available offline; synced when connection restored
