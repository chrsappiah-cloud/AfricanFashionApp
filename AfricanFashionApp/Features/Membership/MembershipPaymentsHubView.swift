//
//  MembershipPaymentsHubView.swift
//  AfricanFashionApp
//
//  In-app entry points for membership / card checkout hosted by your payment processor (Stripe, etc.).
//  Card data must never be typed directly into this demo shell — use PaymentSheet / Safari-based Checkout, or StoreKit for digital goods.
//

import SwiftUI

struct MembershipPaymentsHubView: View {
    @EnvironmentObject private var appState: AppState
    private let links = BrandOutboundLinks.current

    var body: some View {
        List {
            Section {
                Text(
                    "Subscriptions and card payments must be processed by a licensed provider (for example Stripe Checkout, Stripe Connect payouts to your bank, or Apple In-App Purchase for digital goods). "
                        + "This screen only deep-links to the URLs you configure via environment variables or Info.plist overrides at build time."
                )
                .font(DesignSystem.Typography.caption())
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Section("Membership checkout (public & enrolled)") {
                if let url = links.membershipCardCheckoutURL {
                    Link("Open membership checkout", destination: url)
                } else {
                    Text("Set STRIPE_MEMBERSHIP_CHECKOUT_URL (https) to enable card checkout in Safari.")
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                if let url = links.appleSubscriptionsMarketingURL {
                    Link("Apple subscription guidelines", destination: url)
                }
            }

            Section("Administrator settlement & payouts") {
                if appState.isAuthenticated {
                    if let url = links.merchantFinancialDashboardURL {
                        Link("Merchant / Connect dashboard", destination: url)
                    } else {
                        Text("Set ADMIN_MERCHANT_DASHBOARD_URL to your Stripe (or PSP) dashboard for payout routing.")
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                } else {
                    Text("Sign in to surface administrator payout shortcuts (optional gate).")
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("Membership & payouts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MembershipPaymentsHubView()
            .environmentObject(AppState())
    }
}
