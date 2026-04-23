//
//  DomainModels.swift
//  AfricanFashionApp
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var email: String
    var regionCode: String?
}

struct Address: Identifiable, Codable, Hashable {
    let id: UUID
    var fullName: String
    var line1: String
    var city: String
    var postalCode: String
    var countryCode: String
}

struct Seller: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var countryCode: String
    var verified: Bool
}

struct FabricStory: Codable, Hashable {
    var origin: String
    var weaveNotes: String
    var artisanHighlight: String
}

struct MediaAsset: Identifiable, Codable, Hashable {
    let id: UUID
    var url: URL?
    var provenance: MediaProvenance
}

struct MediaProvenance: Codable, Hashable {
    var sourceKind: String
    var originalURLString: String?
    var importedAt: Date
}

struct Product: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var subtitle: String
    var price: Decimal
    var currencyCode: String
    var heroImageName: String
    /// When your catalog API returns a CDN URL, set this so `ProductMediaCloudSync` can persist hero metrics to SwiftData / CloudKit.
    var heroRemoteURLString: String?
    var fabricStory: FabricStory
    var sellerID: UUID
    var moderationStatus: String
    var inventoryStatus: String
    var deletedAt: Date?
    var updatedAt: Date
}

struct Variant: Identifiable, Codable, Hashable {
    let id: UUID
    var productID: UUID
    var label: String
    var sku: String
    var price: Decimal
}

struct CartItem: Identifiable, Codable, Hashable {
    let id: UUID
    var productID: UUID
    var variantID: UUID?
    var quantity: Int
}

struct Order: Identifiable, Codable, Hashable {
    let id: UUID
    var placedAt: Date
    var status: String
    var total: Decimal
    var currencyCode: String
}

struct OrderItem: Identifiable, Codable, Hashable {
    let id: UUID
    var orderID: UUID
    var productID: UUID
    var quantity: Int
    var unitPrice: Decimal
}

struct WishlistItem: Identifiable, Codable, Hashable {
    let id: UUID
    var productID: UUID
    var addedAt: Date
}

struct Review: Identifiable, Codable, Hashable {
    let id: UUID
    var productID: UUID
    var authorName: String
    var rating: Int
    var body: String
    var createdAt: Date
}

struct UploadJob: Identifiable, Codable, Hashable {
    let id: UUID
    var status: String
    var createdAt: Date
    var provenance: MediaProvenance
}

extension Product {
    private static let sampleID1 = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
    private static let sampleID2 = UUID(uuidString: "00000000-0000-4000-8000-000000000002")!
    private static let sampleID3 = UUID(uuidString: "00000000-0000-4000-8000-000000000003")!

    static let samples: [Product] = [
        Product(
            id: sampleID1,
            title: "Kente Silk Evening Wrap",
            subtitle: "Hand-loomed · Limited run",
            price: 420,
            currencyCode: "USD",
            heroImageName: "sparkles",
            heroRemoteURLString: "https://picsum.photos/seed/afa-kente/600/800",
            fabricStory: FabricStory(
                origin: "Ashanti Region, Ghana",
                weaveNotes: "12-ply silk weft with metallic accent threads.",
                artisanHighlight: "Woven in a cooperative studio led by master weaver Ama Serwaa."
            ),
            sellerID: UUID(),
            moderationStatus: "approved",
            inventoryStatus: "in_stock",
            deletedAt: nil,
            updatedAt: Date()
        ),
        Product(
            id: sampleID2,
            title: "Ankara Sculpted Blazer",
            subtitle: "Architectural cut · Future classic",
            price: 289,
            currencyCode: "USD",
            heroImageName: "flame",
            heroRemoteURLString: "https://picsum.photos/seed/afa-ankara/600/800",
            fabricStory: FabricStory(
                origin: "Lagos, Nigeria",
                weaveNotes: "Premium wax-print cotton with bonded structure.",
                artisanHighlight: "Pattern engineered for zero-waste panels."
            ),
            sellerID: UUID(),
            moderationStatus: "approved",
            inventoryStatus: "low_stock",
            deletedAt: nil,
            updatedAt: Date()
        ),
        Product(
            id: sampleID3,
            title: "Maasai Bead Collar II",
            subtitle: "Ceremonial palette · Collector",
            price: 560,
            currencyCode: "USD",
            heroImageName: "circle.hexagongrid",
            heroRemoteURLString: "https://picsum.photos/seed/afa-maasai/600/800",
            fabricStory: FabricStory(
                origin: "Narok County, Kenya",
                weaveNotes: "Glass beads on reinforced leather foundation.",
                artisanHighlight: "Co-designed with local beadwork guild."
            ),
            sellerID: UUID(),
            moderationStatus: "approved",
            inventoryStatus: "in_stock",
            deletedAt: nil,
            updatedAt: Date()
        ),
    ]

    static func sample(id: UUID) -> Product? {
        samples.first { $0.id == id }
    }
}
