import Foundation

// MARK: - Wizard Step

enum VisionWizardStep: Equatable, Codable {
    case prompts(index: Int)
    case identity
    case values
    case scripture
    case review

    var title: String {
        switch self {
        case .prompts: return "Reflection"
        case .identity: return "Identity"
        case .values: return "Values"
        case .scripture: return "Scripture"
        case .review: return "Review"
        }
    }

    static let totalSteps = 8

    var progressIndex: Int {
        switch self {
        case .prompts(let index): return index + 1
        case .identity: return 5
        case .values: return 6
        case .scripture: return 7
        case .review: return 8
        }
    }

    var progressFraction: Double {
        Double(progressIndex) / Double(Self.totalSteps)
    }
}

// MARK: - Prompts

enum VisionPrompt: Int, CaseIterable {
    case oneYear = 0
    case relationships
    case timeAndEnergy
    case faithfulness

    var text: String {
        switch self {
        case .oneYear:
            return "What does your life look like one year from now if recovery goes well?"
        case .relationships:
            return "What kind of husband, father, or friend do you want to be?"
        case .timeAndEnergy:
            return "What would you do with your time and energy if addiction no longer consumed it?"
        case .faithfulness:
            return "What does faithfulness to God look like in your daily life?"
        }
    }

    static let maxLength = 500
}

// MARK: - Curated Values

enum CuratedValue: String, CaseIterable {
    case honesty = "Honesty"
    case integrity = "Integrity"
    case humility = "Humility"
    case courage = "Courage"
    case faithfulness = "Faithfulness"
    case service = "Service"
    case patience = "Patience"
    case gratitude = "Gratitude"
    case vulnerability = "Vulnerability"
    case discipline = "Discipline"
    case compassion = "Compassion"
    case selfControl = "Self-Control"
    case perseverance = "Perseverance"
    case wisdom = "Wisdom"
    case gentleness = "Gentleness"
}

// MARK: - Scripture Library

enum ScriptureCategory: String, CaseIterable, Codable {
    case identity = "Identity"
    case hope = "Hope"
    case transformation = "Transformation"
    case strength = "Strength"
    case freedom = "Freedom"
    case faithfulness = "Faithfulness"
}

struct ScriptureEntry: Identifiable {
    let id = UUID()
    let reference: String
    let text: String
    let category: ScriptureCategory
}

enum ScriptureLibrary {
    static let entries: [ScriptureEntry] = [
        ScriptureEntry(reference: "2 Corinthians 5:17", text: "Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!", category: .identity),
        ScriptureEntry(reference: "Ephesians 2:10", text: "For we are God's handiwork, created in Christ Jesus to do good works.", category: .identity),
        ScriptureEntry(reference: "1 Peter 2:9", text: "But you are a chosen people, a royal priesthood, a holy nation, God's special possession.", category: .identity),
        ScriptureEntry(reference: "Psalm 139:14", text: "I praise you because I am fearfully and wonderfully made.", category: .identity),
        ScriptureEntry(reference: "Jeremiah 29:11", text: "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.", category: .hope),
        ScriptureEntry(reference: "Romans 8:28", text: "And we know that in all things God works for the good of those who love him.", category: .hope),
        ScriptureEntry(reference: "Lamentations 3:22-23", text: "Because of the Lord's great love we are not consumed, for his compassions never fail. They are new every morning.", category: .hope),
        ScriptureEntry(reference: "Romans 15:13", text: "May the God of hope fill you with all joy and peace as you trust in him.", category: .hope),
        ScriptureEntry(reference: "Romans 12:2", text: "Do not conform to the pattern of this world, but be transformed by the renewing of your mind.", category: .transformation),
        ScriptureEntry(reference: "Philippians 1:6", text: "Being confident of this, that he who began a good work in you will carry it on to completion.", category: .transformation),
        ScriptureEntry(reference: "Ezekiel 36:26", text: "I will give you a new heart and put a new spirit in you.", category: .transformation),
        ScriptureEntry(reference: "2 Corinthians 3:18", text: "And we all, who with unveiled faces contemplate the Lord's glory, are being transformed into his image.", category: .transformation),
        ScriptureEntry(reference: "Philippians 4:13", text: "I can do all this through him who gives me strength.", category: .strength),
        ScriptureEntry(reference: "Isaiah 40:31", text: "But those who hope in the Lord will renew their strength. They will soar on wings like eagles.", category: .strength),
        ScriptureEntry(reference: "2 Timothy 1:7", text: "For the Spirit God gave us does not make us timid, but gives us power, love and self-discipline.", category: .strength),
        ScriptureEntry(reference: "Psalm 46:1", text: "God is our refuge and strength, an ever-present help in trouble.", category: .strength),
        ScriptureEntry(reference: "Galatians 5:1", text: "It is for freedom that Christ has set us free. Stand firm, then, and do not let yourselves be burdened again by a yoke of slavery.", category: .freedom),
        ScriptureEntry(reference: "John 8:36", text: "So if the Son sets you free, you will be free indeed.", category: .freedom),
        ScriptureEntry(reference: "Romans 6:14", text: "For sin shall no longer be your master, because you are not under the law, but under grace.", category: .freedom),
        ScriptureEntry(reference: "Psalm 107:14", text: "He brought them out of darkness, the utter darkness, and broke away their chains.", category: .freedom),
        ScriptureEntry(reference: "Proverbs 29:18", text: "Where there is no vision, the people perish; but he that keepeth the law, happy is he.", category: .faithfulness),
        ScriptureEntry(reference: "Proverbs 3:5-6", text: "Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him.", category: .faithfulness),
        ScriptureEntry(reference: "Micah 6:8", text: "He has shown you, O mortal, what is good. And what does the Lord require of you? To act justly and to love mercy and to walk humbly with your God.", category: .faithfulness),
        ScriptureEntry(reference: "Psalm 119:105", text: "Your word is a lamp for my feet, a light on my path.", category: .faithfulness),
    ]

    static func filtered(by category: ScriptureCategory?) -> [ScriptureEntry] {
        guard let category else { return entries }
        return entries.filter { $0.category == category }
    }

    static func search(_ query: String) -> [ScriptureEntry] {
        let lowered = query.lowercased()
        return entries.filter {
            $0.reference.lowercased().contains(lowered) ||
            $0.text.lowercased().contains(lowered)
        }
    }
}

enum VisionLimits {
    static let identityMaxLength = 280
    static let visionBodyMaxLength = 2000
    static let promptMaxLength = 500
    static let maxValues = 10
}
