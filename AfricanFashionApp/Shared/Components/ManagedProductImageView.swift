//
//  ManagedProductImageView.swift
//  AfricanFashionApp
//

import SwiftUI

/// Remote-first product artwork with local symbol fallback.
struct ManagedProductImageView: View {
    let product: Product
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat

    init(product: Product, aspectRatio: CGFloat = 4 / 5, cornerRadius: CGFloat = 16) {
        self.product = product
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Group {
            if let string = product.heroRemoteURLString,
               let url = URL(string: string),
               URLValidator.isAllowedHTTPURL(url) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fill)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
        }
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [DesignSystem.Colors.surface, DesignSystem.Colors.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: product.heroImageName)
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.accent.opacity(0.9))
        }
    }
}
