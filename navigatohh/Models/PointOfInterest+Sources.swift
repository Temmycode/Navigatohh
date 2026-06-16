//
//  PointOfInterest+Sources.swift
//  navigatohh
//
//  Builds a `PointOfInterest` from non-bundled sources (a tapped built-in map POI or a
//  geocoding result). These get a deterministic id (from name + coordinate) so favorites and
//  recents dedupe them the same way as bundled places.
//

import Foundation

extension PointOfInterest {
    /// A place that didn't come from the bundled dataset (tapped map POI, geocoding result).
    static func transient(
        name: String,
        coordinate: Coordinate,
        category: PlaceCategory,
        address: String? = nil,
        summary: String = ""
    ) -> PointOfInterest {
        let id = UUID(seed: "\(name)|\(coordinate.latitude),\(coordinate.longitude)")
        return PointOfInterest(
            id: id,
            name: name,
            category: category,
            coordinate: coordinate,
            summary: summary,
            address: address,
            imageURL: nil
        )
    }
}
