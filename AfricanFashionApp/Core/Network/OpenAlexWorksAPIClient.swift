//
//  OpenAlexWorksAPIClient.swift
//  AfricanFashionApp
//
//  OpenAlex Works API — open scholarly metadata, including institution filters.
//  https://api.openalex.org/works
//

import Foundation

struct OpenAlexWorkSummary: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let publicationYear: Int?
    let hostVenue: String?
    let landingPageURL: URL?
}

private struct OpenAlexWorksEnvelope: Decodable {
    struct Work: Decodable {
        struct Location: Decodable {
            struct Source: Decodable {
                let display_name: String?
            }

            let landing_page_url: String?
            let source: Source?
        }

        let id: String?
        let display_name: String?
        let publication_year: Int?
        let primary_location: Location?
    }

    let results: [Work]?
}

enum OpenAlexWorksAPIClient {
    /// Oxford institution id on OpenAlex: I856595321.
    static let oxfordInstitutionID = "I856595321"

    /// Polite pool contact (OpenAlex recommends `mailto` on requests). Set `OPENALEX_MAILTO` in the scheme or CI.
    static func resolveMailtoContact() -> String {
        if let raw = ProcessInfo.processInfo.environment["OPENALEX_MAILTO"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            return raw
        }
        return "hello@example.com"
    }

    /// Pull works linked to a target institution, sorted by recency.
    static func searchRecentWorksForInstitution(
        institutionID: String = oxfordInstitutionID,
        searchQuery: String? = nil,
        perPage: Int = 5,
        http: HTTPClient = URLSessionHTTPClient()
    ) async throws -> [OpenAlexWorkSummary] {
        var components = URLComponents(string: "https://api.openalex.org/works")!

        let filter = "institutions.id:https://openalex.org/\(institutionID)"
        let mailto = resolveMailtoContact()

        var items: [URLQueryItem] = [
            URLQueryItem(name: "filter", value: filter),
            URLQueryItem(name: "sort", value: "publication_year:desc"),
            URLQueryItem(name: "per-page", value: "\(max(1, min(perPage, 15)))"),
            URLQueryItem(name: "mailto", value: mailto),
        ]
        if let searchQuery, !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items.append(URLQueryItem(name: "search", value: searchQuery))
        }
        components.queryItems = items

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "AfricanFashionApp/1.0 (mailto:\(mailto); https://api.openalex.org)",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await http.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(underlying: URLError(.badServerResponse))
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw APIError.status(code: http.statusCode, body: data)
        }

        let decoded = try JSONDecoder().decode(OpenAlexWorksEnvelope.self, from: data)
        let works = decoded.results ?? []
        return works.enumerated().compactMap { idx, work in
            let id = work.id ?? "openalex-\(idx)"
            let title = work.display_name?.trimmingCharacters(in: .whitespacesAndNewlines)
            let safeTitle = (title?.isEmpty == false) ? title! : "Untitled work"
            let venue = work.primary_location?.source?.display_name?.trimmingCharacters(in: .whitespacesAndNewlines)
            let landing = work.primary_location?.landing_page_url.flatMap(URL.init(string:))
            return OpenAlexWorkSummary(
                id: id,
                title: safeTitle,
                publicationYear: work.publication_year,
                hostVenue: venue?.isEmpty == true ? nil : venue,
                landingPageURL: landing
            )
        }
    }
}
