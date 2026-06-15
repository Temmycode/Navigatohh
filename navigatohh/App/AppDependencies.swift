//
//  AppDependencies.swift
//  navigatohh
//
//  Composition root. Builds and owns the app's services/repositories and is injected into
//  the SwiftUI environment at launch, so any view can pull what it needs without globals.
//
//  Swap LocalPlacesRepository for a remote implementation here (one line) when a backend
//  is ready — nothing else needs to change.
//

import SwiftUI

@MainActor
@Observable
final class AppDependencies {
    let placesRepository: any PlacesRepository
    let locationService: LocationService

    /// Default composition used by the app and the environment fallback.
    init() {
        self.placesRepository = LocalPlacesRepository()
        self.locationService = LocationService()
    }

    /// Injecting initializer for tests and previews.
    init(placesRepository: any PlacesRepository, locationService: LocationService) {
        self.placesRepository = placesRepository
        self.locationService = locationService
    }
}

extension EnvironmentValues {
    // The default is only a fallback; the real graph is injected at the app root.
    @Entry var dependencies: AppDependencies = AppDependencies()
}
