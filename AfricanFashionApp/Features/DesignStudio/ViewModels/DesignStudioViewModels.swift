//
//  DesignStudioViewModels.swift
//  AfricanFashionApp
//

import Combine
import Foundation

@MainActor
final class DesignGeneratorViewModel: ObservableObject {
    @Published var title = "Emerald evening wrap"
    @Published var category = "women's evening gown"
    @Published var season = "Spring/Summer"
    @Published var silhouette = "structured shoulder with fluid wrap skirt"
    @Published var fabricInput = "silk satin, chiffon, handwoven kente accent"
    @Published var colorInput = "emerald, black, gold"
    @Published var aesthetic = "luxury modern African couture"
    @Published var occasion = "red carpet event"
    @Published var notes = "Create front and back concept views with elegant waist definition."

    @Published var heightCm: Double = BodyMeasurements.sample.heightCm
    @Published var bustCm: Double = BodyMeasurements.sample.bustCm
    @Published var waistCm: Double = BodyMeasurements.sample.waistCm
    @Published var hipCm: Double = BodyMeasurements.sample.hipCm
    @Published var inseamCm: Double = BodyMeasurements.sample.inseamCm
    @Published var shoulderCm: Double = BodyMeasurements.sample.shoulderCm

    @Published private(set) var generatedPrompt = ""
    @Published private(set) var generatedLook: GeneratedLook?
    @Published private(set) var isGenerating = false

    private let promptComposer: PromptComposing
    private let imageService: AIImageServing

    init(
        promptComposer: PromptComposing? = nil,
        imageService: AIImageServing? = nil
    ) {
        self.promptComposer = promptComposer ?? PromptComposer()
        self.imageService = imageService ?? ResilientAIImageService()
    }

    func composePrompt() {
        let client = DesignerClientProfile(
            id: UUID(),
            name: "Studio client",
            stylePreferences: splitList(aesthetic),
            favoriteColors: splitList(colorInput),
            dislikedElements: ["poor fit", "generic styling"],
            bodyMeasurements: BodyMeasurements(
                heightCm: heightCm,
                bustCm: bustCm,
                waistCm: waistCm,
                hipCm: hipCm,
                inseamCm: inseamCm,
                shoulderCm: shoulderCm
            ),
            occasions: [occasion],
            notes: notes
        )

        let brief = GarmentBrief(
            id: UUID(),
            title: title,
            category: category,
            season: season,
            silhouette: silhouette,
            fabricPreferences: splitList(fabricInput),
            colorPalette: splitList(colorInput),
            notes: notes
        )

        generatedPrompt = promptComposer.makeCustomClothingPrompt(
            brief: brief,
            client: client,
            aesthetic: aesthetic,
            occasion: occasion
        )
    }

    func generateDesign() async {
        if generatedPrompt.isEmpty {
            composePrompt()
        }
        guard !generatedPrompt.isEmpty else { return }
        isGenerating = true
        defer { isGenerating = false }

        let imageURL = try? await imageService.generateImage(from: generatedPrompt)
        generatedLook = GeneratedLook(
            id: UUID(),
            title: title.isEmpty ? "Generated concept" : title,
            prompt: generatedPrompt,
            imageURL: imageURL,
            notes: notes,
            createdAt: .now,
            versionNumber: 1,
            parentLookID: nil
        )
    }

    var currentMeasurements: BodyMeasurements {
        BodyMeasurements(
            heightCm: heightCm,
            bustCm: bustCm,
            waistCm: waistCm,
            hipCm: hipCm,
            inseamCm: inseamCm,
            shoulderCm: shoulderCm
        )
    }

    private func splitList(_ text: String) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

@MainActor
final class TrendLabViewModel: ObservableObject {
    @Published var market = "Australia"
    @Published var season = "Spring/Summer"
    @Published var audience = "premium contemporary customers"
    @Published var category = "occasionwear and elevated ready-to-wear"
    @Published private(set) var trends: [TrendSignal] = []
    @Published private(set) var trendPrompt = ""
    @Published private(set) var isLoading = false

    private let service: TrendForecastServing
    private let promptComposer: PromptComposing

    init(
        service: TrendForecastServing? = nil,
        promptComposer: PromptComposing? = nil
    ) {
        self.service = service ?? ResilientTrendForecastService()
        self.promptComposer = promptComposer ?? PromptComposer()
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        trendPrompt = promptComposer.makeTrendPredictionPrompt(
            market: market,
            season: season,
            audience: audience,
            category: category
        )
        trends = (try? await service.fetchTrendSignals(
            season: season,
            market: market,
            category: category
        )) ?? []
    }
}

@MainActor
final class DesignStudioDashboardViewModel: ObservableObject {
    let sampleClient = DesignerClientProfile.sample
    let activeCollection = CollectionPlan(
        id: UUID(uuidString: "00000000-0000-4000-8000-000000000201")!,
        title: "Future Heritage Capsule",
        market: "Australia",
        season: "Spring/Summer",
        looks: [
            GeneratedLook(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000301")!,
                title: "Emerald evening wrap",
                prompt: "Design a bespoke evening gown with structured shoulders, kente accent, and emerald silk drape.",
                imageURL: URL(string: "https://picsum.photos/seed/future-heritage-look-1/900/1200"),
                notes: "Hero occasionwear look for editorial and red carpet styling.",
                createdAt: .now,
                versionNumber: 1,
                parentLookID: nil
            ),
            GeneratedLook(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000302")!,
                title: "Tailored ankara blazer",
                prompt: "Design a sculpted blazer with wax-print pattern engineering and modern wide-leg trouser pairing.",
                imageURL: URL(string: "https://picsum.photos/seed/future-heritage-look-2/900/1200"),
                notes: "Commercial ready-to-wear anchor look.",
                createdAt: .now,
                versionNumber: 1,
                parentLookID: nil
            ),
        ],
        trendSignals: []
    )
}
