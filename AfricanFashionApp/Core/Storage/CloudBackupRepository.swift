//
//  CloudBackupRepository.swift
//  AfricanFashionApp
//

import Foundation
import SwiftData

enum CloudBackupRepository {
    /// Upserts a blob keyed by `slug`. CloudKit sync is handled by SwiftData when entitlements + container are valid.
    static func upsert(slug: String, payload: Data, into context: ModelContext) throws {
        let targetSlug = slug
        var descriptor = FetchDescriptor<CloudBackupEntry>(
            predicate: #Predicate { $0.slug == targetSlug },
            sortBy: []
        )
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.payload = payload
            existing.updatedAt = .now
        } else {
            context.insert(CloudBackupEntry(slug: slug, payload: payload))
        }
        try context.save()
    }

    static func load(slug: String, from context: ModelContext) throws -> Data? {
        let targetSlug = slug
        var descriptor = FetchDescriptor<CloudBackupEntry>(
            predicate: #Predicate { $0.slug == targetSlug },
            sortBy: []
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.payload
    }
}
