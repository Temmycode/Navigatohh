//
//  RecentDestination.swift
//  navigatohh
//
//  SwiftData model for a recently-navigated destination. Recorded automatically when the
//  user starts navigation to a place.
//

import Foundation
import SwiftData

@Model
final class RecentDestination {
    @Attribute(.unique) var placeID: UUID
    var name: String
    var categoryRaw: String
    var latitude: Double
    var longitude: Double
    var summary: String
    var address: String?
    var imageURLString: String?
    var visitedAt: Date

    init(
        placeID: UUID,
        name: String,
        categoryRaw: String,
        latitude: Double,
        longitude: Double,
        summary: String,
        address: String?,
        imageURLString: String?,
        visitedAt: Date
    ) {
        self.placeID = placeID
        self.name = name
        self.categoryRaw = categoryRaw
        self.latitude = latitude
        self.longitude = longitude
        self.summary = summary
        self.address = address
        self.imageURLString = imageURLString
        self.visitedAt = visitedAt
    }

    convenience init(from poi: PointOfInterest, visitedAt: Date = Date()) {
        self.init(
            placeID: poi.id,
            name: poi.name,
            categoryRaw: poi.category.rawValue,
            latitude: poi.coordinate.latitude,
            longitude: poi.coordinate.longitude,
            summary: poi.summary,
            address: poi.address,
            imageURLString: poi.imageURL?.absoluteString,
            visitedAt: visitedAt
        )
    }

    var pointOfInterest: PointOfInterest {
        PointOfInterest(
            id: placeID,
            name: name,
            category: PlaceCategory(rawValue: categoryRaw) ?? .other,
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            summary: summary,
            address: address,
            imageURL: imageURLString.flatMap(URL.init(string:))
        )
    }
}
