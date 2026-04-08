FEATURE REQUIREMENTS DOCUMENT

**Affirmations Experience**

Sexual Addiction Recovery App

  ------------------ ----------------------------------------------------
  **Document         1.0 --- Initial Release
  Version**          

  **Status**         Draft --- Ready for Review

  **Audience**       Product, Engineering, Clinical Advisory

  **Research Basis** Carnes addiction model, Cascio et al. (2016) fMRI
                     studies, Wood et al. (2009) backfire research, CSAT
                     clinical guidelines, competitive analysis of
                     Fortify, Brainbuddy, Relay, I Am Sober, ThinkUp
  ------------------ ----------------------------------------------------

> *CLINICAL NOTICE: This feature is designed as a supplemental recovery
> tool. It is not a substitute for professional treatment. All clinical
> content decisions should be reviewed by a Certified Sexual Addiction
> Therapist (CSAT) before release.*

**1. Overview & Purpose**

**1.1 Feature Summary**

The Affirmations Experience is a structured daily practice that helps
users in sexual addiction recovery rebuild identity, reduce shame, and
rewire distorted core beliefs through progressive, clinically calibrated
self-affirmation. It is the primary active recovery activity in the
app\'s daily routine.

Unlike generic affirmation tools, this feature is architecturally
designed around three research findings:

-   **The backfire risk:** Users with low self-esteem --- the defining
    characteristic of sexual addiction --- feel worse when exposed to
    overly aspirational affirmations (Wood, Perunovic & Lee, 2009). The
    feature must never lead with identity-level statements.

-   **Shame is the engine:** Carnes\' four core beliefs drive the
    addiction cycle. Every affirmation is mapped to counter at least one
    of these beliefs directly.

-   **Neural evidence:** Cascio et al. (2016) demonstrated that
    self-affirmation activates the ventral striatum and VMPFC --- the
    brain\'s reward and self-valuation systems --- and that this neural
    activity predicts behavior change (p = .030).

**1.2 Feature Goals**

-   Provide a daily affirmation practice calibrated to the user\'s
    recovery stage

-   Progressively rebuild identity by countering Carnes\' four distorted
    core beliefs

-   Reduce shame-based rumination without triggering toxic positivity or
    backfire

-   Integrate with the app\'s broader recovery ecosystem (mood tracking,
    urge reporting, journaling, sobriety counter)

-   Deliver an SOS affirmation response during active urge moments

-   Maintain absolute privacy in every design and notification decision

**1.3 What This Feature Is Not**

-   A substitute for therapy, group support, or professional treatment

-   A passive content feed --- every interaction should require
    intentional user engagement

-   A streak-based gamification system that can fail and create shame

-   A one-size-fits-all content library --- content must adapt to
    recovery stage

**2. Clinical Foundation**

**2.1 Carnes\' Four Core Beliefs --- Content Mapping**

All affirmation content must map to countering at least one of the four
core distorted beliefs identified by Dr. Patrick Carnes as the
psychological architecture of sexual addiction:

  ------------------------------------------------------------------------
  **Core Belief**     **Manifestation**        **Affirmation Direction**
  ------------------- ------------------------ ---------------------------
  \"I am basically a  Core shame;              Self-worth, identity
  bad, unworthy       identity-level           repair, separating behavior
  person\"            self-condemnation        from personhood

  \"No one would love Secrecy, double life,    Worthiness of love,
  me as I am\"        fear of true intimacy    authenticity, relational
                                               safety

  \"My needs are      Isolation, avoidance,    Healthy connection, asking
  never met by        turning to fantasy       for help, trusting others
  depending on                                 
  others\"                                     

  \"Sex is my most    Sex as primary coping    Expanding needs, healthy
  important need\"    mechanism                pleasure, purpose beyond
                                               sex
  ------------------------------------------------------------------------

**2.2 Progressive Affirmation Framework**

The most critical clinical design constraint: never serve identity-level
\"I am\" affirmations to users in early recovery. Research shows these
backfire for low-self-esteem populations. Use a four-level progression:

  -------------------------------------------------------------------------
  **Level**   **Type**      **Example**               **When to Use**
  ----------- ------------- ------------------------- ---------------------
  1           Permission    \"It is OK for me to talk Days 1--30;
                            to others about what I    post-relapse;
                            think and feel.\"         onboarding

  2           Process       \"I am working my         Days 14--90; stable
                            recovery. I am striving   early recovery
                            for progress, not         
                            perfection.\"             

  3           Tempered      \"I have done bad things, Days 60+; consistent
              Identity      but I am not a bad        engagement
                            person.\"                 

  4           Full Identity \"I am worthy of love and Established recovery;
                            acceptance, exactly as I  therapist-confirmed
                            am.\"                     readiness
  -------------------------------------------------------------------------

> Design rule: Users should always be able to manually choose a lower
> level. Never lock users into higher levels based on time alone.
> Resistance to a specific affirmation is clinically informative ---
> track and surface to the user\'s support network if consented.

**2.3 Contraindications & Escalation Triggers**

The affirmation feature must detect and respond to the following risk
signals:

-   **Worsening mood after practice:** If a user reports mood decline
    for 3+ consecutive sessions, surface a prompt to connect with a
    therapist or sponsor.

-   **Post-relapse window:** Within 24 hours of a reported relapse,
    limit affirmation level to Level 1 only and append a compassionate
    grounding message.

-   **Acute crisis language:** If mood check-in contains crisis
    language, bypass affirmations entirely and route directly to crisis
    resources.

-   **Persistent content rejection:** If a user hides 5+ affirmations in
    a single session, flag for self-review and optionally prompt about
    connecting with a therapist.

**3. Content Library Requirements**

**3.1 Library Specifications**

-   Minimum 200 curated affirmations at launch; 400+ at v2

-   Every affirmation must be tagged with: Level (1--4), Core Belief
    addressed (1--4), Category, Recovery Stage, and Track (Standard /
    Faith-Based)

-   Affirmations authored and reviewed by at least one CSAT before
    content launch

-   Plain language: maximum 8th-grade reading level; no clinical jargon

-   Present-tense framing required (\"I am,\" \"I choose,\" \"I have\")
    --- no future aspirational framing (\"I will be\")

-   Positive framing only --- no negation (\"I am free from\...\" is
    acceptable; \"I am not addicted\" is not)

**3.2 Content Categories**

  ---------------------------------------------------------------------------------
  **Category**             **Min     **Levels**   **Clinical Focus**
                           Count**                
  ------------------------ --------- ------------ ---------------------------------
  Self-Worth & Identity    30        1--4         Counters core belief #1 (\"I am
                                                  bad\")

  Shame Resilience         25        1--3         Separates behavior from
                                                  personhood; self-forgiveness

  Healthy Relationships    25        2--4         Counters core belief #2 (\"No one
                                                  would love me\")

  Connection & Asking for  20        1--3         Counters core belief #3
  Help                                            (isolation)

  Emotional Regulation     20        1--3         Coping with cravings, triggers,
                                                  difficult emotions

  Purpose & Meaning        20        2--4         Counters core belief #4; expands
                                                  identity beyond addiction

  Integrity & Honesty      20        2--4         Rebuilding core character;
                                                  recovery lifestyle

  Daily Strength           20        1--2         Present-moment grounding; \"one
                                                  day at a time\" framing

  Healthy Sexuality        15        3--4         Therapist-reviewed; integrated at
                                                  mid-recovery only

  SOS / Crisis             25        1--2         Emergency delivery during active
                                                  urge moments
  ---------------------------------------------------------------------------------

> *Healthy Sexuality affirmations (Category 9) must not be surfaced
> until the user has at least 60 days logged and has explicitly enabled
> this category. Default: OFF. This category requires a dedicated CSAT
> review cycle separate from other content.*

**3.3 Faith-Based Track**

A distinct content track is required for users who identify with a
spiritual or faith-based recovery approach (e.g., SA/SAA 12-Step
programs). Requirements:

-   Parallel library of equivalent affirmations in faith-based language

-   Opt-in at onboarding; switchable in settings at any time

-   Default: Standard (secular) track

-   Faith-based content should not assume a specific denomination ---
    use broadly inclusive spiritual language (\"Higher Power,\" \"God as
    I understand God\")

**4. Core Feature Requirements**

**4.1 Daily Practice --- Morning Session**

The morning session is the primary affirmation touchpoint. It should
feel like a mindful ritual, not an app notification to dismiss.

-   **Delivery time:** User-selected delivery time, set during
    onboarding. Adjustable in settings at any time.

-   **Session structure:** Three affirmations shown sequentially (one
    card per screen), followed by a Daily Intention prompt.

-   **Level logic:** Cards served from the user\'s current Level (1--4)
    with 80% same-level, 20% one level above to encourage gradual
    growth.

-   **Daily Intention prompt:** After the three affirmations, the user
    completes a short sentence stem: \"Today I choose to\...\" This is
    stored in their journal and surfaced in the evening reflection.

-   **Estimated time:** 3--5 minutes for the full session.

-   **Skip behavior:** Sessions can be skipped without penalty. No
    streak counter visible during or after skipping. Skipped sessions
    are logged internally only.

**4.2 Daily Practice --- Evening Reflection**

-   **Delivery time:** User-selected time; default 9:00 PM.

-   **Session structure:** One affirmation (calming, identity-level
    appropriate) displayed alongside their morning intention. User rates
    their day on a 1--5 scale. Optional: free-text reflection.

-   **Framing:** Compassionate, non-evaluative. Language like \"How did
    today feel?\" not \"Did you stay sober today?\"

-   **Mood data use:** The 1--5 rating populates mood trend charts
    visible in the Insights section.

-   **Audio option:** Evening affirmation can be set to auto-play as
    calming audio with ambient background sound.

**4.3 SOS Mode --- Urge Response**

SOS Mode is activated when the user reports an active urge. This is the
highest-stakes affirmation delivery context. Speed, calm, and clinical
precision matter most.

-   **Trigger:** User taps the SOS / Urge button from any app screen.

-   **Immediate response (0--5 seconds):** A full-screen calm UI. No
    notifications to other users yet. Display one Level 1 or 2
    affirmation from the SOS category, paired with a 4-7-8 breathing
    exercise animation.

-   **After breathing exercise:** Surface two additional affirmations.
    Offer: \"Reach out to your accountability partner\" button.

-   **Content selection:** SOS affirmations must never be above Level 2
    regardless of user\'s progress. Present-moment grounding is the
    clinical priority.

-   **Post-SOS check-in:** 10 minutes after SOS session ends, a gentle
    in-app notification asks: \"How are you feeling now?\" This is the
    only follow-up. No judgment language.

-   **Privacy:** SOS activation is never surfaced to accountability
    partners without the user\'s explicit confirmation after the
    breathing exercise.

**4.4 Affirmation Library --- Browse & Curate**

-   **Full library access:** Users can browse the complete library
    filtered by Category, Level, or search by keyword.

-   **Favorites:** Users can heart any affirmation to add it to their
    personal Favorites collection, which is prioritized in daily
    sessions.

-   **Hide:** Users can hide any affirmation with one tap. Hidden
    affirmations are never surfaced again. No explanation required.

-   **Hidden affirmation insight:** After hiding 3+ affirmations, offer
    a non-intrusive prompt: \"Sometimes the affirmations that feel most
    wrong point to where healing is needed. You might want to explore
    this with a therapist.\" --- Dismissible, shown once per week
    maximum.

**4.5 Custom Affirmation Creation**

-   **Access:** Available from Day 14 onward (users need a foundation of
    curated content first).

-   **Directed abstraction prompts:** The creation flow offers
    evidence-based prompts to generate personal affirmations:
    \"Something I did well today was \_\_\_. This shows I am\...\"

-   **Formatting guidance:** Real-time tips: present tense, positive
    framing, believable language. Examples provided.

-   **Validation:** Custom affirmations are not reviewed by staff ---
    make this clear. A gentle clinical note: \"Your own words carry
    extra power. Make sure this feels true to you --- even partially ---
    right now.\"

-   **Custom affirmations in rotation:** After saving, users choose
    whether to include custom affirmations in their daily practice
    alongside curated ones.

**4.6 Own-Voice Audio Recording**

-   **Core functionality:** Users can record any affirmation in their
    own voice with optional ambient background music (nature sounds,
    soft tones --- 5 preset options).

-   **Research basis:** Users consistently report that hearing
    affirmations in their own voice produces a qualitatively different
    therapeutic experience than text or third-party audio.

-   **Recording flow:** Select affirmation → Choose background → Tap to
    record → Preview → Save.

-   **Playback:** Recordings play in morning/evening sessions when
    selected as favorites. Manual playback available any time.

-   **CRITICAL privacy requirement:** Audio must auto-pause immediately
    when Bluetooth/wired headphones disconnect. This is a non-negotiable
    safety feature --- personal recordings playing on speaker in public
    is a serious disclosure risk.

-   **Storage:** Audio files stored locally on-device only. Not synced
    to cloud without explicit opt-in. Not shared with accountability
    partners.

**5. Progress Tracking & Gamification**

**5.1 Design Principle: Cumulative, Not Streak-Based**

Streak-based gamification is contraindicated in sexual addiction
recovery. A broken streak notification can trigger the exact shame
spiral that fuels the addiction cycle. All progress mechanics must use
cumulative totals rather than consecutive-day counting.

> *Never show: \"You broke your 14-day streak.\" Always show: \"You have
> completed 47 affirmation sessions --- that is 47 moments you chose
> recovery.\"*

**5.2 Approved Progress Metrics**

  -----------------------------------------------------------------------
  **Metric**                  **Display Approach**
  --------------------------- -------------------------------------------
  Total sessions completed    Cumulative count. Prominent on the home
                              screen.

  Total affirmations          Cumulative count. Home screen.
  practiced                   

  Days since last session     Shown only as a gentle re-engagement signal
                              after 3+ days gap. Never as failure
                              language.

  Practice consistency (last  Visual calendar heat map --- darker color =
  30 days)                    more sessions. No empty-day callouts.

  Mood trend over time        Line chart of evening ratings, averaged
                              weekly.

  Favorite affirmations count Shown as personal library size. Encouraging
                              framing.
  -----------------------------------------------------------------------

**5.3 Milestone Acknowledgments**

Celebrate cumulative milestones with brief, warm in-app moments (not
push notifications). Example milestones:

-   First session completed

-   10th, 25th, 50th, 100th, 250th session

-   First custom affirmation created

-   First audio recording saved

-   First SOS session completed (\"Coming back in a hard moment is
    courage.\")

Milestone messages must use growth-mindset framing. Avoid superlatives
(\"amazing,\" \"perfect\"). Prefer: \"That is real work. You showed
up.\"

**5.4 Re-Engagement After a Gap**

-   **After 3 days without a session:** Home screen shows a gentle
    prompt: \"Ready when you are. Here is one affirmation for right
    now.\" --- single affirmation card, no session pressure.

-   **After 7 days:** Soft in-app message: \"Coming back is an act of
    courage. No catching up needed.\" --- Option to restart with a fresh
    Level 1 session.

-   **After 14+ days:** Optional prompt to reconnect with accountability
    partner or therapist. Never shame-based.

-   **Never:** Push notifications that reference a missed streak, days
    away, or disappointing language.

**6. Integration with Recovery Ecosystem**

Affirmations derive their greatest clinical value when connected to
other recovery activities. The following integrations are required at v1
launch:

  -----------------------------------------------------------------------------
  **Integration**     **How It Works**            **Clinical Rationale**
  ------------------- --------------------------- -----------------------------
  Sobriety Counter    Affirmation Level adapts    Avoids backfire effect;
                      based on days in recovery.  ensures content matches
                      Level unlocks gate at Day   psychological readiness.
                      14 for Level 2, Day 60 for  
                      Level 3, Day 180 for Level  
                      4 (with override).          

  Urge Reporting      Reporting an urge triggers  Interrupts
                      SOS Mode with Level 1--2    preoccupation→ritualization
                      affirmations + breathing    cycle at the earliest
                      exercise.                   detectable point.

  Journaling          Morning intention set in    Deepens cognitive processing;
                      affirmation session appears affirmation→reflection
                      as pre-filled prompt in     creates dual encoding.
                      journal. Evening reflection 
                      links to journal entry.     

  Mood Tracking       Evening session mood rating Enables early detection of
                      feeds mood trend chart.     deterioration; mood data
                      Consecutive low ratings     personalizes future content.
                      trigger therapist prompt.   

  Accountability      Partners see only: sessions Social accountability without
  Partner             completed this week (count  exposing private affirmation
                      only, no content). Partner  content.
                      can send a pre-written      
                      encouragement that appears  
                      as a home screen card.      

  Therapist/Sponsor   With user consent,          Enables clinical oversight;
  View                therapist dashboard shows:  hidden affirmations are
                      practice consistency,       diagnostic signals.
                      hidden affirmation count,   
                      mood trend, Level           
                      progression.                
  -----------------------------------------------------------------------------

**6.1 Data Sharing Consent Architecture**

All data sharing with accountability partners and therapists requires:

1.  Explicit opt-in per relationship (partner, therapist, sponsor
    managed separately)

2.  Granular permission selection --- users choose which data types to
    share

3.  Revocable at any time without affecting the relationship connection

4.  Clear in-app disclosure of exactly what the other party sees

5.  Audit log accessible to the user showing all shared data events

**7. Privacy, Safety & Trauma-Informed Design**

**7.1 Privacy-First Architecture**

Sexual addiction carries stigma beyond virtually any other condition.
Every design decision must assume the user lives with constant fear of
accidental disclosure.

  -----------------------------------------------------------------------
  **Requirement**          **Specification**
  ------------------------ ----------------------------------------------
  Notification text        100% generic. Never: \"Time for recovery.\"
                           Always: \"Your daily moment is ready.\"

  Notification sender name App display name only (generic). Never a
                           recovery-specific label.

  Audio auto-pause         All audio --- including own-voice recordings
                           and ambient music --- must auto-pause
                           immediately on headphone disconnect. No
                           exceptions.

  Audio preview in         Prohibited. No audio snippets in notification
  notifications            banners, lock screen, or widgets.

  Biometric lock           Face ID / Touch ID required by default. PIN
                           fallback. Set up during onboarding.

  Quick-hide / Boss screen Shake gesture or dedicated button switches app
                           to a neutral-looking screen instantly.

  Billing descriptor       Generic company name on all payment
                           statements. Never app name or recovery
                           language.

  Local-first storage      Sensitive data (recordings, journal, mood
                           ratings) stored on-device by default. Cloud
                           sync opt-in only.

  Data at rest encryption  AES-256 for all locally stored sensitive data.

  Data in transit          TLS 1.3 minimum for all API communication.
  -----------------------------------------------------------------------

**7.2 Trauma-Informed Design Principles**

Following SAMHSA\'s six principles for trauma-informed care, every
affirmation feature interaction must embody:

-   **Safety:** Predictable, calm UI. Consistent color palette. No
    jarring transitions. Crisis resources always one tap away from any
    screen.

-   **Trustworthiness:** Transparent data practices. Clear disclosure of
    what is stored, shared, and for how long. No dark patterns.

-   **Choice:** User controls delivery time, content categories, audio
    vs. text, Level range, sharing settings. Nothing forced.

-   **Collaboration:** Framing that positions the app as a tool in
    service of the user\'s own recovery plan, not a program being done
    to them.

-   **Empowerment:** Celebrate agency. Every milestone message
    attributes success to the user\'s choices, not the app\'s features.

-   **Cultural sensitivity:** Faith-based and secular tracks. No
    assumptions about gender, sexual orientation, or relationship
    structure in affirmation language. Inclusive pronoun options.

**7.3 Crisis Protocol**

When any of the following signals are detected, the affirmation
experience must pause and route to crisis support:

-   User selects crisis-level mood rating (1/5) on two consecutive
    evenings

-   User self-reports relapse with harm involved

-   Explicit crisis language in free-text journal entries (keyword
    detection with human review)

Crisis routing must include the Crisis Text Line (text HOME to 741741),
SAMHSA Helpline (1-800-662-4357), and an option to contact their
designated therapist or sponsor directly from the app.

> *The app must never position itself as a crisis intervention service.
> Crisis routing is a pointer to professional resources, not a
> substitute for them.*

**8. UX, Notifications & Accessibility**

**8.1 Affirmation Card Design**

-   Full-screen or large-card format --- text must be the visual focus

-   Typography: minimum 22pt; generous line-height (1.6). Legibility
    over aesthetics

-   Calm color backgrounds: soft gradient or solid from a restricted
    palette (no high-contrast or energetic colors)

-   Single affirmation per card --- no content stacking or carousels

-   Swipe interaction for navigation between cards in a session
    (left/right swipe = next/previous)

-   Heart icon (favorite) and hide icon always visible but subtle ---
    secondary to the text

-   Audio play button visible when a recording exists; mic button to
    create recording

**8.2 Notification Strategy**

  -------------------------------------------------------------------------
  **Notification   **Default Text** **Frequency**    **User Control**
  Type**                                             
  ---------------- ---------------- ---------------- ----------------------
  Morning session  \"Your daily     Daily at chosen  Time adjustable;
                   moment is        time             toggleable
                   ready.\"                          

  Evening          \"A moment to    Daily at chosen  Time adjustable;
  reflection       close your       time             toggleable
                   day.\"                            

  Re-engagement    \"Ready when you Once per gap     Toggleable
  (3-day gap)      are.\"           period           

  Post-SOS         \"Checking in    Once, 10 min     Not toggleable
  check-in         --- how are you  after SOS        (safety)
                   feeling?\"                        

  Partner          Partner\'s       User-initiated   Receivable; toggleable
  encouragement    pre-written      by partner       
                   message                           
  -------------------------------------------------------------------------

**8.3 Onboarding Flow**

Onboarding must be brief, welcoming, and not require disclosure of the
user\'s specific addictive behaviors. Recommended flow:

6.  Welcome screen --- purpose of affirmations, 30-second explanation.
    No shame language.

7.  Recovery context --- simple question: \"How long have you been in
    recovery?\" Options: Just starting / 1--3 months / 3--12 months / 1+
    years. This sets initial Level.

8.  Track selection --- Standard vs. Faith-Based (can be changed later).

9.  Notification setup --- morning time, evening time, permission
    request.

10. Privacy setup --- biometric lock, notification text preference.

11. First affirmation --- deliver one Level 1 affirmation as the final
    onboarding step. End on a moment of actual practice, not setup.

Total onboarding time target: under 3 minutes.

**8.4 Accessibility Requirements**

-   WCAG 2.1 AA compliance minimum

-   VoiceOver / TalkBack full support --- all affirmation cards and
    controls must be screen-reader accessible

-   Dynamic type support --- all text scales correctly from smallest to
    largest iOS/Android text settings

-   Minimum touch target size: 44x44pt

-   All audio content paired with full text display --- audio is
    enhancement, not replacement

-   Color is never the sole indicator of meaning

**9. Technical Requirements**

**9.1 Level Engine**

-   Algorithm that determines which affirmation Level to serve based on:
    days in recovery, recent mood ratings, manual Level override,
    post-relapse state, and time since last session

-   Level state must persist across app sessions and device restarts

-   Manual override (user can select lower Level at any time; can
    request Level upgrade after 30 days at current Level)

-   Level changes logged with timestamp for clinical dashboard

**9.2 Content Delivery**

-   Affirmation served must be drawn from: (1) user\'s Favorites, (2)
    current Level pool weighted by Category variety, (3) never repeat
    the same affirmation within a 7-day window unless it is a user
    Favorite

-   SOS pool maintained as a separate, always-available local cache ---
    must work offline

-   Content library updates delivered via CMS without app store release
    (hot update)

-   Offline mode: minimum 30 affirmations cached locally at all times
    for core daily practice

**9.3 Audio**

-   On-device audio recording using device microphone

-   AAC encoding, 64kbps minimum, .m4a format

-   Automatic headphone disconnect detection triggering immediate audio
    pause --- implement via AVAudioSession route-change notifications
    (iOS) and AudioManager focus change (Android)

-   Background music mixed at 60% volume relative to voice recording by
    default; user-adjustable

-   Maximum recording length: 60 seconds per affirmation

**9.4 Data & Compliance**

-   HIPAA-compliant infrastructure for all server-side data

-   42 CFR Part 2 compliance for substance use disorder records if
    therapist integration is enabled

-   Local data encrypted at rest (AES-256) --- use iOS Data Protection /
    Android Keystore

-   GDPR / CCPA compliant --- full data export and deletion on user
    request within 30 days

-   No affirmation content or personal journal data used for advertising
    or third-party ML training

-   Anonymized, aggregate usage analytics only (session counts, level
    distribution) for product improvement --- opt-out available

**10. Out of Scope & Future Phases**

**10.1 Out of Scope for v1**

-   AI-generated affirmation personalization (Phase 2 --- requires
    clinical review pipeline)

-   Video affirmations or third-party narrator audio

-   Group/community affirmation sharing (privacy risk; Phase 3 with
    robust review)

-   Wearable device integration (Phase 2)

-   Partner/couples affirmation exercises (Phase 3 --- clinically
    complex; requires CSAT input)

**10.2 Phase 2 Candidates**

-   **AI personalization:** Dynamically compose affirmations from a
    user\'s own language (words from journal entries, goals stated in
    onboarding), reviewed by a human before delivery.

-   **Mood-responsive delivery:** Serve specific affirmation categories
    based on real-time mood check-in before the session.

-   **Smartwatch integration:** Brief affirmation on wrist during
    commute; haptic-triggered breathing pauses.

-   **Therapist-assigned affirmations:** CSAT can push specific
    affirmations to a client\'s Favorites with a session note.

**10.3 Open Research Questions**

The following questions should be addressed through in-app research
partnerships with university CSAT programs:

-   What is the optimal minimum believability threshold for affirmation
    framing in sexual addiction populations specifically?

-   Does own-voice recording produce measurably better outcomes than
    text-only at 90-day follow-up?

-   What frequency of affirmation practice produces the strongest
    relapse-prevention effect in sexual addiction?

-   How does trauma history (childhood sexual abuse, attachment
    disorder) moderate affirmation response?

*End of Document*

Feature Requirements Document v1.0 --- Affirmations Experience
