//
//  PrimaryButton.swift
//  AfricanFashionApp
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.headline())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    LinearGradient(
                        colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: DesignSystem.Colors.accent.opacity(0.35), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
    }
}
