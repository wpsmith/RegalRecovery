import XCTest
@testable import RegalRecovery

/// Unit tests for Mood models matching acceptance criteria.
/// Test names reference ACs from docs/prd/specific-features/Mood/specs/acceptance-criteria.md.
final class MoodModelsTests: XCTestCase {

    // MARK: - MOOD-FR-001: Rating Scale

    func testMood_FR001_RatingScale_MapsCorrectLabel() {
        // Given: each rating 1-5
        // When: label is computed
        // Then: correct mapping
        XCTAssertEqual(MoodRating.crisis.label, "Crisis")
        XCTAssertEqual(MoodRating.struggling.label, "Struggling")
        XCTAssertEqual(MoodRating.okay.label, "Okay")
        XCTAssertEqual(MoodRating.good.label, "Good")
        XCTAssertEqual(MoodRating.great.label, "Great")
    }

    func testMood_FR001_RatingScale_MapsCorrectEmoji() {
        // Each rating maps to a distinct emoji
        let emojis = MoodRating.allCases.map(\.emoji)
        let uniqueEmojis = Set(emojis)
        XCTAssertEqual(uniqueEmojis.count, 5, "Each rating should have a unique emoji")
    }

    func testMood_FR001_RatingScale_IntegerValues() {
        // Ratings are 1-5 integers
        XCTAssertEqual(MoodRating.crisis.rawValue, 1)
        XCTAssertEqual(MoodRating.struggling.rawValue, 2)
        XCTAssertEqual(MoodRating.okay.rawValue, 3)
        XCTAssertEqual(MoodRating.good.rawValue, 4)
        XCTAssertEqual(MoodRating.great.rawValue, 5)
    }

    // MARK: - Emotion Labels

    func testMood_AC003_EmotionLabels_All15Present() {
        // All 15 predefined emotion labels exist
        XCTAssertEqual(EmotionLabel.allCases.count, 15)
    }

    func testMood_AC003_EmotionLabels_CorrectValues() {
        // Positive cluster
        XCTAssertEqual(EmotionLabel.peaceful.rawValue, "Peaceful")
        XCTAssertEqual(EmotionLabel.grateful.rawValue, "Grateful")
        XCTAssertEqual(EmotionLabel.hopeful.rawValue, "Hopeful")
        XCTAssertEqual(EmotionLabel.confident.rawValue, "Confident")
        XCTAssertEqual(EmotionLabel.connected.rawValue, "Connected")
        // Anxious cluster
        XCTAssertEqual(EmotionLabel.anxious.rawValue, "Anxious")
        XCTAssertEqual(EmotionLabel.lonely.rawValue, "Lonely")
        XCTAssertEqual(EmotionLabel.angry.rawValue, "Angry")
        XCTAssertEqual(EmotionLabel.ashamed.rawValue, "Ashamed")
        XCTAssertEqual(EmotionLabel.overwhelmed.rawValue, "Overwhelmed")
        // Low cluster
        XCTAssertEqual(EmotionLabel.sad.rawValue, "Sad")
        XCTAssertEqual(EmotionLabel.numb.rawValue, "Numb")
        XCTAssertEqual(EmotionLabel.restless.rawValue, "Restless")
        XCTAssertEqual(EmotionLabel.afraid.rawValue, "Afraid")
        XCTAssertEqual(EmotionLabel.frustrated.rawValue, "Frustrated")
    }

    // MARK: - Entry Source

    func testMood_EntrySource_AllValues() {
        XCTAssertEqual(MoodEntrySource.direct.rawValue, "direct")
        XCTAssertEqual(MoodEntrySource.widget.rawValue, "widget")
        XCTAssertEqual(MoodEntrySource.postActivity.rawValue, "post-activity")
        XCTAssertEqual(MoodEntrySource.notification.rawValue, "notification")
    }

    // MARK: - EC-004: Display Mode Switch

    func testMood_EC004_DisplayModeSwitch_PreservesData() {
        // Switch between emoji/numeric mode; data unchanged
        // Both modes map to the same 1-5 integer scale
        let rating = MoodRating.good
        XCTAssertEqual(rating.rawValue, 4) // Numeric
        XCTAssertEqual(rating.emoji, "\u{1F642}") // Emoji
        XCTAssertEqual(rating.label, "Good") // Label

        // Switching display mode does not change the underlying value
        XCTAssertEqual(MoodDisplayMode.emoji.rawValue, "emoji")
        XCTAssertEqual(MoodDisplayMode.numeric.rawValue, "numeric")
    }

    // MARK: - Codable Conformance

    func testMood_CodableRoundTrip_CreateRequest() throws {
        let request = CreateMoodEntryRequest(
            timestamp: Date(timeIntervalSince1970: 1775739000),
            rating: 4,
            emotionLabels: ["Hopeful", "Grateful"],
            contextNote: "Felt centered after morning prayer.",
            source: "direct"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CreateMoodEntryRequest.self, from: data)

        XCTAssertEqual(decoded.rating, 4)
        XCTAssertEqual(decoded.emotionLabels, ["Hopeful", "Grateful"])
        XCTAssertEqual(decoded.contextNote, "Felt centered after morning prayer.")
        XCTAssertEqual(decoded.source, "direct")
    }

    func testMood_CodableRoundTrip_UpdateRequest() throws {
        let request = UpdateMoodEntryRequest(
            rating: 3,
            emotionLabels: nil,
            contextNote: "Actually feeling more okay."
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UpdateMoodEntryRequest.self, from: data)

        XCTAssertEqual(decoded.rating, 3)
        XCTAssertEqual(decoded.contextNote, "Actually feeling more okay.")
    }

    func testMood_CodableRoundTrip_MoodEntryData() throws {
        let json = """
        {
            "moodId": "mood_abc123",
            "timestamp": "2026-04-07T14:30:00Z",
            "rating": 4,
            "ratingLabel": "Good",
            "emotionLabels": ["Hopeful", "Grateful"],
            "contextNote": "Felt centered after morning prayer.",
            "source": "direct",
            "crisisPrompted": false,
            "links": {
                "self": "/v1/activities/mood/mood_abc123"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entry = try decoder.decode(MoodEntryData.self, from: json)

        XCTAssertEqual(entry.moodId, "mood_abc123")
        XCTAssertEqual(entry.rating, 4)
        XCTAssertEqual(entry.ratingLabel, "Good")
        XCTAssertEqual(entry.emotionLabels, ["Hopeful", "Grateful"])
        XCTAssertEqual(entry.crisisPrompted, false)
    }

    func testMood_AC028_CrisisEntry_ResponseDecodable() throws {
        let json = """
        {
            "moodId": "mood_crisis1",
            "timestamp": "2026-04-07T22:00:00Z",
            "rating": 1,
            "ratingLabel": "Crisis",
            "emotionLabels": ["Overwhelmed", "Afraid"],
            "source": "direct",
            "crisisPrompted": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entry = try decoder.decode(MoodEntryData.self, from: json)

        XCTAssertEqual(entry.rating, 1)
        XCTAssertEqual(entry.ratingLabel, "Crisis")
        XCTAssertEqual(entry.crisisPrompted, true)
    }

    func testMood_DailySummary_Decodable() throws {
        let json = """
        {
            "date": "2026-03-28",
            "averageRating": 4.2,
            "colorCode": "green",
            "entryCount": 3,
            "highestRating": 5,
            "lowestRating": 3
        }
        """.data(using: .utf8)!

        let summary = try JSONDecoder().decode(MoodDailySummaryData.self, from: json)

        XCTAssertEqual(summary.date, "2026-03-28")
        XCTAssertEqual(summary.averageRating, 4.2)
        XCTAssertEqual(summary.colorCode, "green")
        XCTAssertEqual(summary.entryCount, 3)
    }

    func testMood_AlertStatus_Decodable() throws {
        let json = """
        {
            "sustainedLowMood": false,
            "consecutiveLowDays": 0,
            "lastCrisisEntry": null,
            "alertSharedWithNetwork": false
        }
        """.data(using: .utf8)!

        let status = try JSONDecoder().decode(MoodAlertStatusData.self, from: json)

        XCTAssertFalse(status.sustainedLowMood)
        XCTAssertEqual(status.consecutiveLowDays, 0)
        XCTAssertNil(status.lastCrisisEntry)
        XCTAssertFalse(status.alertSharedWithNetwork)
    }

    func testMood_StreakData_Decodable() throws {
        let json = """
        {
            "currentStreakDays": 14,
            "longestStreakDays": 30,
            "lastEntryDate": "2026-04-07"
        }
        """.data(using: .utf8)!

        let streak = try JSONDecoder().decode(MoodStreakData.self, from: json)

        XCTAssertEqual(streak.currentStreakDays, 14)
        XCTAssertEqual(streak.longestStreakDays, 30)
        XCTAssertEqual(streak.lastEntryDate, "2026-04-07")
    }
}
