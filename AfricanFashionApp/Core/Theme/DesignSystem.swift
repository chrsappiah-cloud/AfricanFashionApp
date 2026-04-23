//
//  DesignSystem.swift
//  AfricanFashionApp
//

import SwiftUI

enum DesignSystem {
    enum Colors {
        static let background = Color(red: 0.05, green: 0.05, blue: 0.08)
        static let surface = Color(red: 0.12, green: 0.12, blue: 0.16)
        static let accent = Color(red: 0.78, green: 0.55, blue: 0.35)
        static let accentSecondary = Color(red: 0.45, green: 0.62, blue: 0.95)
        static let stroke = Color.white.opacity(0.12)
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.65)
    }

    enum Typography {
        static func heroTitle() -> Font { .system(size: 34, weight: .semibold, design: .rounded) }
        static func title() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
        static func headline() -> Font { .system(size: 17, weight: .semibold, design: .rounded) }
        static func body() -> Font { .system(size: 15, weight: .regular, design: .rounded) }
        static func caption() -> Font { .system(size: 13, weight: .regular, design: .rounded) }
    }

    enum Motion {
        static let cardSpring = Animation.spring(response: 0.45, dampingFraction: 0.82)
    }
}
