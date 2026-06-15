//
//  SearchViewModel.swift
//  navigatohh
//
//  Backs SearchScreen: filters POIs by free-text query and optional category.
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
    private var searchTask: Task<Void, Never>?

    init(repository: any PlacesRepository) {
        self.repository = repository
    }

    func loadInitial() async {
        await runSearch()
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
