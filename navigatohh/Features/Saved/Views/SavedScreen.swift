//
//  SavedScreen.swift
//  navigatohh
//
//  Lists the user's favorite places and recent destinations. Selecting a row opens it on
//  the map. Backed by the observable UserDataStore (SwiftData).
//

import SwiftUI

struct SavedScreen: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.router) private var router

    var body: some View {
        let store = dependencies.userDataStore

        Group {
            if store.favorites.isEmpty && store.recents.isEmpty {
                ContentUnavailableView(
                    "Nothing saved yet",
                    systemImage: "heart",
                    description: Text("Tap the heart on a place to save it, or navigate somewhere to see it in Recents.")
                )
            } else {
                List {
                    if !store.favorites.isEmpty {
                        Section("Favorites") {
                            ForEach(store.favorites) { place in
                                row(place, store: store)
                            }
                        }
                    }

                    if !store.recents.isEmpty {
                        Section {
                            ForEach(store.recents) { place in
                                row(place, store: store)
                            }
                        } header: {
                            HStack {
                                Text("Recent")
                                Spacer()
                                Button("Clear") { store.clearRecents() }
                                    .font(AppTypography.caption)
                                    .textCase(nil)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Saved")
        .task { dependencies.userDataStore.refresh() }
    }

    private func row(_ place: PointOfInterest, store: UserDataStore) -> some View {
        let origin = dependencies.locationService.currentLocation?.coordinate
        let distance = origin.map { DistanceFormatter.string(meters: place.coordinate.distance(to: $0)) }
        return Button {
            router.showPlace(place.id)
        } label: {
            PlaceRow(place: place, trailingText: distance)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            if store.isFavorite(place.id) {
                Button("Unsave", role: .destructive) { store.toggleFavorite(place) }
            } else {
                Button("Save") { store.toggleFavorite(place) }.tint(AppColors.accent)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SavedScreen()
            .environment(\.dependencies, AppDependencies())
            .environment(\.router, AppRouter())
    }
}
