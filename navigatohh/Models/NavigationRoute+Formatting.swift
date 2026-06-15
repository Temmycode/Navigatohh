//
//  NavigationRoute+Formatting.swift
//  navigatohh
//
//  Display helpers for route distance and travel time.
//

import Foundation

extension NavigationRoute {
    /// e.g. "850 m" or "1.2 km".
    var formattedDistance: String {
        DistanceFormatter.string(meters: distanceMeters)
    }

    /// e.g. "5 min" or "1 hr 4 min".
    var formattedTravelTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = expectedTravelTime >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: max(expectedTravelTime, 60)) ?? "—"
    }
}
