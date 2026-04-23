//
//  ProductMediaCloudSync.swift
//  AfricanFashionApp
//

import CryptoKit
import Foundation
import SwiftData

/// Builds `CloudProductMediaDraft` after your API (or simulated pipeline) yields a final **https** URL, then upserts into SwiftData for CloudKit sync.
enum ProductMediaCloudSync {
    /// Upserts one row per catalog product that exposes `heroRemoteURLString` (typical API field).
    static func persistCatalogHeroURLs(from products: [Product], into context: ModelContext) throws {
        for product in products {
            guard let urlString = product.heroRemoteURLString?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !urlString.isEmpty,
                  let url = URL(string: urlString),
                  URLValidator.isAllowedHTTPURL(url)
            else { continue }

            let draft = CloudProductMediaDraft(
                assetID: deterministicAssetID(productID: product.id, namespace: "catalog.hero"),
                productID: product.id,
                mediaKind: "image",
                role: "hero",
                remoteURLString: urlString,
                byteLength: nil,
                pixelWidth: nil,
                pixelHeight: nil,
                durationSeconds: nil,
                frameRate: nil,
                mimeType: "image/jpeg",
                codecIdentifier: nil,
                checksumPrefixHex: nil,
                etagOrRevision: nil,
                processingState: "ready",
                sortIndex: 0
            )
            try CloudProductMediaRepository.upsert(draft, into: context)
        }
    }

    /// Call on the main actor after `UploadService.ingest` when `dto.remoteURL` is set (post–object-storage upload).
    static func persistUploadIngest(
        productID: UUID,
        role: String,
        dto: MediaAssetDTO,
        into context: ModelContext
    ) throws {
        guard let url = dto.remoteURL, URLValidator.isAllowedHTTPURL(url) else { return }

        let draft = CloudProductMediaDraft(
            assetID: dto.id,
            productID: productID,
            mediaKind: mediaKind(forMIMEType: dto.mimeType),
            role: role,
            remoteURLString: url.absoluteString,
            byteLength: dto.byteLength,
            pixelWidth: nil,
            pixelHeight: nil,
            durationSeconds: nil,
            frameRate: nil,
            mimeType: dto.mimeType,
            codecIdentifier: nil,
            checksumPrefixHex: dto.checksumPrefixHex,
            etagOrRevision: nil,
            processingState: "ready",
            sortIndex: 0
        )
        try CloudProductMediaRepository.upsert(draft, into: context)
    }

    static func mediaKind(forMIMEType mime: String?) -> String {
        guard let mime, let slash = mime.firstIndex(of: "/") else { return "image" }
        let major = String(mime[..<slash]).lowercased()
        switch major {
        case "audio": return "audio"
        case "video": return "video"
        default: return "image"
        }
    }

    static func deterministicAssetID(productID: UUID, namespace: String) -> UUID {
        let basis = Data("\(namespace)|\(productID.uuidString)".utf8)
        let digest = SHA256.hash(data: basis)
        return digest.withUnsafeBytes { raw in
            let b = raw.bindMemory(to: UInt8.self)
            return UUID(
                uuid: (
                    b[0], b[1], b[2], b[3],
                    b[4], b[5], b[6], b[7],
                    b[8], b[9], b[10], b[11],
                    b[12], b[13], b[14], b[15]
                )
            )
        }
    }
}
