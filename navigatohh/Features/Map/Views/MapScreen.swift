//
//  MapScreen.swift
//  navigatohh
//
//  The primary screen: a 3D Mapbox map of the Bashorun/Bodija area. A single frosted-glass
//  bottom sheet handles every state — selected place, finding-route, active navigation, and
//  errors — so navigation feedback stays in one consistent place (no split top/bottom UI).
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
                selectedCoordinate: viewModel.selectedPlace?.coordinate,
                selectionFocusID: viewModel.selectionFocusID,
                onSelect: { viewModel.select($0, focus: false) },
                onDeselect: { viewModel.clearSelection() }
            )
            .ignoresSafeArea()
            .onChange(of: router.pendingMapSelection) { _, place in
                guard let place else { return }
                viewModel.select(place, focus: true)
                router.pendingMapSelection = nil
            }

            // Top: offline banner only (informational).
            VStack(spacing: AppSpacing.sm) {
                offlineBanner()
                Spacer()
            }
            .padding(AppSpacing.md)

            // Bottom-trailing: recenter — hidden while the sheet is up to avoid overlap.
            if !isSheetVisible(viewModel) {
                HStack {
                    Spacer()
                    recenterButton(viewModel)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
                .transition(.opacity)
            }

            if case let .failed(message) = viewModel.loadState {
                ErrorView(message: message) {
                    Task { await viewModel.loadPlaces() }
                }
                .background(.regularMaterial)
            }

            // One persistent glass sheet; only its CONTENT swaps between states, so the box
            // never disappears/reappears (no flicker) while finding a route.
            if isSheetVisible(viewModel) {
                sheetContainer { sheetInner(viewModel) }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: viewModel.selectedPlace)
        .animation(.snappy, value: viewModel.navigationState)
    }

    private func isSheetVisible(_ viewModel: MapViewModel) -> Bool {
        viewModel.selectedPlace != nil || viewModel.navigationState != .idle
    }

    // MARK: - Bottom sheet (single source of truth for selection + navigation)

    /// A selected place takes priority over navigation state, so the user can always tap a new
    /// place to preview/re-route — even mid-navigation. Closing the place card falls back to
    /// the active-navigation summary.
    @ViewBuilder
    private func sheetInner(_ viewModel: MapViewModel) -> some View {
        if let place = viewModel.selectedPlace {
            placeContent(place, viewModel: viewModel)
        } else {
            switch viewModel.navigationState {
            case .routing:
                routingContent(viewModel)
            case .active:
                activeContent(viewModel)
            case let .failed(message):
                failedContent(message, viewModel: viewModel)
            case .idle:
                EmptyView()
            }
        }
    }

    private func sheetContainer<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: AppSpacing.md) {
            Capsule()
                .fill(AppColors.secondaryText.opacity(0.35))
                .frame(width: 40, height: 5)
            content()
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }

    // MARK: Selected place

    @ViewBuilder
    private func placeContent(_ place: PointOfInterest, viewModel: MapViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                Label(place.category.title, systemImage: place.category.symbolName)
                    .font(AppTypography.caption.weight(.semibold))
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
                        .font(.title3)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .accessibilityLabel("Close")
            }

            Text(place.name)
                .font(AppTypography.title)

            if let address = place.address {
                Text(address)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(1)
            }

            if !place.summary.isEmpty {
                Text(place.summary)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(2)
            }

            profilePicker(viewModel)

            HStack(spacing: AppSpacing.sm) {
                Button {
                    Task { await viewModel.startNavigation(to: place) }
                } label: {
                    Label("Directions", systemImage: "location.north.line.fill")
                }
                .buttonStyle(.gradient)

                Button {
                    router.push(.placeDetail(place))
                } label: {
                    Text("Details")
                        .font(AppTypography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .background(AppColors.secondaryBackground, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .foregroundStyle(AppColors.primaryText)
            }
        }
    }

    // MARK: Finding route

    private func routingContent(_ viewModel: MapViewModel) -> some View {
        HStack(spacing: AppSpacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(AppColors.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Finding route…")
                    .font(AppTypography.headline)
                Text("to \(viewModel.navigationDestination?.name ?? "destination")")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            Button("Cancel") { viewModel.endNavigation() }
                .font(AppTypography.callout)
                .tint(AppColors.accent)
        }
    }

    // MARK: Active navigation

    private func activeContent(_ viewModel: MapViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: "location.north.line.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    if let route = viewModel.route {
                        Text(route.formattedTravelTime)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppColors.accent)
                        Text("\(route.formattedDistance) · \(viewModel.navigationDestination?.name ?? "destination")")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondaryText)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button(role: .destructive) {
                    viewModel.endNavigation()
                } label: {
                    Text("End").font(AppTypography.headline)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            profilePicker(viewModel)
        }
    }

    // MARK: Failed

    private func failedContent(_ message: String, viewModel: MapViewModel) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(AppTypography.callout)
                .lineLimit(2)
            Spacer()
            Button("Dismiss") { viewModel.endNavigation() }
                .font(AppTypography.callout)
                .tint(AppColors.accent)
        }
    }

    // MARK: - Shared controls

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

    private func recenterButton(_ viewModel: MapViewModel) -> some View {
        Button {
            viewModel.recenter()
        } label: {
            Image(systemName: "location.fill")
                .font(.headline)
                .foregroundStyle(AppColors.accent)
                .padding(AppSpacing.md)
                .glassCard(cornerRadius: 28)
        }
        .accessibilityLabel("Recenter on my location")
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

    private func banner<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: AppRadius.card)
    }
}

#Preview {
    NavigationStack {
        MapScreen()
            .environment(\.dependencies, AppDependencies())
            .environment(\.router, AppRouter())
    }
}
