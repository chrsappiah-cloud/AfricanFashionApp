//
//  CloudBackupEntry.swift
//  AfricanFashionApp
//

import Foundation
import SwiftData

/// Lightweight rows mirrored into the **private CloudKit database** via SwiftData.
/// Store JSON or other serialized app state (cart snapshots, feature flags, offline queues).
@Model
final class CloudBackupEntry {
    var slug: String = ""
    var payload: Data = Data()
    var updatedAt: Date = Date()

    init(slug: String, payload: Data, updatedAt: Date = .now) {
        self.slug = slug
        self.payload = payload
        self.updatedAt = updatedAt
    }
}
