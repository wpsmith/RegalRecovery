+-----------------------------------------------------------------------+
| **FEATURE REQUIREMENTS DOCUMENT**                                     |
|                                                                       |
| **Time Journal (T-30 / T-60)**                                        |
|                                                                       |
| Recovery App Feature \| Accountability & Transparency Module          |
+-----------------------------------------------------------------------+

  ---------------- ------------------------------------------------------
  **Version**      1.0 --- Draft

  **Status**       For Review

  **Date**         April 2026

  **Audience**     Product, Engineering, UX, Clinical Advisors
  ---------------- ------------------------------------------------------

  -----------------------------------------------------------------------
  **1. Executive Summary**

  -----------------------------------------------------------------------

The Time Journal (T-30/T-60) is a structured accountability and
transparency tool used in sexual addiction recovery, originating from
the practices described in Worthy of Her Trust (Arterburn & Martinkus)
and aligned with Dr. Patrick Carnes\' 30 Task Model. It asks a person in
recovery to document their day in 30- or 60-minute increments ---
recording time, location, activity, people present, and emotional state.

This document defines the requirements for implementing a digital Time
Journal as a first-class feature within a recovery app. The feature must
serve two distinct but intertwined purposes:

-   Personal spiritual formation --- helping the user develop integrity,
    self-awareness, and honest self-examination.

-   Relational trust-building --- enabling proactive transparency with a
    spouse or accountability partner.

  -----------------------------------------------------------------------
  **Clinical Foundation** The Time Journal is not merely a log. Research
  and clinical practice position it as a spiritual discipline akin to the
  Puritan practice of self-examination --- forming character, combating
  intimacy aversion, and building the internal congruence that recovery
  requires.

  -----------------------------------------------------------------------

  -----------------------------------------------------------------------
  **2. Background & Research**

  -----------------------------------------------------------------------

**2.1 Origin of the Practice**

The T-30/T-60 Journal was popularized through Jason Martinkus\'s work at
Redemptive Living and the book Worthy of Her Trust (2014). Clinically,
it is positioned alongside Dr. Patrick Carnes\' 30 Task Model for sexual
addiction recovery, which includes \"Learn to be Accountable for
Actions\" as a core task --- keeping track of actions, thoughts, and
behaviors to increase awareness and accountability.

**2.2 Why Time Journaling Works**

The research basis and clinical rationale for time-based journaling in
addiction recovery includes the following mechanisms:

  ---------------------- ------------------------------------------------
  **Mechanism**          **How the Time Journal Addresses It**

  ---------------------- ------------------------------------------------

  ----------------------------------------------------------------------------
  **Recovery Mechanism**     **How the Time Journal Addresses It**
  -------------------------- -------------------------------------------------
  **Intimacy Aversion**      Forces the user to be truly known --- combating
                             the deep resistance to transparency that
                             underlies compulsive sexual behavior.

  **Compartmentalization**   Demands the same person on paper as in reality,
                             deconstructing the \"different versions\" that
                             addictive behavior thrives on.

  **Unaccounted Time**       Removes the mystery that fuels a betrayed
                             spouse\'s anxiety. Answers \"What were you doing
                             when I wasn\'t there?\" before it\'s asked.

  **Behavioral Patterns**    Eliminates vague timelines and gray areas that
                             previously enabled acting out or concealing
                             behavior.

  **Self-Awareness**         Regular check-in points throughout the day create
                             a natural barrier to acting out --- awareness
                             precedes change.

  **Character Formation**    Daily, meticulous documentation builds muscles of
                             humility, honesty, and diligence through small,
                             consistent choices.

  **Relational Trust**       Cumulative honest entries rebuild trust
                             incrementally --- the \"trust sculpture\" built
                             block by block over time.
  ----------------------------------------------------------------------------

**2.3 Five Core Keys from Clinical Practice**

From the T-30 Journal Template and Worthy of Her Trust, effective time
journaling requires five keys:

1.  \*\*Be Consistent\*\* --- Daily, non-negotiable entries.
    Inconsistency actively works against trust-building.

2.  \*\*Be Honest\*\* --- Truthful, detailed, and fully transparent.
    Half-truths are worse than no journal at all.

3.  \*\*Do it in Real-Time\*\* --- Documented as it happens, not
    reconstructed later.

4.  \*\*Include Emotions\*\* --- Rate feelings (e.g., \"anxious ---
    7/10\") to transform a data log into a tool for self-connection.

5.  \*\*Share Proactively\*\* --- The user offers the journal before
    being asked, with humility not defensiveness.

  -----------------------------------------------------------------------
  **3. User Personas**

  -----------------------------------------------------------------------

+-----------------------------------------------------------------------+
| **Primary User --- The Person in Recovery**                           |
+-----------------------------------------------------------------------+
| -   Adult (typically male, 25--55) working through sexual addiction   |
|     recovery.                                                         |
|                                                                       |
| -   May be court-ordered, in a treatment program, or self-directed    |
|     through a faith-based recovery community.                         |
|                                                                       |
| -   Resistant at first --- needs the app to lower friction and        |
|     provide motivation without shame.                                 |
|                                                                       |
| -   Needs real-time prompting because memory decays fast and          |
|     willingness to journal decreases over the day.                    |
|                                                                       |
| -   Values privacy but recognizes the need for accountability.        |
+-----------------------------------------------------------------------+

+-----------------------------------------------------------------------+
| **Trust Partner --- The Betrayed Spouse**                             |
+-----------------------------------------------------------------------+
| -   Partner (typically female) who has experienced sexual betrayal.   |
|                                                                       |
| -   Needs transparency without having to investigate or interrogate.  |
|                                                                       |
| -   May be skeptical of the journal\'s value --- needs to see         |
|     consistency over time.                                            |
|                                                                       |
| -   Should be able to view journal without any friction, at any time, |
|     without the user\'s active involvement.                           |
|                                                                       |
| -   Needs to be able to ask questions in a structured, low-conflict   |
|     format.                                                           |
+-----------------------------------------------------------------------+

+-----------------------------------------------------------------------+
| **Clinical Partner --- Counselor or Sponsor**                         |
+-----------------------------------------------------------------------+
| -   Licensed therapist (CSAT) or 12-step sponsor providing            |
|     accountability structure.                                         |
|                                                                       |
| -   Needs aggregate visibility --- patterns, completion rates,        |
|     emotional trends --- rather than reading every entry.             |
|                                                                       |
| -   May assign the journal as part of a formal treatment plan.        |
|                                                                       |
| -   Needs export functionality for session prep.                      |
+-----------------------------------------------------------------------+

  -----------------------------------------------------------------------
  **4. Feature Goals & Success Metrics**

  -----------------------------------------------------------------------

**4.1 Feature Goals**

-   Enable low-friction, real-time daily journaling in 30 or 60-minute
    increments.

-   Capture the five core entry components: time, location, activity,
    people, and emotional state.

-   Remind and prompt without being punitive --- reducing the activation
    energy to journal.

-   Provide proactive, graceful sharing with a designated partner
    (spouse, sponsor, counselor).

-   Visualize consistency and streaks to reinforce the habit of
    integrity.

-   Protect user data with appropriate privacy controls while enabling
    transparent partner access.

-   Support the clinical journey --- integrated with sobriety tracking,
    check-ins, and counselor review.

**4.2 Success Metrics**

  ------------------------------------------------------------------------
  **Metric**            **Definition**              **Target**
  --------------------- --------------------------- ----------------------
  **Journal Adoption    \% of active users          70% within first 30
  Rate**                completing at least 1       days
                        entry/day                   

  **Daily Completion    Average % of slots filled   ≥ 75% average for
  Score**               per day                     active users

  **Streak Retention**  \% of users maintaining a   50% of active users
                        7-day streak                after 14 days

  **Partner             \% of shared journals with  40% in first 90 days
  Engagement**          at least 1 partner          
                        interaction per week        

  **Retroactive Entry   \% of entries filled        \< 25% retroactive
  Rate**                same-day vs. retroactive    

  **Emotion Field       \% of entries that include  ≥ 60% of entries
  Usage**               at least one emotion        

  **Notification        \% of interval reminders    ≥ 40%
  Response Rate**       that result in an entry     
                        within 15 min               
  ------------------------------------------------------------------------

  -----------------------------------------------------------------------
  **5. Functional Requirements**

  -----------------------------------------------------------------------

  -----------------------------------------------------------------------
  **Priority Key** P0 = Must Have (Launch Blocker) P1 = Should Have
  (Phase 1) P2 = Nice to Have (Phase 2+)

  -----------------------------------------------------------------------

**5.1 Journal Entry Creation**

**Core Entry Fields**

Each entry corresponds to a 30- or 60-minute time slot and must capture:

  -------------------------------------------------------------------------------
  **Req     **Priority**   **Description**
  ID**                     
  --------- -------------- ------------------------------------------------------
  TJ-001    P0             **Time Slot** --- Auto-populated with current
                           30/60-min block; user can adjust.

  TJ-002    P0             **Location** --- Free-text or quick-select from
                           recent/saved locations (e.g., \@home, \@work,
                           \@church).

  TJ-003    P0             **Activity** --- Free-text description of what the
                           user was doing. Supports multi-line.

  TJ-004    P0             **People** --- Names and genders of people interacted
                           with. App should prompt if field is empty for a long
                           entry.

  TJ-005    P0             **Emotion(s)** --- Emotion picker with intensity
                           slider (1--10). Supports multiple emotions per entry.
                           Includes the \"three I\'s\" (insignificance,
                           incompetence, impotence) as quick-select options.

  TJ-006    P1             **Extras / Flags** --- Optional structured fields:
                           financial transactions, screen-time events, notable
                           interactions. Configurable by user or counselor.

  TJ-007    P1             **Entry Mode** --- Toggle between T-30 (48 slots/day)
                           and T-60 (24 slots/day).

  TJ-008    P1             **Sleep / Inactive Flag** --- Mark a block as
                           \"sleeping\" or \"unavailable\" so gaps are
                           intentional, not suspicious.
  -------------------------------------------------------------------------------

**Entry Workflow**

  -------------------------------------------------------------------------------
  **Req     **Priority**   **Description**
  ID**                     
  --------- -------------- ------------------------------------------------------
  TJ-009    P0             **Real-Time Entry Prompt** --- Push notification at
                           each interval boundary (configurable). Tapping opens a
                           minimal entry card.

  TJ-010    P0             **Quick Entry Card** --- A 3-tap minimum entry:
                           location, activity (voice or text), one emotion.
                           Expandable for full detail.

  TJ-011    P0             **Retroactive Entry** --- User can tap any past
                           unfilled slot and complete it, with a visual indicator
                           marking it as retroactive (\"filled later\").

  TJ-012    P1             **Voice-to-Text** --- Dictation support for activity
                           and people fields to reduce friction.

  TJ-013    P1             **Carry-Forward** --- If location hasn\'t changed,
                           pre-fill location from the prior slot.

  TJ-014    P2             **Calendar Import** --- Optionally import calendar
                           events into the corresponding time slots as activity
                           stubs.
  -------------------------------------------------------------------------------

**5.2 Daily Journal View**

  -------------------------------------------------------------------------------
  **Req     **Priority**   **Description**
  ID**                     
  --------- -------------- ------------------------------------------------------
  TJ-015    P0             Full 24-hour timeline view with all 48 (T-30) or 24
                           (T-60) time slots displayed.

  TJ-016    P0             Slots visually differentiated: **Filled** (solid
                           color), **Retroactive** (dashed outline), **Empty**
                           (gray), **Flagged/Sensitive** (accent color).

  TJ-017    P0             Tap any slot to view or edit the entry.

  TJ-018    P1             Day completion indicator showing % of slots filled.

  TJ-019    P1             **Emotion timeline** --- Horizontal graph showing
                           emotional intensity across the day.

  TJ-020    P2             **Daily summary** --- Auto-generated brief summary of
                           patterns (e.g., \"High stress 2--4pm. 3 retroactive
                           entries.\").
  -------------------------------------------------------------------------------

**5.3 Sharing & Partner Access**

This is the most clinically sensitive feature area. The principle from
the T-30 Template is unambiguous: the partner can view the journal
whenever, wherever, however they want --- without requiring the user\'s
permission.

  -------------------------------------------------------------------------------
  **Req     **Priority**   **Description**
  ID**                     
  --------- -------------- ------------------------------------------------------
  TJ-021    P0             **Partner Designation** --- User designates one or
                           more \"Trust Partners\" (spouse, counselor, sponsor)
                           who receive shared access.

  TJ-022    P0             **Real-Time Share** --- New entries are automatically
                           shared with Trust Partners as they are saved. No
                           manual \"send.\"

  TJ-023    P0             **Partner Read-Only Access** --- Trust Partners can
                           view the full journal but cannot edit entries.

  TJ-024    P0             **Partner Notification** --- Trust Partner receives a
                           push/email notification when a new day\'s journal
                           begins and when the day is \"closed.\"

  TJ-025    P0             **No Permission Gate** --- Trust Partners never need
                           to request access or get approval to view an entry.

  TJ-026    P1             **Proactive Share Prompt** --- At end-of-day, prompt
                           the user: \"Would you like to send today\'s summary to
                           \[Partner\]?\" with options for a note.

  TJ-027    P1             **Discussion Thread** --- Trust Partner can leave
                           questions or reactions on specific entries; user
                           receives these and can respond. Not a chat; structured
                           around specific entries.

  TJ-028    P1             **Export to PDF** --- Generate a printable/shareable
                           daily or weekly journal PDF for counseling sessions.

  TJ-029    P2             **Counselor Dashboard** --- Separate limited-scope
                           view for clinicians: pattern trends, consistency
                           score, flagged entries --- without full diary access
                           unless explicitly granted.
  -------------------------------------------------------------------------------

**5.4 Consistency & Habit Tracking**

  -------------------------------------------------------------------------------
  **Req     **Priority**   **Description**
  ID**                     
  --------- -------------- ------------------------------------------------------
  TJ-030    P0             **Streak Counter** --- Days of consecutive journaling
                           (at least 80% of slots filled) displayed prominently.

  TJ-031    P0             **Completion Score** --- Daily score shown as a
                           percentage or ring. Shared with Trust Partners.

  TJ-032    P1             **Weekly & Monthly Heatmap** --- Calendar view
                           color-coded by daily completion percentage.

  TJ-033    P1             **Gap Alerts** --- If the user hasn\'t filled a slot
                           in more than 90 minutes during waking hours, send a
                           gentle nudge.

  TJ-034    P1             **Milestones** --- Celebrate 7, 30, 60, 90, 180,
                           365-day streaks with in-app affirmation (clinically
                           framed, not gamified).

  TJ-035    P2             **Relapse Impact Visualization** --- If a recovery
                           setback is logged, show how the journal streak can be
                           maintained as a separate discipline (the journal
                           continues even on hard days).
  -------------------------------------------------------------------------------

**5.5 Reminders & Notifications**

  -------------------------------------------------------------------------------
  **Req     **Priority**   **Description**
  ID**                     
  --------- -------------- ------------------------------------------------------
  TJ-036    P0             Configurable interval reminder (every 30 or 60 min)
                           during user-set waking hours (e.g., 6am--10pm).

  TJ-037    P0             \"Do Not Disturb\" mode for meetings, worship, etc.
                           --- silences reminders for a set period without losing
                           the slot.

  TJ-038    P1             Smart reminder dampening --- if the user has been
                           filling entries consistently, reduce reminder
                           frequency. If gaps appear, increase.

  TJ-039    P1             End-of-day reminder to review and share the journal.

  TJ-040    P2             Wearable integration --- vibration-only prompts from
                           smartwatch without displaying notification content.
  -------------------------------------------------------------------------------

**5.6 Emotional Awareness Tools**

  -------------------------------------------------------------------------------
  **Req     **Priority**   **Description**
  ID**                     
  --------- -------------- ------------------------------------------------------
  TJ-041    P0             Emotion library with at least 40 named emotions
                           including anger, shame, guilt, loneliness, fear, joy,
                           gratitude, and the three I\'s.

  TJ-042    P0             Intensity rating per emotion (1--10 slider).

  TJ-043    P1             \"Why\" prompt --- optional one-line context for each
                           emotion (e.g., \"Felt incompetent --- my boss
                           dismissed my idea.\").

  TJ-044    P1             **Emotional pattern insights** --- weekly report
                           showing most frequent emotions, peak intensity times,
                           and any correlations with acting-out history (opt-in).

  TJ-045    P2             **Emotion re-evaluation** --- Prompt at end-of-day to
                           revisit entries with strong emotions and consider what
                           was underneath (e.g., anger may mask shame or fear).
  -------------------------------------------------------------------------------

**5.7 Integrity & Honesty Prompts**

The journal should periodically challenge the user\'s honesty --- a core
feature of the T-30 methodology.

  -------------------------------------------------------------------------------
  **Req     **Priority**   **Description**
  ID**                     
  --------- -------------- ------------------------------------------------------
  TJ-046    P1             Random integrity check-in prompts (e.g., \"Is there
                           anything in today\'s journal you\'re tempted to leave
                           out?\").

  TJ-047    P1             On journal submission, display: \"Are you satisfied
                           this entry reflects the whole truth --- including
                           what\'s uncomfortable?\"

  TJ-048    P1             Optional \"Redline\" field --- a confidential note to
                           self that is NOT shared with Trust Partners, allowing
                           raw internal honesty as a drafting layer before the
                           shared entry.

  TJ-049    P2             **Confession assist** --- If user flags an entry as
                           \"I need to add more,\" surface it at end of day with
                           a prompt to expand.
  -------------------------------------------------------------------------------

**5.8 Privacy & Security**

  -------------------------------------------------------------------------------
  **Req     **Priority**   **Description**
  ID**                     
  --------- -------------- ------------------------------------------------------
  TJ-050    P0             End-to-end encryption for all journal content.

  TJ-051    P0             Biometric or PIN lock to open the journal app.

  TJ-052    P0             Trust Partner access is revocable at any time by the
                           user --- but revocation is logged and visible to the
                           counselor.

  TJ-053    P0             No data is ever used for advertising or analytics
                           beyond clinical and product improvement purposes (with
                           explicit consent).

  TJ-054    P1             \"Sensitive entry\" flag --- marks a specific slot so
                           it is blurred (but not hidden) when Trust Partner
                           views. Counselor can see flagged count.

  TJ-055    P1             Data retention policy: user can export full journal
                           history; deletion requires counselor or sponsor
                           co-acknowledgment.
  -------------------------------------------------------------------------------

  -----------------------------------------------------------------------
  **6. Non-Functional Requirements**

  -----------------------------------------------------------------------

  -------------------------------------------------------------------------------
  **Req     **Priority**   **Description**
  ID**                     
  --------- -------------- ------------------------------------------------------
  NFR-001   P0             **Performance** --- Entry save must complete in under
                           500ms. Timeline view must load in under 1 second.

  NFR-002   P0             **Offline First** --- All journaling must work without
                           a network connection. Sync when connectivity resumes.

  NFR-003   P0             **Accessibility** --- WCAG 2.1 AA compliance. Large
                           text support. VoiceOver/TalkBack compatible.

  NFR-004   P0             **Cross-Platform** --- iOS and Android. Responsive
                           design for tablets (counselor use).

  NFR-005   P1             **Clinical Tone** --- UI copy reviewed by a licensed
                           CSAT (Certified Sex Addiction Therapist). No shaming,
                           gamification, or punitive language.

  NFR-006   P1             **Dark Mode** --- Especially important for late-night
                           journaling to reduce screen strain and privacy.

  NFR-007   P1             **Data Portability** --- Full journal history
                           exportable as PDF or CSV at any time.
  -------------------------------------------------------------------------------

  -----------------------------------------------------------------------
  **7. UX Design Principles**

  -----------------------------------------------------------------------

The Time Journal UX must balance two competing tensions: the need for
thorough documentation (which can feel burdensome) and the need for
low-friction habit formation (which requires simplicity). The following
principles guide design decisions.

+---+---------------------------------------------------------------------+
|   | **Minimum Viable Entry First**                                      |
|   |                                                                     |
|   | The quick-entry card (location + activity + one emotion in \< 30    |
|   | seconds) should always be available. Full detail is invited but     |
|   | never required per entry.                                           |
+---+---------------------------------------------------------------------+

+---+---------------------------------------------------------------------+
|   | **Transparency, Not Surveillance**                                  |
|   |                                                                     |
|   | No GPS tracking, phone monitoring, or automated verification. The   |
|   | integrity of the journal comes from the user\'s own honesty, not    |
|   | external enforcement.                                               |
+---+---------------------------------------------------------------------+

+---+---------------------------------------------------------------------+
|   | **Clinically Neutral Tone**                                         |
|   |                                                                     |
|   | No streak-breaking shame language. If a user misses a day, the      |
|   | response is gentle: \"Restart today. Progress, not perfection.\"    |
+---+---------------------------------------------------------------------+

+---+---------------------------------------------------------------------+
|   | **Privacy by Default, Sharing by Design**                           |
|   |                                                                     |
|   | Partner access is powerful and always-on --- but the UI makes it    |
|   | clear that sharing is a gift the user gives, not a cage they\'re    |
|   | in.                                                                 |
+---+---------------------------------------------------------------------+

+---+---------------------------------------------------------------------+
|   | **Time Is the Resource**                                            |
|   |                                                                     |
|   | Minimize the time-to-entry. Every additional second of friction     |
|   | reduces compliance. Keyboard shortcuts, voice, carry-forward, and   |
|   | smart defaults are essential.                                       |
+---+---------------------------------------------------------------------+

+---+---------------------------------------------------------------------+
|   | **Emotion as Signal, Not Performance**                              |
|   |                                                                     |
|   | The emotion fields must feel safe and clinical --- not like the     |
|   | user is performing recovery for an audience. Emotion data is        |
|   | primarily for the user\'s own self-awareness.                       |
+---+---------------------------------------------------------------------+

  -----------------------------------------------------------------------
  **8. Integration with Recovery App Ecosystem**

  -----------------------------------------------------------------------

The Time Journal does not stand alone. It is one of several
interconnected recovery disciplines. The following integrations
strengthen the feature\'s clinical value.

  -------------------------------------------------------------------------------
  **Req     **Priority**   **Description**
  ID**                     
  --------- -------------- ------------------------------------------------------
  INT-001   P1             **Sobriety Counter** --- If user logs a relapse/slip
                           in the recovery check-in, the journal for that day is
                           flagged for counselor review. Journal streak remains
                           separate from sobriety date.

  INT-002   P1             **Daily Check-In** --- Morning check-in prompt
                           surfaces the journal and asks the user to set an
                           intention for transparency.

  INT-003   P1             **Accountability Partner Messaging** --- When user
                           shares the journal, they can append a personal note
                           and invite a voice/text conversation.

  INT-004   P1             **Recovery Plan** --- Counselor can assign Time
                           Journal as a required daily task tied to a treatment
                           plan, with visibility into completion.

  INT-005   P2             **Trigger Log** --- If user logs a trigger or craving,
                           the corresponding time slot in the journal is
                           pre-linked, making it easy to document the full
                           context.

  INT-006   P2             **Group Accountability** --- Anonymous aggregate
                           consistency data can be shared in a group setting
                           (e.g., \"4 of 6 group members journaled every day this
                           week\").
  -------------------------------------------------------------------------------

  -----------------------------------------------------------------------
  **9. Addressing Common User Objections**

  -----------------------------------------------------------------------

The T-30 Template identifies specific objections users raise. The app
must be designed to preempt or gracefully address each.

  -----------------------------------------------------------------------
  **Objection**          **App Design Response**
  ---------------------- ------------------------------------------------
  **\"This feels like    Frame the journal as freedom training, not
  punishment.\"**        penance. Onboarding uses language from the T-30
                         Template: journaling transparently means nothing
                         in your life can be used against you.

  **\"I don\'t have      Quick-entry card designed for \< 30 seconds. The
  time.\"**              app surfaces the time the user already \"has\"
                         (bathroom breaks, commute waits, etc.) as
                         journaling moments.

  **\"I can\'t remember  Smart notifications, carry-forward location, and
  every 30 minutes.\"**  voice entry eliminate memory as an excuse.
                         Retroactive entry is supported with a visual
                         indicator.

  **\"How can she trust  Onboarding teaches that the journal\'s primary
  what I write?\"**      value is personal integrity --- trust with the
                         partner follows from trust with oneself. The app
                         reflects this hierarchy.

  **\"This feels         Acknowledge this honestly. A brief contextual
  invasive.\"**          tooltip: \"If trust has been broken, privacy is
                         rebuilt through transparency --- not the other
                         way around.\"

  **\"It\'s a waste of   Consistency graph and long-term streak
  time.\"**              visualization help the user see the cumulative
                         value. Partner engagement data (questions asked,
                         reactions) shows the relational return.
  -----------------------------------------------------------------------

  -----------------------------------------------------------------------
  **10. Out of Scope (Phase 1)**

  -----------------------------------------------------------------------

-   AI-generated journal entries or auto-fill based on phone
    activity/location data.

-   Automated verification of journal entries against GPS, calendar, or
    phone usage.

-   Public or community sharing of journal content.

-   Integration with external therapist EHR/EMR systems (Phase 3+).

-   Couples journaling or joint entries.

  -----------------------------------------------------------------------
  **Note** GPS or phone-usage cross-referencing was explicitly considered
  and excluded. The journal\'s value is in the act of honest
  self-documentation, not surveillance. Automated verification would
  undermine the spiritual formation purpose and raise significant privacy
  concerns.

  -----------------------------------------------------------------------

  -----------------------------------------------------------------------
  **11. Glossary**

  -----------------------------------------------------------------------

  ---------------- ------------------------------------------------------
  **T-30 / T-60**  Time Journal format where activities are logged every
                   30 minutes (T-30) or 60 minutes (T-60) throughout the
                   day.

  **Trust          A designated individual (spouse, sponsor, counselor)
  Partner**        who has read-only access to the user\'s journal.

  **Proactive      Sharing the journal before being asked --- a core
  Transparency**   behavioral goal of the tool.

  **The Three      Insignificance, Incompetence, Impotence --- emotional
  I\'s**           states clinically associated with sexual addiction
                   cycles. Featured as quick-select emotions.

  **Completion     Percentage of time slots filled in a given day, used
  Score**          as a consistency metric.

  **CSAT**         Certified Sex Addiction Therapist --- a licensed
                   clinician with specialized training in compulsive
                   sexual behavior.

  **Coram Deo**    Latin: \"before the face of God.\" A theological
                   concept in the PDF emphasizing transparent living as a
                   spiritual discipline.

  **Trust          Metaphor from Worthy of Her Trust describing trust as
  Sculpture**      rebuilt block-by-block through consistent, honest
                   behavior over time.

  **Integrity**    From the root word \"integer\" --- wholeness. Being
                   the same person in all contexts, with no
                   compartmentalization.
  ---------------- ------------------------------------------------------

  -----------------------------------------------------------------------
  **12. Revision History**

  -----------------------------------------------------------------------

  ------------- ---------- --------------- -------------------------------------
  **Version**   **Date**   **Author**      **Description**

  1.0           April 2026 Product Team    Initial draft based on T-30 Journal
                                           Template PDF and clinical research.
  ------------- ---------- --------------- -------------------------------------

--- End of Document ---