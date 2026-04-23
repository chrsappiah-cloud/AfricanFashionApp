//
//  CartStore.swift
//  AfricanFashionApp
//

import Combine
import SwiftUI

struct CartLine: Identifiable, Hashable {
    let id: UUID
    let product: Product
    var quantity: Int
}

@MainActor
final class CartStore: ObservableObject {
    @Published private(set) var lines: [CartLine] = []

    var itemCount: Int {
        lines.reduce(0) { $0 + $1.quantity }
    }

    func add(product: Product, quantity: Int = 1) {
        if let index = lines.firstIndex(where: { $0.product.id == product.id }) {
            lines[index].quantity += quantity
        } else {
            lines.append(CartLine(id: UUID(), product: product, quantity: quantity))
        }
    }

    func decrement(line: CartLine) {
        guard let index = lines.firstIndex(where: { $0.id == line.id }) else { return }
        if lines[index].quantity > 1 {
            lines[index].quantity -= 1
        } else {
            lines.remove(at: index)
        }
    }

    func increment(line: CartLine) {
        guard let index = lines.firstIndex(where: { $0.id == line.id }) else { return }
        lines[index].quantity += 1
    }

    func remove(line: CartLine) {
        lines.removeAll { $0.id == line.id }
    }

    func clear() {
        lines.removeAll()
    }
}
