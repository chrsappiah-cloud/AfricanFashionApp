//
//  CrossrefWorksAPIClient.swift
//  AfricanFashionApp
//
//  Crossref REST API — open scholarly metadata (no API key for polite use).
//  https://github.com/CrossRef/rest-api-doc
//

import Foundation

struct CrossrefWorkSummary: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let doi: String?
    let resourceURL: URL?
}

private struct CrossrefWorksEnvelope: Decodable {
    struct Message: Decodable {
        struct Item: Decodable {
            let title: [String]?
            let DOI: String?
            let URL: String?
        }

        let items: [Item]?
    }

    let message: Message?
}

enum CrossrefWorksAPIClient {
    /// Free-text query against Crossref works (JSON). Keep `rows` small for mobile UX.
    static func searchWorks(
        query: String,
        rows: Int = 5,
        http: HTTPClient = URLSessionHTTPClient()
    ) async throws -> [CrossrefWorkSummary] {
        var components = URLComponents(string: "https://api.crossref.org/works")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "rows", value: "\(max(1, min(rows, 20)))"),
        ]
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "AfricanFashionApp/1.0 (mailto:hello@example.com; https://github.com/CrossRef/rest-api-doc)",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await http.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(underlying: URLError(.badServerResponse))
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw APIError.status(code: http.statusCode, body: data)
        }

        let decoded = try JSONDecoder().decode(CrossrefWorksEnvelope.self, from: data)
        let items = decoded.message?.items ?? []

        return items.enumerated().compactMap { idx, item in
            let title = (item.title?.first?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
                ?? "Untitled work"
            let doi = item.DOI?.trimmingCharacters(in: .whitespacesAndNewlines)
            let id = doi.flatMap { !$0.isEmpty ? $0 : nil } ?? "crossref-\(idx)-\(title.hashValue)"
            let resource = item.URL.flatMap { URL(string: $0) }
                ?? doi.flatMap { URL(string: "https://doi.org/\($0)") }
            return CrossrefWorkSummary(id: id, title: title, doi: doi, resourceURL: resource)
        }
    }
}
