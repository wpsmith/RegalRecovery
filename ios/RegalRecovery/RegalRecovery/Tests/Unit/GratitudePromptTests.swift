import Testing
@testable import RegalRecovery

@Suite("GratitudePromptService")
struct GratitudePromptTests {

    let service = GratitudePromptService()

    // MARK: - GL-PR-AC1: 50+ prompts

    @Test("GL-PR-AC1: Bundled library has 50+ prompts")
    func testGratitude_GL_PR_AC1_PromptCount() {
        #expect(service.allPrompts.count >= 50,
                "Bundled library should have at least 50 prompts, found \(service.allPrompts.count)")
    }

    // MARK: - GL-PR-AC2: Deterministic daily prompt

    @Test("GL-PR-AC2: Same user + same day = same prompt")
    func testGratitude_GL_PR_AC2_DeterministicDaily() {
        let userId = UUID()
        let date = Date()

        let prompt1 = service.dailyPrompt(for: userId, on: date)
        let prompt2 = service.dailyPrompt(for: userId, on: date)

        #expect(prompt1.id == prompt2.id,
                "Same user on same day should get the same prompt")
    }

    // MARK: - GL-PR-AC3: Cycle to next prompt

    @Test("GL-PR-AC3: 'Different prompt' cycles to next")
    func testGratitude_GL_PR_AC3_CyclePrompt() {
        let first = service.allPrompts[0]
        let next = service.nextPrompt(after: first)

        #expect(first.id != next.id, "Next prompt should differ from current")

        // Wraparound
        let last = service.allPrompts[service.allPrompts.count - 1]
        let wrappedNext = service.nextPrompt(after: last)
        #expect(wrappedNext.id == service.allPrompts[0].id,
                "After last prompt, should wrap to first")
    }

    // MARK: - GL-PR-AC5: Each prompt has a category

    @Test("GL-PR-AC5: Every prompt tagged with a category")
    func testGratitude_GL_PR_AC5_PromptCategories() {
        for prompt in service.allPrompts {
            #expect(!prompt.category.isEmpty,
                    "Prompt \(prompt.id) should have a non-empty category")
        }
    }

    // MARK: - GL-PR-AC6: Distribution across categories

    @Test("GL-PR-AC6: Minimum 3 prompts per main category")
    func testGratitude_GL_PR_AC6_CategoryDistribution() {
        let categoryCounts = Dictionary(grouping: service.allPrompts, by: \.category)

        let expectedCategories = [
            "faithGod", "family", "relationships", "health",
            "recovery", "workCareer", "natureBeauty", "smallMoments", "growthProgress"
        ]

        for category in expectedCategories {
            let count = categoryCounts[category]?.count ?? 0
            #expect(count >= 3,
                    "Category '\(category)' should have >= 3 prompts, found \(count)")
        }
    }

    // MARK: - Unique IDs

    @Test("All prompt IDs are unique")
    func testGratitude_GL_PR_UniqueIds() {
        let ids = service.allPrompts.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count, "All prompt IDs should be unique")
    }

    // MARK: - Fallback for unknown prompt

    @Test("Unknown prompt falls back to first")
    func testGratitude_GL_PR_NextPromptFallbackForUnknown() {
        let unknown = GratitudePrompt(id: "unknown_id", text: "Unknown", category: "test")
        let next = service.nextPrompt(after: unknown)
        #expect(next.id == service.allPrompts[0].id,
                "Unknown prompt should fall back to first prompt")
    }

    // MARK: - Category filter

    @Test("Category filter returns matching prompts")
    func testGratitude_GL_PR_CategoryFilter() {
        let faithPrompts = service.prompts(for: "faithGod")
        #expect(faithPrompts.count > 0, "Should find prompts for faithGod")
        for prompt in faithPrompts {
            #expect(prompt.category == "faithGod")
        }
    }
}
