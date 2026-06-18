//
//  FashionDesignStudioRecords.swift
//  AfricanFashionApp
//

import Foundation
import SwiftData

@Model
final class StudioClientRecord {
    var id: UUID = UUID()
    var name: String = ""
    var stylePreferencesText: String = ""
    var favoriteColorsText: String = ""
    var dislikedElementsText: String = ""
    var occasionsText: String = ""
    var notes: String = ""
    var heightCm: Double = 0
    var bustCm: Double = 0
    var waistCm: Double = 0
    var hipCm: Double = 0
    var inseamCm: Double = 0
    var shoulderCm: Double = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(profile: DesignerClientProfile, createdAt: Date = .now, updatedAt: Date = .now) {
        id = profile.id
        name = profile.name
        stylePreferencesText = profile.stylePreferences.joined(separator: "\n")
        favoriteColorsText = profile.favoriteColors.joined(separator: "\n")
        dislikedElementsText = profile.dislikedElements.joined(separator: "\n")
        occasionsText = profile.occasions.joined(separator: "\n")
        notes = profile.notes
        heightCm = profile.bodyMeasurements.heightCm
        bustCm = profile.bodyMeasurements.bustCm
        waistCm = profile.bodyMeasurements.waistCm
        hipCm = profile.bodyMeasurements.hipCm
        inseamCm = profile.bodyMeasurements.inseamCm
        shoulderCm = profile.bodyMeasurements.shoulderCm
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var profile: DesignerClientProfile {
        DesignerClientProfile(
            id: id,
            name: name,
            stylePreferences: stylePreferencesText.lines,
            favoriteColors: favoriteColorsText.lines,
            dislikedElements: dislikedElementsText.lines,
            bodyMeasurements: BodyMeasurements(
                heightCm: heightCm,
                bustCm: bustCm,
                waistCm: waistCm,
                hipCm: hipCm,
                inseamCm: inseamCm,
                shoulderCm: shoulderCm
            ),
            occasions: occasionsText.lines,
            notes: notes
        )
    }
}

@Model
final class StudioGeneratedLookRecord {
    var id: UUID = UUID()
    var title: String = ""
    var prompt: String = ""
    var imageURLString: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    var versionNumber: Int = 1
    var parentLookID: UUID?

    init(look: GeneratedLook) {
        id = look.id
        title = look.title
        prompt = look.prompt
        imageURLString = look.imageURL?.absoluteString ?? ""
        notes = look.notes
        createdAt = look.createdAt
        versionNumber = look.versionNumber
        parentLookID = look.parentLookID
    }

    var look: GeneratedLook {
        GeneratedLook(
            id: id,
            title: title,
            prompt: prompt,
            imageURL: URL(string: imageURLString),
            notes: notes,
            createdAt: createdAt,
            versionNumber: versionNumber,
            parentLookID: parentLookID
        )
    }
}

@Model
final class StudioTrendSignalRecord {
    var id: UUID = UUID()
    var category: String = ""
    var confidence: Double = 0
    var summary: String = ""
    var keywordsText: String = ""
    var designDirection: String = ""
    var market: String = ""
    var season: String = ""
    var capturedAt: Date = Date()

    init(signal: TrendSignal, market: String, season: String, capturedAt: Date = .now) {
        id = signal.id
        category = signal.category
        confidence = signal.confidence
        summary = signal.summary
        keywordsText = signal.keywords.joined(separator: "\n")
        designDirection = signal.designDirection
        self.market = market
        self.season = season
        self.capturedAt = capturedAt
    }

    var signal: TrendSignal {
        TrendSignal(
            id: id,
            category: category,
            confidence: confidence,
            summary: summary,
            keywords: keywordsText.lines,
            designDirection: designDirection
        )
    }
}

private extension String {
    var lines: [String] {
        split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
