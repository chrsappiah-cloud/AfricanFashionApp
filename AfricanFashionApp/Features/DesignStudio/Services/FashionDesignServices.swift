//
//  FashionDesignServices.swift
//  AfricanFashionApp
//

import Foundation

protocol PromptComposing {
    func makeCustomClothingPrompt(
        brief: GarmentBrief,
        client: DesignerClientProfile,
        aesthetic: String,
        occasion: String
    ) -> String

    func makeTrendPredictionPrompt(
        market: String,
        season: String,
        audience: String,
        category: String
    ) -> String
}

struct PromptComposer: PromptComposing {
    init() {}

    func makeCustomClothingPrompt(
        brief: GarmentBrief,
        client: DesignerClientProfile,
        aesthetic: String,
        occasion: String
    ) -> String {
        let measurements = client.bodyMeasurements
        return """
        Design a high-fashion custom \(brief.category) for \(occasion).
        Client: \(client.name).
        Style: \(aesthetic).
        Client preferences: \(client.stylePreferences.joined(separator: ", ")).
        Avoid: \(client.dislikedElements.joined(separator: ", ")).
        Season: \(brief.season).
        Silhouette: \(brief.silhouette).
        Fabrics: \(brief.fabricPreferences.joined(separator: ", ")).
        Color palette: \(brief.colorPalette.joined(separator: ", ")).
        Fit guidance: height \(measurements.heightCm) cm, bust \(measurements.bustCm) cm, waist \(measurements.waistCm) cm, hips \(measurements.hipCm) cm, inseam \(measurements.inseamCm) cm, shoulder \(measurements.shoulderCm) cm.
        Focus on flattering proportions, premium construction details, realistic fabric drape, African luxury craft references, clean background, and front and back garment concept views.
        Additional notes: \(brief.notes)
        """
    }

    func makeTrendPredictionPrompt(
        market: String,
        season: String,
        audience: String,
        category: String
    ) -> String {
        """
        Analyze emerging fashion trends for \(market) in \(season) for \(audience).
        Focus on \(category).
        Predict likely popular silhouettes, colors, fabrics, trims, styling details, and commercial directions.
        Return concise trend themes, confidence levels, and recommended design directions for a fashion collection.
        """
    }
}

protocol TrendForecastServing {
    func fetchTrendSignals(season: String, market: String, category: String) async throws -> [TrendSignal]
}

struct TrendForecastService: TrendForecastServing {
    init() {}

    func fetchTrendSignals(season: String, market: String, category: String) async throws -> [TrendSignal] {
        [
            TrendSignal(
                id: UUID(),
                category: "Color",
                confidence: 0.88,
                summary: "Mineral emerald, cocoa black, sunlit gold, and botanical green palettes are commercially strong for \(market).",
                keywords: ["emerald", "cocoa", "gold", "botanical"],
                designDirection: "Use jewel-tone accents against deep neutrals for premium occasionwear."
            ),
            TrendSignal(
                id: UUID(),
                category: "Silhouette",
                confidence: 0.81,
                summary: "Softly structured tailoring and elongated wrap shapes continue to rise for \(season).",
                keywords: ["wrap", "structured shoulder", "wide-leg", "elongated"],
                designDirection: "Combine waist definition with relaxed movement for day-to-evening versatility."
            ),
            TrendSignal(
                id: UUID(),
                category: "Fabric",
                confidence: 0.76,
                summary: "Consumers are responding to visible craft, breathable natural fibers, and traceable textile stories.",
                keywords: ["linen", "silk", "hand-loom", "traceable"],
                designDirection: "Pair artisan textiles with refined construction notes and transparent provenance."
            ),
            TrendSignal(
                id: UUID(),
                category: "Commercial",
                confidence: 0.72,
                summary: "\(category) buyers are favouring capsule pieces that photograph well and can be restyled.",
                keywords: ["capsule", "modular", "editorial", "restyle"],
                designDirection: "Create hero garments with removable wraps, reversible styling, or statement accessories."
            ),
        ]
    }
}

protocol AIImageServing {
    func generateImage(from prompt: String) async throws -> URL?
}

protocol TechPackGenerating {
    func makeTechPack(
        look: GeneratedLook,
        measurements: BodyMeasurements,
        trends: [TrendSignal]
    ) -> TechPackDocument
}

struct LiveTrendForecastService: TrendForecastServing {
    private let httpClient: HTTPClient
    private let endpoint: URL
    private let bearerToken: String?

    init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
        endpoint: URL = AppConfiguration.fashionTrendForecastURL,
        bearerToken: String? = AppConfiguration.fashionAIAPIToken
    ) {
        self.httpClient = httpClient
        self.endpoint = endpoint
        self.bearerToken = bearerToken
    }

    func fetchTrendSignals(season: String, market: String, category: String) async throws -> [TrendSignal] {
        try BackendAPI.validateTransportSecurity(for: endpoint)
        let payload = TrendForecastRequest(
            season: season,
            market: market,
            category: category
        )
        let body = try JSONEncoder().encode(payload)
        let request = BackendAPI.makeJSONRequest(
            url: endpoint,
            method: "POST",
            body: body,
            bearerToken: bearerToken
        )

        let data = try await BackendAPI.executeWithRetry {
            let (data, response) = try await httpClient.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.transport(underlying: URLError(.badServerResponse))
            }
            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw APIError.status(code: httpResponse.statusCode, body: data)
            }
            return data
        }

        let decoded = try JSONDecoder().decode(TrendForecastResponse.self, from: data)
        return decoded.signals.map(\.trendSignal)
    }
}

struct ResilientTrendForecastService: TrendForecastServing {
    private let primary: TrendForecastServing
    private let fallback: TrendForecastServing

    init(
        primary: TrendForecastServing = LiveTrendForecastService(),
        fallback: TrendForecastServing = TrendForecastService()
    ) {
        self.primary = primary
        self.fallback = fallback
    }

    func fetchTrendSignals(season: String, market: String, category: String) async throws -> [TrendSignal] {
        do {
            return try await primary.fetchTrendSignals(season: season, market: market, category: category)
        } catch {
            return try await fallback.fetchTrendSignals(season: season, market: market, category: category)
        }
    }
}

struct LiveAIImageService: AIImageServing {
    private let httpClient: HTTPClient
    private let endpoint: URL
    private let bearerToken: String?

    init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
        endpoint: URL = AppConfiguration.fashionImageGenerationURL,
        bearerToken: String? = AppConfiguration.fashionAIAPIToken
    ) {
        self.httpClient = httpClient
        self.endpoint = endpoint
        self.bearerToken = bearerToken
    }

    func generateImage(from prompt: String) async throws -> URL? {
        try BackendAPI.validateTransportSecurity(for: endpoint)
        let body = try JSONEncoder().encode(ImageGenerationRequest(
            model: AppConfiguration.fashionImageModel,
            prompt: prompt
        ))
        let request = BackendAPI.makeJSONRequest(
            url: endpoint,
            method: "POST",
            body: body,
            bearerToken: bearerToken
        )

        let data = try await BackendAPI.executeWithRetry {
            let (data, response) = try await httpClient.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.transport(underlying: URLError(.badServerResponse))
            }
            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw APIError.status(code: httpResponse.statusCode, body: data)
            }
            return data
        }

        let decoded = try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
        return URL(string: decoded.imageURL)
    }
}

struct LocalPreviewAIImageService: AIImageServing {
    init() {}

    func generateImage(from prompt: String) async throws -> URL? {
        let seed = abs(prompt.hashValue)
        return URL(string: "https://picsum.photos/seed/fashion-studio-\(seed)/900/1200")
    }
}

struct ResilientAIImageService: AIImageServing {
    private let primary: AIImageServing
    private let fallback: AIImageServing

    init(
        primary: AIImageServing = LiveAIImageService(),
        fallback: AIImageServing = LocalPreviewAIImageService()
    ) {
        self.primary = primary
        self.fallback = fallback
    }

    func generateImage(from prompt: String) async throws -> URL? {
        do {
            return try await primary.generateImage(from: prompt)
        } catch {
            return try await fallback.generateImage(from: prompt)
        }
    }
}

private struct TrendForecastRequest: Encodable {
    var season: String
    var market: String
    var category: String
}

private struct TrendForecastResponse: Decodable {
    var signals: [TrendSignalDTO]
}

private struct TrendSignalDTO: Decodable {
    var id: UUID?
    var category: String
    var confidence: Double
    var summary: String
    var keywords: [String]
    var designDirection: String

    var trendSignal: TrendSignal {
        TrendSignal(
            id: id ?? UUID(),
            category: category,
            confidence: confidence,
            summary: summary,
            keywords: keywords,
            designDirection: designDirection
        )
    }
}

struct FashionTechPackService: TechPackGenerating {
    func makeTechPack(
        look: GeneratedLook,
        measurements: BodyMeasurements,
        trends: [TrendSignal]
    ) -> TechPackDocument {
        TechPackDocument(
            id: UUID(),
            title: "\(look.title) Tech Pack",
            generatedAt: .now,
            sections: [
                TechPackSection(
                    id: UUID(),
                    title: "Concept Summary",
                    body: look.notes.isEmpty ? look.prompt : look.notes
                ),
                TechPackSection(
                    id: UUID(),
                    title: "Fit And Measurements",
                    body: "Height \(measurements.heightCm) cm, bust \(measurements.bustCm) cm, waist \(measurements.waistCm) cm, hip \(measurements.hipCm) cm, inseam \(measurements.inseamCm) cm, shoulder \(measurements.shoulderCm) cm."
                ),
                TechPackSection(
                    id: UUID(),
                    title: "Construction Direction",
                    body: "Use the generated prompt as the design source of truth. Preserve front and back garment concept views, realistic drape, premium seam finishing, and culturally respectful African luxury craft references."
                ),
                TechPackSection(
                    id: UUID(),
                    title: "Trend Evidence",
                    body: trends.isEmpty
                        ? "No saved trend signals were attached. Refresh Trend Lab before final collection review."
                        : trends.map { "\($0.category): \($0.summary) Direction: \($0.designDirection)" }.joined(separator: "\n\n")
                ),
                TechPackSection(
                    id: UUID(),
                    title: "Production Notes",
                    body: "Review fit on a live model or dress form before sampling. Confirm textile availability, ethical sourcing, care requirements, and final trim details before vendor handoff."
                ),
            ]
        )
    }
}

private struct ImageGenerationRequest: Encodable {
    var model: String
    var prompt: String
    var size = "1024x1536"
    var quality = "medium"
    var outputFormat = "png"
    var purpose = "fashion-concept"

    enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case size
        case quality
        case outputFormat = "output_format"
        case purpose
    }
}

private struct ImageGenerationResponse: Decodable {
    var imageURL: String

    enum CodingKeys: String, CodingKey {
        case imageURL = "image_url"
    }
}
