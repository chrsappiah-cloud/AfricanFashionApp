//
//  AfricanFashionApp.swift
//  AfricanFashionApp
//

import SwiftData
import SwiftUI

@main
struct AfricanFashionApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var appRouter = AppRouter()
    @StateObject private var cartStore = CartStore()

    private static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CloudBackupEntry.self,
            CloudUserProfile.self,
            CloudAdministrationRecord.self,
            CloudProductMediaAsset.self,
            StudioClientRecord.self,
            StudioGeneratedLookRecord.self,
            StudioTrendSignalRecord.self,
        ])
        let cloudBacked = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(AppConfiguration.cloudKitContainerIdentifier)
        )
        do {
            return try ModelContainer(for: schema, configurations: [cloudBacked])
        } catch {
            // CloudKit can fail at launch (capability/account/schema/provisioning mismatch). Fall back gracefully.
            let localOnly = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [localOnly])
            } catch {
                // Last-resort safe mode: allow app boot even if on-disk store is incompatible/corrupted.
                let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [inMemory])
                } catch {
                    fatalError("Failed to create SwiftData container (cloud, local, in-memory).")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appRouter)
                .environmentObject(cartStore)
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
