//
//  OrdersView.swift
//  AfricanFashionApp
//

import SwiftUI

struct OrdersView: View {
    private let demoOrders: [Order] = [
        Order(id: UUID(), placedAt: .now.addingTimeInterval(-86400 * 4), status: "Shipped", total: 420, currencyCode: "USD"),
        Order(id: UUID(), placedAt: .now.addingTimeInterval(-86400 * 20), status: "Delivered", total: 289, currencyCode: "USD"),
    ]

    var body: some View {
        List(demoOrders) { order in
            GlassCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.placedAt, style: .date)
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(order.status)
                        .font(DesignSystem.Typography.headline())
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(order.total, format: .currency(code: order.currencyCode))
                        .font(DesignSystem.Typography.body())
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("Orders")
    }
}

#Preview {
    NavigationStack {
        OrdersView()
    }
}
