//
//  CloudAdministrationRecord.swift
//  AfricanFashionApp
//

import Foundation
import SwiftData

/// Serialized **device-local administration** (feature flags, moderation references, sync checkpoints).
/// Global marketplace admin belongs on your server; this row is for operator tooling / staged policy blobs.
@Model
final class CloudAdministrationRecord {
    var scopeKey: String = ""
    var payloadJSON: Data = Data()
    var updatedAt: Date = Date()

    init(scopeKey: String = CloudScopeKeys.administration, payloadJSON: Data, updatedAt: Date = .now) {
        self.scopeKey = scopeKey
        self.payloadJSON = payloadJSON
        self.updatedAt = updatedAt
    }
}
