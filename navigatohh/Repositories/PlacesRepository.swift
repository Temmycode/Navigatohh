//
//  PlacesRepository.swift
//  navigatohh
//
//  Abstraction over the source of place data. The app is local-first today
//  (LocalPlacesRepository), but Views/ViewModels only ever talk to this protocol,
//  so a remote backend can be dropped in later without touching them.
//

import Foundation

protocol PlacesRepository: Sendable {
    /// All known points of interest.
    func places() async throws -> [PointOfInterest]

    /// A single point of interest by id, if it exists.
    func place(id: UUID) async throws -> PointOfInterest?

    /// Places matching a free-text query and/or category filter.
    func search(query: String, category: PlaceCategory?) async throws -> [PointOfInterest]
}

extension PlacesRepository {
    /// Default search implemented on top of `places()`; concrete repositories may override
    /// with a more efficient server-side or indexed search.
    func search(query: String, category: PlaceCategory?) async throws -> [PointOfInterest] {
        let all = try await places()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return all.filter { poi in
            let matchesCategory = category == nil || poi.category == category
            let matchesQuery = trimmed.isEmpty
                || poi.name.localizedCaseInsensitiveContains(trimmed)
                || poi.summary.localizedCaseInsensitiveContains(trimmed)
                || (poi.address?.localizedCaseInsensitiveContains(trimmed) ?? false)
            return matchesCategory && matchesQuery
        }
    }
}
