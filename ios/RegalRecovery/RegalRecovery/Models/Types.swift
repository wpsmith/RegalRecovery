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
    case forgettingPriorities = 0
    case anxiety
    case speedingUp
    case tickedOff
    case exhausted
    case relapse

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .forgettingPriorities: return "Forgetting Priorities"
        case .anxiety: return "Anxiety"
        case .speedingUp: return "Speeding Up"
        case .tickedOff: return "Ticked Off"
        case .exhausted: return "Exhausted"
        case .relapse: return "Relapse"
        }
    }

    var letter: String {
        String(name.prefix(1))
    }

    var description: String {
        switch self {
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
        case .forgettingPriorities: return .rrSuccess
        case .anxiety: return .yellow
        case .speedingUp: return .orange
        case .tickedOff: return .orange
        case .exhausted: return .rrDestructive
        case .relapse: return .rrDestructive
        }
    }
}

struct FASTEREntry: Identifiable {
    let id = UUID()
    let date: Date
    let stage: FASTERStage
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

struct RecentActivity: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let time: String
    let icon: String
    let iconColor: Color
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
