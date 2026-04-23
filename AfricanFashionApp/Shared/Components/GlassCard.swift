//
//  GlassCard.swift
//  AfricanFashionApp
//

import SwiftUI

struct GlassCard<Content: View>: View {
    private let cornerRadius: CGFloat
    @ViewBuilder private let content: () -> Content

    init(cornerRadius: CGFloat = 20, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .glassBackground(cornerRadius: cornerRadius)
    }
}
