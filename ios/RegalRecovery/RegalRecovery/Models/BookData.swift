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

    func loadText(for chapter: BookChapter) -> String {
        guard let url = Bundle.main.url(
            forResource: chapter.filename,
            withExtension: "txt",
            subdirectory: subdirectory
        ),
              let raw = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        let lines = raw.components(separatedBy: "\n")
        let body = lines.dropFirst(headerLinesToSkip).joined(separator: "\n")
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var progressStorageKey: String { "book.\(id).readingProgress" }
}
