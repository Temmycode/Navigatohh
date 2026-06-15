//
//  CLLocationCoordinate2D+.swift
//  navigatohh
//
//  Conveniences for working with CoreLocation coordinates.
//

import CoreLocation

extension CLLocationCoordinate2D {
    var coordinate: Coordinate { Coordinate(self) }

    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}
