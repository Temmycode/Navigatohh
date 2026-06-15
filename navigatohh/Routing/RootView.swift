//
//  RootView.swift
//  navigatohh
//
//  The app's top-level shell: a TabView whose Map tab owns the programmatic navigation
//  path (so tapping a POI can push its detail screen). Search and 3D get their own stacks.
//

import SwiftUI

struct RootView: View {
    @Environment(\.router) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.path) {
                MapScreen()
                    .navigationDestination(for: AppRoute.self) { route in
                        destination(for: route)
                    }
            }
            .tabItem { Label(AppTab.map.title, systemImage: AppTab.map.symbolName) }
            .tag(AppTab.map)

            NavigationStack {
                SearchScreen()
                    .navigationDestination(for: AppRoute.self) { route in
                        destination(for: route)
                    }
            }
            .tabItem { Label(AppTab.search.title, systemImage: AppTab.search.symbolName) }
            .tag(AppTab.search)

            NavigationStack {
                SavedScreen()
            }
            .tabItem { Label(AppTab.saved.title, systemImage: AppTab.saved.symbolName) }
            .tag(AppTab.saved)

            if AppConfiguration.FeatureFlags.immersiveModeEnabled {
                NavigationStack {
                    ImmersiveSceneView()
                }
                .tabItem { Label(AppTab.immersive.title, systemImage: AppTab.immersive.symbolName) }
                .tag(AppTab.immersive)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case let .placeDetail(placeID):
            PlaceDetailScreen(placeID: placeID)
        }
    }
}

#Preview {
    RootView()
        .environment(\.dependencies, AppDependencies())
        .environment(\.router, AppRouter())
}
