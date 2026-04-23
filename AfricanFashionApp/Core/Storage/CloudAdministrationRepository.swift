//
//  CloudAdministrationRepository.swift
//  AfricanFashionApp
//

import Foundation
import SwiftData

enum CloudAdministrationRepository {
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// Ensures a primary administration row exists with a default payload.
    static func ensurePrimary(into context: ModelContext) throws {
        let targetKey = CloudScopeKeys.administration
        var descriptor = FetchDescriptor<CloudAdministrationRecord>(
            predicate: #Predicate { $0.scopeKey == targetKey },
            sortBy: []
        )
        descriptor.fetchLimit = 1
        if try context.fetch(descriptor).first != nil { return }
        let data = try encoder.encode(CloudAdministrationPayload())
        context.insert(CloudAdministrationRecord(payloadJSON: data))
        try context.save()
    }

    static func loadPayload(from context: ModelContext) throws -> CloudAdministrationPayload? {
        let targetKey = CloudScopeKeys.administration
        var descriptor = FetchDescriptor<CloudAdministrationRecord>(
            predicate: #Predicate { $0.scopeKey == targetKey },
            sortBy: []
        )
        descriptor.fetchLimit = 1
        guard let data = try context.fetch(descriptor).first?.payloadJSON else { return nil }
        return try decoder.decode(CloudAdministrationPayload.self, from: data)
    }

    static func savePayload(_ payload: CloudAdministrationPayload, into context: ModelContext) throws {
        let targetKey = CloudScopeKeys.administration
        var descriptor = FetchDescriptor<CloudAdministrationRecord>(
            predicate: #Predicate { $0.scopeKey == targetKey },
            sortBy: []
        )
        descriptor.fetchLimit = 1
        let encoded = try encoder.encode(payload)
        if let existing = try context.fetch(descriptor).first {
            existing.payloadJSON = encoded
            existing.updatedAt = .now
        } else {
            context.insert(CloudAdministrationRecord(payloadJSON: encoded))
        }
        try context.save()
    }
}
