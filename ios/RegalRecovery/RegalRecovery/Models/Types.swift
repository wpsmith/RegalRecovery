import SwiftUI

// MARK: - User Profile

struct UserProfile {
    let name: String
    let email: String
    let birthYear: Int
    let gender: String
    let timezone: String
    let addictions: [String]
    let sobrietyDate: Date
    let bibleVersion: String
    let motivations: [String]
    let avatarInitial: String
}

// MARK: - Streak

struct StreakData {
    let currentDays: Int
    let sobrietyDate: Date
    let longestStreak: Int
    let totalRelapses: Int
    let nextMilestoneDays: Int
    let milestones: [Milestone]
}

struct Milestone: Identifiable {
    let id = UUID()
    let days: Int
    let dateEarned: Date
    let scripture: String
}

// MARK: - Support Network

struct SupportContact: Identifiable {
    let id = UUID()
    let name: String
    let role: ContactRole
    let permissionSummary: String
    let linkedDaysAgo: Int
    let phone: String
}

enum ContactRole: String {
    case sponsor = "Sponsor"
    case counselor = "Counselor (CSAT)"
    case spouse = "Spouse"
    case accountabilityPartner = "Accountability Partner"

    var color: Color {
        switch self {
        case .sponsor: return .rrPrimary
        case .counselor: return .purple
        case .spouse: return .rrDestructive
        case .accountabilityPartner: return .rrSecondary
        }
    }
}

// MARK: - Activities

struct ActivityEntry: Identifiable {
    let id = UUID()
    let type: ActivityType
    let date: Date
    let summary: String
    let detail: String
    let value: Double?
    let icon: String
    let iconColor: Color
}

enum ActivityType: String, CaseIterable {
    case sobrietyCommitment = "Daily Sobriety Commitment"
    case recoveryCheckIn = "Recovery Check-in"
    case journal = "Journal / Jotting"
    case emotionalJournal = "Emotional Journal"
    case timeJournal = "Time Journal"
    case fasterScale = "FASTER Scale"
    case postMortem = "Post-Mortem Analysis"
    case urgeLog = "Urge Log"
    case mood = "Mood Rating"
    case gratitude = "Gratitude List"
    case prayer = "Prayer"
    case exercise = "Exercise"
    case phoneCalls = "Phone Calls"
    case meetingsAttended = "Meetings Attended"
    case spouseCheckIn = "Spouse Check-in Prep"
    case stepWork = "12-Step Work"
    case weeklyGoals = "Weekly Goals"
    case affirmationLog = "Affirmation Log"

    var icon: String {
        switch self {
        case .sobrietyCommitment: return "sun.max.fill"
        case .recoveryCheckIn: return "heart.text.clipboard"
        case .journal: return "note.text"
        case .emotionalJournal: return "heart.circle.fill"
        case .timeJournal: return "clock.fill"
        case .fasterScale: return "gauge.with.needle"
        case .postMortem: return "magnifyingglass.circle"
        case .urgeLog: return "exclamationmark.triangle.fill"
        case .mood: return "face.smiling"
        case .gratitude: return "leaf.fill"
        case .prayer: return "hands.and.sparkles.fill"
        case .exercise: return "figure.run"
        case .phoneCalls: return "phone.fill"
        case .meetingsAttended: return "person.3.fill"
        case .spouseCheckIn: return "heart.fill"
        case .stepWork: return "stairs"
        case .weeklyGoals: return "target"
        case .affirmationLog: return "text.quote"
        }
    }

    var iconColor: Color {
        switch self {
        case .sobrietyCommitment: return .rrSecondary
        case .recoveryCheckIn: return .rrPrimary
        case .journal, .emotionalJournal, .timeJournal: return .purple
        case .fasterScale: return .rrSuccess
        case .postMortem: return .rrDestructive
        case .urgeLog: return .orange
        case .mood: return .yellow
        case .gratitude: return .rrSuccess
        case .prayer: return .rrPrimary
        case .exercise: return .blue
        case .phoneCalls: return .green
        case .meetingsAttended: return .rrPrimary
        case .spouseCheckIn: return .pink
        case .stepWork: return .rrSecondary
        case .weeklyGoals: return .rrPrimary
        case .affirmationLog: return .rrSecondary
        }
    }

    var section: ActivitySection {
        switch self {
        case .sobrietyCommitment, .recoveryCheckIn:
            return .sobrietyCommitment
        case .journal, .emotionalJournal, .timeJournal, .fasterScale, .postMortem:
            return .journalingReflection
        case .urgeLog, .mood, .gratitude, .prayer, .exercise:
            return .selfCare
        case .phoneCalls, .meetingsAttended, .spouseCheckIn:
            return .connection
        case .stepWork, .weeklyGoals, .affirmationLog:
            return .growth
        }
    }
}

enum ActivitySection: String, CaseIterable {
    case sobrietyCommitment = "Sobriety & Commitment"
    case journalingReflection = "Journaling & Reflection"
    case selfCare = "Self-Care & Wellness"
    case connection = "Connection"
    case growth = "Growth"
}

// MARK: - FASTER Scale

enum FASTERStage: Int, CaseIterable, Identifiable {
    case restoration = -1
    case forgettingPriorities = 0
    case anxiety
    case speedingUp
    case tickedOff
    case exhausted
    case relapse

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .restoration: return "Restoration"
        case .forgettingPriorities: return "Forgetting Priorities"
        case .anxiety: return "Anxiety"
        case .speedingUp: return "Speeding Up"
        case .tickedOff: return "Ticked Off"
        case .exhausted: return "Exhausted"
        case .relapse: return "Relapse"
        }
    }

    var letter: String {
        switch self {
        case .restoration: return "R+"
        default: return String(name.prefix(1))
        }
    }

    var description: String {
        switch self {
        case .restoration: return "Actively engaged in recovery, maintaining healthy routines, connected to support."
        case .forgettingPriorities: return "Losing focus on recovery priorities, skipping routines, drifting from commitments."
        case .anxiety: return "Worry, restlessness, difficulty concentrating, feeling overwhelmed by daily pressures."
        case .speedingUp: return "Taking on too much, staying busy to avoid feelings, rushing through the day."
        case .tickedOff: return "Irritability, resentment, blaming others, feeling entitled or self-righteous."
        case .exhausted: return "Physical and emotional depletion, isolation, feeling hopeless or burned out."
        case .relapse: return "Acting out on addictive behaviors, breaking sobriety commitment."
        }
    }

    var color: Color {
        switch self {
        case .restoration: return Color(red: 0.176, green: 0.416, blue: 0.310)
        case .forgettingPriorities: return .rrSuccess
        case .anxiety: return .yellow
        case .speedingUp: return .orange
        case .tickedOff: return .orange
        case .exhausted: return .rrDestructive
        case .relapse: return .rrDestructive
        }
    }

    var indicators: [String] {
        switch self {
        case .restoration:
            return [
                "Attending meetings regularly",
                "Maintaining daily devotional",
                "Honest with accountability partner",
                "Keeping commitments",
                "Healthy sleep schedule",
                "Exercising regularly",
                "Connected to support network",
            ]
        case .forgettingPriorities:
            return [
                "Isolating from others",
                "Keeping minor secrets",
                "Sarcastic or cynical attitude",
                "Procrastinating on recovery work",
                "Breaking small commitments",
                "Overconfidence in recovery",
                "Preoccupied with entertainment",
                "Skipping meetings or quiet time",
            ]
        case .anxiety:
            return [
                "Sleep problems or insomnia",
                "Vague worry or dread",
                "Difficulty concentrating",
                "Nervous energy or fidgeting",
                "Avoiding specific people or places",
                "Increased caffeine or sugar intake",
                "Obsessing over things I can't control",
            ]
        case .speedingUp:
            return [
                "Taking on too many tasks",
                "Staying constantly busy",
                "Difficulty sitting still",
                "Rushing through conversations",
                "Skipping meals or self-care",
                "Working excessive hours",
                "Saying yes to everything",
                "Neglecting relationships",
            ]
        case .tickedOff:
            return [
                "Irritable over small things",
                "Resentment toward someone",
                "Blaming others for problems",
                "Feeling entitled or self-righteous",
                "Road rage or short temper",
                "Keeping score in relationships",
                "Sarcasm that cuts",
            ]
        case .exhausted:
            return [
                "Physically drained constantly",
                "Emotionally numb or flat",
                "Withdrawing from everyone",
                "Feeling hopeless about recovery",
                "Can't see a way forward",
                "Fantasizing about acting out",
                "Stopped caring about consequences",
            ]
        case .relapse:
            return [
                "Acted out on addictive behavior",
                "Broke sobriety commitment",
                "Lying to cover up behavior",
                "Bingeing or escalating behavior",
                "Planning next opportunity to act out",
                "Complete disconnect from support",
            ]
        }
    }

    var adaptiveContent: (title: String, body: String) {
        switch self {
        case .restoration:
            return (
                "You're in Restoration",
                "Keep up the great work. Stay connected to your support network, maintain your routines, and remember — consistency is what got you here. Consider encouraging someone else in their recovery today."
            )
        case .forgettingPriorities:
            return (
                "Priority Check",
                "You may be drifting from your recovery foundations. Review your commitments: Are you attending meetings? Keeping your quiet time? Being honest with your accountability partner? Small course corrections now prevent bigger problems later."
            )
        case .anxiety:
            return (
                "Grounding Exercise",
                "Anxiety is a signal, not a sentence. Try the 5-4-3-2-1 technique: notice 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste. Then take three slow breaths. You don't have to figure everything out right now."
            )
        case .speedingUp:
            return (
                "Slow Down Challenge",
                "Busyness is a way of avoiding what's underneath. Your challenge: take 10 minutes right now to do absolutely nothing. No phone, no tasks. Just be still. What feelings come up when you stop?"
            )
        case .tickedOff:
            return (
                "Name the Feeling",
                "Anger often masks hurt, fear, or shame. Before reacting, ask: What am I really feeling beneath the irritation? Who am I really angry at? Consider reaching out to your accountability partner to talk it through."
            )
        case .exhausted:
            return (
                "You Need Support Right Now",
                "You're in a critical place. This is not the time to isolate. Please reach out to your accountability partner, sponsor, or counselor today — not tomorrow. You don't have to have the words; just make the call."
            )
        case .relapse:
            return (
                "You Are Not Beyond Recovery",
                "A relapse is not the end of your story. Right now, the most important thing is to be honest with someone safe. Contact your accountability partner or sponsor. If you're in crisis, use the SOS button. Grace is real, and so is your next step forward."
            )
        }
    }
}

struct FASTEREntry: Identifiable {
    let id = UUID()
    let date: Date
    let stage: FASTERStage
    let moodScore: Int
    let selectedIndicators: [FASTERStage: Set<String>]

    init(date: Date, stage: FASTERStage, moodScore: Int = 3, selectedIndicators: [FASTERStage: Set<String>] = [:]) {
        self.date = date
        self.stage = stage
        self.moodScore = moodScore
        self.selectedIndicators = selectedIndicators
    }
}

// MARK: - Check-In

struct CheckInEntry: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
    let answers: [String: Int]
}

// MARK: - Emotional Journal

struct EmotionalJournalEntry: Identifiable {
    let id = UUID()
    let date: Date
    let emotion: String
    let emotionColor: Color
    let intensity: Int
    let activity: String
    let location: String
}

enum PrimaryEmotion: String, CaseIterable {
    case happy = "Happy"
    case sad = "Sad"
    case angry = "Angry"
    case fearful = "Fearful"
    case disgusted = "Disgusted"
    case surprised = "Surprised"

    var color: Color {
        switch self {
        case .happy: return .yellow
        case .sad: return .blue
        case .angry: return .red
        case .fearful: return .purple
        case .disgusted: return .green
        case .surprised: return .orange
        }
    }

    var secondaryEmotions: [String] {
        switch self {
        case .happy: return ["Joyful", "Grateful", "Content", "Peaceful", "Hopeful", "Proud"]
        case .sad: return ["Lonely", "Grieving", "Disappointed", "Hopeless", "Ashamed", "Empty"]
        case .angry: return ["Frustrated", "Resentful", "Irritated", "Bitter", "Jealous", "Betrayed"]
        case .fearful: return ["Anxious", "Insecure", "Overwhelmed", "Vulnerable", "Panicked", "Worried"]
        case .disgusted: return ["Contemptuous", "Repulsed", "Self-loathing", "Judgmental"]
        case .surprised: return ["Shocked", "Confused", "Amazed", "Startled"]
        }
    }
}

// MARK: - Time Journal

struct TimeBlock: Identifiable {
    let id = UUID()
    let startHour: Int
    let startMinute: Int
    let durationMinutes: Int
    let activity: String
    let need: String
    let color: Color
}

// MARK: - Meetings

struct Meeting: Identifiable {
    let id = UUID()
    let name: String
    let fellowship: String
    let day: String
    let time: String
    let distance: String?
    let location: String
    let isVirtual: Bool
    let isSaved: Bool
    let latitude: Double
    let longitude: Double
}

// MARK: - Three Circles

struct ThreeCirclesData {
    let red: [String]
    let yellow: [String]
    let green: [String]
}

// MARK: - Affirmations

struct AffirmationPack: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let affirmations: [Affirmation]
}

struct Affirmation: Identifiable {
    let id = UUID()
    let text: String
    let scripture: String
    let isFavorite: Bool
}

// MARK: - Devotional

struct DevotionalDay: Identifiable {
    let id = UUID()
    let day: Int
    let title: String
    let scripture: String
    let scriptureText: String
    let reflection: String
    let isComplete: Bool
    var completedAt: Date?
}

// MARK: - Prayer

struct PrayerItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let text: String
}

// MARK: - Commitment

struct CommitmentQuestion: Identifiable {
    let id = UUID()
    let text: String
    let isChecked: Bool
}

// MARK: - Step Work

struct StepWorkItem: Identifiable {
    let id: Int
    let title: String
    let description: String
    let scripture: String
    let status: StepStatus
    let reflectionQuestions: [String]
    let answeredCount: Int
}

enum StepStatus {
    case complete
    case inProgress
    case locked
}

// MARK: - Goal

struct WeeklyGoal: Identifiable {
    let id = UUID()
    let title: String
    let dynamic: String
    let isComplete: Bool
}

// MARK: - Commitment Status

struct CommitmentStatus {
    let morningComplete: Bool
    let morningTime: String?
    let eveningComplete: Bool
    let eveningTime: String?
}

// MARK: - Recent Activity

enum HistoryItemType: String {
    case morningCommitment
    case eveningReview
    case recoveryCheckIn
    case journal
    case emotionalJournal
    case fasterScale
    case urgeLog
    case mood
    case gratitude
    case prayer
    case exercise
    case phoneCall
    case meeting
    case spouseCheckIn
}

struct RecentActivity: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let time: String
    let icon: String
    let iconColor: Color
    var sourceType: HistoryItemType?
    var sourceId: UUID?
}

// MARK: - Glossary

struct GlossaryTerm: Identifiable {
    let id = UUID()
    let term: String
    let definition: String
}

// MARK: - Crisis Resource

struct CrisisResource: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let description: String
}

// MARK: - Notification Setting

struct NotificationSetting: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    var isEnabled: Bool
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

// MARK: - Journal Prompt

struct PromptItem: Identifiable {
    let id = UUID()
    let text: String
    let category: String
    let tags: [String]
}

// MARK: - Onboarding

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case account
    case recovery
    case permissions
}

// MARK: - Daily Plan Activity State

enum DailyPlanActivityState: String {
    case completed
    case pending
    case upcoming
    case overdue
    case skipped

    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .pending: return "circle"
        case .upcoming: return "circle"
        case .overdue: return "exclamationmark.triangle.fill"
        case .skipped: return "xmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .completed: return .rrSuccess
        case .pending: return .rrText
        case .upcoming: return .rrTextSecondary
        case .overdue: return .orange
        case .skipped: return .rrTextSecondary
        }
    }
}

// MARK: - Daily Score Level

enum DailyScoreLevel: String {
    case excellent
    case strong
    case moderate
    case low
    case minimal

    var range: ClosedRange<Int> {
        switch self {
        case .excellent: return 90...100
        case .strong: return 70...89
        case .moderate: return 50...69
        case .low: return 25...49
        case .minimal: return 0...24
        }
    }

    var color: Color {
        switch self {
        case .excellent: return .rrSuccess
        case .strong: return .blue
        case .moderate: return .yellow
        case .low: return .orange
        case .minimal: return .rrDestructive
        }
    }

    var label: String {
        switch self {
        case .excellent: return "Excellent"
        case .strong: return "Strong"
        case .moderate: return "Moderate"
        case .low: return "Low"
        case .minimal: return "Minimal"
        }
    }

    static func level(for score: Int) -> DailyScoreLevel {
        let clamped = max(0, min(100, score))
        switch clamped {
        case 90...100: return .excellent
        case 70...89: return .strong
        case 50...69: return .moderate
        case 25...49: return .low
        default: return .minimal
        }
    }
}

// MARK: - Daily Eligible Activity

struct DailyEligibleActivity {
    let activityType: String
    let displayName: String
    let icon: String
    let multiplePerDay: Bool
    let maxPerDay: Int
    let defaultEnabled: Bool
    let typicalHour: Int
    let typicalMinute: Int
    let typicalBlock: String
    let featureFlagKey: String
    let section: ActivitySection

    /// Activities filtered by feature flags (reactive via FeatureFlagStore)
    static var enabled: [DailyEligibleActivity] {
        all.filter { activity in
            FeatureFlagStore.shared.isEnabled(activity.featureFlagKey)
        }
    }

    static let all: [DailyEligibleActivity] = [
        DailyEligibleActivity(
            activityType: ActivityType.sobrietyCommitment.rawValue,
            displayName: "Morning Commitment",
            icon: "sun.max.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: true,
            typicalHour: 7,
            typicalMinute: 0,
            typicalBlock: "Morning",
            featureFlagKey: "activity.sobriety-commitment",
            section: .sobrietyCommitment
        ),
        DailyEligibleActivity(
            activityType: ActivityType.affirmationLog.rawValue,
            displayName: "Christian Affirmations",
            icon: "text.quote",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 7,
            typicalMinute: 0,
            typicalBlock: "Morning",
            featureFlagKey: "activity.affirmations",
            section: .sobrietyCommitment
        ),
        DailyEligibleActivity(
            activityType: ActivityType.journal.rawValue,
            displayName: "Journaling / Jotting",
            icon: "note.text",
            multiplePerDay: true,
            maxPerDay: 10,
            defaultEnabled: false,
            typicalHour: 7,
            typicalMinute: 0,
            typicalBlock: "Morning",
            featureFlagKey: "activity.journaling",
            section: .journalingReflection
        ),
        DailyEligibleActivity(
            activityType: "devotional",
            displayName: "Devotional",
            icon: "book.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 7,
            typicalMinute: 0,
            typicalBlock: "Morning",
            featureFlagKey: "activity.devotionals",
            section: .journalingReflection
        ),
        DailyEligibleActivity(
            activityType: ActivityType.prayer.rawValue,
            displayName: "Prayer",
            icon: "hands.and.sparkles.fill",
            multiplePerDay: true,
            maxPerDay: 5,
            defaultEnabled: false,
            typicalHour: 7,
            typicalMinute: 0,
            typicalBlock: "Morning",
            featureFlagKey: "activity.prayer",
            section: .journalingReflection
        ),
        DailyEligibleActivity(
            activityType: "memoryVerseReview",
            displayName: "Memory Verse Review",
            icon: "text.book.closed.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 7,
            typicalMinute: 0,
            typicalBlock: "Morning",
            featureFlagKey: "activity.memory-verse",
            section: .journalingReflection
        ),
        DailyEligibleActivity(
            activityType: ActivityType.emotionalJournal.rawValue,
            displayName: "Emotional Journaling",
            icon: "heart.circle.fill",
            multiplePerDay: true,
            maxPerDay: 5,
            defaultEnabled: false,
            typicalHour: 12,
            typicalMinute: 0,
            typicalBlock: "Midday",
            featureFlagKey: "activity.emotional-journaling",
            section: .journalingReflection
        ),
        DailyEligibleActivity(
            activityType: ActivityType.mood.rawValue,
            displayName: "Mood Rating",
            icon: "face.smiling",
            multiplePerDay: true,
            maxPerDay: 5,
            defaultEnabled: false,
            typicalHour: 12,
            typicalMinute: 0,
            typicalBlock: "Midday",
            featureFlagKey: "activity.mood",
            section: .selfCare
        ),
        DailyEligibleActivity(
            activityType: ActivityType.gratitude.rawValue,
            displayName: "Gratitude List",
            icon: "leaf.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.gratitude",
            section: .journalingReflection
        ),
        DailyEligibleActivity(
            activityType: ActivityType.phoneCalls.rawValue,
            displayName: "Phone Calls",
            icon: "phone.fill",
            multiplePerDay: true,
            maxPerDay: 10,
            defaultEnabled: false,
            typicalHour: 12,
            typicalMinute: 0,
            typicalBlock: "Midday",
            featureFlagKey: "activity.phone-calls",
            section: .connection
        ),
        DailyEligibleActivity(
            activityType: ActivityType.exercise.rawValue,
            displayName: "Exercise / Physical Activity",
            icon: "figure.run",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 8,
            typicalMinute: 0,
            typicalBlock: "Morning",
            featureFlagKey: "activity.exercise",
            section: .selfCare
        ),
        DailyEligibleActivity(
            activityType: ActivityType.meetingsAttended.rawValue,
            displayName: "Meetings Attended",
            icon: "person.3.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 20,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.meetings",
            section: .connection
        ),
        DailyEligibleActivity(
            activityType: "personCheckInSpouse",
            displayName: "Person Check-in -- Spouse",
            icon: "heart.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.person-check-ins",
            section: .connection
        ),
        DailyEligibleActivity(
            activityType: "personCheckInSponsor",
            displayName: "Person Check-in -- Sponsor",
            icon: "person.fill.checkmark",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 12,
            typicalMinute: 0,
            typicalBlock: "Midday",
            featureFlagKey: "activity.person-check-ins",
            section: .connection
        ),
        DailyEligibleActivity(
            activityType: "personCheckInCounselor",
            displayName: "Person Check-in -- Counselor/Coach",
            icon: "stethoscope",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 12,
            typicalMinute: 0,
            typicalBlock: "Midday",
            featureFlagKey: "activity.person-check-ins",
            section: .connection
        ),
        DailyEligibleActivity(
            activityType: ActivityType.spouseCheckIn.rawValue,
            displayName: "Spouse Check-in Preparation",
            icon: "heart.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.spouse-checkin-prep",
            section: .connection
        ),
        DailyEligibleActivity(
            activityType: ActivityType.recoveryCheckIn.rawValue,
            displayName: "Recovery Check-in",
            icon: "heart.text.clipboard",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.check-ins",
            section: .sobrietyCommitment
        ),
        DailyEligibleActivity(
            activityType: ActivityType.fasterScale.rawValue,
            displayName: "FASTER Scale",
            icon: "gauge.with.needle",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.faster-scale",
            section: .sobrietyCommitment
        ),
        DailyEligibleActivity(
            activityType: "pci",
            displayName: "PCI",
            icon: "checklist",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.pci",
            section: .sobrietyCommitment
        ),
        DailyEligibleActivity(
            activityType: ActivityType.weeklyGoals.rawValue,
            displayName: "Weekly/Daily Goals Review",
            icon: "target",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.goals",
            section: .growth
        ),
        DailyEligibleActivity(
            activityType: "nutrition",
            displayName: "Nutrition (Meal Logging)",
            icon: "fork.knife",
            multiplePerDay: true,
            maxPerDay: 5,
            defaultEnabled: false,
            typicalHour: 12,
            typicalMinute: 0,
            typicalBlock: "Midday",
            featureFlagKey: "activity.nutrition",
            section: .selfCare
        ),
        DailyEligibleActivity(
            activityType: ActivityType.timeJournal.rawValue,
            displayName: "T30/60 Journaling",
            icon: "clock.fill",
            multiplePerDay: true,
            maxPerDay: 24,
            defaultEnabled: false,
            typicalHour: 7,
            typicalMinute: 0,
            typicalBlock: "Morning",
            featureFlagKey: "activity.time-journal",
            section: .journalingReflection
        ),
        DailyEligibleActivity(
            activityType: "actingInBehaviors",
            displayName: "Acting In Behaviors Check-in",
            icon: "shield.lefthalf.filled",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.acting-in-behaviors",
            section: .sobrietyCommitment
        ),
        DailyEligibleActivity(
            activityType: "voiceJournal",
            displayName: "Voice Journal",
            icon: "mic.fill",
            multiplePerDay: true,
            maxPerDay: 10,
            defaultEnabled: false,
            typicalHour: 12,
            typicalMinute: 0,
            typicalBlock: "Midday",
            featureFlagKey: "activity.voice-journal",
            section: .journalingReflection
        ),
        DailyEligibleActivity(
            activityType: "bookReading",
            displayName: "Book Reading",
            icon: "book.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.book-reading",
            section: .growth
        ),
    ]
}
