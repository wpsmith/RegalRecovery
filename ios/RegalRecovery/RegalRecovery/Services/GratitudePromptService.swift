import Foundation

struct GratitudePrompt: Identifiable, Codable {
    let id: String
    let text: String
    let category: String
}

final class GratitudePromptService {

    let allPrompts: [GratitudePrompt]

    init() {
        allPrompts = Self.loadPrompts()
    }

    /// Returns a deterministic daily prompt for the given user and date.
    /// Same user sees the same prompt all day; different prompt each day.
    func dailyPrompt(for userId: UUID, on date: Date) -> GratitudePrompt {
        guard !allPrompts.isEmpty else { return Self.fallbackPrompts[0] }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let hash = userId.hashValue
        let index = abs((dayOfYear + hash) % allPrompts.count)
        return allPrompts[index]
    }

    /// Cycles to the next prompt after the current one (wraps around).
    func nextPrompt(after current: GratitudePrompt) -> GratitudePrompt {
        guard !allPrompts.isEmpty else { return Self.fallbackPrompts[0] }
        guard let currentIndex = allPrompts.firstIndex(where: { $0.id == current.id }) else {
            return allPrompts[0]
        }
        let nextIndex = (currentIndex + 1) % allPrompts.count
        return allPrompts[nextIndex]
    }

    /// Returns all prompts matching the given category.
    func prompts(for category: String) -> [GratitudePrompt] {
        allPrompts.filter { $0.category == category }
    }

    // MARK: - Private

    private static func loadPrompts() -> [GratitudePrompt] {
        guard let url = Bundle.main.url(forResource: "gratitude-prompts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let prompts = try? JSONDecoder().decode([GratitudePrompt].self, from: data),
              !prompts.isEmpty else {
            return fallbackPrompts
        }
        return prompts
    }

    private static let fallbackPrompts: [GratitudePrompt] = [
        GratitudePrompt(id: "gp_fb_001", text: "What is something God has done in your life that you didn't deserve?", category: "faithGod"),
        GratitudePrompt(id: "gp_fb_002", text: "What is something a family member did recently that made you smile?", category: "family"),
        GratitudePrompt(id: "gp_fb_003", text: "Who showed you kindness recently, and how did it make you feel?", category: "relationships"),
        GratitudePrompt(id: "gp_fb_004", text: "What is one thing about your body or health you're grateful for?", category: "health"),
        GratitudePrompt(id: "gp_fb_005", text: "What is something about your recovery journey you're thankful for right now?", category: "recovery"),
        GratitudePrompt(id: "gp_fb_006", text: "What is something you accomplished at work that you're proud of?", category: "workCareer"),
        GratitudePrompt(id: "gp_fb_007", text: "What is something beautiful you noticed today?", category: "natureBeauty"),
        GratitudePrompt(id: "gp_fb_008", text: "What is one thing about today that surprised you in a good way?", category: "smallMoments"),
        GratitudePrompt(id: "gp_fb_009", text: "What is a hard thing you did recently that you're proud of?", category: "growthProgress"),
        GratitudePrompt(id: "gp_fb_010", text: "What made today worth living?", category: "smallMoments")
    ]
}
