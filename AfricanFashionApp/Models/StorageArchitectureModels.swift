//
//  StorageArchitectureModels.swift
//  AfricanFashionApp
//

import Foundation

struct StorageBackendsStatusPayload: Decodable, Sendable {
    struct Provider: Decodable, Identifiable, Sendable {
        struct CloudKitInfo: Decodable, Sendable {
            let containerID: String
            let replicationMode: String
        }

        let provider: String
        let status: String
        let capabilities: [String]
        let cloudKit: CloudKitInfo?

        var id: String { provider }
    }

    struct RoutingPolicy: Decodable, Sendable {
        let primary: String
        let failover: String
        let adminData: [String]
        let userData: [String]
        let mediaData: [String]
    }

    let ok: Bool
    let generatedAt: String
    let activeWriteProvider: String
    let activeReadProvider: String
    let failoverEnabled: Bool
    let providers: [Provider]
    let routingPolicy: RoutingPolicy
}

struct DatabaseBlueprintPayload: Decodable, Sendable {
    struct RelationalCore: Decodable, Sendable {
        struct Table: Decodable, Identifiable, Sendable {
            let name: String
            let primaryKey: String
            let indexes: [String]
            let purpose: String

            var id: String { name }
        }

        let engine: String
        let tables: [Table]
    }

    let version: String
    let architecture: String
    let relationalCore: RelationalCore
}
