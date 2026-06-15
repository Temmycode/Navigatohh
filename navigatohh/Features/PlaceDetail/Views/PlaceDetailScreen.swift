//
//  PlaceDetailScreen.swift
//  navigatohh
//
//  Detail view for a single POI. The hero image is loaded through Kingfisher (RemoteImage).
//  "Navigate here" is a stub seam for the future Mapbox Navigation SDK integration.
//

import SwiftUI
import OSLog

struct PlaceDetailScreen: View {
    let placeID: UUID

    @Environment(\.dependencies) private var dependencies
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
                    // TODO: integrate Mapbox Navigation SDK for turn-by-turn routing.
                    AppLogger.map.info("Navigate-here requested for \(place.name, privacy: .public)")
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
