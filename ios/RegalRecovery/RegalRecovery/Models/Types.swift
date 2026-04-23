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
    let linkedDaysAgo: Int
    let phone: String
}

enum ContactRole: String {
    case sponsor = "Sponsor"
    case counselor = "Counselor (CSAT)"
    case spouse = "Spouse"
    case accountabilityPartner = "Accountability Partner"

    var displayName: String {
        switch self {
        case .sponsor: return String(localized: "Sponsor")
        case .counselor: return String(localized: "Counselor (CSAT)")
        case .spouse: return String(localized: "Spouse")
        case .accountabilityPartner: return String(localized: "Accountability Partner")
        }
    }

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
    case journal = "Journal / Jotting"
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
    case fanos = "FANOS Check-in"
    case fitnap = "FITNAP Check-in"
    case stepWork = "12-Step Work"
    case weeklyGoals = "Weekly Goals"
    case affirmationLog = "Affirmation Log"
    case motivations = "Motivations"
    case triggerLog = "Trigger Log"

    var displayName: String {
        switch self {
        case .sobrietyCommitment: return String(localized: "Daily Sobriety Commitment")
        case .journal: return String(localized: "Journal / Jotting")
        case .timeJournal: return String(localized: "Time Journal")
        case .fasterScale: return String(localized: "FASTER Scale")
        case .postMortem: return String(localized: "Post-Mortem Analysis")
        case .urgeLog: return String(localized: "Urge Log")
        case .mood: return String(localized: "Mood Rating")
        case .gratitude: return String(localized: "Gratitude List")
        case .prayer: return String(localized: "Prayer")
        case .exercise: return String(localized: "Exercise")
        case .phoneCalls: return String(localized: "Phone Calls")
        case .meetingsAttended: return String(localized: "Meetings Attended")
        case .fanos: return String(localized: "FANOS Check-in")
        case .fitnap: return String(localized: "FITNAP Check-in")
        case .stepWork: return String(localized: "12-Step Work")
        case .weeklyGoals: return String(localized: "Weekly Goals")
        case .affirmationLog: return String(localized: "Affirmation Log")
        case .motivations: return String(localized: "Motivations")
        case .triggerLog: return String(localized: "Trigger Log")
        }
    }

    var icon: String {
        switch self {
        case .sobrietyCommitment: return "sun.max.fill"
        case .journal: return "note.text"
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
        case .fanos: return "heart.fill"
        case .fitnap: return "heart.text.clipboard"
        case .stepWork: return "stairs"
        case .weeklyGoals: return "target"
        case .affirmationLog: return "text.quote"
        case .motivations: return "flame.fill"
        case .triggerLog: return "bolt.trianglebadge.exclamationmark.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .sobrietyCommitment: return .rrSecondary
        case .journal, .timeJournal: return .purple
        case .fasterScale: return .rrSuccess
        case .postMortem: return .rrDestructive
        case .urgeLog: return .orange
        case .mood: return .yellow
        case .gratitude: return .rrSuccess
        case .prayer: return .rrPrimary
        case .exercise: return .blue
        case .phoneCalls: return .green
        case .meetingsAttended: return .rrPrimary
        case .fanos: return .pink
        case .fitnap: return .pink
        case .stepWork: return .rrSecondary
        case .weeklyGoals: return .rrPrimary
        case .affirmationLog: return .rrSecondary
        case .motivations: return .orange
        case .triggerLog: return Color(red: 0.345, green: 0.337, blue: 0.839)
        }
    }

    var section: ActivitySection {
        switch self {
        case .sobrietyCommitment:
            return .sobrietyCommitment
        case .journal, .timeJournal, .fasterScale, .postMortem:
            return .journalingReflection
        case .urgeLog, .mood, .gratitude, .prayer, .exercise, .triggerLog:
            return .selfCare
        case .phoneCalls, .meetingsAttended, .fanos, .fitnap:
            return .connection
        case .stepWork, .weeklyGoals, .affirmationLog, .motivations:
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

    var displayName: String {
        switch self {
        case .sobrietyCommitment: return String(localized: "Sobriety & Commitment")
        case .journalingReflection: return String(localized: "Journaling & Reflection")
        case .selfCare: return String(localized: "Self-Care & Wellness")
        case .connection: return String(localized: "Connection")
        case .growth: return String(localized: "Growth")
        }
    }
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
        case .restoration: return String(localized: "Restoration")
        case .forgettingPriorities: return String(localized: "Forgetting Priorities")
        case .anxiety: return String(localized: "Anxiety")
        case .speedingUp: return String(localized: "Speeding Up")
        case .tickedOff: return String(localized: "Ticked Off")
        case .exhausted: return String(localized: "Exhausted")
        case .relapse: return String(localized: "Relapse")
        }
    }

    var letter: String {
        switch self {
        case .restoration: return "R+"
        case .forgettingPriorities: return "F"
        case .anxiety: return "A"
        case .speedingUp: return "S"
        case .tickedOff: return "T"
        case .exhausted: return "E"
        case .relapse: return "R"
        }
    }

    var subtitle: String {
        switch self {
        case .restoration: return String(localized: "The starting line")
        case .forgettingPriorities: return String(localized: "The quiet drift")
        case .anxiety: return String(localized: "The background noise gets louder")
        case .speedingUp: return String(localized: "Running from the pain you won't name")
        case .tickedOff: return String(localized: "Anger takes the wheel")
        case .exhausted: return String(localized: "The crash")
        case .relapse: return String(localized: "The cycle restarts")
        }
    }

    var description: String {
        switch self {
        case .restoration:
            return String(localized: "You're being honest, staying connected, keeping your commitments, and dealing with problems as they come up. No current secrets. This is where recovery lives — not perfection, but presence.")
        case .forgettingPriorities:
            return String(localized: "The most subtle stage. You start drifting from the things that keep you healthy — skipping a meeting, losing touch with your partner, spending more time scrolling than connecting. Overconfidence is the hallmark.")
        case .anxiety:
            return String(localized: "A growing sense of unease moves in. Old negative thoughts replay. Your brain picks up on the drift and tags it as danger. Sleep gets worse, you become more judgmental, and current stresses start feeling catastrophic.")
        case .speedingUp:
            return String(localized: "You can't outrun anxiety, but you're going to try. Relentless busyness — staying so occupied you never sit with your feelings. Deceptive because culture rewards it. Underneath is someone terrified to slow down.")
        case .tickedOff:
            return String(localized: "Anger has become your primary coping mechanism. It works temporarily — provides adrenaline, makes you feel powerful, gives you someone to blame. Black-and-white thinking, keeping score, defensiveness, self-pity.")
        case .exhausted:
            return String(localized: "The adrenaline from anger has run out. Heavy fog — depression, hopelessness, emotional numbness. Cravings become overwhelming because your brain is desperately searching for anything that feels normal. This is the danger zone.")
        case .relapse:
            return String(localized: "The behavior returns. And immediately, the shame arrives. The cruelest part: shame drives isolation, which restarts the entire FASTER descent. Relapse is not the end of recovery — it is information.")
        }
    }

    var color: Color {
        switch self {
        case .restoration: return Color(red: 0.176, green: 0.416, blue: 0.310)       // #2D6A4F
        case .forgettingPriorities: return Color(red: 0.482, green: 0.620, blue: 0.239) // #7B9E3D
        case .anxiety: return Color(red: 0.788, green: 0.635, blue: 0.153)             // #C9A227
        case .speedingUp: return Color(red: 0.831, green: 0.502, blue: 0.165)          // #D4802A
        case .tickedOff: return Color(red: 0.788, green: 0.365, blue: 0.180)           // #C95D2E
        case .exhausted: return Color(red: 0.651, green: 0.239, blue: 0.251)           // #A63D40
        case .relapse: return Color(red: 0.420, green: 0.153, blue: 0.216)             // #6B2737
        }
    }

    var indicators: [String] {
        switch self {
        case .restoration:
            return [
                String(localized: "No active secrets"),
                String(localized: "Keeping commitments"),
                String(localized: "Honest relationships"),
                String(localized: "Attending meetings"),
                String(localized: "Processing pain openly"),
                String(localized: "Growing in connection"),
            ]
        case .forgettingPriorities:
            return [
                String(localized: "Skipping meetings"),
                String(localized: "Isolating"),
                String(localized: "Keeping small secrets"),
                String(localized: "Sarcasm and cynicism"),
                String(localized: "Overconfidence"),
                String(localized: "Procrastinating"),
                String(localized: "Losing interest in growth"),
                String(localized: "Entertainment as escape"),
            ]
        case .anxiety:
            return [
                String(localized: "Vague worry or dread"),
                String(localized: "Negative self-talk replaying"),
                String(localized: "Sleep problems"),
                String(localized: "Perfectionism"),
                String(localized: "Judging others harshly"),
                String(localized: "People-pleasing"),
                String(localized: "Flirting for reassurance"),
                String(localized: "Unrealistic to-do lists"),
            ]
        case .speedingUp:
            return [
                String(localized: "Workaholic behavior"),
                String(localized: "Can't relax or sit still"),
                String(localized: "Skipping meals"),
                String(localized: "Excessive caffeine"),
                String(localized: "Over-exercising"),
                String(localized: "Racing thoughts at night"),
                String(localized: "Overspending"),
                String(localized: "Constant device use"),
            ]
        case .tickedOff:
            return [
                String(localized: "Resentment and bitterness"),
                String(localized: "Black-and-white thinking"),
                String(localized: "Blaming everyone else"),
                String(localized: "Defensiveness"),
                String(localized: "Road rage"),
                String(localized: "Self-pity"),
                String(localized: "Silent treatment"),
                String(localized: "Intimidation"),
            ]
        case .exhausted:
            return [
                String(localized: "Emotional numbness"),
                String(localized: "Hopelessness"),
                String(localized: "Spontaneous crying"),
                String(localized: "Intense cravings"),
                String(localized: "Survival mode"),
                String(localized: "Missing work or obligations"),
                String(localized: "Confusion and poor decisions"),
                String(localized: "Thoughts of self-harm"),
            ]
        case .relapse:
            return [
                String(localized: "Acting out on addictive behavior"),
                String(localized: "Breaking sobriety commitment"),
            ]
        }
    }

    /// Adaptive content shown after assessment for this stage.
    var adaptiveContent: (title: String, body: String) {
        switch self {
        case .restoration:
            return (String(localized: "You're in Restoration"), String(localized: "Keep doing what you're doing. Stay connected, keep your commitments, and continue processing life honestly with the people around you. Recovery lives in the daily practice."))
        case .forgettingPriorities:
            return (String(localized: "Priority Check"), String(localized: "Take a moment to review your commitments. Are you attending your meetings? Have you called your accountability partner this week? Are there small secrets forming? Reconnect with one priority today."))
        case .anxiety:
            return (String(localized: "Ground Yourself"), String(localized: "Try the 5-4-3-2-1 grounding exercise: Name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, and 1 you taste. Take three slow breaths. The anxiety is a signal — not a verdict."))
        case .speedingUp:
            return (String(localized: "Slow Down"), String(localized: "Your busyness is a shield against feeling. Challenge: take 10 minutes right now to do absolutely nothing. No phone, no tasks. Just sit. Notice what feelings come up when you stop running."))
        case .tickedOff:
            return (String(localized: "Name What's Underneath"), String(localized: "Anger feels powerful, but it's masking something. What are you really feeling beneath the irritation? Try naming the emotion without judging it. Consider reaching out to your counselor or accountability partner today."))
        case .exhausted:
            return (String(localized: "You Need Support Now"), String(localized: "You're running on empty and your coping capacity is depleted. This is not the time to push through alone. Please reach out to your accountability partner, sponsor, or counselor today. You don't have to explain everything — just say you're struggling."))
        case .relapse:
            return (String(localized: "This Is Not the End"), String(localized: "Relapse is painful, but it is not your identity. The shame you're feeling right now is the exact force that restarts the cycle — don't let it drive you into isolation. Call your accountability partner or sponsor. If you're in crisis, contact the 988 Suicide & Crisis Lifeline (call or text 988)."))
        }
    }
}

/// Check-in phase for the multi-step FASTER Scale flow.
enum CheckInPhase {
    case mood
    case scale
    case results
}

struct FASTEREntry: Identifiable {
    let id: UUID
    let date: Date
    let stage: FASTERStage
    let moodScore: Int
    let selectedIndicators: [FASTERStage: Set<String>]

    init(id: UUID = UUID(), date: Date, stage: FASTERStage, moodScore: Int = 3, selectedIndicators: [FASTERStage: Set<String>] = [:]) {
        self.id = id
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

    var displayName: String {
        switch self {
        case .happy: return String(localized: "Happy")
        case .sad: return String(localized: "Sad")
        case .angry: return String(localized: "Angry")
        case .fearful: return String(localized: "Fearful")
        case .disgusted: return String(localized: "Disgusted")
        case .surprised: return String(localized: "Surprised")
        }
    }

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
        case .happy: return [String(localized: "Joyful"), String(localized: "Grateful"), String(localized: "Content"), String(localized: "Peaceful"), String(localized: "Hopeful"), String(localized: "Proud")]
        case .sad: return [String(localized: "Lonely"), String(localized: "Grieving"), String(localized: "Disappointed"), String(localized: "Hopeless"), String(localized: "Ashamed"), String(localized: "Empty")]
        case .angry: return [String(localized: "Frustrated"), String(localized: "Resentful"), String(localized: "Irritated"), String(localized: "Bitter"), String(localized: "Jealous"), String(localized: "Betrayed")]
        case .fearful: return [String(localized: "Anxious"), String(localized: "Insecure"), String(localized: "Overwhelmed"), String(localized: "Vulnerable"), String(localized: "Panicked"), String(localized: "Worried")]
        case .disgusted: return [String(localized: "Contemptuous"), String(localized: "Repulsed"), String(localized: "Self-loathing"), String(localized: "Judgmental")]
        case .surprised: return [String(localized: "Shocked"), String(localized: "Confused"), String(localized: "Amazed"), String(localized: "Startled")]
        }
    }
}

// MARK: - Mood Check-In

enum MoodPrimary: String, CaseIterable, Identifiable {
    case love = "Love"
    case joy = "Joy"
    case surprise = "Surprise"
    case anger = "Anger"
    case sadness = "Sadness"
    case fear = "Fear"

    var id: String { rawValue }

    var score: Int {
        switch self {
        case .love: return 9
        case .joy: return 10
        case .surprise: return 6
        case .anger: return 3
        case .sadness: return 2
        case .fear: return 2
        }
    }

    var emoji: String {
        switch self {
        case .love: return "❤️"
        case .joy: return "😊"
        case .surprise: return "😮"
        case .anger: return "😠"
        case .sadness: return "😢"
        case .fear: return "😨"
        }
    }

    var color: Color {
        switch self {
        case .love: return Color(red: 0.831, green: 0.220, blue: 0.353)
        case .joy: return Color(red: 0.976, green: 0.733, blue: 0.176)
        case .surprise: return Color(red: 0.482, green: 0.620, blue: 0.239)
        case .anger: return Color(red: 0.831, green: 0.243, blue: 0.196)
        case .sadness: return Color(red: 0.247, green: 0.459, blue: 0.702)
        case .fear: return Color(red: 0.506, green: 0.286, blue: 0.635)
        }
    }

    var secondaryEmotions: [SecondaryEmotion] {
        switch self {
        case .love:
            return [
                SecondaryEmotion(name: "Affection", emoji: "🥰", description: "Warmth and caring toward someone", tertiaryEmotions: ["Adoration", "Fondness", "Liking", "Attractiveness", "Caring", "Tenderness", "Compassion", "Sentimentality"]),
                SecondaryEmotion(name: "Lust", emoji: "🔥", description: "Intense physical or emotional desire", tertiaryEmotions: ["Desire", "Passion", "Infatuation"]),
                SecondaryEmotion(name: "Longing", emoji: "💭", description: "Deep yearning for connection or closeness", tertiaryEmotions: ["Longing"]),
            ]
        case .joy:
            return [
                SecondaryEmotion(name: "Cheerfulness", emoji: "😄", description: "Light-hearted happiness and good spirits", tertiaryEmotions: ["Amusement", "Bliss", "Gaiety", "Glee", "Jolliness", "Joviality", "Delight", "Enjoyment", "Gladness", "Happiness", "Jubilation", "Elation", "Satisfaction", "Ecstasy", "Euphoria"]),
                SecondaryEmotion(name: "Zest", emoji: "⚡", description: "Energetic enthusiasm and excitement", tertiaryEmotions: ["Enthusiasm", "Zeal", "Excitement", "Thrill", "Exhilaration"]),
                SecondaryEmotion(name: "Contentment", emoji: "😌", description: "Quiet satisfaction with how things are", tertiaryEmotions: ["Pleasure", "Contentment"]),
                SecondaryEmotion(name: "Pride", emoji: "🦁", description: "Satisfaction from achievement or self-worth", tertiaryEmotions: ["Triumph", "Pride"]),
                SecondaryEmotion(name: "Optimism", emoji: "🌅", description: "Hopefulness about what's ahead", tertiaryEmotions: ["Eagerness", "Hope", "Optimism"]),
                SecondaryEmotion(name: "Enthrallment", emoji: "✨", description: "Captivated and deeply absorbed", tertiaryEmotions: ["Enthrallment", "Rapture"]),
                SecondaryEmotion(name: "Relief", emoji: "😮‍💨", description: "Tension releasing after worry or stress", tertiaryEmotions: ["Relief"]),
            ]
        case .surprise:
            return [
                SecondaryEmotion(name: "Surprise", emoji: "😲", description: "Unexpected event catching you off guard", tertiaryEmotions: ["Amazement", "Astonishment"]),
            ]
        case .anger:
            return [
                SecondaryEmotion(name: "Irritation", emoji: "😤", description: "Low-level annoyance building under the surface", tertiaryEmotions: ["Aggravation", "Agitation", "Annoyance", "Grouchiness", "Grumpiness"]),
                SecondaryEmotion(name: "Exasperation", emoji: "🤦", description: "Frustrated beyond patience", tertiaryEmotions: ["Exasperation", "Frustration"]),
                SecondaryEmotion(name: "Rage", emoji: "🤬", description: "Intense, overwhelming anger", tertiaryEmotions: ["Anger", "Hostility", "Ferocity", "Bitterness", "Outrage", "Fury", "Wrath", "Loathing", "Scorn", "Spite", "Vengefulness", "Dislike", "Resentment"]),
                SecondaryEmotion(name: "Disgust", emoji: "🤢", description: "Strong aversion or moral repulsion", tertiaryEmotions: ["Disgust", "Revulsion", "Contempt"]),
                SecondaryEmotion(name: "Envy", emoji: "💚", description: "Wanting what someone else has", tertiaryEmotions: ["Envy", "Jealousy"]),
                SecondaryEmotion(name: "Torment", emoji: "😖", description: "Agonizing internal conflict or suffering", tertiaryEmotions: ["Torment"]),
            ]
        case .sadness:
            return [
                SecondaryEmotion(name: "Suffering", emoji: "💔", description: "Deep emotional or physical pain", tertiaryEmotions: ["Agony", "Anguish", "Hurt"]),
                SecondaryEmotion(name: "Sadness", emoji: "😞", description: "General heaviness and low mood", tertiaryEmotions: ["Depression", "Despair", "Gloom", "Glumness", "Unhappiness", "Grief", "Sorrow", "Woe", "Misery", "Melancholy"]),
                SecondaryEmotion(name: "Disappointment", emoji: "😔", description: "Unmet expectations or letdown", tertiaryEmotions: ["Dismay", "Displeasure", "Disappointment"]),
                SecondaryEmotion(name: "Shame", emoji: "😳", description: "Feeling exposed, flawed, or unworthy", tertiaryEmotions: ["Guilt", "Shame", "Regret", "Remorse"]),
                SecondaryEmotion(name: "Neglect", emoji: "🫥", description: "Feeling unseen, dismissed, or abandoned", tertiaryEmotions: ["Alienation", "Defeatism", "Dejection", "Embarrassment", "Homesickness", "Humiliation", "Insecurity", "Isolation", "Insult", "Loneliness", "Rejection"]),
                SecondaryEmotion(name: "Sympathy", emoji: "🫂", description: "Feeling sorrow for another's pain", tertiaryEmotions: ["Pity", "Sympathy"]),
            ]
        case .fear:
            return [
                SecondaryEmotion(name: "Horror", emoji: "😱", description: "Intense shock or dread from perceived danger", tertiaryEmotions: ["Alarm", "Shock", "Fright", "Horror", "Terror", "Panic", "Hysteria", "Mortification"]),
                SecondaryEmotion(name: "Nervousness", emoji: "😰", description: "Uneasy anticipation of something bad", tertiaryEmotions: ["Anxiety", "Apprehension", "Distress", "Dread", "Nervousness", "Tenseness", "Uneasiness", "Worry"]),
            ]
        }
    }
}

struct SecondaryEmotion: Identifiable {
    let name: String
    let emoji: String
    let description: String
    let tertiaryEmotions: [String]

    var id: String { name }
}

enum MoodCheckInStep: Int, CaseIterable {
    case primaryMood = 0
    case secondaryEmotion
    case tertiaryEmotion
    case intensityAndContext
    case journalPrompt

    var title: String {
        switch self {
        case .primaryMood: return "How are you feeling?"
        case .secondaryEmotion: return "More specifically..."
        case .tertiaryEmotion: return "Even more precisely..."
        case .intensityAndContext: return "Tell me more"
        case .journalPrompt: return "Reflect"
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

struct Affirmation: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let scripture: String
    var isFavorite: Bool

    var stableKey: String { text }
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
    case journal
    case fasterScale
    case urgeLog
    case mood
    case gratitude
    case prayer
    case exercise
    case phoneCall
    case meeting
    case fanos
    case fitnap
    case triggerLog
    case bowtie
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
    let textOption: String?
    let category: String
    let is24x7: Bool

    init(name: String, phone: String, description: String, textOption: String? = nil, category: String = "Crisis", is24x7: Bool = true) {
        self.name = name
        self.phone = phone
        self.description = description
        self.textOption = textOption
        self.category = category
        self.is24x7 = is24x7
    }
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

    var displayName: String {
        switch self {
        case .system: return String(localized: "System")
        case .light: return String(localized: "Light")
        case .dark: return String(localized: "Dark")
        }
    }
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

    var displayName: String {
        switch self {
        case .completed: return String(localized: "Completed")
        case .pending: return String(localized: "Pending")
        case .upcoming: return String(localized: "Upcoming")
        case .overdue: return String(localized: "Overdue")
        case .skipped: return String(localized: "Skipped")
        }
    }

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
        case .excellent: return String(localized: "Excellent")
        case .strong: return String(localized: "Strong")
        case .moderate: return String(localized: "Moderate")
        case .low: return String(localized: "Low")
        case .minimal: return String(localized: "Minimal")
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
    let displayNameKey: String
    let shortNameKey: String
    let icon: String
    let multiplePerDay: Bool
    let maxPerDay: Int
    let defaultEnabled: Bool
    let typicalHour: Int
    let typicalMinute: Int
    let typicalBlock: String
    let featureFlagKey: String
    let section: ActivitySection

    var displayName: String {
        String(localized: String.LocalizationValue(displayNameKey))
    }

    var shortName: String {
        String(localized: String.LocalizationValue(shortNameKey))
    }

    /// Activities filtered by feature flags (reactive via FeatureFlagStore)
    static var enabled: [DailyEligibleActivity] {
        all.filter { activity in
            FeatureFlagStore.shared.isEnabled(activity.featureFlagKey)
        }
    }

    static let all: [DailyEligibleActivity] = [
        DailyEligibleActivity(
            activityType: ActivityType.sobrietyCommitment.rawValue,
            displayNameKey: "Morning Commitment",
            shortNameKey: "Commitment",
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
            displayNameKey: "Affirmations",
            shortNameKey: "Affirmations",
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
            displayNameKey: "Journaling",
            shortNameKey: "Journaling",
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
            displayNameKey: "Devotional",
            shortNameKey: "Devotional",
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
            displayNameKey: "Prayer",
            shortNameKey: "Prayer",
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
            displayNameKey: "Memory Verse Review",
            shortNameKey: "Memory Verse",
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
            activityType: ActivityType.mood.rawValue,
            displayNameKey: "Mood Rating",
            shortNameKey: "Mood",
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
            displayNameKey: "Gratitude List",
            shortNameKey: "Gratitude",
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
            displayNameKey: "Phone Calls",
            shortNameKey: "Calls",
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
            displayNameKey: "Exercise / Physical Activity",
            shortNameKey: "Exercise",
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
            displayNameKey: "Meetings Attended",
            shortNameKey: "Meetings",
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
            displayNameKey: "Spouse Check-in",
            shortNameKey: "Spouse",
            icon: "heart.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.spouse-check-ins",
            section: .connection
        ),
        DailyEligibleActivity(
            activityType: ActivityType.fanos.rawValue,
            displayNameKey: "FANOS Check-in",
            shortNameKey: "FANOS",
            icon: "heart.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.fanos",
            section: .connection
        ),
        DailyEligibleActivity(
            activityType: ActivityType.fitnap.rawValue,
            displayNameKey: "FITNAP Check-in",
            shortNameKey: "FITNAP",
            icon: "heart.text.clipboard",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.fitnap",
            section: .connection
        ),
        DailyEligibleActivity(
            activityType: ActivityType.fasterScale.rawValue,
            displayNameKey: "FASTER Scale",
            shortNameKey: "FASTER",
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
            activityType: "lbi",
            displayNameKey: "Life Balance",
            shortNameKey: "LBI",
            icon: "checklist",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: true,
            typicalHour: 21,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "feature.lbi",
            section: .sobrietyCommitment
        ),
        DailyEligibleActivity(
            activityType: ActivityType.weeklyGoals.rawValue,
            displayNameKey: "Weekly/Daily Goals Review",
            shortNameKey: "Goals",
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
            displayNameKey: "Nutrition (Meal Logging)",
            shortNameKey: "Nutrition",
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
            displayNameKey: "T30/60 Journaling",
            shortNameKey: "Time Journal",
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
            displayNameKey: "Acting In Behaviors Check-in",
            shortNameKey: "Acting In",
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
            displayNameKey: "Voice Journal",
            shortNameKey: "Voice Journal",
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
            displayNameKey: "Recovery Reading",
            shortNameKey: "Reading",
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
        DailyEligibleActivity(
            activityType: ActivityType.motivations.rawValue,
            displayNameKey: "Motivations",
            shortNameKey: "Motivations",
            icon: "flame.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 7,
            typicalMinute: 0,
            typicalBlock: "Morning",
            featureFlagKey: "activity.motivations",
            section: .growth
        ),
        DailyEligibleActivity(
            activityType: ActivityType.triggerLog.rawValue,
            displayNameKey: "Trigger Log",
            shortNameKey: "Triggers",
            icon: "bolt.trianglebadge.exclamationmark.fill",
            multiplePerDay: true,
            maxPerDay: 20,
            defaultEnabled: false,
            typicalHour: 12,
            typicalMinute: 0,
            typicalBlock: "Anytime",
            featureFlagKey: "activity.triggers",
            section: .selfCare
        ),
        DailyEligibleActivity(
            activityType: "bowtie",
            displayNameKey: "Bowtie Diagram",
            shortNameKey: "Bowtie",
            icon: "asset:bowtie.icon",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 19,
            typicalMinute: 0,
            typicalBlock: "Evening",
            featureFlagKey: "activity.bowtie",
            section: .growth
        ),
    ]
}
