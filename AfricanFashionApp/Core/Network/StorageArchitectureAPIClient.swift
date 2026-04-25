//
//  StorageArchitectureAPIClient.swift
//  AfricanFashionApp
//

import Foundation

struct StorageArchitectureAPIClient {
    private let httpClient: HTTPClient
    private let decoder: JSONDecoder

    init(httpClient: HTTPClient = URLSessionHTTPClient()) {
        self.httpClient = httpClient
        self.decoder = JSONDecoder()
    }

    func fetchStorageBackendsStatus() async throws -> StorageBackendsStatusPayload {
        let url = BackendAPI.makeURL(path: "v1/system/storage-backends")
        try BackendAPI.validateTransportSecurity(for: url)
        let request = BackendAPI.makeJSONRequest(url: url, method: "GET")
        return try await BackendAPI.executeWithRetry {
            let (data, response) = try await httpClient.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.transport(underlying: URLError(.badServerResponse))
            }
            guard (200 ... 299).contains(http.statusCode) else {
                throw APIError.status(code: http.statusCode, body: data)
            }
            return try decoder.decode(StorageBackendsStatusPayload.self, from: data)
        }
    }

    func fetchDatabaseBlueprint() async throws -> DatabaseBlueprintPayload {
        let url = BackendAPI.makeURL(path: "v1/system/database-blueprint")
        try BackendAPI.validateTransportSecurity(for: url)
        let request = BackendAPI.makeJSONRequest(url: url, method: "GET")
        return try await BackendAPI.executeWithRetry {
            let (data, response) = try await httpClient.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.transport(underlying: URLError(.badServerResponse))
            }
            guard (200 ... 299).contains(http.statusCode) else {
                throw APIError.status(code: http.statusCode, body: data)
            }
            return try decoder.decode(DatabaseBlueprintPayload.self, from: data)
        }
    }
}
