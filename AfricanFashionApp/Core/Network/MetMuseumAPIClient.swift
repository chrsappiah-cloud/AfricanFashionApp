//
//  MetMuseumAPIClient.swift
//  AfricanFashionApp
//
//  The Met Collection API — open data, no key required (please stay under ~80 req/s).
//  https://metmuseum.github.io/ — CC0 images where `isPublicDomain` is true.
//

import Foundation

/// Curated row for UI: real garment / textile photography from The Met’s open collection.
struct MetOpenAccessArtwork: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let subtitle: String
    let imageURL: URL
    let collectionObjectURL: URL?
    let isPublicDomain: Bool
}

struct MetSearchResponse: Sendable {
    let total: Int?
    let objectIDs: [Int]?
}

extension MetSearchResponse: Decodable {
    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        total = try c.decodeIfPresent(Int.self, forKey: .total)
        objectIDs = try c.decodeIfPresent([Int].self, forKey: .objectIDs)
    }

    private enum CodingKeys: String, CodingKey {
        case total
        case objectIDs
    }
}

struct MetObjectResponse: Sendable {
    let objectID: Int?
    let title: String?
    let culture: String?
    let period: String?
    let dynasty: String?
    let artistDisplayName: String?
    let primaryImage: String?
    let primaryImageSmall: String?
    let isPublicDomain: Bool?
    let objectURL: String?
}

extension MetObjectResponse: Decodable {
    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        objectID = try c.decodeIfPresent(Int.self, forKey: .objectID)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        culture = try c.decodeIfPresent(String.self, forKey: .culture)
        period = try c.decodeIfPresent(String.self, forKey: .period)
        dynasty = try c.decodeIfPresent(String.self, forKey: .dynasty)
        artistDisplayName = try c.decodeIfPresent(String.self, forKey: .artistDisplayName)
        primaryImage = try c.decodeIfPresent(String.self, forKey: .primaryImage)
        primaryImageSmall = try c.decodeIfPresent(String.self, forKey: .primaryImageSmall)
        isPublicDomain = try c.decodeIfPresent(Bool.self, forKey: .isPublicDomain)
        objectURL = try c.decodeIfPresent(String.self, forKey: .objectURL)
    }

    private enum CodingKeys: String, CodingKey {
        case objectID
        case title
        case culture
        case period
        case dynasty
        case artistDisplayName
        case primaryImage
        case primaryImageSmall
        case isPublicDomain
        case objectURL
    }
}

enum MetMuseumAPIClient: Sendable {
    nonisolated private static let baseURL = URL(string: "https://collectionapi.metmuseum.org/public/collection/v1")!

    /// Searches the collection; returns object id candidates (newest / relevance order from the API).
    nonisolated static func searchObjectIDs(
        query: String,
        hasImages: Bool = true,
        http: HTTPClient = URLSessionHTTPClient()
    ) async throws -> [Int] {
        var components = URLComponents(url: baseURL.appendingPathComponent("search"), resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = [URLQueryItem(name: "q", value: query)]
        if hasImages {
            items.append(URLQueryItem(name: "hasImages", value: "true"))
        }
        components.queryItems = items
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await http.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw APIError.status(code: (response as? HTTPURLResponse)?.statusCode ?? 0, body: data)
        }
        let decoded = try JSONDecoder().decode(MetSearchResponse.self, from: data)
        return decoded.objectIDs ?? []
    }

    nonisolated static func fetchObject(
        id: Int,
        http: HTTPClient = URLSessionHTTPClient()
    ) async throws -> MetObjectResponse {
        let url = baseURL.appendingPathComponent("objects/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await http.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw APIError.status(code: (response as? HTTPURLResponse)?.statusCode ?? 0, body: data)
        }
        return try JSONDecoder().decode(MetObjectResponse.self, from: data)
    }

    /// Loads a short list of **real** open-access images for textiles, dress, and adornment (world fashion, including African regions).
    nonisolated static func loadOpenAccessFashionHighlights(
        queries: [String] = [
            "African textile",
            "Kente cloth",
            "Yoruba crown",
            "African jewelry",
            "Adinkra cloth",
        ],
        maxTotal: Int = 12,
        http: HTTPClient = URLSessionHTTPClient()
    ) async -> [MetOpenAccessArtwork] {
        var seen = Set<Int>()
        var collected: [MetOpenAccessArtwork] = []

        for query in queries {
            guard collected.count < maxTotal else { break }
            guard let ids = try? await searchObjectIDs(query: query, hasImages: true, http: http) else { continue }
            for id in ids {
                guard collected.count < maxTotal else { break }
                guard !seen.contains(id) else { continue }
                if let artwork = await mapToArtworkIfEligible(id: id, http: http) {
                    seen.insert(id)
                    collected.append(artwork)
                }
            }
        }

        if collected.count < max(4, maxTotal / 2) {
            let fallback = (try? await searchObjectIDs(query: "textile costume accessory", hasImages: true, http: http)) ?? []
            for id in fallback {
                guard collected.count < maxTotal else { break }
                guard !seen.contains(id) else { continue }
                if let artwork = await mapToArtworkIfEligible(id: id, http: http) {
                    seen.insert(id)
                    collected.append(artwork)
                }
            }
        }

        return collected
    }

    private nonisolated static func mapToArtworkIfEligible(
        id: Int,
        http: HTTPClient
    ) async -> MetOpenAccessArtwork? {
        do {
            let obj = try await fetchObject(id: id, http: http)
            let imageString: String? = {
                if let primary = obj.primaryImage, !primary.isEmpty { return primary }
                if let small = obj.primaryImageSmall, !small.isEmpty { return small }
                return nil
            }()
            guard let raw = imageString, let imageURL = URL(string: raw) else {
                return nil
            }
            guard obj.isPublicDomain == true else {
                return nil
            }
            let trimmedTitle = (obj.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let title = trimmedTitle.isEmpty ? "Collection object" : trimmedTitle
            let parts = [obj.culture, obj.dynasty, obj.period, obj.artistDisplayName]
                .compactMap { value -> String? in
                    let t = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    return t.isEmpty ? nil : t
                }
            let subtitle = parts.joined(separator: " · ")
            let page = obj.objectURL.flatMap(URL.init(string:))
            return MetOpenAccessArtwork(
                id: obj.objectID ?? id,
                title: title,
                subtitle: subtitle.isEmpty ? "The Metropolitan Museum of Art" : subtitle,
                imageURL: imageURL,
                collectionObjectURL: page,
                isPublicDomain: true
            )
        } catch {
            return nil
        }
    }
}
