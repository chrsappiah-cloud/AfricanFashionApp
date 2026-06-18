//
//  FashionDesignStudioModels.swift
//  AfricanFashionApp
//

import Foundation

struct DesignerClientProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var stylePreferences: [String]
    var favoriteColors: [String]
    var dislikedElements: [String]
    var bodyMeasurements: BodyMeasurements
    var occasions: [String]
    var notes: String
}

struct BodyMeasurements: Codable, Hashable {
    var heightCm: Double
    var bustCm: Double
    var waistCm: Double
    var hipCm: Double
    var inseamCm: Double
    var shoulderCm: Double
}

struct GarmentBrief: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var category: String
    var season: String
    var silhouette: String
    var fabricPreferences: [String]
    var colorPalette: [String]
    var notes: String
}

struct TrendSignal: Identifiable, Codable, Hashable {
    let id: UUID
    var category: String
    var confidence: Double
    var summary: String
    var keywords: [String]
    var designDirection: String
}

struct GeneratedLook: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var prompt: String
    var imageURL: URL?
    var notes: String
    var createdAt: Date
    var versionNumber: Int = 1
    var parentLookID: UUID?
}

struct TechPackDocument: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var generatedAt: Date
    var sections: [TechPackSection]
}

struct TechPackSection: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var body: String
}

struct CollectionPlan: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var market: String
    var season: String
    var looks: [GeneratedLook]
    var trendSignals: [TrendSignal]
}

extension BodyMeasurements {
    static let sample = BodyMeasurements(
        heightCm: 170,
        bustCm: 88,
        waistCm: 70,
        hipCm: 95,
        inseamCm: 76,
        shoulderCm: 40
    )
}

extension DesignerClientProfile {
    static let sample = DesignerClientProfile(
        id: UUID(uuidString: "00000000-0000-4000-8000-000000000101")!,
        name: "Ama Serwaa",
        stylePreferences: ["modern couture", "structured shoulders", "fluid drape"],
        favoriteColors: ["emerald", "black", "gold"],
        dislikedElements: ["heavy embellishment", "stiff skirts"],
        bodyMeasurements: .sample,
        occasions: ["red carpet", "gallery opening"],
        notes: "Prefers elegant waist definition and garment movement."
    )
}
