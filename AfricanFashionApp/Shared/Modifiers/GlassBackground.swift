//
//  GlassBackground.swift
//  AfricanFashionApp
//

import SwiftUI

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
                    }
            }
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }
}
