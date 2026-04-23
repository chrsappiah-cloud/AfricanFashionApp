//
//  HomeView.swift
//  AfricanFashionApp
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                GeometryReader { proxy in
                    let minY = proxy.frame(in: .named("homeScroll")).minY
                    TabView {
                        ForEach(viewModel.heroes) { hero in
                            ZStack(alignment: .bottomLeading) {
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.accent.opacity(0.55),
                                        DesignSystem.Colors.background,
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                Image(systemName: hero.systemImage)
                                    .font(.system(size: 120, weight: .thin))
                                    .foregroundStyle(.white.opacity(0.25))
                                    .offset(y: minY * 0.25)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(hero.title)
                                        .font(DesignSystem.Typography.heroTitle())
                                    Text(hero.subtitle)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                                .padding(24)
                            }
                            .frame(width: proxy.size.width, height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: 260)
                }
                .frame(height: 260)
                .padding(.horizontal, 4)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Our mission")
                            .font(DesignSystem.Typography.headline())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text(
                            "Wendy's AfricanFash exists to redefine the compass of African fashion and position it on the map of world fashion and global culture through authentic craft, modern design, and cultural storytelling."
                        )
                        .font(DesignSystem.Typography.body())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 4)

                Text("Spotlight")
                    .font(DesignSystem.Typography.title())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.spotlight) { product in
                            NavigationLink {
                                ProductDetailView(productID: product.id)
                            } label: {
                                spotlightCard(product)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Signature collections")
                        .font(DesignSystem.Typography.title())
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.signatureCollections, id: \.self) { label in
                                Text(label)
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(DesignSystem.Colors.surface.opacity(0.8))
                                    )
                                    .overlay {
                                        Capsule(style: .continuous)
                                            .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 10) {
                    Text("What clients are saying")
                        .font(DesignSystem.Typography.title())
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    TabView {
                        ForEach(viewModel.testimonials) { item in
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("\"\(item.quote)\"")
                                        .font(DesignSystem.Typography.body())
                                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    Text(item.author)
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 120, alignment: .top)
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .frame(height: 170)
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                }
                .padding(.horizontal, 4)

                if !viewModel.metOpenAccessArtworks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("World fashion — The Met (open access)")
                            .font(DesignSystem.Typography.title())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("The Metropolitan Museum of Art Collection API — CC0 images, no API key. Includes global dress; search queries emphasize African textiles and regalia.")
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(viewModel.metOpenAccessArtworks) { art in
                                    VStack(alignment: .leading, spacing: 8) {
                                        AsyncImage(url: art.imageURL) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            case .failure:
                                                Color(white: 0.15)
                                            case .empty:
                                                Color(white: 0.15)
                                            @unknown default:
                                                Color(white: 0.15)
                                            }
                                        }
                                        .frame(width: 200, height: 260)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
                                        }

                                        Text(art.title)
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                                            .lineLimit(2)
                                            .frame(width: 200, alignment: .leading)

                                        Text(art.subtitle)
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                                            .lineLimit(2)
                                            .frame(width: 200, alignment: .leading)

                                        if let link = art.collectionObjectURL {
                                            Link("View on metmuseum.org", destination: link)
                                                .font(DesignSystem.Typography.caption())
                                                .tint(DesignSystem.Colors.accentSecondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Runway & craft on YouTube")
                        .font(DesignSystem.Typography.title())
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Live results from YouTube (mobile). Add `YOUTUBE_DATA_API_KEY` in your scheme for an extra API-powered strip below.")
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    YouTubeSearchResultsWebView(searchQuery: viewModel.youtubeDiscoveryQuery)
                        .frame(height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
                        }
                }
                .padding(.horizontal, 4)

                if !viewModel.youtubeAPISnippets.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Curated embeds (Data API)")
                            .font(DesignSystem.Typography.headline())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(viewModel.youtubeAPISnippets) { snippet in
                                    VStack(alignment: .leading, spacing: 8) {
                                        if let thumb = snippet.thumbnailURL {
                                            AsyncImage(url: thumb) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                case .failure:
                                                    Color(white: 0.12)
                                                case .empty:
                                                    Color(white: 0.12)
                                                @unknown default:
                                                    Color(white: 0.12)
                                                }
                                            }
                                            .frame(width: 280, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        }
                                        YouTubeEmbedWebView(videoID: snippet.videoID)
                                            .frame(width: 280, height: 158)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        Text(snippet.title)
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                                            .lineLimit(2)
                                            .frame(width: 280, alignment: .leading)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .coordinateSpace(name: "homeScroll")
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Atelier")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadMetFashionHighlights()
        }
        .task {
            await viewModel.loadYouTubeAPISnippetsIfConfigured()
        }
    }

    private func spotlightCard(_ product: Product) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                ManagedProductImageView(product: product, aspectRatio: 4 / 3, cornerRadius: 14)
                    .frame(height: 160)
                Text(product.title)
                    .font(DesignSystem.Typography.headline())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(product.subtitle)
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(width: 220, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(CartStore())
    }
}
