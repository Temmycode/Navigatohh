//
//  NavigationRoute.swift
//  navigatohh
//
//  A computed route between two points. This is a deliberately minimal stub:
//  the scaffold does not yet integrate turn-by-turn routing (Mapbox Navigation SDK).
//  It exists so the "Navigate here" flow has a concrete type to pass around, and so
//  routing can be added later without reshaping the call sites.
//

import Foundation

struct NavigationRoute: Identifiable, Hashable, Sendable {
    let id: UUID
    var origin: Coordinate
    var destination: Coordinate
    /// Ordered polyline points making up the route geometry.
    var waypoints: [Coordinate]
    /// Estimated distance in metres.
    var distanceMeters: Double
    /// Estimated travel time in seconds.
    var expectedTravelTime: TimeInterval
    
    init(
        id: UUID = UUID(),
        origin: Coordinate,
        destination: Coordinate,
        waypoints: [Coordinate] = [],
        distanceMeters: Double = 0,
        expectedTravelTime: TimeInterval = 0
    ) {
        self.id = id
        self.origin = origin
        self.destination = destination
        self.waypoints = waypoints
        self.distanceMeters = distanceMeters
        self.expectedTravelTime = expectedTravelTime
    }
}
