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
    let routeService: any RouteService
    let geocodingService: any GeocodingService
    let navigationSession: NavigationSession
    let offlineMapManager: OfflineMapManager
    let userDataStore: UserDataStore

    /// Default composition used by the app and the environment fallback.
    init() {
        let location = LocationService()
        let routes = MapboxRouteService(accessToken: AppSecrets.mapboxPublicToken)
        let userData = UserDataStore()
        self.placesRepository = LocalPlacesRepository()
        self.locationService = location
        self.routeService = routes
        self.geocodingService = MapboxGeocodingService(accessToken: AppSecrets.mapboxPublicToken)
        self.userDataStore = userData
        self.navigationSession = NavigationSession(routeService: routes, locationService: location, userDataStore: userData)
        self.offlineMapManager = OfflineMapManager()
    }

    /// Injecting initializer for tests and previews.
    init(
        placesRepository: any PlacesRepository,
        locationService: LocationService,
        routeService: any RouteService,
        geocodingService: any GeocodingService
    ) {
        let userData = UserDataStore()
        self.placesRepository = placesRepository
        self.locationService = locationService
        self.routeService = routeService
        self.geocodingService = geocodingService
        self.userDataStore = userData
        self.navigationSession = NavigationSession(routeService: routeService, locationService: locationService, userDataStore: userData)
        self.offlineMapManager = OfflineMapManager()
    }
}

extension EnvironmentValues {
    // The default is only a fallback; the real graph is injected at the app root.
    @Entry var dependencies: AppDependencies = AppDependencies()
}
