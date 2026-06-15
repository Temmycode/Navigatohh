//
//  PointOfInterest.swift
//  navigatohh
//
//  Core domain model representing a place on the map.
//

import Foundation

struct PointOfInterest: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var category: PlaceCategory
    var coordinate: Coordinate
    var summary: String
    var address: String?
    var imageURL: URL?

    init(
        id: UUID = UUID(),
        name: String,
        category: PlaceCategory,
        coordinate: Coordinate,
        summary: String,
        address: String? = nil,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.coordinate = coordinate
        self.summary = summary
        self.address = address
        self.imageURL = imageURL
    }
}
