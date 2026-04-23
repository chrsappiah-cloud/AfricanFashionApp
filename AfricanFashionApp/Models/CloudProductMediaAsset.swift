//
//  CloudProductMediaAsset.swift
//  AfricanFashionApp
//

import Foundation
import SwiftData

/// **Metadata + canonical URL** for product media (image / audio / video). Large binaries should live on CDN or
/// object storage; CloudKit stores metrics, URLs, and sync hints for realtime catalog and upload pipelines.
@Model
final class CloudProductMediaAsset {
    var assetID: UUID = UUID()
    var productID: UUID = UUID()
    /// `image` | `audio` | `video`
    var mediaKind: String = "image"
    /// e.g. `hero`, `gallery`, `lookbook`, `voiceover`, `360_preview`
    var role: String = "hero"
    /// HTTPS URL for the canonical asset (signed URL or CDN path).
    var remoteURLString: String = ""
    var byteLength: Int64?
    var pixelWidth: Int?
    var pixelHeight: Int?
    var durationSeconds: Double?
    var frameRate: Double?
    var mimeType: String?
    var codecIdentifier: String?
    /// First 16 bytes of SHA-256 as hex (32 chars) — enough for dedupe metrics without storing full hash in UI.
    var checksumPrefixHex: String?
    var etagOrRevision: String?
    /// `ready` | `processing` | `failed` | `stale`
    var processingState: String = "ready"
    var sortIndex: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        assetID: UUID = UUID(),
        productID: UUID,
        mediaKind: String,
        role: String,
        remoteURLString: String,
        byteLength: Int64? = nil,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil,
        durationSeconds: Double? = nil,
        frameRate: Double? = nil,
        mimeType: String? = nil,
        codecIdentifier: String? = nil,
        checksumPrefixHex: String? = nil,
        etagOrRevision: String? = nil,
        processingState: String = "ready",
        sortIndex: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.assetID = assetID
        self.productID = productID
        self.mediaKind = mediaKind
        self.role = role
        self.remoteURLString = remoteURLString
        self.byteLength = byteLength
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.durationSeconds = durationSeconds
        self.frameRate = frameRate
        self.mimeType = mimeType
        self.codecIdentifier = codecIdentifier
        self.checksumPrefixHex = checksumPrefixHex
        self.etagOrRevision = etagOrRevision
        self.processingState = processingState
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
