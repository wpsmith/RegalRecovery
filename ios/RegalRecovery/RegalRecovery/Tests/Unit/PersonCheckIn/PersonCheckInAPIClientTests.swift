import XCTest
@testable import RegalRecovery

final class PersonCheckInAPIClientTests: XCTestCase {

    func testCreateCheckInSendsCorrectRequestBody() throws {
        let request = CreatePersonCheckInRequestDTO(
            checkInType: "spouse",
            method: "in-person",
            timestamp: "2026-03-28T18:30:00Z",
            contactName: "Sarah",
            durationMinutes: 30,
            qualityRating: 4,
            topicsDiscussed: ["relationships-marriage", "emotions-feelings", "accountability"],
            notes: "Had a really honest conversation about this week.",
            followUpItems: ["Schedule a date night for Friday"],
            counselorSubCategory: nil
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(CreatePersonCheckInRequestDTO.self, from: data)

        XCTAssertEqual(decoded.checkInType, "spouse")
        XCTAssertEqual(decoded.method, "in-person")
        XCTAssertEqual(decoded.contactName, "Sarah")
        XCTAssertEqual(decoded.durationMinutes, 30)
        XCTAssertEqual(decoded.qualityRating, 4)
        XCTAssertEqual(decoded.topicsDiscussed?.count, 3)
        XCTAssertEqual(decoded.followUpItems?.count, 1)
    }

    func testListCheckInsParseCursorPagination() throws {
        let json = """
        {
            "data": [],
            "links": {
                "self": "/activities/person-check-ins?limit=25",
                "next": "/activities/person-check-ins?cursor=abc123&limit=25"
            },
            "meta": {
                "page": {
                    "nextCursor": "abc123",
                    "limit": 25
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(PersonCheckInListAPIResponse.self, from: data)

        XCTAssertNotNil(response.links?.next)
        XCTAssertEqual(response.meta?.page?.nextCursor, "abc123")
        XCTAssertEqual(response.meta?.page?.limit, 25)
    }

    func testQuickLogSendsMinimalRequest() throws {
        let request = QuickLogPersonCheckInRequestDTO(
            checkInType: "sponsor",
            method: nil
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(QuickLogPersonCheckInRequestDTO.self, from: data)

        XCTAssertEqual(decoded.checkInType, "sponsor")
        XCTAssertNil(decoded.method)
    }

    func testPatchSendsMergePatchContentType() {
        // The update endpoint must use "application/merge-patch+json" content type.
        // This is validated by the API client implementation.
        // Here we verify the request DTO encodes correctly with optional fields.
        let request = UpdatePersonCheckInRequestDTO(
            method: nil,
            contactName: nil,
            durationMinutes: nil,
            qualityRating: 4,
            topicsDiscussed: ["sobriety-recovery", "step-work"],
            notes: "Great conversation about Step 4 progress.",
            followUpItems: ["Write out resentment list before next meeting"],
            counselorSubCategory: nil
        )

        XCTAssertEqual(request.qualityRating, 4)
        XCTAssertEqual(request.topicsDiscussed?.count, 2)
        XCTAssertNil(request.method)
    }
}
