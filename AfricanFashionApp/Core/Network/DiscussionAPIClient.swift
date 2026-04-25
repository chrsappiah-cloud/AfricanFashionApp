//
//  DiscussionAPIClient.swift
//  AfricanFashionApp
//

import Foundation

struct DiscussionAPIClient {
    private let httpClient: HTTPClient
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(httpClient: HTTPClient = URLSessionHTTPClient()) {
        self.httpClient = httpClient
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func fetchFeed(channelID: String?) async throws -> DiscussionFeedPayload {
        if AppConfiguration.current.environment == .development {
            return MockDiscussionData.feed(channelID: channelID)
        }

        let base = BackendAPI.makeURL(path: "v1/discussion/feed")
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        if let channelID, !channelID.isEmpty {
            components?.queryItems = [URLQueryItem(name: "channel", value: channelID)]
        }
        guard let url = components?.url else { throw APIError.invalidURL }
        try BackendAPI.validateTransportSecurity(for: url)

        let request = BackendAPI.makeJSONRequest(
            url: url,
            method: "GET"
        )
        return try await BackendAPI.executeWithRetry {
            let (data, response) = try await httpClient.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.transport(underlying: URLError(.badServerResponse))
            }
            guard (200 ... 299).contains(http.statusCode) else {
                throw APIError.status(code: http.statusCode, body: data)
            }
            return try decoder.decode(DiscussionFeedPayload.self, from: data)
        }
    }

    func createThread(channelID: String, title: String, message: String) async throws -> DiscussionThread {
        if AppConfiguration.current.environment == .development {
            return MockDiscussionData.createThread(channelID: channelID, title: title, message: message)
        }

        let url = BackendAPI.makeURL(path: "v1/discussion/threads")
        try BackendAPI.validateTransportSecurity(for: url)
        let body = try encoder.encode(
            CreateDiscussionThreadRequest(
                channelID: channelID,
                title: title,
                message: message
            )
        )
        let request = BackendAPI.makeJSONRequest(url: url, method: "POST", body: body)
        return try await BackendAPI.executeWithRetry {
            let (data, response) = try await httpClient.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.transport(underlying: URLError(.badServerResponse))
            }
            guard (200 ... 299).contains(http.statusCode) else {
                throw APIError.status(code: http.statusCode, body: data)
            }
            return try decoder.decode(DiscussionThread.self, from: data)
        }
    }

    func fetchPipelineStatus() async throws -> APIPipelineStatus {
        if AppConfiguration.current.environment == .development {
            return APIPipelineStatus(
                api: true,
                middleware: true,
                realtime: true,
                database: true,
                message: "Development mock pipeline online.",
                checkedAt: Date()
            )
        }

        let url = BackendAPI.makeURL(path: "v1/system/pipeline-status")
        try BackendAPI.validateTransportSecurity(for: url)
        let request = BackendAPI.makeJSONRequest(url: url, method: "GET")
        let (data, response) = try await httpClient.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(underlying: URLError(.badServerResponse))
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw APIError.status(code: http.statusCode, body: data)
        }
        return try decoder.decode(APIPipelineStatus.self, from: data)
    }
}

enum MockDiscussionData {
    private static let channels: [DiscussionChannel] = [
        DiscussionChannel(id: "style-lab", title: "Style Lab", subtitle: "Design ideas and critiques"),
        DiscussionChannel(id: "market", title: "Market Trends", subtitle: "Demand insights and pricing"),
        DiscussionChannel(id: "craft", title: "Craft Circle", subtitle: "Textiles, tailoring, finishing")
    ]

    private static var threads: [DiscussionThread] = [
        DiscussionThread(
            id: UUID(),
            channelID: "style-lab",
            authorName: "Creative Director",
            authorRole: "Mentor",
            title: "Top silhouette trends for this season",
            message: "Share your strongest silhouette reference and explain why it will convert in your target city.",
            postedAt: Date().addingTimeInterval(-4800),
            replyCount: 14,
            likeCount: 58,
            isPinned: true
        ),
        DiscussionThread(
            id: UUID(),
            channelID: "market",
            authorName: "Retail Partner",
            authorRole: "Advisor",
            title: "How are you pricing premium handmade pieces?",
            message: "Drop your pricing framework and customer segment assumptions.",
            postedAt: Date().addingTimeInterval(-7400),
            replyCount: 7,
            likeCount: 23,
            isPinned: false
        )
    ]

    static func feed(channelID: String?) -> DiscussionFeedPayload {
        let filtered = threads
            .filter { channelID == nil || $0.channelID == channelID }
            .sorted {
                if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
                return $0.postedAt > $1.postedAt
            }
        return DiscussionFeedPayload(channels: channels, threads: filtered)
    }

    static func createThread(channelID: String, title: String, message: String) -> DiscussionThread {
        let newThread = DiscussionThread(
            id: UUID(),
            channelID: channelID,
            authorName: "You",
            authorRole: "Member",
            title: title,
            message: message,
            postedAt: Date(),
            replyCount: 0,
            likeCount: 0,
            isPinned: false
        )
        threads.insert(newThread, at: 0)
        return newThread
    }
}
