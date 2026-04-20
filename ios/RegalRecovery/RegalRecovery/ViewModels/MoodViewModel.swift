import Foundation
import SwiftData

@Observable
class MoodCheckInViewModel {

    // MARK: - Flow State

    var currentStep: MoodCheckInStep = .primaryMood
    var showCompletion = false

    // MARK: - Layer 1: Primary Mood

    var selectedPrimary: MoodPrimary?

    // MARK: - Layer 2: Secondary Emotion

    var selectedSecondary: SecondaryEmotion?
    var showSecondaryInfo: SecondaryEmotion?

    // MARK: - Layer 2.5: Tertiary Emotion

    var selectedTertiary: String?
    var showTertiaryConfirmation = false
    var showTertiaryInfo: String?

    // MARK: - Layer 3: Intensity & Context

    var intensity: Double = 5
    var urgeToActOut: Double = 0
    var selectedTags: Set<String> = []
    var activityDetails: String = ""
    var whoDetails: String = ""

    // MARK: - Layer 4: Journal

    var journalPrompt: String = ""
    var journalResponse: String = ""

    // MARK: - Context Tag Options

    static let triggerTags = ["Stress", "Boredom", "Loneliness", "Conflict", "Fatigue", "Temptation", "Social Media", "HALT"]
    static let activityTags = ["Working", "Exercising", "Praying", "Meeting", "Socializing", "Resting", "Commuting", "Eating"]
    static let peopleTags = ["Alone", "With Spouse", "With Family", "With Friends", "Work Colleagues", "With Sponsor", "In Group"]
    static let peopleWhoTags: Set<String> = ["With Family", "With Friends", "Work Colleagues", "In Group"]

    // MARK: - Tertiary Emotion Metadata

    struct TertiaryMeta {
        let emoji: String
        let description: String
    }

    static let tertiaryMetadata: [String: TertiaryMeta] = [
        // Love > Affection
        "Adoration": TertiaryMeta(emoji: "😍", description: "Deep, devoted love and admiration"),
        "Fondness": TertiaryMeta(emoji: "🥰", description: "Gentle affection and warm regard"),
        "Liking": TertiaryMeta(emoji: "😊", description: "Pleasant feelings of enjoyment toward someone"),
        "Attractiveness": TertiaryMeta(emoji: "💫", description: "Feeling drawn to someone magnetically"),
        "Caring": TertiaryMeta(emoji: "🤲", description: "Wanting to nurture and support someone"),
        "Tenderness": TertiaryMeta(emoji: "💕", description: "Soft, gentle warmth toward another"),
        "Compassion": TertiaryMeta(emoji: "🙏", description: "Deep empathy and desire to ease suffering"),
        "Sentimentality": TertiaryMeta(emoji: "🥹", description: "Moved by memories or meaningful moments"),
        // Love > Lust
        "Desire": TertiaryMeta(emoji: "🔥", description: "Strong wanting or craving for closeness"),
        "Passion": TertiaryMeta(emoji: "❤️‍🔥", description: "Intense, consuming emotional or physical drive"),
        "Infatuation": TertiaryMeta(emoji: "💘", description: "Overwhelming, often unrealistic attraction"),
        // Love > Longing
        "Longing": TertiaryMeta(emoji: "💭", description: "Aching desire for something or someone absent"),
        // Joy > Cheerfulness
        "Amusement": TertiaryMeta(emoji: "😄", description: "Lighthearted entertainment and fun"),
        "Bliss": TertiaryMeta(emoji: "🤩", description: "Perfect, serene happiness"),
        "Gaiety": TertiaryMeta(emoji: "🎉", description: "Festive, carefree lightheartedness"),
        "Glee": TertiaryMeta(emoji: "😁", description: "Triumphant, almost mischievous delight"),
        "Jolliness": TertiaryMeta(emoji: "🤗", description: "Cheerful, warm good humor"),
        "Joviality": TertiaryMeta(emoji: "😃", description: "Hearty, sociable cheerfulness"),
        "Delight": TertiaryMeta(emoji: "🥳", description: "Great pleasure from something wonderful"),
        "Enjoyment": TertiaryMeta(emoji: "😌", description: "Quiet pleasure from a positive experience"),
        "Gladness": TertiaryMeta(emoji: "😀", description: "Simple, uncomplicated happiness"),
        "Happiness": TertiaryMeta(emoji: "😊", description: "Stable sense of well-being and contentment"),
        "Jubilation": TertiaryMeta(emoji: "🙌", description: "Exuberant celebration of success"),
        "Elation": TertiaryMeta(emoji: "🎊", description: "Soaring high spirits and excitement"),
        "Satisfaction": TertiaryMeta(emoji: "😏", description: "Fulfillment from something well done"),
        "Ecstasy": TertiaryMeta(emoji: "✨", description: "Overwhelming, transcendent joy"),
        "Euphoria": TertiaryMeta(emoji: "🌟", description: "Intense, almost surreal happiness"),
        // Joy > Zest
        "Enthusiasm": TertiaryMeta(emoji: "⚡", description: "Eager, energetic interest in something"),
        "Zeal": TertiaryMeta(emoji: "🔥", description: "Passionate devotion to a cause or idea"),
        "Excitement": TertiaryMeta(emoji: "🤸", description: "Energized anticipation of something good"),
        "Thrill": TertiaryMeta(emoji: "🎢", description: "Sudden rush of exhilarating excitement"),
        "Exhilaration": TertiaryMeta(emoji: "🚀", description: "Invigorating sense of vitality and freedom"),
        // Joy > Contentment
        "Pleasure": TertiaryMeta(emoji: "☺️", description: "Enjoying a moment or sensation"),
        "Contentment": TertiaryMeta(emoji: "😌", description: "Peaceful acceptance of how things are"),
        // Joy > Pride
        "Triumph": TertiaryMeta(emoji: "🏆", description: "Victory or significant achievement"),
        "Pride": TertiaryMeta(emoji: "🦁", description: "Satisfaction in your own worth or accomplishment"),
        // Joy > Optimism
        "Eagerness": TertiaryMeta(emoji: "🙋", description: "Ready and enthusiastic to begin"),
        "Hope": TertiaryMeta(emoji: "🌱", description: "Believing something good is coming"),
        "Optimism": TertiaryMeta(emoji: "🌅", description: "Confident expectation of positive outcomes"),
        // Joy > Enthrallment
        "Enthrallment": TertiaryMeta(emoji: "🌀", description: "Completely captivated and absorbed"),
        "Rapture": TertiaryMeta(emoji: "💎", description: "Transported by intense beauty or wonder"),
        // Joy > Relief
        "Relief": TertiaryMeta(emoji: "😮‍💨", description: "Tension dissolving after worry passes"),
        // Surprise
        "Amazement": TertiaryMeta(emoji: "🤯", description: "Stunned by something extraordinary"),
        "Astonishment": TertiaryMeta(emoji: "😲", description: "Shocked by the unexpected"),
        // Anger > Irritation
        "Aggravation": TertiaryMeta(emoji: "😠", description: "Annoyance intensified by persistence"),
        "Agitation": TertiaryMeta(emoji: "😤", description: "Restless, uncomfortable irritation"),
        "Annoyance": TertiaryMeta(emoji: "🙄", description: "Mild frustration at something bothersome"),
        "Grouchiness": TertiaryMeta(emoji: "😾", description: "Cranky, easily irritated mood"),
        "Grumpiness": TertiaryMeta(emoji: "😒", description: "Persistently dissatisfied and short-tempered"),
        // Anger > Exasperation
        "Exasperation": TertiaryMeta(emoji: "🤦", description: "Patience completely exhausted"),
        "Frustration": TertiaryMeta(emoji: "😩", description: "Blocked from achieving what you want"),
        // Anger > Rage
        "Anger": TertiaryMeta(emoji: "😡", description: "Strong displeasure demanding action"),
        "Hostility": TertiaryMeta(emoji: "👊", description: "Aggressive opposition toward someone"),
        "Ferocity": TertiaryMeta(emoji: "🐺", description: "Wild, untamed intensity of feeling"),
        "Bitterness": TertiaryMeta(emoji: "🍋", description: "Resentment hardened over time"),
        "Outrage": TertiaryMeta(emoji: "🤬", description: "Shocked anger at injustice"),
        "Fury": TertiaryMeta(emoji: "💢", description: "Uncontrollable, explosive anger"),
        "Wrath": TertiaryMeta(emoji: "⚔️", description: "Righteous, punishing anger"),
        "Loathing": TertiaryMeta(emoji: "🚫", description: "Intense hatred and disgust combined"),
        "Scorn": TertiaryMeta(emoji: "😏", description: "Contemptuous dismissal of someone"),
        "Spite": TertiaryMeta(emoji: "🗡️", description: "Desire to hurt someone who hurt you"),
        "Vengefulness": TertiaryMeta(emoji: "⚖️", description: "Driven to retaliate or punish"),
        "Dislike": TertiaryMeta(emoji: "👎", description: "Aversion without strong intensity"),
        "Resentment": TertiaryMeta(emoji: "😑", description: "Lingering anger from perceived unfairness"),
        // Anger > Disgust
        "Disgust": TertiaryMeta(emoji: "🤢", description: "Strong physical or moral revulsion"),
        "Revulsion": TertiaryMeta(emoji: "🤮", description: "Overwhelming desire to pull away"),
        "Contempt": TertiaryMeta(emoji: "😤", description: "Feeling someone is beneath you"),
        // Anger > Envy
        "Envy": TertiaryMeta(emoji: "💚", description: "Wanting what belongs to another"),
        "Jealousy": TertiaryMeta(emoji: "👀", description: "Fear of losing what's yours to another"),
        // Anger > Torment
        "Torment": TertiaryMeta(emoji: "😖", description: "Agonizing internal suffering"),
        // Sadness > Suffering
        "Agony": TertiaryMeta(emoji: "😫", description: "Extreme physical or emotional pain"),
        "Anguish": TertiaryMeta(emoji: "💔", description: "Severe distress from loss or helplessness"),
        "Hurt": TertiaryMeta(emoji: "🩹", description: "Emotional wound from someone's actions"),
        // Sadness > Sadness
        "Depression": TertiaryMeta(emoji: "🌧️", description: "Persistent low mood and loss of energy"),
        "Despair": TertiaryMeta(emoji: "🕳️", description: "Complete loss of hope"),
        "Gloom": TertiaryMeta(emoji: "☁️", description: "Dark, heavy emotional atmosphere"),
        "Glumness": TertiaryMeta(emoji: "😶", description: "Quiet, withdrawn low mood"),
        "Unhappiness": TertiaryMeta(emoji: "😞", description: "General dissatisfaction with life"),
        "Grief": TertiaryMeta(emoji: "🖤", description: "Deep sorrow from significant loss"),
        "Sorrow": TertiaryMeta(emoji: "😢", description: "Heartfelt sadness and regret"),
        "Woe": TertiaryMeta(emoji: "😿", description: "Grief-stricken lamentation"),
        "Misery": TertiaryMeta(emoji: "😣", description: "Prolonged suffering and wretchedness"),
        "Melancholy": TertiaryMeta(emoji: "🎵", description: "Bittersweet, reflective sadness"),
        // Sadness > Disappointment
        "Dismay": TertiaryMeta(emoji: "😧", description: "Distressed shock at bad news"),
        "Displeasure": TertiaryMeta(emoji: "😕", description: "Mild annoyance from unmet expectations"),
        "Disappointment": TertiaryMeta(emoji: "😔", description: "Sadness when reality falls short"),
        // Sadness > Shame
        "Guilt": TertiaryMeta(emoji: "😓", description: "Regret over a specific action taken"),
        "Shame": TertiaryMeta(emoji: "😳", description: "Feeling fundamentally flawed as a person"),
        "Regret": TertiaryMeta(emoji: "😞", description: "Wishing you'd chosen differently"),
        "Remorse": TertiaryMeta(emoji: "💧", description: "Deep sorrow for harm you caused"),
        // Sadness > Neglect
        "Alienation": TertiaryMeta(emoji: "🏝️", description: "Feeling cut off from others"),
        "Defeatism": TertiaryMeta(emoji: "🏳️", description: "Giving up before trying"),
        "Dejection": TertiaryMeta(emoji: "😮‍💨", description: "Cast down and dispirited"),
        "Embarrassment": TertiaryMeta(emoji: "🫣", description: "Self-conscious from social exposure"),
        "Homesickness": TertiaryMeta(emoji: "🏠", description: "Longing for familiar comfort"),
        "Humiliation": TertiaryMeta(emoji: "😶‍🌫️", description: "Stripped of dignity publicly"),
        "Insecurity": TertiaryMeta(emoji: "🫨", description: "Doubting your own worth or ability"),
        "Isolation": TertiaryMeta(emoji: "🧊", description: "Feeling completely alone and disconnected"),
        "Insult": TertiaryMeta(emoji: "💥", description: "Stung by disrespectful words"),
        "Loneliness": TertiaryMeta(emoji: "🫙", description: "Painful awareness of being alone"),
        "Rejection": TertiaryMeta(emoji: "🚪", description: "Excluded or turned away by others"),
        // Sadness > Sympathy
        "Pity": TertiaryMeta(emoji: "😿", description: "Sorrow for another's misfortune"),
        "Sympathy": TertiaryMeta(emoji: "🫂", description: "Sharing in someone else's emotional pain"),
        // Fear > Horror
        "Alarm": TertiaryMeta(emoji: "🚨", description: "Sudden alert to immediate danger"),
        "Shock": TertiaryMeta(emoji: "⚡", description: "Stunned inability to process what happened"),
        "Fright": TertiaryMeta(emoji: "😨", description: "Sudden sharp fear from a threat"),
        "Horror": TertiaryMeta(emoji: "😱", description: "Paralyzing dread at something terrible"),
        "Terror": TertiaryMeta(emoji: "🫣", description: "Extreme, overwhelming fear"),
        "Panic": TertiaryMeta(emoji: "😵", description: "Loss of rational control from fear"),
        "Hysteria": TertiaryMeta(emoji: "🌀", description: "Emotional overwhelm beyond reason"),
        "Mortification": TertiaryMeta(emoji: "💀", description: "Shame so intense it feels fatal"),
        // Fear > Nervousness
        "Anxiety": TertiaryMeta(emoji: "😰", description: "Persistent worry about what might happen"),
        "Apprehension": TertiaryMeta(emoji: "😟", description: "Uneasy dread about the future"),
        "Distress": TertiaryMeta(emoji: "😥", description: "Acute emotional suffering demanding relief"),
        "Dread": TertiaryMeta(emoji: "🫥", description: "Heavy anticipation of something awful"),
        "Nervousness": TertiaryMeta(emoji: "😬", description: "Jittery unease in uncertain situations"),
        "Tenseness": TertiaryMeta(emoji: "🧱", description: "Body and mind wound tight with stress"),
        "Uneasiness": TertiaryMeta(emoji: "😐", description: "Subtle discomfort that something is off"),
        "Worry": TertiaryMeta(emoji: "🤔", description: "Repetitive thoughts about potential problems"),
    ]

    func tertiaryEmoji(for emotion: String) -> String {
        Self.tertiaryMetadata[emotion]?.emoji ?? "•"
    }

    func tertiaryDescription(for emotion: String) -> String {
        Self.tertiaryMetadata[emotion]?.description ?? ""
    }

    // MARK: - Journal Prompts

    private static let promptsByMood: [MoodPrimary: [String]] = [
        .love: [
            "What's contributing to this feeling of connection?",
            "How can you nurture this relationship today?",
            "Who would you like to express gratitude toward?",
        ],
        .joy: [
            "What's contributing to this good feeling?",
            "How can you carry this energy forward?",
            "What healthy choice led to this feeling?",
        ],
        .surprise: [
            "What caught you off guard?",
            "How is this surprise affecting your recovery?",
            "What does this unexpected moment reveal?",
        ],
        .anger: [
            "What triggered this feeling?",
            "What are you really feeling beneath the anger?",
            "Who can you reach out to right now?",
        ],
        .sadness: [
            "What do you need most right now?",
            "What has helped you through hard times before?",
            "Can you name what you're feeling beneath the surface?",
        ],
        .fear: [
            "What specifically are you afraid of?",
            "What coping strategy will you use?",
            "Remember: this feeling is temporary, not permanent.",
        ],
    ]

    // MARK: - Computed

    var availableSecondaryEmotions: [SecondaryEmotion] {
        selectedPrimary?.secondaryEmotions ?? []
    }

    var availableTertiaryEmotions: [String] {
        selectedSecondary?.tertiaryEmotions ?? []
    }

    var suggestedPrompt: String {
        guard let primary = selectedPrimary,
              let prompts = Self.promptsByMood[primary] else {
            return "What's on your mind?"
        }
        let index = Calendar.current.component(.hour, from: Date()) % prompts.count
        return prompts[index]
    }

    var canSkipToSave: Bool {
        selectedPrimary != nil
    }

    var progressFraction: Double {
        Double(currentStep.rawValue + 1) / Double(MoodCheckInStep.allCases.count)
    }

    var canAdvance: Bool {
        switch currentStep {
        case .primaryMood:
            return selectedPrimary != nil
        case .secondaryEmotion:
            return true
        case .tertiaryEmotion:
            return true
        case .intensityAndContext:
            return true
        case .journalPrompt:
            return false
        }
    }

    var isFirstStep: Bool {
        currentStep == .primaryMood
    }

    var isLastStep: Bool {
        currentStep == .journalPrompt
    }

    // MARK: - Actions

    func selectPrimary(_ mood: MoodPrimary) {
        selectedPrimary = mood
        journalPrompt = suggestedPrompt
        currentStep = .secondaryEmotion
    }

    func selectSecondary(_ emotion: SecondaryEmotion) {
        selectedSecondary = emotion
        currentStep = .tertiaryEmotion
    }

    func selectTertiary(_ emotion: String) {
        selectedTertiary = emotion
        showTertiaryConfirmation = true
    }

    func confirmTertiaryAndAdvance() {
        showTertiaryConfirmation = false
        currentStep = .intensityAndContext
    }

    var shouldShowWhoField: Bool {
        !selectedTags.isDisjoint(with: Self.peopleWhoTags)
    }

    var shouldShowActivityDetails: Bool {
        !selectedTags.isDisjoint(with: Set(Self.activityTags))
    }

    func goForward() {
        guard canAdvance,
              let next = MoodCheckInStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func goBack() {
        guard currentStep.rawValue > 0,
              let prev = MoodCheckInStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    // MARK: - Save

    func save(context: ModelContext, userId: UUID) {
        guard let primary = selectedPrimary else { return }

        let tagsJSON: String? = {
            guard !selectedTags.isEmpty else { return nil }
            let sorted = selectedTags.sorted()
            guard let data = try? JSONEncoder().encode(sorted) else { return nil }
            return String(data: data, encoding: .utf8)
        }()

        let entry = RRMoodEntry(
            userId: userId,
            date: Date(),
            primaryMood: primary.rawValue,
            secondaryEmotion: selectedTertiary ?? selectedSecondary?.name,
            intensity: intensity > 0 ? Int(intensity) : nil,
            urgeToActOut: urgeToActOut > 0 ? Int(urgeToActOut) : nil,
            contextTagsJSON: tagsJSON,
            journalPrompt: journalResponse.isEmpty ? nil : journalPrompt,
            journalResponse: journalResponse.isEmpty ? nil : journalResponse,
            score: primary.score
        )

        context.insert(entry)
        showCompletion = true
    }
}
