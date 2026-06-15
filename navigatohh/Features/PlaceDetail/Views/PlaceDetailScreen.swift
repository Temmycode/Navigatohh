//
//  PlaceDetailScreen.swift
//  navigatohh
//
//  Detail view for a single POI. The hero image is loaded through Kingfisher (RemoteImage).
//  "Navigate here" starts a route via the shared NavigationSession and jumps to the map.
//

import SwiftUI

struct PlaceDetailScreen: View {
    let placeID: UUID

    @Environment(\.dependencies) private var dependencies
    @Environment(\.router) private var router
    @State private var viewModel: PlaceDetailViewModel?

    var body: some View {
        Group {
            switch viewModel?.state {
            case .none, .loading:
                LoadingView()
            case let .loaded(place):
                detail(place)
            case .notFound:
                ContentUnavailableView("Place not found", systemImage: "mappin.slash")
            case let .failed(message):
                ErrorView(message: message) {
                    Task { await viewModel?.load() }
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case let .loaded(place) = viewModel?.state {
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
        .task {
            guard viewModel == nil else { return }
            let vm = PlaceDetailViewModel(placeID: placeID, repository: dependencies.placesRepository)
            viewModel = vm
            await vm.load()
        }
    }

    private func detail(_ place: PointOfInterest) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                RemoteImage(url: place.imageURL)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))

                Label(place.category.title, systemImage: place.category.symbolName)
                    .font(AppTypography.caption)
                    .foregroundStyle(place.category.tint)

                Text(place.name)
                    .font(AppTypography.largeTitle)

                if let address = place.address {
                    Label(address, systemImage: "mappin.and.ellipse")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Text(place.summary)
                    .font(AppTypography.body)

                Button {
                    // Switch to the map, clear this stack, and start routing. The map's
                    // banner reflects the shared NavigationSession state.
                    router.selectedTab = .map
                    router.popToRoot()
                    Task { await dependencies.navigationSession.start(to: place) }
                } label: {
                    Label("Navigate here", systemImage: "location.north.line.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accent)
                .padding(.top, AppSpacing.sm)
            }
            .padding(AppSpacing.md)
        }
    }
}
