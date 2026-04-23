//
//  WishlistView.swift
//  AfricanFashionApp
//

import SwiftUI

struct WishlistView: View {
    @State private var savedProducts: [Product] = Product.samples

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(savedProducts) { product in
                    GlassCard {
                        HStack {
                            Image(systemName: product.heroImageName)
                                .font(.largeTitle)
                                .foregroundStyle(DesignSystem.Colors.accentSecondary)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(product.title)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                Text(product.subtitle)
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                savedProducts.removeAll { $0.id == product.id }
                            } label: {
                                Image(systemName: "heart.slash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Saved")
    }
}

#Preview {
    NavigationStack {
        WishlistView()
    }
}
