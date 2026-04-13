import SwiftUI

// MARK: - NumberStyle

enum NumberStyle {
    case arabic
    case roman

    func display(for number: Int) -> String {
        switch self {
        case .arabic:
            return "\(number)"
        case .roman:
            return Self.toRoman(number)
        }
    }

    private static func toRoman(_ number: Int) -> String {
        let values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
        let symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
        var result = ""
        var remaining = number
        for (value, symbol) in zip(values, symbols) {
            while remaining >= value {
                result += symbol
                remaining -= value
            }
        }
        return result
    }
}

// MARK: - BookChapter

struct BookChapter: Identifiable {
    let id: String
    let filename: String
    let title: String
    let subtitle: String
    let number: Int?
}

// MARK: - Book

struct Book: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let author: String
    let edition: String?
    let icon: String
    let iconColor: Color
    let subdirectory: String
    let headerLinesToSkip: Int
    let chapters: [BookChapter]
    let chapterLabel: String
    let numberStyle: NumberStyle

    /// Loads chapter text with locale-aware resolution.
    /// 1. Try localized path: `{subdirectory}/{lang}/{filename}.txt`
    /// 2. Fall back to English: `{subdirectory}/en/{filename}.txt`
    func loadText(for chapter: BookChapter) -> String {
        let lang = BookLanguageManager.shared.currentLanguage

        // Try selected language
        if let url = Bundle.main.url(
            forResource: chapter.filename,
            withExtension: "txt",
            subdirectory: "\(subdirectory)/\(lang)"
        ), let text = try? String(contentsOf: url, encoding: .utf8) {
            return processText(text)
        }

        // Fallback to English
        if lang != "en",
           let url = Bundle.main.url(
               forResource: chapter.filename,
               withExtension: "txt",
               subdirectory: "\(subdirectory)/en"
           ), let text = try? String(contentsOf: url, encoding: .utf8) {
            return processText(text)
        }

        return ""
    }

    /// Whether a localized file exists for the given chapter in the current language.
    func hasLocalizedContent(for chapter: BookChapter) -> Bool {
        let lang = BookLanguageManager.shared.currentLanguage
        return Bundle.main.url(
            forResource: chapter.filename,
            withExtension: "txt",
            subdirectory: "\(subdirectory)/\(lang)"
        ) != nil
    }

    /// Whether the current language is non-English but no translated content exists
    /// (checked against the first chapter as a proxy for the whole book).
    var isUsingFallback: Bool {
        let lang = BookLanguageManager.shared.currentLanguage
        guard lang != "en", let first = chapters.first else { return false }
        return !hasLocalizedContent(for: first)
    }

    private func processText(_ raw: String) -> String {
        let lines = raw.components(separatedBy: "\n")
        let body = lines.dropFirst(headerLinesToSkip).joined(separator: "\n")
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var progressStorageKey: String { "book.\(id).readingProgress" }

    // MARK: - Localized Metadata

    /// Returns the book title in the current language.
    /// If no translated content exists for this book, returns the English title.
    var localizedTitle: String {
        guard !isUsingFallback else { return title }
        let lang = BookLanguageManager.shared.currentLanguage
        return Self.titleTranslations[id]?[lang] ?? title
    }

    /// Returns the book subtitle in the current language.
    /// If no translated content exists for this book, returns the English subtitle.
    var localizedSubtitle: String {
        guard !isUsingFallback else { return subtitle }
        let lang = BookLanguageManager.shared.currentLanguage
        return Self.subtitleTranslations[id]?[lang] ?? subtitle
    }

    // MARK: - Translation Dictionaries

    private static let titleTranslations: [String: [String: String]] = [
        "bigbook": [
            "es": "Alcohólicos Anónimos",
            "fr": "Les Alcooliques anonymes",
        ],
        "confessions": [
            "es": "Confesiones",
            "fr": "Les Confessions",
        ],
        "humility": [
            "es": "Humildad",
            "fr": "L'Humilité",
        ],
        "absolutesurrender": [
            "es": "Rendición Absoluta",
            "fr": "Abandon Absolu",
        ],
        "schoolofprayer": [
            "es": "Con Cristo en la Escuela de la Oración",
            "fr": "Avec Christ à l'École de la Prière",
        ],
        "waitingongod": [
            "es": "Esperando en Dios",
            "fr": "En Attendant Dieu",
        ],
        "imitationOfChrist": [
            "es": "La Imitación de Cristo",
            "fr": "L'Imitation de Jésus-Christ",
        ],
        "practicePresenceOfGod": [
            "es": "La Práctica de la Presencia de Dios",
            "fr": "La Pratique de la Présence de Dieu",
        ],
        "pursuitOfGod": [
            "es": "La Búsqueda de Dios",
            "fr": "La Poursuite de Dieu",
        ],
        "graceAbounding": [
            "es": "Gracia Abundante para el Principal de los Pecadores",
            "fr": "Grâce Surabondante pour le Premier des Pécheurs",
        ],
        "powerThroughPrayer": [
            "es": "Poder a Través de la Oración",
            "fr": "Le Pouvoir par la Prière",
        ],
        "holyInChrist": [
            "es": "Santo en Cristo",
            "fr": "Saint en Christ",
        ],
    ]

    private static let subtitleTranslations: [String: [String: String]] = [
        "bigbook": [
            "es": "El Libro Grande",
            "fr": "Le Gros Livre",
        ],
        "confessions": [
            "es": "Traducido por E.B. Pusey",
            "fr": "Traduit par E.B. Pusey",
        ],
        "humility": [
            "es": "La Belleza de la Santidad",
            "fr": "La Beauté de la Sainteté",
        ],
        "holyInChrist": [
            "es": "Reflexiones sobre el Llamado de los Hijos de Dios a ser Santos como Él es Santo",
            "fr": "Réflexions sur l'Appel des Enfants de Dieu à être Saints comme Il est Saint",
        ],
        "schoolofprayer": [
            "es": "Con Cristo en la Escuela de la Oración",
            "fr": "Avec Christ à l'École de la Prière",
        ],
    ]
}
