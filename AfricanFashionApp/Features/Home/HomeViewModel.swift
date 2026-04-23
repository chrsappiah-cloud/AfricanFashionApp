//
//  HomeViewModel.swift
//  AfricanFashionApp
//

import Combine
import SwiftUI

struct HomeHero: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var subtitle: String
    var systemImage: String
}

struct HomeTestimonial: Identifiable, Hashable {
    let id = UUID()
    var quote: String
    var author: String
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var heroes: [HomeHero] = [
        HomeHero(
            title: "Wendy's AfricanFash",
            subtitle: "Rooted in African craft, designed for global style.",
            systemImage: "globe.africa.fill"
        ),
        HomeHero(
            title: "Redefining the Compass",
            subtitle: "We elevate African fashion as a leading voice in world fashion.",
            systemImage: "safari.fill"
        ),
        HomeHero(
            title: "Culture in Motion",
            subtitle: "Our mission connects heritage, innovation, and global culture.",
            systemImage: "sparkles"
        ),
    ]

    @Published private(set) var spotlight: [Product] = Array(Product.samples.prefix(2))
    @Published private(set) var signatureCollections: [String] = [
        "New Arrivals",
        "Best Sellers",
        "Straw Bags",
        "UPF 50+ Hats",
        "Travel Icons",
    ]
    @Published private(set) var testimonials: [HomeTestimonial] = [
        HomeTestimonial(
            quote: "Lightweight, packable, and still looks editorial. Exactly what I needed for travel.",
            author: "Ama K. — Verified Buyer"
        ),
        HomeTestimonial(
            quote: "The craft quality is immediate; the silhouette keeps its shape all day.",
            author: "Nana A. — Verified Buyer"
        ),
        HomeTestimonial(
            quote: "Luxury finish with everyday function. Compliments every single time.",
            author: "Lindiwe R. — Verified Buyer"
        ),
    ]

    /// Shown in `YouTubeSearchResultsWebView` — real YouTube search, no API key required.
    let youtubeDiscoveryQuery = "African fashion runway kente ankara accessories"

    @Published private(set) var youtubeAPISnippets: [YouTubeVideoSnippet] = []

    /// Real garment / textile / accessory photography from The Met’s **open** Collection API (no key).
    @Published private(set) var metOpenAccessArtworks: [MetOpenAccessArtwork] = []

    func loadYouTubeAPISnippetsIfConfigured() async {
        guard YouTubeSearchAPIClient.resolveAPIKey() != nil else { return }
        do {
            let page = try await YouTubeSearchAPIClient.searchVideos(
                query: "African fashion runway accessories editorial",
                configuration: .africanFashionEditorial,
                maxResults: 6
            )
            youtubeAPISnippets = page.items
        } catch {
            youtubeAPISnippets = []
        }
    }

    func loadMetFashionHighlights() async {
        metOpenAccessArtworks = await MetMuseumAPIClient.loadOpenAccessFashionHighlights()
    }
}
