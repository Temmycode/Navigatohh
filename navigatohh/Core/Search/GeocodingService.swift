//
//  GeocodingService.swift
//  navigatohh
//
//  Abstraction over forward geocoding (text -> real-world places). Lets Search find places
//  beyond the bundled dataset without coupling to a specific provider.
//

import Foundation

protocol GeocodingService: Sendable {
    /// Finds real-world places matching the query, optionally biased toward `proximity`.
    func search(query: String, proximity: Coordinate?) async throws -> [PointOfInterest]
}
