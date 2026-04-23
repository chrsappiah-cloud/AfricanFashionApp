//
//  CheckoutView.swift
//  AfricanFashionApp
//

import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject private var cartStore: CartStore
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
