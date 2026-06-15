//
//  AppRoute.swift
//  navigatohh
//
//  Type-safe destinations pushed onto a NavigationStack. Add a case here, then handle it
//  in the `navigationDestination` modifier in RootView.
//

import Foundation

enum AppRoute: Hashable {
    case placeDetail(placeID: UUID)
}

/// The top-level tabs of the app.
enum AppTab: Hashable, CaseIterable, Identifiable {
    case map
    case search
    case immersive

    var id: Self { self }

    var title: String {
        switch self {
        case .map:       return "Map"
        case .search:    return "Search"
        case .immersive: return "3D"
        }
    }

    var symbolName: String {
        switch self {
        case .map:       return "map.fill"
        case .search:    return "magnifyingglass"
        case .immersive: return "cube.transparent.fill"
        }
    }
}
