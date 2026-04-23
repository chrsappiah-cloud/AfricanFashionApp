//
//  CartViewModel.swift
//  AfricanFashionApp
//

import Combine
import SwiftUI

@MainActor
final class CartViewModel: ObservableObject {
    @Published var promoCode: String = ""

    func subtotal(from lines: [CartLine]) -> Decimal {
        lines.reduce(0) { partial, line in
            partial + line.product.price * Decimal(line.quantity)
        }
    }
}
