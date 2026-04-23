//
//  ProductDetailViewModel.swift
//  AfricanFashionApp
//

import Combine
import SwiftUI

@MainActor
final class ProductDetailViewModel: ObservableObject {
    @Published private(set) var product: Product?
    @Published private(set) var similar: [Product] = []

    func load(productID: UUID) {
        product = Product.sample(id: productID)
        similar = Product.samples.filter { $0.id != productID }
    }
}
