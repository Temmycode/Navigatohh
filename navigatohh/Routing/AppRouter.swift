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
    func showPlace(_ id: UUID) {
        selectedTab = .map
        push(.placeDetail(placeID: id))
    }
}

extension EnvironmentValues {
    @Entry var router: AppRouter = AppRouter()
}
