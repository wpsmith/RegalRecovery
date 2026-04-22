import Foundation

// MARK: - Seed Data Structures

struct TriggerSeed {
    let label: String
    let category: TriggerCategory
}

struct CopingStrategySeed {
    let label: String
    let description: String
    let category: TriggerCategory
}

// MARK: - Trigger Seed Data

enum TriggerSeedData {

    // MARK: - Popular Triggers

    static let popularLabels: Set<String> = [
        "Stress",
        "Loneliness",
        "Boredom",
        "Anger",
        "Tired",
        "Home alone",
        "Late night",
        "Fantasy",
        "Shame",
        "Rejection",
        "Conflict with spouse",
        "Social media",
        "Anxiety",
        "Unstructured time",
        "Resentment",
        "Feeling unappreciated",
        "Euphoric recall",
        "Insomnia",
        "Self-pity",
        "Social isolation"
    ]

    static var popularTriggers: [TriggerSeed] {
        allTriggers.filter { popularLabels.contains($0.label) }
    }

    // MARK: - Category-Specific Triggers

    private static let emotionalTriggers: [TriggerSeed] = [
        TriggerSeed(label: "Stress", category: .emotional),
        TriggerSeed(label: "Anxiety", category: .emotional),
        TriggerSeed(label: "Loneliness", category: .emotional),
        TriggerSeed(label: "Boredom", category: .emotional),
        TriggerSeed(label: "Anger", category: .emotional),
        TriggerSeed(label: "Shame", category: .emotional),
        TriggerSeed(label: "Rejection", category: .emotional),
        TriggerSeed(label: "Sadness", category: .emotional),
        TriggerSeed(label: "Excitement", category: .emotional),
        TriggerSeed(label: "Frustration", category: .emotional),
        TriggerSeed(label: "Overwhelm", category: .emotional),
        TriggerSeed(label: "Fear", category: .emotional),
        TriggerSeed(label: "Guilt", category: .emotional),
        TriggerSeed(label: "Resentment", category: .emotional),
        TriggerSeed(label: "Hopelessness", category: .emotional),
        TriggerSeed(label: "Jealousy", category: .emotional),
        TriggerSeed(label: "Self-pity", category: .emotional),
        TriggerSeed(label: "Entitlement", category: .emotional),
        TriggerSeed(label: "Grief", category: .emotional),
        TriggerSeed(label: "Inadequacy", category: .emotional),
        TriggerSeed(label: "Embarrassment", category: .emotional),
        TriggerSeed(label: "Numbness", category: .emotional),
        TriggerSeed(label: "Restlessness", category: .emotional),
        TriggerSeed(label: "Disappointment", category: .emotional)
    ]

    private static let physicalTriggers: [TriggerSeed] = [
        TriggerSeed(label: "Hungry", category: .physical),
        TriggerSeed(label: "Tired", category: .physical),
        TriggerSeed(label: "Physical pain", category: .physical),
        TriggerSeed(label: "Insomnia", category: .physical),
        TriggerSeed(label: "Illness", category: .physical),
        TriggerSeed(label: "Exhaustion", category: .physical),
        TriggerSeed(label: "Physical tension", category: .physical),
        TriggerSeed(label: "Hormonal changes", category: .physical),
        TriggerSeed(label: "Hangover", category: .physical),
        TriggerSeed(label: "Caffeine crash", category: .physical),
        TriggerSeed(label: "Sedentary all day", category: .physical),
        TriggerSeed(label: "Sleep deprived", category: .physical),
        TriggerSeed(label: "Under the influence", category: .physical)
    ]

    private static let environmentalTriggers: [TriggerSeed] = [
        TriggerSeed(label: "Home alone", category: .environmental),
        TriggerSeed(label: "Hotel room", category: .environmental),
        TriggerSeed(label: "Late night", category: .environmental),
        TriggerSeed(label: "Social media", category: .environmental),
        TriggerSeed(label: "Triggering content online", category: .environmental),
        TriggerSeed(label: "Specific location", category: .environmental),
        TriggerSeed(label: "Driving alone", category: .environmental),
        TriggerSeed(label: "Travel", category: .environmental),
        TriggerSeed(label: "Unstructured time", category: .environmental),
        TriggerSeed(label: "Bathroom or shower", category: .environmental),
        TriggerSeed(label: "Work from home", category: .environmental),
        TriggerSeed(label: "Office alone", category: .environmental),
        TriggerSeed(label: "Waiting room", category: .environmental),
        TriggerSeed(label: "In bed with phone", category: .environmental),
        TriggerSeed(label: "Public Wi-Fi", category: .environmental),
        TriggerSeed(label: "Gym or locker room", category: .environmental),
        TriggerSeed(label: "Pool or beach", category: .environmental)
    ]

    private static let relationalTriggers: [TriggerSeed] = [
        TriggerSeed(label: "Conflict with spouse", category: .relational),
        TriggerSeed(label: "Feeling rejected", category: .relational),
        TriggerSeed(label: "Feeling criticized", category: .relational),
        TriggerSeed(label: "Feeling unappreciated", category: .relational),
        TriggerSeed(label: "Intimacy avoidance", category: .relational),
        TriggerSeed(label: "Attraction to someone", category: .relational),
        TriggerSeed(label: "Seeing an ex", category: .relational),
        TriggerSeed(label: "Being flirted with", category: .relational),
        TriggerSeed(label: "Arguments", category: .relational),
        TriggerSeed(label: "Sexual rejection", category: .relational),
        TriggerSeed(label: "Feeling unseen", category: .relational),
        TriggerSeed(label: "Feeling controlled", category: .relational),
        TriggerSeed(label: "Feeling abandoned", category: .relational),
        TriggerSeed(label: "Social isolation", category: .relational),
        TriggerSeed(label: "Peer pressure", category: .relational),
        TriggerSeed(label: "Comparison to others", category: .relational),
        TriggerSeed(label: "Marital distance", category: .relational),
        TriggerSeed(label: "Parenting stress", category: .relational)
    ]

    private static let cognitiveTriggers: [TriggerSeed] = [
        TriggerSeed(label: "Fantasy", category: .cognitive),
        TriggerSeed(label: "Objectifying others", category: .cognitive),
        TriggerSeed(label: "Euphoric recall", category: .cognitive),
        TriggerSeed(label: "\"Just this once\" thinking", category: .cognitive),
        TriggerSeed(label: "Minimizing consequences", category: .cognitive),
        TriggerSeed(label: "Rationalizing behavior", category: .cognitive),
        TriggerSeed(label: "Comparing to others", category: .cognitive),
        TriggerSeed(label: "Self-defeating thoughts", category: .cognitive),
        TriggerSeed(label: "Nostalgia for acting out", category: .cognitive),
        TriggerSeed(label: "Testing boundaries", category: .cognitive),
        TriggerSeed(label: "\"I deserve this\" thinking", category: .cognitive),
        TriggerSeed(label: "Dwelling on past failures", category: .cognitive),
        TriggerSeed(label: "Intrusive thoughts", category: .cognitive),
        TriggerSeed(label: "Planning to act out", category: .cognitive),
        TriggerSeed(label: "Romanticizing the past", category: .cognitive),
        TriggerSeed(label: "\"Nobody will know\" thinking", category: .cognitive),
        TriggerSeed(label: "Denial of progress", category: .cognitive)
    ]

    private static let spiritualTriggers: [TriggerSeed] = [
        TriggerSeed(label: "Doubt", category: .spiritual),
        TriggerSeed(label: "Spiritual dryness", category: .spiritual),
        TriggerSeed(label: "Skipping prayer", category: .spiritual),
        TriggerSeed(label: "Missing church", category: .spiritual),
        TriggerSeed(label: "Missing meetings", category: .spiritual),
        TriggerSeed(label: "Feeling distant from God", category: .spiritual),
        TriggerSeed(label: "Legalism", category: .spiritual),
        TriggerSeed(label: "Perfectionism", category: .spiritual),
        TriggerSeed(label: "Hyper-spiritualizing", category: .spiritual),
        TriggerSeed(label: "Unforgiveness", category: .spiritual),
        TriggerSeed(label: "Spiritual comparison", category: .spiritual),
        TriggerSeed(label: "Questioning God's love", category: .spiritual),
        TriggerSeed(label: "Loss of purpose", category: .spiritual)
    ]

    private static let situationalTriggers: [TriggerSeed] = [
        TriggerSeed(label: "Celebrations", category: .situational),
        TriggerSeed(label: "Holidays", category: .situational),
        TriggerSeed(label: "Vacations", category: .situational),
        TriggerSeed(label: "Financial stress", category: .situational),
        TriggerSeed(label: "Work deadline", category: .situational),
        TriggerSeed(label: "Job loss or change", category: .situational),
        TriggerSeed(label: "Grief or loss", category: .situational),
        TriggerSeed(label: "Moving or relocation", category: .situational),
        TriggerSeed(label: "Life transitions", category: .situational),
        TriggerSeed(label: "Success or promotion", category: .situational),
        TriggerSeed(label: "Anniversary of trauma", category: .situational),
        TriggerSeed(label: "Divorce or separation", category: .situational),
        TriggerSeed(label: "New relationship", category: .situational),
        TriggerSeed(label: "Retirement", category: .situational),
        TriggerSeed(label: "Major purchase", category: .situational),
        TriggerSeed(label: "Legal trouble", category: .situational),
        TriggerSeed(label: "Health diagnosis", category: .situational),
        TriggerSeed(label: "Birth of a child", category: .situational)
    ]

    // MARK: - All Triggers

    static let allTriggers: [TriggerSeed] =
        emotionalTriggers +
        physicalTriggers +
        environmentalTriggers +
        relationalTriggers +
        cognitiveTriggers +
        spiritualTriggers +
        situationalTriggers

    // MARK: - System Coping Strategies

    static let systemCopingStrategies: [CopingStrategySeed] = [
        // Emotional (4)
        CopingStrategySeed(
            label: "Box breathing (4-4-4-4)",
            description: "Breathe in for 4 counts, hold for 4, breathe out for 4, hold for 4. Repeat until calm.",
            category: .emotional
        ),
        CopingStrategySeed(
            label: "5-4-3-2-1 grounding",
            description: "Name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste.",
            category: .emotional
        ),
        CopingStrategySeed(
            label: "Urge surfing",
            description: "Observe the urge like a wave. Notice it rise, peak, and fall without acting on it.",
            category: .emotional
        ),
        CopingStrategySeed(
            label: "Name the emotion",
            description: "Identify and name the specific emotion you're feeling. This helps create distance from it.",
            category: .emotional
        ),

        // Physical (3)
        CopingStrategySeed(
            label: "HALT check",
            description: "Are you Hungry, Angry, Lonely, or Tired? Address the physical need first.",
            category: .physical
        ),
        CopingStrategySeed(
            label: "Take a walk",
            description: "Get outside and move your body for 10-15 minutes. Physical activity shifts your state.",
            category: .physical
        ),
        CopingStrategySeed(
            label: "Cold water on face",
            description: "Splash cold water on your face or hold an ice cube. This activates your parasympathetic nervous system.",
            category: .physical
        ),

        // Environmental (3)
        CopingStrategySeed(
            label: "Change your location",
            description: "Move to a different room or go outside. Breaking the environmental pattern helps interrupt the urge.",
            category: .environmental
        ),
        CopingStrategySeed(
            label: "Put the phone down",
            description: "Set your device aside or put it in another room. Remove access to triggering content.",
            category: .environmental
        ),
        CopingStrategySeed(
            label: "Turn on lights",
            description: "Illuminate your space. Darkness and isolation often intensify urges.",
            category: .environmental
        ),

        // Relational (3)
        CopingStrategySeed(
            label: "Call your accountability partner",
            description: "Reach out to someone in your support network and share what you're experiencing.",
            category: .relational
        ),
        CopingStrategySeed(
            label: "Call your sponsor",
            description: "Contact your sponsor and talk through the urge or trigger before acting.",
            category: .relational
        ),
        CopingStrategySeed(
            label: "Text someone",
            description: "Send a message to a trusted friend or group. You don't have to face this alone.",
            category: .relational
        ),

        // Cognitive (3)
        CopingStrategySeed(
            label: "Play the tape forward",
            description: "Imagine the full consequences of acting out. How will you feel in 5 minutes? 5 hours? Tomorrow?",
            category: .cognitive
        ),
        CopingStrategySeed(
            label: "Read your coping card",
            description: "Review your list of reasons for recovery and consequences of acting out.",
            category: .cognitive
        ),
        CopingStrategySeed(
            label: "Challenge the thought",
            description: "Ask: Is this thought true? Is it helpful? What would I tell a friend thinking this?",
            category: .cognitive
        ),

        // Spiritual (3)
        CopingStrategySeed(
            label: "Pray",
            description: "Talk to God about what you're experiencing. Ask for strength and clarity.",
            category: .spiritual
        ),
        CopingStrategySeed(
            label: "Read scripture",
            description: "Open your Bible or devotional app. Focus on verses about God's faithfulness and strength.",
            category: .spiritual
        ),
        CopingStrategySeed(
            label: "Worship music",
            description: "Put on worship music and focus on God's presence rather than the urge.",
            category: .spiritual
        ),

        // Situational (3)
        CopingStrategySeed(
            label: "Review your recovery plan",
            description: "Look at your written recovery plan and remind yourself of your commitments.",
            category: .situational
        ),
        CopingStrategySeed(
            label: "Check your calendar",
            description: "Look at what's coming up. Remember the life you're building and protecting.",
            category: .situational
        ),
        CopingStrategySeed(
            label: "Journal about it",
            description: "Write down what you're feeling and experiencing. This creates clarity and distance.",
            category: .situational
        )
    ]
}
