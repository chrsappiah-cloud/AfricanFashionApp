//
//  UploadService.swift
//  AfricanFashionApp
//

import CryptoKit
import Foundation

struct MediaAssetDTO: Codable, Identifiable, Hashable {
    let id: UUID
    var remoteURL: URL?
    var provenance: MediaProvenance
    /// Populated after bytes land in object storage (or simulated CDN in development).
    var byteLength: Int64?
    var mimeType: String?
    /// First 16 bytes of SHA-256 as hex (32 chars), for dedupe / integrity metrics in CloudKit rows.
    var checksumPrefixHex: String?
}

struct UploadSource: Sendable {
    enum Kind: Sendable {
        case local(Data, filename: String, mimeType: String)
        case remote(URL)
    }

    let kind: Kind
}

actor UploadService {
    private let http: HTTPClient

    init(http: HTTPClient = URLSessionHTTPClient()) {
        self.http = http
    }

    func ingest(_ source: UploadSource) async throws -> MediaAssetDTO {
        switch source.kind {
        case let .local(data, filename, mimeType):
            try await uploadData(data, filename: filename, mimeType: mimeType)
        case let .remote(url):
            try await fetchAndUpload(url)
        }
    }

    private func uploadData(_ data: Data, filename: String, mimeType: String) async throws -> MediaAssetDTO {
        let provenance = MediaProvenance(
            sourceKind: "local_file",
            originalURLString: nil,
            importedAt: Date()
        )
        let assetID = UUID()
        let checksum = Self.checksumPrefixHex(for: data)
        let encodedName =
            filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "asset.bin"
        let cdnString =
            "https://cdn.example.com/uploads/\(assetID.uuidString)/\(encodedName)"
        guard let remoteURL = URL(string: cdnString), URLValidator.isAllowedHTTPURL(remoteURL) else {
            throw APIError.invalidURL
        }
        return MediaAssetDTO(
            id: assetID,
            remoteURL: remoteURL,
            provenance: provenance,
            byteLength: Int64(data.count),
            mimeType: mimeType,
            checksumPrefixHex: checksum
        )
    }

    private func fetchAndUpload(_ url: URL) async throws -> MediaAssetDTO {
        guard URLValidator.isAllowedHTTPURL(url) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (_, response) = try await http.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(underlying: URLError(.badServerResponse))
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw APIError.status(code: http.statusCode, body: nil)
        }
        let provenance = MediaProvenance(
            sourceKind: "remote_url",
            originalURLString: url.absoluteString,
            importedAt: Date()
        )
        return MediaAssetDTO(
            id: UUID(),
            remoteURL: url,
            provenance: provenance,
            byteLength: nil,
            mimeType: http.value(forHTTPHeaderField: "Content-Type"),
            checksumPrefixHex: nil
        )
    }

    private nonisolated static func checksumPrefixHex(for data: Data, prefixByteCount: Int = 16) -> String {
        let digest = SHA256.hash(data: data)
        return digest.prefix(prefixByteCount).map { String(format: "%02x", $0) }.joined()
    }
}
