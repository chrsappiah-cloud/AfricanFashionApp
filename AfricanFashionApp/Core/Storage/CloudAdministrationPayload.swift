//
//  CloudAdministrationPayload.swift
//  AfricanFashionApp
//

import Foundation

/// JSON envelope stored in `CloudAdministrationRecord.payloadJSON`.
struct CloudAdministrationPayload: Codable, Equatable, Sendable {
    var featureFlags: [String: Bool]
    /// Product IDs awaiting moderation on **your backend**; CloudKit only holds references.
    var moderationQueueProductIDs: [UUID]
    var lastCatalogSync: Date?
    var schemaVersion: Int

    init(
        featureFlags: [String: Bool] = [:],
        moderationQueueProductIDs: [UUID] = [],
        lastCatalogSync: Date? = nil,
        schemaVersion: Int = 1
    ) {
        self.featureFlags = featureFlags
        self.moderationQueueProductIDs = moderationQueueProductIDs
        self.lastCatalogSync = lastCatalogSync
        self.schemaVersion = schemaVersion
    }
}
