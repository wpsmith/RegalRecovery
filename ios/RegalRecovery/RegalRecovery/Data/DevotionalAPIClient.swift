// DevotionalAPIClient.swift
// Regal Recovery
//
// Hand-written Swift API client for all devotional endpoints.
// Source of truth: docs/specs/openapi/devotionals.yaml
// Feature flag: activity.devotionals

import Foundation

/// API client for the Devotionals feature.
/// All methods throw on network/decoding errors. HTTP error codes are mapped
/// to ``DevotionalAPIError`` cases.
actor DevotionalAPIClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: () async -> String?

    init(
        baseURL: URL = URL(string: "https://api.regalrecovery.com/v1")!,
        session: URLSession = .shared,
        tokenProvider: @escaping () async -> String?
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
    }

    // MARK: - Content Endpoints

    /// GET /devotionals/today
    func getTodayDevotional() async throws -> DevotionalDTO {
        let data = try await get(path: "/devotionals/today")
        let envelope = try JSONDecoder.apiDecoder.decode(DevotionalResponseEnvelope.self, from: data)
        return envelope.data
    }

    /// GET /devotionals
    func listDevotionals(
        cursor: String? = nil,
        limit: Int = 20,
        topic: DevotionalTopic? = nil,
        author: String? = nil,
        seriesId: String? = nil,
        tier: DevotionalContentTier? = nil,
        language: String? = nil,
        search: String? = nil
    ) async throws -> DevotionalListResponseEnvelope {
        var params: [(String, String)] = []
        if let cursor { params.append(("cursor", cursor)) }
        params.append(("limit", "\(limit)"))
        if let topic { params.append(("topic", topic.rawValue)) }
        if let author { params.append(("author", author)) }
        if let seriesId { params.append(("seriesId", seriesId)) }
        if let tier { params.append(("tier", tier.rawValue)) }
        if let language { params.append(("language", language)) }
        if let search { params.append(("search", search)) }

        let data = try await get(path: "/devotionals", queryItems: params)
        return try JSONDecoder.apiDecoder.decode(DevotionalListResponseEnvelope.self, from: data)
    }

    /// GET /devotionals/{id}
    func getDevotional(id: String) async throws -> DevotionalDTO {
        let data = try await get(path: "/devotionals/\(id)")
        let envelope = try JSONDecoder.apiDecoder.decode(DevotionalResponseEnvelope.self, from: data)
        return envelope.data
    }

    // MARK: - Completion Endpoints

    /// POST /devotionals/{id}/completions
    func createCompletion(
        devotionalId: String,
        timestamp: Date,
        reflection: String? = nil,
        moodTag: DevotionalMoodTag? = nil
    ) async throws -> DevotionalCompletionDTO {
        let body = DevotionalCompletionRequestDTO(
            timestamp: ISO8601DateFormatter().string(from: timestamp),
            reflection: reflection,
            moodTag: moodTag
        )
        let data = try await post(path: "/devotionals/\(devotionalId)/completions", body: body)
        let envelope = try JSONDecoder.apiDecoder.decode(CompletionResponseEnvelope.self, from: data)
        return envelope.data
    }

    /// GET /devotionals/completions/{completionId}
    func getCompletion(completionId: String) async throws -> DevotionalCompletionDTO {
        let data = try await get(path: "/devotionals/completions/\(completionId)")
        let envelope = try JSONDecoder.apiDecoder.decode(CompletionResponseEnvelope.self, from: data)
        return envelope.data
    }

    /// PATCH /devotionals/completions/{completionId}
    func updateCompletion(
        completionId: String,
        reflection: String? = nil,
        moodTag: DevotionalMoodTag? = nil
    ) async throws -> DevotionalCompletionDTO {
        let body = DevotionalCompletionUpdateDTO(reflection: reflection, moodTag: moodTag)
        let data = try await patch(path: "/devotionals/completions/\(completionId)", body: body)
        let envelope = try JSONDecoder.apiDecoder.decode(CompletionResponseEnvelope.self, from: data)
        return envelope.data
    }

    // MARK: - History Endpoints

    /// GET /devotionals/history
    func listHistory(
        cursor: String? = nil,
        limit: Int = 20,
        seriesId: String? = nil,
        topic: DevotionalTopic? = nil,
        author: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        searchReflections: String? = nil,
        sort: String = "-timestamp"
    ) async throws -> HistoryResponseEnvelope {
        var params: [(String, String)] = []
        if let cursor { params.append(("cursor", cursor)) }
        params.append(("limit", "\(limit)"))
        if let seriesId { params.append(("seriesId", seriesId)) }
        if let topic { params.append(("topic", topic.rawValue)) }
        if let author { params.append(("author", author)) }
        if let startDate { params.append(("startDate", startDate)) }
        if let endDate { params.append(("endDate", endDate)) }
        if let searchReflections { params.append(("searchReflections", searchReflections)) }
        params.append(("sort", sort))

        let data = try await get(path: "/devotionals/history", queryItems: params)
        return try JSONDecoder.apiDecoder.decode(HistoryResponseEnvelope.self, from: data)
    }

    /// POST /devotionals/history/export
    func exportHistory(
        startDate: String? = nil,
        endDate: String? = nil,
        includeReflections: Bool = true
    ) async throws -> DevotionalExportResponseDTO {
        let body = DevotionalExportRequestDTO(
            startDate: startDate,
            endDate: endDate,
            includeReflections: includeReflections
        )
        let data = try await post(path: "/devotionals/history/export", body: body)
        return try JSONDecoder.apiDecoder.decode(DevotionalExportResponseDTO.self, from: data)
    }

    // MARK: - Favorites Endpoints

    /// GET /devotionals/favorites
    func listFavorites(cursor: String? = nil, limit: Int = 20) async throws -> FavoritesResponseEnvelope {
        var params: [(String, String)] = []
        if let cursor { params.append(("cursor", cursor)) }
        params.append(("limit", "\(limit)"))
        let data = try await get(path: "/devotionals/favorites", queryItems: params)
        return try JSONDecoder.apiDecoder.decode(FavoritesResponseEnvelope.self, from: data)
    }

    /// POST /devotionals/favorites/{id}
    func addFavorite(devotionalId: String) async throws {
        _ = try await post(path: "/devotionals/favorites/\(devotionalId)", body: Optional<String>.none)
    }

    /// DELETE /devotionals/favorites/{id}
    func removeFavorite(devotionalId: String) async throws {
        _ = try await delete(path: "/devotionals/favorites/\(devotionalId)")
    }

    // MARK: - Series Endpoints

    /// GET /devotionals/series
    func listSeries(
        cursor: String? = nil,
        limit: Int = 20,
        tier: DevotionalContentTier? = nil
    ) async throws -> SeriesListResponseEnvelope {
        var params: [(String, String)] = []
        if let cursor { params.append(("cursor", cursor)) }
        params.append(("limit", "\(limit)"))
        if let tier { params.append(("tier", tier.rawValue)) }
        let data = try await get(path: "/devotionals/series", queryItems: params)
        return try JSONDecoder.apiDecoder.decode(SeriesListResponseEnvelope.self, from: data)
    }

    /// GET /devotionals/series/{seriesId}
    func getSeries(seriesId: String) async throws -> DevotionalSeriesDTO {
        let data = try await get(path: "/devotionals/series/\(seriesId)")
        let envelope = try JSONDecoder.apiDecoder.decode(SeriesResponseEnvelope.self, from: data)
        return envelope.data
    }

    /// POST /devotionals/series/{seriesId}/activate
    func activateSeries(seriesId: String) async throws -> ActivateSeriesResponseDTO {
        let data = try await post(path: "/devotionals/series/\(seriesId)/activate", body: Optional<String>.none)
        return try JSONDecoder.apiDecoder.decode(ActivateSeriesResponseDTO.self, from: data)
    }

    // MARK: - Sharing

    /// POST /devotionals/{id}/share
    func shareDevotional(
        devotionalId: String,
        shareType: DevotionalShareType,
        contactId: String? = nil
    ) async throws -> DevotionalShareResponseDTO {
        let body = DevotionalShareRequestDTO(shareType: shareType, contactId: contactId)
        let data = try await post(path: "/devotionals/\(devotionalId)/share", body: body)
        return try JSONDecoder.apiDecoder.decode(DevotionalShareResponseDTO.self, from: data)
    }

    // MARK: - Streak

    /// GET /devotionals/streak
    func getStreak() async throws -> DevotionalStreakDTO {
        let data = try await get(path: "/devotionals/streak")
        let envelope = try JSONDecoder.apiDecoder.decode(StreakResponseEnvelope.self, from: data)
        return envelope.data
    }

    // MARK: - Private HTTP Methods

    private func get(path: String, queryItems: [(String, String)] = []) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems.map { URLQueryItem(name: $0.0, value: $0.1) }
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        try await applyAuth(&request)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        return data
    }

    private func post<T: Encodable>(path: String, body: T?) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        try await applyAuth(&request)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        return data
    }

    private func patch<T: Encodable>(path: String, body: T) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "PATCH"
        request.setValue("application/merge-patch+json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        try await applyAuth(&request)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        return data
    }

    private func delete(path: String) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "DELETE"
        try await applyAuth(&request)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        return data
    }

    private func applyAuth(_ request: inout URLRequest) async throws {
        if let token = await tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func checkResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DevotionalAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw DevotionalAPIError.unauthorized
        case 403:
            throw DevotionalAPIError.premiumLocked
        case 404:
            throw DevotionalAPIError.notFound
        case 409:
            throw DevotionalAPIError.conflict
        case 422:
            throw DevotionalAPIError.validationError
        default:
            throw DevotionalAPIError.serverError(httpResponse.statusCode)
        }
    }
}

// MARK: - API Error

enum DevotionalAPIError: Error, LocalizedError {
    case unauthorized
    case premiumLocked
    case notFound
    case conflict
    case validationError
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Authentication required"
        case .premiumLocked: return "This content requires a purchase"
        case .notFound: return "Content not found"
        case .conflict: return "This devotional has already been completed today"
        case .validationError: return "Invalid input"
        case .invalidResponse: return "Invalid server response"
        case .serverError(let code): return "Server error (\(code))"
        }
    }
}

// MARK: - JSON Decoder Extension

extension JSONDecoder {
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
