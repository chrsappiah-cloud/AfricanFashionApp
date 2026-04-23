//
//  CloudProductMediaRepository.swift
//  AfricanFashionApp
//

import Foundation
import SwiftData

struct CloudProductMediaDraft: Equatable, Sendable {
    var assetID: UUID
    var productID: UUID
    var mediaKind: String
    var role: String
    var remoteURLString: String
    var byteLength: Int64?
    var pixelWidth: Int?
    var pixelHeight: Int?
    var durationSeconds: Double?
    var frameRate: Double?
    var mimeType: String?
    var codecIdentifier: String?
    var checksumPrefixHex: String?
    var etagOrRevision: String?
    var processingState: String
    var sortIndex: Int
}

enum CloudProductMediaRepository {
    static func upsert(_ draft: CloudProductMediaDraft, into context: ModelContext) throws {
        let targetID = draft.assetID
        var descriptor = FetchDescriptor<CloudProductMediaAsset>(
            predicate: #Predicate { $0.assetID == targetID },
            sortBy: []
        )
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            apply(draft: draft, to: existing)
        } else {
            context.insert(
                CloudProductMediaAsset(
                    assetID: draft.assetID,
                    productID: draft.productID,
                    mediaKind: draft.mediaKind,
                    role: draft.role,
                    remoteURLString: draft.remoteURLString,
                    byteLength: draft.byteLength,
                    pixelWidth: draft.pixelWidth,
                    pixelHeight: draft.pixelHeight,
                    durationSeconds: draft.durationSeconds,
                    frameRate: draft.frameRate,
                    mimeType: draft.mimeType,
                    codecIdentifier: draft.codecIdentifier,
                    checksumPrefixHex: draft.checksumPrefixHex,
                    etagOrRevision: draft.etagOrRevision,
                    processingState: draft.processingState,
                    sortIndex: draft.sortIndex
                )
            )
        }
        try context.save()
    }

    private static func apply(draft: CloudProductMediaDraft, to asset: CloudProductMediaAsset) {
        asset.productID = draft.productID
        asset.mediaKind = draft.mediaKind
        asset.role = draft.role
        asset.remoteURLString = draft.remoteURLString
        asset.byteLength = draft.byteLength
        asset.pixelWidth = draft.pixelWidth
        asset.pixelHeight = draft.pixelHeight
        asset.durationSeconds = draft.durationSeconds
        asset.frameRate = draft.frameRate
        asset.mimeType = draft.mimeType
        asset.codecIdentifier = draft.codecIdentifier
        asset.checksumPrefixHex = draft.checksumPrefixHex
        asset.etagOrRevision = draft.etagOrRevision
        asset.processingState = draft.processingState
        asset.sortIndex = draft.sortIndex
        asset.updatedAt = .now
    }

    static func assets(forProductID productID: UUID, in context: ModelContext) throws -> [CloudProductMediaAsset] {
        let targetProduct = productID
        let descriptor = FetchDescriptor<CloudProductMediaAsset>(
            predicate: #Predicate { $0.productID == targetProduct },
            sortBy: [SortDescriptor(\.sortIndex), SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }
}
