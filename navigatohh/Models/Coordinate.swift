//
//  Coordinate.swift
//  navigatohh
//
//  A lightweight, Codable geographic coordinate. Kept separate from CoreLocation's
//  CLLocationCoordinate2D (which is not Codable) so models stay serialisable, while
//  still bridging to it for map/location work.
//

import CoreLocation

struct Coordinate: Codable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ clCoordinate: CLLocationCoordinate2D) {
        self.latitude = clCoordinate.latitude
        self.longitude = clCoordinate.longitude
    }

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Straight-line distance in metres to another coordinate.
    func distance(to other: Coordinate) -> CLLocationDistance {
        let a = CLLocation(latitude: latitude, longitude: longitude)
        let b = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return a.distance(from: b)
    }
}
