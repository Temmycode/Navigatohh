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

    private let repository: any PlacesRepository
    private let locationService: LocationService

    init(repository: any PlacesRepository, locationService: LocationService) {
        self.repository = repository
        self.locationService = locationService
    }

    var userLocation: Coordinate? {
        locationService.currentLocation?.coordinate
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
