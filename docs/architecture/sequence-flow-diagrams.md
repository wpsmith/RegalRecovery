# Regal Recovery -- Sequence and Flow Diagrams

Critical user flows documented as Mermaid diagrams, grounded in the [Feature Specifications](../02-feature-specifications.md) and [Technical Architecture](../03-technical-architecture.md).

---

## Table of Contents

1. [Morning Sobriety Commitment Flow](#1-morning-sobriety-commitment-flow)
2. [Urge Logging to Emergency Tools to Resolution](#2-urge-logging--emergency-tools--resolution)
3. [Recovery Agent Guided Tool Walkthrough](#3-recovery-agent-guided-tool-walkthrough)
4. [Data Sharing Permission Grant](#4-data-sharing-permission-grant)
5. [Backup and Restore Flow](#5-backup-and-restore-flow)
6. [Relapse to Post-Mortem to Prevention Plan Update](#6-relapse--post-mortem--prevention-plan-update)
7. [Onboarding Fast Track](#7-onboarding-fast-track)
8. [Recovery Health Score Calculation State Machine](#8-recovery-health-score-calculation-state-machine)

---

## 1. Morning Sobriety Commitment Flow

The daily commitment is the foundational recovery action. Local notifications trigger the flow; the commitment is saved to DynamoDB and the streak is recalculated. If the user has configured support network notifications, SNS fans out to APNS/FCM for each contact.

```mermaid
sequenceDiagram
    autonumber
    participant LN as Local Notification<br/>(OS Scheduler)
    participant App as Mobile App<br/>(Android / iOS)
    participant Valkey as Valkey Cache
    participant APIGW as AWS HTTP API Gateway
    participant Cognito as AWS Cognito
    participant Lambda as Lambda (Go)<br/>POST /commitments
    participant DDB as DynamoDB<br/>Commitments Table
    participant StreamLambda as Lambda (Go)<br/>Streak Calculator
    participant SNS as AWS SNS
    participant APNS as APNS / FCM

    LN->>App: Morning commitment reminder fires
    App->>App: User opens commitment screen
    App->>App: User confirms daily sobriety commitment

    alt Online
        App->>APIGW: POST /commitments {type: "sobriety", date, addictionId}
        APIGW->>Cognito: Validate JWT (15-min access token)
        Cognito-->>APIGW: Token valid, userId + tenantId extracted
        APIGW->>Lambda: Forward request with auth context
        Lambda->>DDB: PutItem (PK=USER#userId, SK=COMMIT#date)
        DDB-->>Lambda: 200 OK
        Lambda->>Valkey: Invalidate streak cache (userId, "sobriety")
        Lambda-->>APIGW: 201 Created {commitmentId, timestamp}
        APIGW-->>App: 201 Created

        DDB->>StreamLambda: DynamoDB Stream triggers streak recalculation
        StreamLambda->>DDB: Query commitment history (GSI by userId + type)
        StreamLambda->>DDB: Update streak record (currentStreak, longestStreak)
        StreamLambda->>Valkey: Write updated streak to cache

        alt Support network notifications enabled
            StreamLambda->>SNS: Publish CommitmentCompleted event
            SNS->>APNS: Push to iOS support contacts
            SNS->>APNS: Push to Android support contacts (FCM)
        end

        App->>APIGW: GET /streaks/{addictionId}
        APIGW->>Lambda: Forward with auth context
        Lambda->>Valkey: Read streak from cache
        Valkey-->>Lambda: {currentStreak: N, nextMilestone: M}
        Lambda-->>APIGW: 200 OK {streak data}
        APIGW-->>App: 200 OK
        App->>App: Display updated streak + milestone progress
    else Offline
        App->>App: Save commitment to local DB (offline queue)
        App->>App: Recalculate streak locally
        App->>App: Display updated streak from local data
        Note over App: FR4.5: Queued writes replayed<br/>in chronological order on reconnect
    end

    alt Milestone reached (e.g., 30 days)
        App->>App: Full-screen celebration animation
        App->>App: Reflection prompt + share options
    end
```

**Key design decisions:**
- Local notifications (FR3.2) ensure the reminder fires even without server connectivity.
- Streak recalculation is async via DynamoDB Streams to keep the write path fast (NFR1.4: < 2s).
- Valkey cache avoids recalculating streaks on every dashboard load (NFR1.3: < 500ms).
- Offline-first: commitment is persisted locally before any network call (FR4.1, FR4.5).

---

## 2. Urge Logging to Emergency Tools to Resolution

Triggered by the Emergency FAB (available on every screen). The flow covers urge capture, emergency tool activation, sponsor contact, follow-up notification, and resolution logging. All emergency tools work fully offline (< 1s load).

```mermaid
sequenceDiagram
    autonumber
    participant User as User
    participant App as Mobile App<br/>(Android / iOS)
    participant Phone as OS Phone Dialer
    participant LN as Local Notification<br/>(OS Scheduler)
    participant APIGW as AWS HTTP API Gateway
    participant Cognito as AWS Cognito
    participant Lambda as Lambda (Go)<br/>Urge Service
    participant DDB as DynamoDB<br/>Urge Logs Table
    participant StreamLambda as Lambda (Go)<br/>Analytics Processor
    participant SNS as AWS SNS
    participant APNS as APNS / FCM

    User->>App: Tap Emergency FAB (long-press)
    App->>App: Open Urge Log Screen 1:<br/>Intensity slider (1-10) + Addiction selection

    User->>App: Set intensity=8, select addiction
    App->>App: Screen 2: Trigger Identification<br/>Quick-select chips (Emotional, Environmental,<br/>Relational, Physical, Digital, Spiritual)

    User->>App: Select triggers [Emotional, Digital]
    App->>App: Screen 3: Context Notes<br/>(optional, voice-to-text available)

    User->>App: Add context via voice-to-text
    App->>App: Screen 4: Action Plan<br/>Emergency Tools Overlay

    Note over App: Emergency Tools available:<br/>- Call sponsor (phone deep link)<br/>- Panic Prayer<br/>- 5-min breathing exercise<br/>- Temptation Timer (20-min wave)<br/>- GPS to safe locations<br/>- Accountability Broadcast<br/>- Distraction tools

    User->>App: Tap "Call My Sponsor"
    App->>Phone: tel:// deep link to sponsor number
    Phone->>Phone: Call connected
    Phone-->>App: User returns to app after call

    App->>App: Post-call prompt: "How did the call go?"
    App->>App: Log phone call entry<br/>(direction: made, contact: sponsor, connected: yes)

    App->>LN: Schedule 15-min follow-up notification
    Note over LN: FR3.5: Follow-up at 15 min and 1 hour

    rect rgb(240, 248, 255)
        Note over LN,App: 15 minutes later
        LN->>App: "How are you doing? Has the urge passed?"
        User->>App: Opens follow-up check-in
    end

    App->>App: Screen 5: Urge Resolution<br/>"Did you maintain sobriety?"

    alt Sobriety maintained
        User->>App: Tap "Yes, I resisted"
        App->>App: Celebration message displayed
        App->>App: Save urge log locally (outcome: "Resisted")

        App->>APIGW: POST /urge-logs {intensity, triggers, context, outcome: "resisted", duration}
        APIGW->>Cognito: Validate JWT
        Cognito-->>APIGW: Valid
        APIGW->>Lambda: Forward request
        Lambda->>DDB: PutItem (PK=USER#userId, SK=URGE#timestamp)
        DDB-->>Lambda: OK
        Lambda-->>APIGW: 201 Created
        APIGW-->>App: 201 Created

        DDB->>StreamLambda: DynamoDB Stream event
        StreamLambda->>DDB: Update urge analytics (frequency, trigger counts)
        Note over StreamLambda: FR8.1-8.3: Trend calculation,<br/>trigger identification, correlations

    else Relapse occurred
        User->>App: Tap "No, I acted out"
        App->>App: Compassionate messaging:<br/>"This does not erase your progress."
        App->>App: Redirect to Relapse Logging Flow
        Note over App: See Diagram 6:<br/>Relapse -> Post-Mortem -> Prevention Plan
    end

    alt Accountability Broadcast requested
        App->>APIGW: POST /broadcasts {type: "struggling", message}
        APIGW->>Lambda: Forward request
        Lambda->>SNS: Publish broadcast event
        SNS->>APNS: Push to all support contacts
    end
```

**Key design decisions:**
- Phone deep link (tel://) avoids requiring CALL_PHONE permission on iOS entirely; Android uses it on-demand.
- All emergency tools are cached locally for offline use (FR4.4) and load in < 1s (NFR1.2).
- Follow-up notifications are local (FR3.2, FR3.5) to guarantee delivery without server dependency.
- Urge log is saved locally first, then synced -- offline queue ensures zero data loss (NFR2.4).

---

## 3. Recovery Agent Guided Tool Walkthrough

The Recovery Agent (P3, Premium+) acts as a conversational interface to all app tools. This diagram shows a FASTER Scale walkthrough where the agent asks each question (F, A, S, T, E, R), the user responds naturally, and the agent submits the completed entry. The agent has read access to user data and write access only with explicit per-entry confirmation.

```mermaid
sequenceDiagram
    autonumber
    participant User as User
    participant App as Mobile App<br/>(Android / iOS)
    participant Agent as Recovery Agent<br/>(On-device context +<br/>AI Backend)
    participant APIGW as AWS HTTP API Gateway
    participant Cognito as AWS Cognito
    participant AgentLambda as Lambda (Go)<br/>Agent Orchestrator
    participant AIService as AI Service<br/>(LLM Provider)
    participant DataLambda as Lambda (Go)<br/>FASTER Scale Service
    participant DDB as DynamoDB
    participant StreamLambda as Lambda (Go)<br/>Streak Calculator
    participant Valkey as Valkey Cache

    User->>App: "I want to do a FASTER Scale check-in"
    App->>App: Decrypt recent user context on-device<br/>(streaks, recent FASTER history, mood)

    App->>APIGW: POST /agent/conversations {message, context}
    APIGW->>Cognito: Validate JWT
    Cognito-->>APIGW: Valid
    APIGW->>AgentLambda: Forward with auth context
    AgentLambda->>DDB: Fetch FASTER Scale template
    AgentLambda->>AIService: Generate conversational prompt for F stage
    AIService-->>AgentLambda: Response
    AgentLambda-->>APIGW: Agent message
    APIGW-->>App: "Let's walk through a FASTER Scale.<br/>F is for Forgetting Priorities.<br/>Have you been skipping meetings, prayer,<br/>or other recovery practices lately?"

    User->>App: "Yeah, I skipped my meeting Tuesday<br/>and haven't prayed in 3 days"

    App->>APIGW: POST /agent/conversations {message, conversationId}
    APIGW->>AgentLambda: Forward
    AgentLambda->>AIService: Extract F-stage data + generate A prompt
    AIService-->>AgentLambda: {fStage: {active: true, details: "..."}, nextPrompt}
    AgentLambda-->>APIGW: Agent message
    APIGW-->>App: "Got it. That's important to notice.<br/>A is for Anxiety. Are you feeling anxious,<br/>worried, or restless about anything right now?"

    User->>App: "Work has been really stressful.<br/>I'm worried about a deadline Friday."

    App->>APIGW: POST /agent/conversations {message, conversationId}
    APIGW->>AgentLambda: Forward
    AgentLambda->>AIService: Extract A-stage data + generate S prompt
    AIService-->>AgentLambda: Response
    AgentLambda-->>APIGW: Agent message
    APIGW-->>App: "That makes sense. S is for Speeding Up.<br/>Are you overcommitting, staying too busy,<br/>or using busyness to avoid your feelings?"

    User->>App: "A little. I've been working late every night."

    Note over App,AgentLambda: Same pattern continues for<br/>T (Ticked Off), E (Exhausted), R (Relapse)

    App->>APIGW: POST /agent/conversations {message, conversationId}
    APIGW->>AgentLambda: Forward (T-stage response)
    AgentLambda->>AIService: Extract + generate E prompt
    AgentLambda-->>App: "T is for Ticked Off..."

    App->>APIGW: POST /agent/conversations {message, conversationId}
    APIGW->>AgentLambda: Forward (E-stage response)
    AgentLambda->>AIService: Extract + generate R prompt
    AgentLambda-->>App: "E is for Exhausted..."

    App->>APIGW: POST /agent/conversations {message, conversationId}
    APIGW->>AgentLambda: Forward (R-stage response)
    AgentLambda->>AIService: Compile all 6 stages, determine overall position
    AIService-->>AgentLambda: {stages: {...}, overallPosition: "A", alertLevel: "Yellow"}

    AgentLambda-->>APIGW: Completed assessment summary
    APIGW-->>App: "Based on our conversation, you're at the<br/>A (Anxiety) stage. Here's a summary:<br/>[F: Active, A: Active, S: Mild, T: No, E: No, R: No]<br/>Should I save this as your FASTER Scale entry?"

    User->>App: "Yes, save it"

    Note over User,App: Explicit user confirmation required<br/>before agent writes any data

    App->>APIGW: POST /faster-scale-entries {stages, overallPosition, source: "recovery-agent"}
    APIGW->>DataLambda: Forward with auth context
    DataLambda->>DDB: PutItem (PK=USER#userId, SK=FASTER#timestamp)<br/>metadata: {source: "via Recovery Agent"}
    DDB-->>DataLambda: OK
    DataLambda-->>APIGW: 201 Created {entryId}
    APIGW-->>App: 201 Created

    DDB->>StreamLambda: DynamoDB Stream event
    StreamLambda->>DDB: Update FASTER Scale streak
    StreamLambda->>DDB: Update Recovery Health Score<br/>(Emotional Health dimension, 20% weight)
    StreamLambda->>Valkey: Invalidate + update cached scores

    App->>App: Display confirmation:<br/>"FASTER Scale entry saved.<br/>Your Emotional Health score has been updated."

    alt Alert level is Yellow or higher
        App->>App: Agent suggests follow-up:<br/>"Since you're at Anxiety, would you like to<br/>talk about a plan to address the work stress?"
    end
```

**Key design decisions:**
- Agent decrypts user context on-device before sending to the backend, sending only what is needed for the current turn (privacy requirement from Feature 8).
- Every agent-written entry is tagged with `source: "via Recovery Agent"` in metadata.
- Write access requires explicit per-entry user confirmation -- the agent never silently writes data.
- FASTER Scale position feeds into Recovery Health Score (Emotional Health dimension, 20% weight).
- If the agent detects crisis indicators (R - Relapse), it escalates to emergency tools (cannot be overridden).

---

## 4. Data Sharing Permission Grant

All data sharing is opt-in (Feature 9). No support contact can view anything by default. The user grants access per person, per category, or per activity. Every data access by a support contact is logged in the audit trail (Section 10.3.8).

```mermaid
sequenceDiagram
    autonumber
    participant User as User (Recovering)
    participant App as Mobile App<br/>(Android / iOS)
    participant APIGW as AWS HTTP API Gateway
    participant Cognito as AWS Cognito
    participant PermLambda as Lambda (Go)<br/>Permissions Service
    participant DDB as DynamoDB<br/>Permissions Table
    participant Contact as Support Contact<br/>(Sponsor App)
    participant DataLambda as Lambda (Go)<br/>Data Access Service
    participant AuditLambda as Lambda (Go)<br/>Audit Logger
    participant SNS as AWS SNS
    participant APNS as APNS / FCM

    User->>App: Settings > Privacy > Data Sharing
    App->>App: Display support network contacts<br/>(Sponsor, Spouse, Counselor, AP)

    User->>App: Select contact: "John (Sponsor)"
    App->>App: Display permission categories:<br/>Sobriety Status, Check-ins, FASTER Scale,<br/>Urge Trends, Mood, Commitments, Journals,<br/>Post-Mortems, Financial, Recovery Health Score

    User->>App: Grant permissions:<br/>- Sobriety Status: READ<br/>- Check-ins: READ<br/>- FASTER Scale: READ<br/>- Journals: DENIED<br/>- Financial: DENIED

    Note over User,App: Suggested permission templates offered<br/>but never auto-enabled (Feature 9)

    App->>APIGW: PUT /permissions/{contactId} {permissions: [...]}
    APIGW->>Cognito: Validate JWT (sensitive operation = re-auth required)
    Cognito-->>APIGW: Valid
    APIGW->>PermLambda: Forward with auth context
    PermLambda->>DDB: UpdateItem (PK=USER#userId, SK=PERM#contactId)<br/>{categories: {sobriety: "read", checkins: "read",<br/>fasterScale: "read", journals: "denied", financial: "denied"}}
    DDB-->>PermLambda: OK
    PermLambda-->>APIGW: 200 OK
    APIGW-->>App: 200 OK
    App->>App: Display confirmation:<br/>"John can now view: Sobriety, Check-ins, FASTER Scale"

    rect rgb(240, 248, 255)
        Note over Contact,APNS: Later: Support contact requests data
        Contact->>APIGW: GET /sponsees/{userId}/check-ins
        APIGW->>Cognito: Validate JWT (contactId from token)
        Cognito-->>APIGW: Valid
        APIGW->>DataLambda: Forward with contactId + userId

        DataLambda->>DDB: GetItem permissions (PK=USER#userId, SK=PERM#contactId)

        alt Permission granted for category
            DDB-->>DataLambda: {checkins: "read"} -- Permission granted
            DataLambda->>DDB: Query check-in data (PK=USER#userId, SK begins_with CHECKIN#)
            DDB-->>DataLambda: Check-in records
            DataLambda->>AuditLambda: Log access event async
            AuditLambda->>DDB: PutItem audit record<br/>(who: contactId, what: "check-ins",<br/>when: timestamp, userId: userId)

            alt User has access notifications enabled
                AuditLambda->>SNS: Publish DataAccessed event
                SNS->>APNS: Push to user: "Your sponsor<br/>viewed your check-in data"
            end

            DataLambda-->>APIGW: 200 OK {data: [...]}
            APIGW-->>Contact: 200 OK {check-in data}

        else Permission denied for category
            DDB-->>DataLambda: {journals: "denied"}
            DataLambda-->>APIGW: 403 Forbidden
            APIGW-->>Contact: 403 Forbidden<br/>{error: "Access not granted for this category"}
        end
    end

    rect rgb(255, 245, 245)
        Note over Contact,AuditLambda: Coercive access detection (Feature 9)
        Note over AuditLambda: If single contact views data 20+ times<br/>in 24 hours, trigger safety alert
        AuditLambda->>SNS: Publish CoerciveAccessDetected event (to user only)
        SNS->>APNS: Private notification to user only:<br/>"We noticed unusual activity on your account.<br/>If you feel unsafe, help is available."<br/>+ National DV Hotline link
        Note over AuditLambda: This notification is NEVER<br/>visible to the support contact
    end
```

**Key design decisions:**
- Permission changes are a sensitive operation requiring re-authentication (biometric or PIN) per Section 10.3.1.
- Permission check happens on every data request -- never cached in a way that would allow stale grants.
- Audit trail (Section 10.3.8) logs every access with who/what/when, retained for 1 year.
- Silent revoke option: user can revoke access without notification to the support contact (Feature 9 safety).
- Coercive access detection is a server-side pattern check, never visible to the flagged contact.

---

## 5. Backup and Restore Flow

User-initiated backup to iCloud, Google Drive, or Dropbox. Data is encrypted on-device before upload. Backup file names are generic (`rr_backup_[date].enc`) to avoid revealing recovery-related information (Section 10.3.11). Ephemeral entries are excluded by default.

```mermaid
sequenceDiagram
    autonumber
    participant User as User
    participant App as Mobile App<br/>(Android / iOS)
    participant LocalDB as Local Database<br/>(Room / SwiftData)
    participant Crypto as On-Device<br/>Encryption Engine
    participant Cloud as Cloud Provider<br/>(iCloud / Google Drive / Dropbox)
    participant APIGW as AWS HTTP API Gateway
    participant Cognito as AWS Cognito
    participant Lambda as Lambda (Go)<br/>Backup Metadata Service
    participant DDB as DynamoDB<br/>Backup Metadata Table

    rect rgb(240, 255, 240)
        Note over User,DDB: BACKUP FLOW
        User->>App: Settings > Backup & Restore > Back Up Now
        App->>App: Display notice:<br/>"Your backup is encrypted and not human-readable.<br/>For a readable copy, use Export in Settings > Privacy > My Data."

        App->>LocalDB: Export all user data<br/>(profile, trackers, journals, streaks,<br/>settings, community connections)
        LocalDB-->>App: Raw data package

        App->>App: Filter ephemeral entries<br/>(excluded by default per Section 10.3.6)

        Note over App: Arousal template data IS included<br/>in backups (Section 10.3.11)

        App->>Crypto: Encrypt data package (AES-256)<br/>Key derived from user credentials
        Crypto-->>App: Encrypted blob (rr_backup_2026-03-28.enc)

        App->>Cloud: OAuth authentication (iCloud/Google/Dropbox)
        Cloud-->>App: Auth token

        App->>Cloud: Upload encrypted backup file
        Note over Cloud: Generic filename: rr_backup_2026-03-28.enc<br/>No recovery-related metadata exposed

        alt Upload succeeds
            Cloud-->>App: 200 OK {fileId, size}
            App->>APIGW: POST /backup-metadata {provider, fileId, timestamp, size, deviceName}
            APIGW->>Cognito: Validate JWT
            APIGW->>Lambda: Forward
            Lambda->>DDB: PutItem backup record
            DDB-->>Lambda: OK
            Lambda-->>App: 201 Created
            App->>App: Display confirmation:<br/>"Backup complete. 12.4 MB uploaded<br/>to Google Drive on Mar 28, 2026."

        else Upload fails
            Cloud-->>App: Error (network/storage/auth)
            App->>App: Retry up to 3 times with exponential backoff
            alt All retries fail
                App->>App: Display error:<br/>"Backup failed. Check your internet connection."<br/>or "Re-authenticate with Google Drive."
            end
        end
    end

    rect rgb(240, 248, 255)
        Note over User,DDB: RESTORE FLOW (New Device)
        User->>App: Install app on new device
        User->>App: Sign in (email/Apple ID/Google)
        App->>Cognito: Authenticate user
        Cognito-->>App: JWT tokens issued

        User->>App: Settings > Backup & Restore > Restore
        App->>APIGW: GET /backup-metadata
        APIGW->>Lambda: Forward with auth context
        Lambda->>DDB: Query backup records for userId
        DDB-->>Lambda: List of backups
        Lambda-->>App: [{date, size, deviceName, provider}, ...]
        App->>App: Display backup list:<br/>"iPhone 15 -- Mar 28, 2026 -- 12.4 MB -- Google Drive"

        User->>App: Select backup to restore
        App->>Cloud: OAuth authentication
        Cloud-->>App: Auth token
        App->>Cloud: Download encrypted backup file
        Cloud-->>App: Encrypted blob

        App->>Cognito: Re-authenticate (required per Section 10.3.11)
        Cognito-->>App: Confirmed

        App->>Crypto: Decrypt backup (AES-256)<br/>Key derived from user credentials
        Crypto-->>App: Decrypted data package

        App->>LocalDB: Import all data<br/>(profile, trackers, journals, streaks,<br/>settings, community connections)
        LocalDB-->>App: Import complete

        App->>App: Trigger sync with server<br/>(reconcile local restored data with server state)
        Note over App: FR4.3: Domain-specific merge strategy<br/>Relapse data: union merge<br/>Sobriety date: most conservative wins<br/>Streaks: server recalculates authoritatively

        App->>App: Display confirmation:<br/>"Restore complete. All your recovery data<br/>has been restored."
    end
```

**Key design decisions:**
- Encryption happens entirely on-device before any data leaves the phone -- cloud providers never see plaintext.
- Backup metadata (not content) is stored in DynamoDB to support listing backups across devices.
- Restore requires re-authentication as an additional security gate (Section 10.3.11).
- After restore, the app triggers a full sync with the server to reconcile using the domain-specific merge strategy (FR4.3).
- Ephemeral entries are excluded by default but can be included via user setting (Section 10.3.6).

---

## 6. Relapse to Post-Mortem to Prevention Plan Update

This flow begins when a user discloses a relapse (either via direct logging or FASTER Scale reaching R). It proceeds through compassionate relapse logging, guided post-mortem analysis (6 sections), and concludes with actionable prevention plan updates. For users with 180+ days of sobriety, an extended compassion pathway is triggered.

```mermaid
flowchart TD
    Start([User Discloses Relapse]) --> Source{Entry Point}

    Source -->|Direct Logging| RelapseLog[Relapse Logging Screen]
    Source -->|FASTER Scale = R| FASTERRedirect[FASTER Scale redirects<br/>to Relapse Logging]
    Source -->|Recovery Agent| AgentDisclosure[Agent detects relapse<br/>in conversation]

    FASTERRedirect --> RelapseLog
    AgentDisclosure --> RelapseLog

    RelapseLog --> Compassion{Streak >= 180 days?}

    Compassion -->|Yes| ExtendedCompassion[Extended Compassion Message:<br/>'This does not erase 6 months of growth.'<br/>+ Direct link to call sponsor/therapist<br/>+ Curated long-streak recovery plan]
    Compassion -->|No| StandardCompassion[Compassionate Message:<br/>'Recovery is not a straight line.<br/>Every day you fought matters.']

    ExtendedCompassion --> RelapseDetails
    StandardCompassion --> RelapseDetails

    RelapseDetails[Relapse Details:<br/>Date/Time picker<br/>Addiction specification<br/>Duration] --> SaveRelapse

    SaveRelapse[Lambda: POST /relapses<br/>DynamoDB: Save relapse record<br/>Reset sobriety date<br/>Preserve previous streak in history]

    SaveRelapse --> TotalDays[Display Both Counters:<br/>New streak: Day 0<br/>Total sober days: 247 of 250]

    SaveRelapse --> NotifyOption{Notify support<br/>network?}
    NotifyOption -->|Yes| SNSNotify[SNS: Push notification<br/>to support contacts]
    NotifyOption -->|No| PostMortemPrompt

    SNSNotify --> PostMortemPrompt

    PostMortemPrompt{Begin Post-Mortem<br/>Analysis?}
    PostMortemPrompt -->|Not now| SaveReminder[Schedule reminder<br/>for later today]
    PostMortemPrompt -->|Yes| PM1

    PM1[Section 1: The Day Before<br/>Emotional/spiritual state<br/>Recovery practices status<br/>Unresolved conflicts<br/>Mood rating 1-10]

    PM1 --> PM2[Section 2: Morning<br/>Morning commitment status<br/>Wake-up mood<br/>Notable events<br/>Auto-populated from app data]

    PM2 --> PM3[Section 3: Throughout the Day<br/>Hour-by-hour walkthrough<br/>Events, interactions, emotions<br/>When warning signs appeared<br/>FASTER stages identified]

    PM3 --> PM4[Section 4: The Build-Up<br/>First noticed something off<br/>Trigger accumulation<br/>Emotional/Environmental/Relational/<br/>Physical/Digital/Spiritual<br/>Decision point identification:<br/>'I could have ___ but instead I ___']

    PM4 --> PM5[Section 5: The Acting Out<br/>What happened<br/>Thoughts and feelings<br/>Addiction involved<br/>Duration<br/>Compassionate framing throughout]

    PM5 --> PM6[Section 6: Immediately After<br/>Feelings Wheel integration<br/>What did you do next?<br/>Did you reach out?<br/>What would you do differently?]

    PM6 --> Timeline[Generate Visual Timeline<br/>24-hour progression<br/>FASTER stages as color bands<br/>Trigger accumulation indicators<br/>Decision points marked]

    Timeline --> ActionPlan[Action Plan Creation<br/>3-5 specific actionable changes<br/>Format: 'At point X, I could have Y'<br/>Tagged: spiritual/relational/<br/>emotional/physical/practical]

    ActionPlan --> ConvertActions{Convert actions<br/>to app items?}
    ConvertActions -->|Yes| CreateCommitments[Lambda: POST /commitments<br/>Convert items to daily/weekly<br/>commitments or goals]
    ConvertActions -->|No| SavePM

    CreateCommitments --> UpdatePrevention[Lambda: PATCH /prevention-plans<br/>Update Relapse Prevention Plan<br/>with new strategies from post-mortem]

    SavePM[Lambda: POST /post-mortems<br/>DynamoDB: Save complete analysis<br/>metadata: source via Recovery Agent]

    UpdatePrevention --> SavePM

    SavePM --> CrossAnalysis[DynamoDB Stream triggers<br/>Cross-Analysis Update:<br/>Most common triggers<br/>Most frequent FASTER stage at<br/>point of no return<br/>Recurring missed interventions]

    CrossAnalysis --> ShareOption{Share with<br/>sponsor/counselor?}
    ShareOption -->|Full analysis| ShareFull[Share complete post-mortem<br/>via app or PDF export]
    ShareOption -->|Summary only| ShareSummary[Share summary view only]
    ShareOption -->|Not now| End

    ShareFull --> End([Flow Complete:<br/>Streak reset, post-mortem saved,<br/>prevention plan updated,<br/>new commitments active])
    ShareSummary --> End

    SaveReminder --> End

    style Start fill:#D0021B,color:#fff
    style End fill:#7ED321,color:#fff
    style ExtendedCompassion fill:#F5A623,color:#fff
    style StandardCompassion fill:#F5A623,color:#fff
    style ActionPlan fill:#4A90E2,color:#fff
    style UpdatePrevention fill:#4A90E2,color:#fff
```

**Key design decisions:**
- Extended compassion pathway for 180+ day relapses ensures long-streak users receive targeted support and are not left feeling like all progress was erased.
- Post-mortem auto-populates data from existing app records (morning commitment status, mood ratings) to reduce manual entry burden.
- Action plan items can be directly converted into commitments or goals -- closing the loop between analysis and behavior change.
- Cross-analysis runs asynchronously via DynamoDB Streams to identify patterns across multiple relapses.
- All timestamps on relapse events are immutable once created (FR2.7) -- no backdating allowed.

---

## 7. Onboarding Fast Track

Five steps to dashboard in under 2 minutes. Only notifications permission is requested during onboarding; all other permissions are deferred to contextual moments. Crisis access ("Need help right now?") is available from the Welcome Screen without requiring account creation.

```mermaid
flowchart TD
    Launch([App Launch]) --> LangDetect{Auto-detect<br/>device language}

    LangDetect -->|English or Spanish| LangScreen[Step 1: Language Selection<br/>English / Espanol<br/>Large buttons with flag icons]
    LangDetect -->|Other| DefaultEn[Default to English]
    DefaultEn --> LangScreen

    LangScreen --> Welcome[Step 2: Welcome Screen<br/>'You are not alone. And you are in the right place.'<br/>3 value propositions<br/>Get Started CTA]

    Welcome --> CrisisCheck{User taps<br/>'Need help right now?'}
    CrisisCheck -->|Yes| EmergencyOverlay[Emergency Tools Overlay<br/>No account required<br/>Crisis contacts, breathing,<br/>988 Lifeline, GPS safe locations]
    CrisisCheck -->|No| AccountCheck{Existing<br/>account?}

    EmergencyOverlay -.->|When ready| AccountCheck

    AccountCheck -->|Yes| SignIn[Sign In Flow<br/>Email + Password / Apple ID / Google<br/>Biometric re-auth]
    AccountCheck -->|No| Account

    SignIn --> Dashboard

    Account[Step 3: Account Creation<br/>Sign up: Email, Apple ID, or Google<br/>Email: real-time validation<br/>Terms + Privacy checkbox<br/>Email verification in background<br/>NOT blocking]

    Account --> AgeCheck{Age >= 18?}
    AgeCheck -->|No| AgeBlock[Block account creation<br/>Compassionate message<br/>Direct to age-appropriate resources]
    AgeCheck -->|Yes| BiometricPrompt[Biometric Opt-in Prompt<br/>Face ID / Touch ID / Fingerprint<br/>Default: required]

    BiometricPrompt --> Core[Step 4: Core Setup - Single Screen<br/>Display name - required, max 30 chars<br/>Primary addiction - required<br/>Selection chips: Sex Addiction, Pornography,<br/>Substance Use, Gambling, Shopping,<br/>Eating Disorders, Other<br/>Sobriety start date - required, default today]

    Core --> Notif[Step 5: Enable Notifications<br/>'Can we send you a daily reminder<br/>to make your recovery commitment?'<br/>Enable Reminders CTA -> OS permission<br/>Not now -> skip with Dashboard banner]

    Notif --> Dashboard([Dashboard Arrival<br/>Welcome animation<br/>Sobriety streak displayed<br/>3 suggested first actions:<br/>1. Make first commitment<br/>2. Read today's affirmation<br/>3. Set up support network<br/>Profile completion banner with progress ring])

    style Launch fill:#4A90E2,color:#fff
    style Dashboard fill:#7ED321,color:#fff
    style AgeBlock fill:#D0021B,color:#fff
    style EmergencyOverlay fill:#F5A623,color:#fff

    %% AWS Services involved
    subgraph AWS Backend
        direction TB
        CognitoAuth[AWS Cognito<br/>Account creation<br/>Social sign-in<br/>Email verification]
        APIGateway[AWS HTTP API Gateway<br/>POST /users<br/>POST /profiles]
        LambdaOnboard[Lambda Go<br/>Onboarding Service]
        DynamoDB[(DynamoDB<br/>Users Table<br/>Profiles Table)]
        SES[AWS SES<br/>Email verification]
    end

    Account -.->|POST /auth/signup| CognitoAuth
    CognitoAuth -.-> SES
    Core -.->|POST /profiles| APIGateway
    APIGateway -.-> LambdaOnboard
    LambdaOnboard -.-> DynamoDB
```

**Key design decisions:**
- Crisis access before account creation is a non-negotiable safety requirement -- a user in crisis should never be blocked by a sign-up form.
- Email verification runs in the background (does not block the user) to minimize time-to-dashboard.
- Age verification at Step 3 prevents under-18 users from proceeding (Section 10.3.1).
- Only one OS permission (notifications) is requested during onboarding -- all others are deferred (Section 5.5).
- Onboarding state is auto-saved so interrupted flows resume exactly where the user left off (FR4.1 principle applied to onboarding).

---

## 8. Recovery Health Score Calculation State Machine

The Recovery Health Score (0-100) is calculated daily from five weighted dimensions. The score maps to risk levels that drive notifications, support network alerts, and crisis resource surfacing. During the first 7 days ("Calibrating"), no alerts fire regardless of score.

```mermaid
stateDiagram-v2
    [*] --> Calibrating: User has < 7 days of data

    state Calibrating {
        [*] --> CollectingData
        CollectingData: Gathering baseline data
        CollectingData: No alerts triggered
        CollectingData: Score shown with 'Calibrating' label
        CollectingData: Weight adjustment based on active features
    }

    Calibrating --> Thriving: 7+ days data AND score 80-100
    Calibrating --> Steady: 7+ days data AND score 60-79
    Calibrating --> Cautious: 7+ days data AND score 40-59
    Calibrating --> AtRisk: 7+ days data AND score 20-39
    Calibrating --> Critical: 7+ days data AND score 0-19

    state Thriving {
        [*] --> ThrivingState
        ThrivingState: Score 80-100 (Green)
        ThrivingState: Strong engagement across all dimensions
        ThrivingState: Active recovery
    }

    state Steady {
        [*] --> SteadyState
        SteadyState: Score 60-79 (Blue)
        SteadyState: Consistent effort
        SteadyState: Some dimensions may need attention
    }

    state Cautious {
        [*] --> CautiousState
        CautiousState: Score 40-59 (Yellow)
        CautiousState: Multiple dimensions declining
        CautiousState: Proactive attention needed
    }

    state AtRisk {
        [*] --> AtRiskState
        AtRiskState: Score 20-39 (Orange)
        AtRiskState: Significant disengagement
        AtRiskState: Support network should be aware
        AtRiskState: Below 40 for 3+ days -> prompt outreach
    }

    state Critical {
        [*] --> CriticalState
        CriticalState: Score 0-19 (Red)
        CriticalState: Immediate intervention needed
        CriticalState: Crisis resources surfaced
        CriticalState: Tier 1 notification to support network
    }

    Thriving --> Steady: Score drops below 80
    Thriving --> Cautious: Rapid decline (20+ pts in 48h)

    Steady --> Thriving: Score rises to 80+
    Steady --> Cautious: Score drops below 60

    Cautious --> Steady: Score rises to 60+
    Cautious --> AtRisk: Score drops below 40

    AtRisk --> Cautious: Score rises to 40+
    AtRisk --> Critical: Score drops below 20

    Critical --> AtRisk: Score rises to 20+
    Critical --> Cautious: Score rises to 40+

    state ScoringPaused {
        [*] --> PausedState
        PausedState: User-initiated pause
        PausedState: Max 7 days
        PausedState: Support network notified of pause
    }

    Thriving --> ScoringPaused: User pauses scoring
    Steady --> ScoringPaused: User pauses scoring
    Cautious --> ScoringPaused: User pauses scoring
    AtRisk --> ScoringPaused: User pauses scoring

    ScoringPaused --> Calibrating: Pause ends, recalibrate
```

### Score Calculation Data Flow

```mermaid
flowchart LR
    subgraph Inputs ["Data Inputs (DynamoDB Queries)"]
        direction TB
        Sobriety[Sobriety Data<br/>Current streak length<br/>Days since last relapse<br/>Relapse frequency trend]
        Engagement[Engagement Data<br/>Commitment completion<br/>Check-in completion<br/>Journal frequency<br/>Activity variety]
        Emotional[Emotional Health Data<br/>Avg mood rating<br/>Mood stability - variance<br/>Emotional journal frequency<br/>FASTER Scale position]
        Connection[Connection Data<br/>Phone calls made<br/>Person check-ins<br/>Meeting attendance<br/>Community engagement]
        Growth[Growth Data<br/>Step work progress<br/>Devotional consistency<br/>Exercise/nutrition logs<br/>Goal completion rate]
    end

    subgraph QualityFilters ["Quality Filters"]
        direction TB
        JournalCheck[Journal entries<br/>less than 20 chars excluded]
        CheckinSpeed[Check-ins under 30s<br/>weighted at 50%]
        FASTERVariance[FASTER identical answers<br/>flagged for review]
    end

    subgraph Calculator ["Lambda: Score Calculator<br/>(DynamoDB Stream Trigger)"]
        direction TB
        WeightAdjust[Adjust Weights<br/>Based on Active Features<br/>User not penalized for<br/>features never enabled]
        DimScore[Calculate Dimension Scores<br/>Sobriety: 30% weight<br/>Engagement: 25% weight<br/>Emotional: 20% weight<br/>Connection: 15% weight<br/>Growth: 10% weight]
        Aggregate[Aggregate to 0-100 Score<br/>Apply logarithmic curve<br/>to sobriety streak]
        RiskLevel[Map to Risk Level<br/>Thriving / Steady / Cautious<br/>At Risk / Critical]
    end

    subgraph Outputs ["Outputs"]
        direction TB
        DDBScore[(DynamoDB<br/>Score History Table)]
        ValkeyCache[(Valkey Cache<br/>Current Score)]
        Dashboard[Dashboard Widget<br/>Score + Color + Trend Arrow]
        Alerts[Alert Engine<br/>Below 40 for 3 days -> prompt<br/>Below 20 -> Tier 1 notify<br/>20pt drop in 48h -> flag]
        SupportView[Support Network View<br/>Score visible per permissions]
    end

    Sobriety --> WeightAdjust
    Engagement --> QualityFilters
    Emotional --> WeightAdjust
    Connection --> WeightAdjust
    Growth --> WeightAdjust

    QualityFilters --> WeightAdjust

    WeightAdjust --> DimScore
    DimScore --> Aggregate
    Aggregate --> RiskLevel

    RiskLevel --> DDBScore
    RiskLevel --> ValkeyCache
    RiskLevel --> Dashboard
    RiskLevel --> Alerts
    RiskLevel --> SupportView
```

**Key design decisions:**
- Logarithmic curve on sobriety streak prevents the score from being dominated by long-term sobriety alone -- engagement and emotional health remain meaningful even at 1,000+ days.
- Quality filters prevent gaming: short journal entries, speed-tapped check-ins, and identical FASTER answers are down-weighted or excluded.
- Weight adjustment for inactive features ensures users are scored fairly based on what they actually use -- a user who never enabled exercise tracking is not penalized.
- Scoring pause (max 7 days) acknowledges that vacations and intentional breaks should not trigger false alarms, while ensuring the pause itself is visible to the support network.
- The score is recalculated asynchronously via DynamoDB Streams whenever underlying data changes, then cached in Valkey for sub-500ms dashboard loads.

---

## AWS Services Summary

For reference, the services involved across all flows:

| Service | Role in Flows |
|---|---|
| **AWS HTTP API Gateway** | All API routing with built-in Cognito authorizer |
| **AWS Cognito** | Authentication (JWT tokens, 15-min access, rotating refresh), social sign-in, email verification |
| **AWS Lambda (Go)** | All business logic: commitment service, urge service, FASTER scale service, permissions service, agent orchestrator, score calculator, streak calculator, audit logger, backup metadata |
| **DynamoDB** | Primary data store (on-demand): users, commitments, urge logs, FASTER entries, permissions, audit trail, post-mortems, scores, backup metadata. DynamoDB Streams for async processing |
| **Valkey (Redis-compatible)** | Cache: streak data, current scores, dashboard hot data, session state |
| **AWS SNS** | Fan-out notifications: support network alerts, milestone celebrations, accountability broadcasts, coercive access alerts |
| **APNS / FCM** | Platform push delivery (via SNS) |
| **AWS SES** | Transactional email: verification, password reset, lapsed user re-engagement |
| **AWS S3** | Media storage, static assets (not used for user backups -- those go to user's own cloud provider) |
| **CloudFront** | CDN for static content and assets |
| **CloudWatch + X-Ray** | Observability: logs, metrics, alarms, distributed tracing across Lambda invocations |
| **SSM Parameter Store** | Secrets and configuration: API keys, feature flags |

---

## Open Questions

1. **Agent AI provider selection**: The Recovery Agent requires an LLM backend. Provider selection (Bedrock, OpenAI, Anthropic) has not been finalized. This affects latency, cost, and data residency for EU users.
2. **Backup encryption key derivation**: The exact key derivation function (KDF) for backup encryption needs specification -- whether to use the user's password directly (PBKDF2/Argon2) or a separate backup passphrase.
3. **Score calculation frequency**: Currently specified as "daily" but the DynamoDB Stream trigger model would recalculate on every data change. Need to decide between true real-time scoring vs. batched daily calculation (cost vs. UX trade-off).
4. **Offline agent capability**: The Recovery Agent flow assumes connectivity. Defining the offline fallback (cached responses? simplified local model? redirect to manual tool entry?) needs specification.
5. **Cross-device backup conflict**: If a user restores a backup on a new device while the old device is still active, the merge strategy for in-flight offline data on the old device needs clarification beyond the general FR4.3 rules.
