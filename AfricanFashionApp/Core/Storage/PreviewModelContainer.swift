//
//  PreviewModelContainer.swift
//  AfricanFashionApp
//

import SwiftData

enum PreviewModelContainer {
    static let cloudSchema: ModelContainer = {
        let schema = Schema([
            CloudBackupEntry.self,
            CloudUserProfile.self,
            CloudAdministrationRecord.self,
            CloudProductMediaAsset.self,
            StudioClientRecord.self,
            StudioGeneratedLookRecord.self,
            StudioTrendSignalRecord.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
}
