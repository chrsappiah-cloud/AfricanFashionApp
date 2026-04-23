//
//  CartView.swift
//  AfricanFashionApp
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var appRouter: AppRouter
    @StateObject private var viewModel = CartViewModel()

    var body: some View {
        NavigationStack(path: $appRouter.cartPath) {
            Group {
                if cartStore.lines.isEmpty {
                    ContentUnavailableView("Your bag is ready", systemImage: "bag", description: Text("Add pieces from Home or Catalog."))
                } else {
                    List {
                        Section("Items") {
                            ForEach(cartStore.lines) { line in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(line.product.title)
                                            .font(DesignSystem.Typography.headline())
                                        Text(line.product.price, format: .currency(code: line.product.currencyCode))
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    }
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Button {
                                            cartStore.decrement(line: line)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .imageScale(.large)
                                        }
                                        .buttonStyle(.borderless)

                                        Text("\(line.quantity)")
                                            .font(DesignSystem.Typography.headline())
                                            .frame(minWidth: 28)

                                        Button {
                                            cartStore.increment(line: line)
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .imageScale(.large)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                    .foregroundStyle(DesignSystem.Colors.accent)
                                }
                            }
                        }

                        Section("Promo") {
                            TextField("Code", text: $viewModel.promoCode)
                        }

                        Section {
                            HStack {
                                Text("Subtotal")
                                Spacer()
                                Text(viewModel.subtotal(from: cartStore.lines), format: .currency(code: "USD"))
                            }
                            .font(DesignSystem.Typography.headline())

                            Button("Review checkout") {
                                appRouter.openCheckout()
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(DesignSystem.Colors.background)
                }
            }
            .navigationTitle("Bag")
            .navigationDestination(for: AppRouter.Destination.self) { destination in
                switch destination {
                case .checkout:
                    CheckoutView()
                case .product(let id):
                    ProductDetailView(productID: id)
                case .orders:
                    OrdersView()
                case .uploadStudio:
                    UploadStudioView()
                }
            }
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack {
        CartView()
            .environmentObject(CartStore())
            .environmentObject(AppRouter())
    }
}
