//
//  ProductDetailView.swift
//  AfricanFashionApp
//

import SwiftUI

struct ProductDetailView: View {
    let productID: UUID
    @EnvironmentObject private var cartStore: CartStore
    @StateObject private var viewModel = ProductDetailViewModel()
    @State private var zoom: CGFloat = 1.0
    @State private var baseZoom: CGFloat = 1.0

    var body: some View {
        Group {
            if let product = viewModel.product {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ManagedProductImageView(product: product, aspectRatio: 4 / 3, cornerRadius: 28)
                            .scaleEffect(zoom)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        zoom = min(max(baseZoom * value, 1), 3)
                                    }
                                    .onEnded { _ in
                                        baseZoom = zoom
                                        withAnimation(DesignSystem.Motion.cardSpring) {
                                            zoom = 1
                                            baseZoom = 1
                                        }
                                    }
                            )
                            .accessibilityLabel("Product hero artwork")
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)

                        Text(product.title)
                            .font(DesignSystem.Typography.title())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text(product.subtitle)
                            .font(DesignSystem.Typography.body())
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Fabric story")
                                    .font(DesignSystem.Typography.headline())
                                Text(product.fabricStory.origin)
                                    .font(DesignSystem.Typography.caption())
                                Text(product.fabricStory.weaveNotes)
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                Text(product.fabricStory.artisanHighlight)
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                        }

                        if !viewModel.similar.isEmpty {
                            Text("Similar styles")
                                .font(DesignSystem.Typography.headline())
                                .foregroundStyle(DesignSystem.Colors.textPrimary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.similar) { item in
                                        GlassCard {
                                            VStack(alignment: .leading) {
                                                ManagedProductImageView(product: item, aspectRatio: 4 / 3, cornerRadius: 10)
                                                    .frame(height: 80)
                                                Text(item.title)
                                                    .font(DesignSystem.Typography.caption())
                                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                            }
                                            .frame(width: 160, alignment: .leading)
                                        }
                                    }
                                }
                            }
                        }

                        PrimaryButton(title: "Add to bag") {
                            cartStore.add(product: product)
                        }
                    }
                    .padding(16)
                }
                .background(DesignSystem.Colors.background.ignoresSafeArea())
            } else {
                ContentUnavailableView("Product unavailable", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load(productID: productID)
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(productID: Product.samples[0].id)
            .environmentObject(CartStore())
    }
}
