//
//  MapScreen.swift
//  navigatohh
//
//  The primary screen: a 3D Mapbox map of the Bashorun/Bodija area with POI annotations,
//  a card for the currently selected place, a recenter control, and a navigation banner
//  (distance + ETA) once a route is active.
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
        .navigationTitle("Navigatohh")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard viewModel == nil else { return }
            viewModel = MapViewModel(
                repository: dependencies.placesRepository,
                locationService: dependencies.locationService,
                navigationSession: dependencies.navigationSession
            )
            await dependencies.offlineMapManager.refreshStatus()
            await viewModel?.onAppear()
        }
    }

    @ViewBuilder
    private func content(_ viewModel: MapViewModel) -> some View {
        ZStack(alignment: .bottom) {
            MapboxMapRepresentable(
                places: viewModel.places,
                userLocation: viewModel.userLocation,
                route: viewModel.route,
                recenterRequestID: viewModel.recenterRequestID,
                onSelect: { viewModel.select($0) }
            )
            .ignoresSafeArea()

            // Top: navigation + offline banners.
            VStack(spacing: AppSpacing.sm) {
                navigationBanner(viewModel)
                offlineBanner()
                Spacer()
            }
            .padding(AppSpacing.md)

            // Bottom-trailing: recenter control (hidden while a place card is shown).
            if viewModel.selectedPlace == nil {
                HStack {
                    Spacer()
                    recenterButton(viewModel)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
            }

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
        .animation(.snappy, value: viewModel.navigationState)
    }

    // MARK: - Navigation banner

    @ViewBuilder
    private func navigationBanner(_ viewModel: MapViewModel) -> some View {
        switch viewModel.navigationState {
        case .idle:
            EmptyView()
        case .routing:
            banner {
                HStack(spacing: AppSpacing.sm) {
                    ProgressView()
                    Text("Finding route…").font(AppTypography.callout)
                }
            }
        case .active:
            if let route = viewModel.route {
                banner {
                    VStack(spacing: AppSpacing.sm) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "location.north.line.fill")
                                .foregroundStyle(AppColors.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.navigationDestination?.name ?? "Destination")
                                    .font(AppTypography.headline)
                                    .lineLimit(1)
                                Text("\(route.formattedTravelTime) · \(route.formattedDistance)")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            Spacer()
                            Button("End", role: .destructive) { viewModel.endNavigation() }
                                .buttonStyle(.bordered)
                        }
                        profilePicker(viewModel)
                    }
                }
            }
        case let .failed(message):
            banner {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(message).font(AppTypography.caption).lineLimit(2)
                    Spacer()
                    Button("Dismiss") { viewModel.endNavigation() }
                        .font(AppTypography.caption)
                }
            }
        }
    }

    private func banner<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
            .shadow(radius: 6, y: 3)
    }

    /// Segmented driving/walking/cycling picker bound to the shared navigation session.
    private func profilePicker(_ viewModel: MapViewModel) -> some View {
        Picker(
            "Travel mode",
            selection: Binding(
                get: { viewModel.navigationProfile },
                set: { newValue in Task { await viewModel.setProfile(newValue) } }
            )
        ) {
            ForEach(RouteProfile.selectable) { profile in
                Text(profile.title).tag(profile)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Offline map banner

    @ViewBuilder
    private func offlineBanner() -> some View {
        let offline = dependencies.offlineMapManager
        switch offline.status {
        case .unknown, .downloaded:
            EmptyView()
        case .notDownloaded:
            banner {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "square.and.arrow.down").foregroundStyle(AppColors.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Offline map").font(AppTypography.headline)
                        Text("Save Bashorun/Bodija for offline use")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    Spacer()
                    Button("Download") { Task { await offline.download() } }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accent)
                }
            }
        case let .downloading(progress):
            banner {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Downloading offline map… \(Int(progress * 100))%")
                        .font(AppTypography.caption)
                    ProgressView(value: progress)
                        .tint(AppColors.accent)
                }
            }
        case let .failed(message):
            banner {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(message).font(AppTypography.caption).lineLimit(2)
                    Spacer()
                    Button("Retry") { Task { await offline.download() } }
                        .font(AppTypography.caption)
                }
            }
        }
    }

    private func recenterButton(_ viewModel: MapViewModel) -> some View {
        Button {
            viewModel.recenter()
        } label: {
            Image(systemName: "location.fill")
                .font(.headline)
                .padding(AppSpacing.md)
                .background(AppColors.surface, in: Circle())
                .shadow(radius: 4, y: 2)
        }
        .tint(AppColors.accent)
        .accessibilityLabel("Recenter on my location")
    }

    // MARK: - Selected place card

    private func selectedCard(_ place: PointOfInterest, viewModel: MapViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                Label(place.category.title, systemImage: place.category.symbolName)
                    .font(AppTypography.caption)
                    .foregroundStyle(place.category.tint)
                Spacer()
                Button {
                    dependencies.userDataStore.toggleFavorite(place)
                } label: {
                    Image(systemName: dependencies.userDataStore.isFavorite(place.id) ? "heart.fill" : "heart")
                        .foregroundStyle(.pink)
                }
                .accessibilityLabel(dependencies.userDataStore.isFavorite(place.id) ? "Remove from favorites" : "Add to favorites")
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

            profilePicker(viewModel)

            HStack(spacing: AppSpacing.sm) {
                Button {
                    Task { await viewModel.startNavigation(to: place) }
                } label: {
                    Label("Directions", systemImage: "location.north.line.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accent)

                Button {
                    router.push(.placeDetail(placeID: place.id))
                } label: {
                    Text("Details").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
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
