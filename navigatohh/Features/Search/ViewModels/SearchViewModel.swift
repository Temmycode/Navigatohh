//
//  SearchViewModel.swift
//  navigatohh
//
//  Backs SearchScreen: filters POIs by free-text query and optional category, and orders
//  results by distance from the user's current location ("nearby" first).
//

import Observation
import OSLog

@MainActor
@Observable
final class SearchViewModel {
    var query: String = "" {
        didSet { scheduleSearch() }
    }
    var selectedCategory: PlaceCategory? {
        didSet { scheduleSearch() }
    }
    private(set) var results: [PointOfInterest] = []

    private let repository: any PlacesRepository
    private let locationService: LocationService
    private var searchTask: Task<Void, Never>?

    init(repository: any PlacesRepository, locationService: LocationService) {
        self.repository = repository
        self.locationService = locationService
    }

    var userLocation: Coordinate? {
        locationService.currentLocation?.coordinate
    }

    /// True when results are being ordered by proximity (location available + no text query).
    var isShowingNearby: Bool {
        userLocation != nil && query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Results ordered by distance from the user when a location fix is available.
    /// Computed (not stored) so the order updates live as the location changes.
    var displayResults: [PointOfInterest] {
        guard let origin = userLocation else { return results }
        return results.sorted { $0.coordinate.distance(to: origin) < $1.coordinate.distance(to: origin) }
    }

    func loadInitial() async {
        locationService.requestPermission()
        locationService.startUpdating()
        await runSearch()
    }

    /// Formatted distance from the user to a place, or nil if no location fix yet.
    func distanceText(for place: PointOfInterest) -> String? {
        guard let origin = userLocation else { return nil }
        return DistanceFormatter.string(meters: place.coordinate.distance(to: origin))
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { await runSearch() }
    }

    private func runSearch() async {
        do {
            let found = try await repository.search(query: query, category: selectedCategory)
            guard !Task.isCancelled else { return }
            results = found
        } catch {
            AppLogger.data.error("Search failed: \(error.localizedDescription, privacy: .public)")
            results = []
        }
    }
}
