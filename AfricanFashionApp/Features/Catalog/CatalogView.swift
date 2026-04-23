//
//  CatalogView.swift
//  AfricanFashionApp
//

import SwiftData
import SwiftUI

struct CatalogView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appRouter: AppRouter
    @StateObject private var viewModel = CatalogViewModel()

    var body: some View {
        NavigationStack(path: $appRouter.catalogPath) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Fabric story", selection: $viewModel.fabricFilter) {
                                Text("Any").tag("Any")
                                Text("Ghana").tag("Ghana")
                                Text("Nigeria").tag("Nigeria")
                                Text("Kenya").tag("Kenya")
                            }
                            .pickerStyle(.segmented)

                            Picker("Region cue", selection: $viewModel.regionFilter) {
                                Text("Any").tag("Any")
                                Text("West").tag("Lagos")
                                Text("East").tag("Kenya")
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, 16)
                    }
                    header: {
                        collectionHeader
                    }

                    if !viewModel.railProducts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Featured in \(viewModel.selectedCollection.rawValue)")
                                .font(DesignSystem.Typography.headline())
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.railProducts) { product in
                                        Button {
                                            appRouter.openProduct(product.id)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 8) {
                                                ManagedProductImageView(product: product, aspectRatio: 4 / 5, cornerRadius: 14)
                                                    .frame(width: 160, height: 200)
                                                Text(product.title)
                                                    .font(DesignSystem.Typography.caption())
                                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                                    .lineLimit(2)
                                                Text(product.price, format: .currency(code: product.currencyCode))
                                                    .font(DesignSystem.Typography.caption())
                                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                            }
                                            .frame(width: 160, alignment: .leading)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("All products")
                            .font(DesignSystem.Typography.title())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .padding(.horizontal, 16)
                        ForEach(viewModel.filteredProducts) { product in
                            Button {
                                appRouter.openProduct(product.id)
                            } label: {
                                HStack(spacing: 14) {
                                    ManagedProductImageView(product: product, aspectRatio: 1, cornerRadius: 12)
                                        .frame(width: 54, height: 54)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.title)
                                            .font(DesignSystem.Typography.headline())
                                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                                        Text(product.subtitle)
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    }
                                    Spacer()
                                    Text(product.price, format: .currency(code: product.currencyCode))
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.background)
            .navigationTitle("Catalog")
            .task {
                try? ProductMediaCloudSync.persistCatalogHeroURLs(from: viewModel.products, into: modelContext)
            }
            .navigationDestination(for: AppRouter.Destination.self) { destination in
                switch destination {
                case .product(let id):
                    ProductDetailView(productID: id)
                case .checkout, .orders, .uploadStudio:
                    EmptyView()
                }
            }
        }
    }

    private var collectionHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CatalogCollection.allCases) { collection in
                    let isSelected = viewModel.selectedCollection == collection
                    Button(collection.rawValue) {
                        withAnimation(DesignSystem.Motion.cardSpring) {
                            viewModel.selectedCollection = collection
                        }
                    }
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(isSelected ? DesignSystem.Colors.background : DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.surface.opacity(0.92))
                    )
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(DesignSystem.Colors.stroke, lineWidth: isSelected ? 0 : 1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial.opacity(0.9))
    }
}

#Preview {
    CatalogView()
        .environmentObject(AppRouter())
        .modelContainer(PreviewModelContainer.cloudSchema)
}
