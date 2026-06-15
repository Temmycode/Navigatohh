//
//  LocalPlacesRepository.swift
//  navigatohh
//
//  Local-first implementation backed by a bundled JSON seed (Resources/SeedData/places.json).
//  Decodes once and caches in memory.
//

import Foundation

actor LocalPlacesRepository: PlacesRepository {
    private let resourceName: String
    private var cache: [PointOfInterest]?

    init(resourceName: String = "places") {
        self.resourceName = resourceName
    }

    func places() async throws -> [PointOfInterest] {
        if let cache { return cache }
        let loaded: [PointOfInterest] = try BundleJSONLoader.load(from: resourceName)
        cache = loaded
        return loaded
    }

    func place(id: UUID) async throws -> PointOfInterest? {
        try await places().first { $0.id == id }
    }
}
