import SwiftUI

/// Centralized mapping of Sensa Emoji SVG assets to emotion/mood concepts.
/// All emotion and mood icon rendering across the app goes through this enum
/// so emoji-to-concept mappings can be adjusted in one place.
enum SensaEmoji: String, CaseIterable {
    // Happy range
    case beaming = "Beaming face with smiling eyes"
    case smilingEyes = "Smiling face with smiling eyes"
    case grinning = "Grinning face"
    case slightlySmiling = "Slightly smiling face"
    case relieved = "Relieved face"
    case partying = "Partying face"
    case heartEyes = "Smiling face with heart-eyes"
    case starStruck = "Star-struck"

    // Sad range
    case crying = "Crying face"
    case loudlyCrying = "Loudly crying face"
    case pensive = "Pensive face"
    case disappointed = "Dissapointed face"

    // Angry range
    case angry = "Angry face"
    case pouting = "Pouting face"
    case steamFromNose = "Face with steam from nose"

    // Fear range
    case fearful = "Fearful face"
    case anxious = "Anxious face with sweat"
    case worried = "Worried face"

    // Disgust range
    case nauseated = "Nauseated face"
    case confounded = "Confounded face"

    // Surprise range
    case astonished = "Astonished face"
    case hushed = "Hushed face"
    case explodingHead = "Exploding head"

    // Neutral/other
    case neutral = "Neutral face"
    case expressionless = "Expressioless face"
    case slightlyFrowning = "Slightly frowning face"
    case frowning = "Frowning face"
    case downcastSweat = "Downcast face with sweat"
    case hugging = "Hugging face"
    case woozy = "Woozy face"
    case thinking = "Thinking face"

    /// The xcassets image name.
    var assetName: String { rawValue }

    /// Returns a SwiftUI Image sized to fit within the given dimension.
    func image(size: CGFloat = 32) -> some View {
        Image(assetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .accessibilityLabel(rawValue)
    }

    // MARK: - PrimaryEmotion (FANOS & Emotional Journal)

    static func forPrimaryEmotion(_ emotion: PrimaryEmotion) -> SensaEmoji {
        switch emotion {
        case .happy:     return .beaming
        case .sad:       return .crying
        case .angry:     return .angry
        case .fearful:   return .fearful
        case .disgusted: return .nauseated
        case .surprised: return .astonished
        }
    }

    // MARK: - Secondary Emotions (Emotional Journal)

    static func forSecondaryEmotion(_ name: String) -> SensaEmoji {
        switch name {
        // Happy secondaries
        case "Joyful":       return .partying
        case "Grateful":     return .heartEyes
        case "Content":      return .smilingEyes
        case "Peaceful":     return .relieved
        case "Hopeful":      return .slightlySmiling
        case "Proud":        return .starStruck
        // Sad secondaries
        case "Lonely":       return .pensive
        case "Grieving":     return .loudlyCrying
        case "Disappointed": return .disappointed
        case "Hopeless":     return .downcastSweat
        case "Ashamed":      return .frowning
        case "Empty":        return .expressionless
        // Angry secondaries
        case "Frustrated":   return .steamFromNose
        case "Resentful":    return .pouting
        case "Irritated":    return .angry
        case "Bitter":       return .confounded
        case "Jealous":      return .slightlyFrowning
        case "Betrayed":     return .pouting
        // Fearful secondaries
        case "Anxious":      return .anxious
        case "Insecure":     return .worried
        case "Overwhelmed":  return .downcastSweat
        case "Vulnerable":   return .slightlyFrowning
        case "Panicked":     return .fearful
        case "Worried":      return .worried
        // Disgusted secondaries
        case "Contemptuous": return .confounded
        case "Repulsed":     return .nauseated
        case "Self-loathing": return .frowning
        case "Judgmental":   return .neutral
        // Surprised secondaries
        case "Shocked":      return .explodingHead
        case "Confused":     return .thinking
        case "Amazed":       return .astonished
        case "Startled":     return .hushed
        default:             return .neutral
        }
    }

    // MARK: - Mood 1-10 (MoodRatingView)

    static func forMoodScore10(_ score: Int) -> SensaEmoji {
        switch score {
        case 1...2:  return .loudlyCrying
        case 3...4:  return .worried
        case 5...6:  return .neutral
        case 7...8:  return .smilingEyes
        default:     return .beaming
        }
    }

    // MARK: - MoodPrimary (Layered Check-In)

    static func forMoodPrimary(_ mood: MoodPrimary) -> SensaEmoji {
        switch mood {
        case .love: return .heartEyes
        case .joy: return .beaming
        case .surprise: return .astonished
        case .anger: return .angry
        case .sadness: return .crying
        case .fear: return .fearful
        }
    }

    // MARK: - FASTER Mood (1-5, 1=Great 5=Rough)

    static func forFASTERMood(_ score: Int) -> SensaEmoji {
        switch score {
        case 1: return .beaming
        case 2: return .slightlySmiling
        case 3: return .neutral
        case 4: return .worried
        case 5: return .loudlyCrying
        default: return .neutral
        }
    }

    // MARK: - EmotionCatalog Category (Time Journal)

    static func forEmotionCategory(_ name: String) -> SensaEmoji {
        switch name {
        case "Happy":         return .beaming
        case "Sad":           return .crying
        case "Angry":         return .angry
        case "Fearful":       return .fearful
        case "Shame":         return .frowning
        case "The Three I's": return .downcastSweat
        case "Numb":          return .expressionless
        case "Surprise":      return .astonished
        case "Connected":     return .hugging
        default:              return .neutral
        }
    }

    // MARK: - Gratitude Mood (1-5, 1=Low 5=Great)

    static func forGratitudeMood(_ score: Int) -> SensaEmoji {
        switch score {
        case 1: return .loudlyCrying
        case 2: return .slightlyFrowning
        case 3: return .neutral
        case 4: return .smilingEyes
        case 5: return .starStruck
        default: return .neutral
        }
    }
}
