//
//  AppRouter.swift
//  navigatohh
//
//  Observable navigation state. Holds the selected tab and a navigation path per the
//  primary stack, so navigation can be driven programmatically from anywhere (e.g. tapping
//  a POI on the map pushes its detail screen).
//

import SwiftUI

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .map
    var path = NavigationPath()

    /// Cross-tab hand-off: set to ask the Map tab to select & focus a place. The map consumes
    /// and clears it.
    var pendingMapSelection: PointOfInterest?

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    /// Switch to the map tab and open a place's detail screen.
    func showPlace(_ place: PointOfInterest) {
        selectedTab = .map
        push(.placeDetail(place))
    }

    /// Switch to the map tab and show the place as the selected card (Google-Maps style),
    /// without pushing a detail screen.
    func focusOnMap(_ place: PointOfInterest) {
        selectedTab = .map
        popToRoot()
        pendingMapSelection = place
    }
}

extension EnvironmentValues {
    @Entry var router: AppRouter = AppRouter()
}
