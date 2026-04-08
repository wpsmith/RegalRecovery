import XCTest
@testable import RegalRecovery

/// Contract tests verifying serialized JSON from Swift models matches the OpenAPI spec.
final class PostMortemAPIClientTests: XCTestCase {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .useDefaultKeys
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Create Request Contract

    /// Verifies CreatePostMortemRequest serializes with camelCase fields matching OpenAPI spec.
    func testCreateRequest_MatchesOpenAPISchema() throws {
        let request = CreatePostMortemRequest(
            timestamp: "2026-03-28T23:00:00Z",
            eventType: "relapse",
            relapseId: "r_98765",
            addictionId: "a_67890",
            sections: PostMortemSectionsData(
                dayBefore: DayBeforeSectionData(
                    text: "Was feeling disconnected",
                    moodRating: 4,
                    recoveryPracticesKept: false,
                    unresolvedConflicts: "Argument with spouse"
                ),
                morning: nil, throughoutTheDay: nil, buildUp: nil, actingOut: nil, immediatelyAfter: nil
            )
        )

        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["timestamp"] as? String, "2026-03-28T23:00:00Z")
        XCTAssertEqual(json["eventType"] as? String, "relapse")
        XCTAssertEqual(json["relapseId"] as? String, "r_98765")
        XCTAssertEqual(json["addictionId"] as? String, "a_67890")

        let sections = json["sections"] as? [String: Any]
        XCTAssertNotNil(sections)
        let dayBefore = sections?["dayBefore"] as? [String: Any]
        XCTAssertEqual(dayBefore?["text"] as? String, "Was feeling disconnected")
        XCTAssertEqual(dayBefore?["moodRating"] as? Int, 4)
        XCTAssertEqual(dayBefore?["recoveryPracticesKept"] as? Bool, false)
    }

    // MARK: - Event Types

    /// Verifies all event type enum values match the OpenAPI spec.
    func testEventType_AllValuesMatchSpec() {
        XCTAssertEqual(PostMortemEventType.relapse.rawValue, "relapse")
        XCTAssertEqual(PostMortemEventType.nearMiss.rawValue, "near-miss")
        XCTAssertEqual(PostMortemEventType.combined.rawValue, "combined")
    }

    // MARK: - Trigger Categories

    /// Verifies all trigger category values match the OpenAPI spec (same as Urge Logging).
    func testTriggerCategory_AllValuesMatchSpec() {
        let expected = ["emotional", "environmental", "relational", "physical", "digital", "spiritual"]
        let actual = [TriggerCategory.emotional, .environmental, .relational, .physical, .digital, .spiritual]
            .map(\.rawValue)
        XCTAssertEqual(actual, expected)
    }

    // MARK: - FASTER Stages

    /// Verifies all FASTER stage values match the OpenAPI spec.
    func testFASTERStage_AllValuesMatchSpec() {
        XCTAssertEqual(FASTERStage.restoration.rawValue, "restoration")
        XCTAssertEqual(FASTERStage.forgettingPriorities.rawValue, "forgetting-priorities")
        XCTAssertEqual(FASTERStage.anxiety.rawValue, "anxiety")
        XCTAssertEqual(FASTERStage.speedingUp.rawValue, "speeding-up")
        XCTAssertEqual(FASTERStage.tickedOff.rawValue, "ticked-off")
        XCTAssertEqual(FASTERStage.exhausted.rawValue, "exhausted")
        XCTAssertEqual(FASTERStage.relapse.rawValue, "relapse")
    }

    // MARK: - Action Categories

    /// Verifies action plan categories match the spec.
    func testActionCategory_AllValuesMatchSpec() {
        let expected = ["spiritual", "relational", "emotional", "physical", "practical"]
        let actual = [ActionCategory.spiritual, .relational, .emotional, .physical, .practical]
            .map(\.rawValue)
        XCTAssertEqual(actual, expected)
    }

    // MARK: - Response Decoding

    /// Verifies PostMortemSummaryData decodes correctly from API JSON.
    func testPostMortemSummary_DecodesFromJSON() throws {
        let json = """
        {
            "analysisId": "pm_99999",
            "timestamp": "2026-03-28T23:00:00Z",
            "status": "draft",
            "eventType": "relapse",
            "relapseId": "r_98765",
            "addictionId": "a_67890",
            "sectionsCompleted": ["dayBefore"],
            "sectionsRemaining": ["morning", "throughoutTheDay", "buildUp", "actingOut", "immediatelyAfter"],
            "actionItemCount": 0
        }
        """.data(using: .utf8)!

        let summary = try decoder.decode(PostMortemSummaryData.self, from: json)
        XCTAssertEqual(summary.analysisId, "pm_99999")
        XCTAssertEqual(summary.status, "draft")
        XCTAssertEqual(summary.eventType, "relapse")
        XCTAssertEqual(summary.sectionsCompleted?.count, 1)
        XCTAssertEqual(summary.sectionsRemaining?.count, 5)
    }

    /// Verifies PostMortemInsightsData decodes correctly.
    func testInsightsResponse_DecodesFromJSON() throws {
        let json = """
        {
            "totalAnalyses": 5,
            "commonTriggers": [
                {"category": "digital", "frequency": 4, "percentage": 80.0}
            ],
            "commonFasterStageAtBreak": {
                "stage": "exhausted",
                "frequency": 3,
                "percentage": 60.0
            },
            "commonTimeOfDay": {
                "period": "evening",
                "frequency": 4,
                "percentage": 80.0
            },
            "recurringDecisionPoints": [
                {"theme": "Choosing to isolate instead of reaching out", "frequency": 3}
            ]
        }
        """.data(using: .utf8)!

        let insights = try decoder.decode(PostMortemInsightsData.self, from: json)
        XCTAssertEqual(insights.totalAnalyses, 5)
        XCTAssertEqual(insights.commonTriggers?.first?.category, "digital")
        XCTAssertEqual(insights.commonFasterStageAtBreak?.stage, "exhausted")
        XCTAssertEqual(insights.commonTimeOfDay?.period, "evening")
        XCTAssertEqual(insights.recurringDecisionPoints?.first?.frequency, 3)
    }

    // MARK: - Trigger Detail Roundtrip

    /// Verifies TriggerDetailData encodes/decodes with three-layer exploration.
    func testTriggerDetail_ThreeLayerRoundtrip() throws {
        let trigger = TriggerDetailData(
            category: "emotional",
            surface: "Boredom",
            underlying: "Loneliness",
            coreWound: "Fear of being unlovable"
        )

        let data = try encoder.encode(trigger)
        let decoded = try decoder.decode(TriggerDetailData.self, from: data)

        XCTAssertEqual(decoded.category, "emotional")
        XCTAssertEqual(decoded.surface, "Boredom")
        XCTAssertEqual(decoded.underlying, "Loneliness")
        XCTAssertEqual(decoded.coreWound, "Fear of being unlovable")
    }

    // MARK: - Share Request

    /// Verifies share request serializes correctly.
    func testShareRequest_SerializesCorrectly() throws {
        let request = SharePostMortemRequestBody(shares: [
            ShareEntryData(contactId: "c_99999", shareType: "full"),
            ShareEntryData(contactId: "c_88888", shareType: "summary"),
        ])

        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let shares = json["shares"] as? [[String: Any]]
        XCTAssertEqual(shares?.count, 2)
        XCTAssertEqual(shares?.first?["contactId"] as? String, "c_99999")
        XCTAssertEqual(shares?.first?["shareType"] as? String, "full")
    }

    // MARK: - Endpoint Paths

    /// Verifies post-mortem endpoint paths match OpenAPI spec.
    func testEndpointPaths_MatchOpenAPISpec() {
        XCTAssertEqual(
            Endpoint.createPostMortem(CreatePostMortemRequest(
                timestamp: "", eventType: "", relapseId: nil, addictionId: nil, sections: nil
            )).path,
            "/activities/post-mortem"
        )
        XCTAssertEqual(
            Endpoint.getPostMortem(analysisId: "pm_99999").path,
            "/activities/post-mortem/pm_99999"
        )
        XCTAssertEqual(
            Endpoint.completePostMortem(analysisId: "pm_99999").path,
            "/activities/post-mortem/pm_99999/complete"
        )
        XCTAssertEqual(
            Endpoint.getPostMortemInsights(addictionId: nil).path,
            "/activities/post-mortem/insights"
        )
    }

    // MARK: - Compassionate Messages

    /// Verifies compassionate messages match the spec exactly.
    func testCompassionateMessages_MatchSpec() {
        XCTAssertEqual(
            PostMortemMessages.opening,
            "A relapse is painful, but it is also an opportunity to learn. This process will help you understand what happened so you can build a stronger foundation going forward."
        )
        XCTAssertEqual(
            PostMortemMessages.closing,
            "Thank you for your honesty and courage. Every insight you have gained here is a step toward lasting freedom."
        )
    }
}
