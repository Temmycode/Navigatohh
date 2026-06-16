//
//  PlaceDetailScreen.swift
//  navigatohh
//
//  Detail view for a single place. Receives the full `PointOfInterest` (works for bundled
//  places, tapped built-in POIs, and geocoding results alike). A hero (image or brand
//  gradient) headlines the place; "Navigate here" starts a route and jumps to the map.
//

import SwiftUI

struct PlaceDetailScreen: View {
    let place: PointOfInterest

    @Environment(\.dependencies) private var dependencies
    @Environment(\.router) private var router

    private var distanceText: String? {
        guard let origin = dependencies.locationService.currentLocation?.coordinate else { return nil }
        return DistanceFormatter.string(meters: place.coordinate.distance(to: origin))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                infoSection
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dependencies.userDataStore.toggleFavorite(place)
                } label: {
                    Image(systemName: dependencies.userDataStore.isFavorite(place.id) ? "heart.fill" : "heart")
                }
                .tint(.pink)
                .accessibilityLabel(dependencies.userDataStore.isFavorite(place.id) ? "Remove from favorites" : "Add to favorites")
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if place.imageURL != nil {
                    RemoteImage(url: place.imageURL)
                } else {
                    AppColors.brandGradient
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: place.category.symbolName)
                                .font(.system(size: 96))
                                .foregroundStyle(.white.opacity(0.18))
                                .padding(AppSpacing.lg)
                        }
                }
            }
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
                .frame(height: 260)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label(place.category.title, systemImage: place.category.symbolName)
                    .font(AppTypography.caption.weight(.semibold))
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.white)

                Text(place.name)
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(.white)
                    .lineLimit(3)
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Info + actions

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if let address = place.address {
                Label(address, systemImage: "mappin.and.ellipse")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.secondaryText)
            }

            if let distanceText {
                Label("\(distanceText) away", systemImage: "location.fill")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.accent)
            }

            if !place.summary.isEmpty {
                Text(place.summary)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primaryText)
            }

            Button {
                router.selectedTab = .map
                router.popToRoot()
                Task { await dependencies.navigationSession.start(to: place) }
            } label: {
                Label("Navigate here", systemImage: "location.north.line.fill")
            }
            .buttonStyle(.gradient)
            .padding(.top, AppSpacing.sm)
        }
        .padding(AppSpacing.md)
    }
}
