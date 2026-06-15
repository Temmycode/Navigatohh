//
//  SavedPlace.swift
//  navigatohh
//
//  SwiftData model for a favorited place. Snapshots the POI fields so the Saved list
//  renders without re-fetching from the places repository.
//

import Foundation
import SwiftData

@Model
final class SavedPlace {
    @Attribute(.unique) var placeID: UUID
    var name: String
    var categoryRaw: String
    var latitude: Double
    var longitude: Double
    var summary: String
    var address: String?
    var imageURLString: String?
    var savedAt: Date

    init(
        placeID: UUID,
        name: String,
        categoryRaw: String,
        latitude: Double,
        longitude: Double,
        summary: String,
        address: String?,
        imageURLString: String?,
        savedAt: Date
    ) {
        self.placeID = placeID
        self.name = name
        self.categoryRaw = categoryRaw
        self.latitude = latitude
        self.longitude = longitude
        self.summary = summary
        self.address = address
        self.imageURLString = imageURLString
        self.savedAt = savedAt
    }

    convenience init(from poi: PointOfInterest, savedAt: Date = Date()) {
        self.init(
            placeID: poi.id,
            name: poi.name,
            categoryRaw: poi.category.rawValue,
            latitude: poi.coordinate.latitude,
            longitude: poi.coordinate.longitude,
            summary: poi.summary,
            address: poi.address,
            imageURLString: poi.imageURL?.absoluteString,
            savedAt: savedAt
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
