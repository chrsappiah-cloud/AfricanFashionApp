//
//  CatalogViewModel.swift
//  AfricanFashionApp
//

import Combine
import SwiftUI

enum CatalogCollection: String, CaseIterable, Identifiable {
    case viewAll = "View All"
    case newArrivals = "New Arrivals"
    case strawBags = "Straw Bags"
    case upfHats = "UPF 50+ Hats"
    case travelIcons = "Travel Icons"

    var id: String { rawValue }
}

@MainActor
final class CatalogViewModel: ObservableObject {
    @Published var fabricFilter: String = "Any"
    @Published var regionFilter: String = "Any"
    @Published var selectedCollection: CatalogCollection = .viewAll
    @Published private(set) var products: [Product] = Product.samples

    var filteredProducts: [Product] {
        products.filter { product in
            let fabricOK = fabricFilter == "Any" || product.fabricStory.origin.localizedCaseInsensitiveContains(fabricFilter)
            let regionOK = regionFilter == "Any" || product.fabricStory.origin.localizedCaseInsensitiveContains(regionFilter)
            let collectionOK = isInSelectedCollection(product)
            return fabricOK && regionOK && collectionOK
        }
    }

    var railProducts: [Product] {
        Array(filteredProducts.prefix(8))
    }

    private func isInSelectedCollection(_ product: Product) -> Bool {
        switch selectedCollection {
        case .viewAll:
            return true
        case .newArrivals:
            return product.updatedAt > Calendar.current.date(byAdding: .day, value: -45, to: .now) ?? .distantPast
        case .strawBags:
            let haystack = "\(product.title) \(product.subtitle)".lowercased()
            return haystack.contains("bag") || haystack.contains("tote")
        case .upfHats:
            let haystack = "\(product.title) \(product.subtitle)".lowercased()
            return haystack.contains("hat") || haystack.contains("visor")
        case .travelIcons:
            return product.price >= 300
        }
    }
}
