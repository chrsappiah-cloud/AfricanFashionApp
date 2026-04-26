//
//  CheckoutView.swift
//  AfricanFashionApp
//

import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject private var cartStore: CartStore
    private let brandLinks = BrandOutboundLinks.current
    @State private var fullName = ""
    @State private var addressLine = ""
    @State private var city = ""

    var body: some View {
        Form {
            Section("Delivery") {
                TextField("Full name", text: $fullName)
                TextField("Address", text: $addressLine)
                TextField("City", text: $city)
            }

            Section("Review") {
                ForEach(cartStore.lines) { line in
                    HStack {
                        Text(line.product.title)
                        Spacer()
                        Text(line.product.price, format: .currency(code: line.product.currencyCode))
                    }
                }
            }

            Section {
                Button("Place order (demo)") {
                    cartStore.clear()
                }
            }

            Section("Card checkout (production)") {
                Text(
                    "Physical goods and subscriptions should use your processor’s hosted checkout or Apple Pay / StoreKit. "
                        + "Configure STRIPE_MEMBERSHIP_CHECKOUT_URL to open live card capture in Safari."
                )
                .font(DesignSystem.Typography.caption())
                .foregroundStyle(DesignSystem.Colors.textSecondary)

                if let url = brandLinks.membershipCardCheckoutURL {
                    Link("Pay with card (hosted checkout)", destination: url)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("Checkout")
    }
}

#Preview {
    NavigationStack {
        CheckoutView()
            .environmentObject(CartStore())
    }
}
