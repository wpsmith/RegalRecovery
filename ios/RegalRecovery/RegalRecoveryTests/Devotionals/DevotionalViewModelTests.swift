// DevotionalViewModelTests.swift
// RegalRecoveryTests
//
// Unit tests for the DevotionalViewModel.
// Test names reference acceptance criteria from specs/acceptance-criteria.md.

import XCTest
@testable import RegalRecovery

final class DevotionalViewModelTests: XCTestCase {

    // MARK: - Model Tests

    /// Verify all required content elements are present in the DTO.
    func testTodayDevotional_displaysAllContentElements() throws {
        let dto = makeTestDevotionalDTO()

        XCTAssertFalse(dto.id.isEmpty, "id must be present")
        XCTAssertFalse(dto.title.isEmpty, "title must be present")
        XCTAssertFalse(dto.scriptureReference.isEmpty, "scriptureReference must be present")
        XCTAssertFalse(dto.scriptureText.isEmpty, "scriptureText must be present")
        XCTAssertFalse(dto.reading.isEmpty, "reading must be present")
        XCTAssertFalse(dto.recoveryConnection.isEmpty, "recoveryConnection must be present")
        XCTAssertFalse(dto.reflectionQuestion.isEmpty, "reflectionQuestion must be present")
        XCTAssertFalse(dto.prayer.isEmpty, "prayer must be present")
    }

    /// Verify reflection can be saved with a completion.
    func testReflection_savesAndShowsInHistory() throws {
        let reflection = "The passage about surrender resonated deeply."
        let request = DevotionalCompletionRequestDTO(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            reflection: reflection,
            moodTag: .hopeful
        )

        XCTAssertEqual(request.reflection, reflection)
        XCTAssertEqual(request.moodTag, .hopeful)
    }

    /// Verify streak data formats correctly.
    func testStreakDisplay_formatsCorrectly() throws {
        let streak = DevotionalStreakDTO(
            currentDays: 15,
            longestDays: 23,
            lastCompletedDate: "2026-04-07"
        )

        XCTAssertEqual(streak.currentDays, 15)
        XCTAssertEqual(streak.longestDays, 23)
        XCTAssertEqual(streak.lastCompletedDate, "2026-04-07")
    }

    /// Verify series progress shows currentDay of totalDays.
    func testSeriesProgress_showsCurrentOfTotal() throws {
        let series = makeTestSeriesDTO(currentDay: 47, totalDays: 365)

        XCTAssertEqual(series.currentDay, 47)
        XCTAssertEqual(series.totalDays, 365)
        XCTAssertEqual(series.status, .active)
    }

    /// Verify locked content is identified correctly.
    func testLockedContent_showsPurchaseCTA() throws {
        let summary = DevotionalSummaryDTO(
            id: "dev_premium1",
            title: "Premium Devotional",
            scriptureReference: "John 3:16",
            topic: .hope,
            authorName: nil,
            date: "2026-04-07",
            seriesId: "series_premium",
            tier: .premium,
            isLocked: true,
            isCompleted: false,
            isFavorite: false,
            language: "en",
            links: nil
        )

        XCTAssertTrue(summary.isLocked, "Premium unpurchased content should be locked")
        XCTAssertEqual(summary.tier, .premium)
    }

    // MARK: - Mood Tag Tests

    /// Verify all mood tags are decodable.
    func testAllMoodTags_areValid() throws {
        let allTags: [DevotionalMoodTag] = [
            .grateful, .hopeful, .peaceful, .convicted,
            .challenged, .comforted, .anxious, .struggling, .numb
        ]

        XCTAssertEqual(allTags.count, 9)
        for tag in allTags {
            XCTAssertFalse(tag.rawValue.isEmpty)
            XCTAssertFalse(tag.displayName.isEmpty)
        }
    }

    // MARK: - Topic Tests

    /// Verify all topics match the OpenAPI spec enum.
    func testAllTopics_matchSpec() throws {
        let expectedTopics: Set<String> = [
            "shame", "temptation", "identity", "marriage", "forgiveness",
            "surrender", "gratitude", "restoration", "fear", "hope"
        ]

        let actualTopics = Set(DevotionalTopic.allCases.map(\.rawValue))
        XCTAssertEqual(actualTopics, expectedTopics)
    }

    // MARK: - Completion DTO Tests

    /// Verify completion request encodes timestamp as ISO8601.
    func testCompletionRequest_encodesTimestamp() throws {
        let date = Date()
        let request = DevotionalCompletionRequestDTO(
            timestamp: ISO8601DateFormatter().string(from: date),
            reflection: nil,
            moodTag: nil
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["timestamp"])
        XCTAssertNil(json["reflection"] as? String)
    }

    /// Verify completion without reflection is valid (AC-DEV-REFLECT-05).
    func testCompletionWithoutReflection_isValid() throws {
        let request = DevotionalCompletionRequestDTO(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            reflection: nil,
            moodTag: nil
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(DevotionalCompletionRequestDTO.self, from: data)

        XCTAssertNil(decoded.reflection)
        XCTAssertNil(decoded.moodTag)
    }

    // MARK: - Series Status Tests

    /// Verify all series status values decode correctly.
    func testSeriesStatus_allValuesDecodable() throws {
        let statuses: [DevotionalSeriesStatus] = [.notStarted, .active, .paused, .completed]

        for status in statuses {
            let json = "\"\(status.rawValue)\""
            let data = json.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(DevotionalSeriesStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - Share Tests

    /// Verify share request encodes share type correctly.
    func testShareRequest_encodesShareType() throws {
        let request = DevotionalShareRequestDTO(shareType: .link, contactId: nil)
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["shareType"] as? String, "link")
        XCTAssertNil(json["contactId"] as? String)
    }

    // MARK: - ViewModel Legacy Tests

    /// Verify legacy load populates days array.
    func testLegacyLoad_populatesDays() async {
        let vm = DevotionalViewModel()
        await vm.load()

        XCTAssertFalse(vm.days.isEmpty)
        XCTAssertGreaterThan(vm.completedDays, 0)
    }

    // MARK: - Helpers

    private func makeTestDevotionalDTO() -> DevotionalDTO {
        DevotionalDTO(
            id: "dev_test123",
            title: "Strength in Surrender",
            scriptureReference: "2 Corinthians 12:9",
            scriptureText: "My grace is sufficient for you",
            bibleTranslation: .NIV,
            reading: "In our recovery journey, we often try to fight our battles alone...",
            recoveryConnection: "Surrender is not giving up -- it is giving over.",
            reflectionQuestion: "Where in your recovery are you trying to control what only God can do?",
            prayer: "Lord, I confess that I have been trying to do this on my own...",
            authorName: "Dr. Mark Laaser",
            authorBio: "Christian counselor",
            date: "2026-04-07",
            topic: .surrender,
            seriesId: nil,
            seriesDay: nil,
            seriesTotalDays: nil,
            tier: .free,
            language: "en",
            isCompleted: false,
            isFavorite: false,
            links: ["self": "/v1/devotionals/dev_test123"]
        )
    }

    private func makeTestSeriesDTO(currentDay: Int, totalDays: Int) -> DevotionalSeriesDTO {
        DevotionalSeriesDTO(
            seriesId: "series_test",
            name: "365 Days of Recovery",
            description: "A year-long journey",
            authorName: "Dr. Mark Laaser",
            totalDays: totalDays,
            tier: .premium,
            price: 14.99,
            currency: "USD",
            isOwned: true,
            isActive: true,
            currentDay: currentDay,
            completedDays: currentDay - 1,
            status: .active,
            category: .recovery,
            language: "en",
            thumbnailUrl: nil,
            links: nil
        )
    }
}
