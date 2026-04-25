//
//  RootView.swift
//  AfricanFashionApp
//

import SwiftData
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct CartTabBadge: ViewModifier {
    let tab: AppTab
    let count: Int

    func body(content: Content) -> some View {
        if tab == .cart, count > 0 {
            content.badge(count)
        } else {
            content
        }
    }
}

private struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var cartStore: CartStore

    @State private var cartMirrorTask: Task<Void, Never>?

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tabRoot(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .modifier(CartTabBadge(tab: tab, count: cartStore.itemCount))
                    .tag(tab)
            }
        }
        .tint(DesignSystem.Colors.accent)
        .task {
            mirrorUserAndAdministrationToCloud()
        }
        .onChange(of: appState.isAuthenticated) { _, _ in mirrorUserAndAdministrationToCloud() }
        .onChange(of: appState.hasCompletedOnboarding) { _, _ in mirrorUserAndAdministrationToCloud() }
        .onChange(of: appState.regionFocus) { _, _ in mirrorUserAndAdministrationToCloud() }
        .onChange(of: appState.stylePreferencesNote) { _, _ in mirrorUserAndAdministrationToCloud() }
        .onChange(of: appState.profileEmail) { _, _ in mirrorUserAndAdministrationToCloud() }
        .onChange(of: appState.profileDisplayName) { _, _ in mirrorUserAndAdministrationToCloud() }
        .onChange(of: cartStore.lines) { _, _ in
            cartMirrorTask?.cancel()
            cartMirrorTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { return }
                try? CartCloudMirror.sync(lines: cartStore.lines, into: modelContext)
            }
        }
    }

    private func mirrorUserAndAdministrationToCloud() {
        try? CloudAdministrationRepository.ensurePrimary(into: modelContext)
        try? CloudUserProfileRepository.upsertPrimary(appState: appState, into: modelContext)
    }

    @ViewBuilder
    private func tabRoot(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            NavigationStack {
                HomeView()
            }
        case .catalog:
            CatalogView()
        case .discussion:
            NavigationStack {
                DiscussionView()
            }
        case .cart:
            CartView()
        case .wishlist:
            NavigationStack {
                WishlistView()
            }
        case .profile:
            ProfileView()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(AppRouter())
        .environmentObject(CartStore())
        .modelContainer(PreviewModelContainer.cloudSchema)
}
