//
//  SearchViewModel.swift
//  navigatohh
//
//  Backs SearchScreen. Empty query → nearby bundled places (distance-sorted). Text query →
//  bundled matches first, then real-world places from the Mapbox Geocoding API, merged and
//  deduped. Distance to each place is annotated when a location fix is available.
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
    private let geocodingService: any GeocodingService
    private let locationService: LocationService
    private var searchTask: Task<Void, Never>?

    init(
        repository: any PlacesRepository,
        geocodingService: any GeocodingService,
        locationService: LocationService
    ) {
        self.repository = repository
        self.geocodingService = geocodingService
        self.locationService = locationService
    }

    var userLocation: Coordinate? {
        locationService.currentLocation?.coordinate
    }

    /// True when results are the proximity-ordered nearby list (location available + no query).
    var isShowingNearby: Bool {
        userLocation != nil && query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Nearby mode sorts by distance; text-query mode keeps the merged relevance order.
    var displayResults: [PointOfInterest] {
        guard isShowingNearby, let origin = userLocation else { return results }
        return results.sorted { $0.coordinate.distance(to: origin) < $1.coordinate.distance(to: origin) }
    }

    func loadInitial() async {
        locationService.requestPermission()
        locationService.startUpdating()
        await runSearch()
    }

    func distanceText(for place: PointOfInterest) -> String? {
        guard let origin = userLocation else { return nil }
        return DistanceFormatter.string(meters: place.coordinate.distance(to: origin))
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { await runSearch() }
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let local = try await repository.search(query: query, category: selectedCategory)
            guard !Task.isCancelled else { return }

            // Empty query, or a category filter active → bundled places only.
            guard !trimmed.isEmpty, selectedCategory == nil else {
                results = local
                return
            }

            // Text query → also query global geocoding (best-effort; ignore offline/failures).
            let remote = (try? await geocodingService.search(query: trimmed, proximity: userLocation)) ?? []
            guard !Task.isCancelled else { return }
            results = merge(local: local, remote: remote)
        } catch {
            AppLogger.data.error("Search failed: \(error.localizedDescription, privacy: .public)")
            results = []
        }
    }

    /// Bundled matches first, then geocoding results, deduped by name + rounded coordinate.
    private func merge(local: [PointOfInterest], remote: [PointOfInterest]) -> [PointOfInterest] {
        var seen = Set<String>()
        func key(_ p: PointOfInterest) -> String {
            let lat = Int((p.coordinate.latitude * 1000).rounded())
            let lon = Int((p.coordinate.longitude * 1000).rounded())
            return "\(p.name.lowercased())|\(lat)|\(lon)"
        }
        return (local + remote).filter { seen.insert(key($0)).inserted }
    }
}
