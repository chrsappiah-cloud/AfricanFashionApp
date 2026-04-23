//
//  AppRouter.swift
//  AfricanFashionApp
//

import Combine
import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    enum Destination: Hashable {
        case product(UUID)
        case checkout
        case orders
        case uploadStudio
    }

    @Published var catalogPath = NavigationPath()
    @Published var cartPath = NavigationPath()
    @Published var profilePath = NavigationPath()

    func openProduct(_ id: UUID) {
        catalogPath.append(Destination.product(id))
    }

    func openCheckout() {
        cartPath.append(Destination.checkout)
    }

    func openOrders() {
        profilePath.append(Destination.orders)
    }

    func openUploadStudio() {
        profilePath.append(Destination.uploadStudio)
    }
}
