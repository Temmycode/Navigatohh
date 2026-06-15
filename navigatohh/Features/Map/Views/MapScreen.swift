//
//  MapScreen.swift
//  navigatohh
//
//  The primary screen: a 3D Mapbox map of the Bashorun/Bodija area with POI annotations and
//  a card for the currently selected place.
//
//  The ViewModel depends on environment-injected services, so it's built lazily in `.task`
//  rather than at `init` (where the environment isn't available yet).
//

import SwiftUI

struct MapScreen: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.router) private var router
    @State private var viewModel: MapViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                LoadingView(message: "Preparing map…")
            }
        }
        .navigationTitle("navigatohh")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard viewModel == nil else { return }
            let vm = MapViewModel(
                repository: dependencies.placesRepository,
                locationService: dependencies.locationService
            )
            viewModel = vm
            await vm.onAppear()
        }
    }

    @ViewBuilder
    private func content(_ viewModel: MapViewModel) -> some View {
        ZStack(alignment: .bottom) {
            MapboxMapRepresentable(
                places: viewModel.places,
                userLocation: viewModel.userLocation,
                onSelect: { viewModel.select($0) }
            )
            .ignoresSafeArea(edges: .top)

            if case let .failed(message) = viewModel.loadState {
                ErrorView(message: message) {
                    Task { await viewModel.loadPlaces() }
                }
                .background(.regularMaterial)
            }

            if let place = viewModel.selectedPlace {
                selectedCard(place, viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: viewModel.selectedPlace)
    }

    private func selectedCard(_ place: PointOfInterest, viewModel: MapViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Label(place.category.title, systemImage: place.category.symbolName)
                    .font(AppTypography.caption)
                    .foregroundStyle(place.category.tint)
                Spacer()
                Button {
                    viewModel.clearSelection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.secondaryText)
                }
            }

            Text(place.name)
                .font(AppTypography.title)

            Text(place.summary)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.secondaryText)
                .lineLimit(2)

            Button {
                router.push(.placeDetail(placeID: place.id))
            } label: {
                Text("View details")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .shadow(radius: 8, y: 4)
        .padding(AppSpacing.md)
    }
}

#Preview {
    NavigationStack {
        MapScreen()
            .environment(\.dependencies, AppDependencies())
            .environment(\.router, AppRouter())
    }
}
