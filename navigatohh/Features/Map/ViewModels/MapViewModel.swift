//
//  MapViewModel.swift
//  navigatohh
//
//  Drives MapScreen: loads points of interest from the repository, tracks the user's
//  location via LocationService, and holds the current selection.
//

import Observation
import OSLog

@MainActor
@Observable
final class MapViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var places: [PointOfInterest] = []
    var selectedPlace: PointOfInterest?

    /// Bumped to ask the map to recenter on the user. The representable observes the change.
    private(set) var recenterRequestID = 0

    private let repository: any PlacesRepository
    private let locationService: LocationService
    private let navigationSession: NavigationSession

    init(
        repository: any PlacesRepository,
        locationService: LocationService,
        navigationSession: NavigationSession
    ) {
        self.repository = repository
        self.locationService = locationService
        self.navigationSession = navigationSession
    }

    var userLocation: Coordinate? {
        locationService.currentLocation?.coordinate
    }

    // MARK: - Navigation (reads the shared session)

    var route: NavigationRoute? { navigationSession.route }
    var navigationState: NavigationSession.State { navigationSession.state }
    var navigationDestination: PointOfInterest? { navigationSession.destination }
    var isNavigating: Bool { navigationSession.isNavigating }
    var navigationProfile: RouteProfile { navigationSession.profile }

    func startNavigation(to place: PointOfInterest) async {
        clearSelection()
        await navigationSession.start(to: place)
    }

    func setProfile(_ profile: RouteProfile) async {
        await navigationSession.changeProfile(profile)
    }

    func endNavigation() {
        navigationSession.end()
    }

    func recenter() {
        recenterRequestID += 1
    }

    func onAppear() async {
        locationService.requestPermission()
        locationService.startUpdating()
        await loadPlaces()
    }

    func loadPlaces() async {
        loadState = .loading
        do {
            places = try await repository.places()
            loadState = .loaded
        } catch {
            AppLogger.map.error("Failed to load places: \(error.localizedDescription, privacy: .public)")
            loadState = .failed(error.localizedDescription)
        }
    }

    func select(_ place: PointOfInterest) {
        selectedPlace = place
    }

    func clearSelection() {
        selectedPlace = nil
    }
}
