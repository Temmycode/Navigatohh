//
//  RouteService.swift
//  navigatohh
//
//  Abstraction over route/directions computation. Views/ViewModels depend on this
//  protocol, not on Mapbox's Directions API, so the implementation can change freely.
//

import Foundation

enum RouteProfile: String, Sendable, Hashable, CaseIterable, Identifiable {
    case driving = "driving"
    case walking = "walking"
    case cycling = "cycling"
    case drivingTraffic = "driving-traffic"

    var id: String { rawValue }

    /// Profiles offered in the UI picker.
    static let selectable: [RouteProfile] = [.driving, .walking, .cycling]

    var title: String {
        switch self {
        case .driving, .drivingTraffic: return "Drive"
        case .walking:                  return "Walk"
        case .cycling:                  return "Cycle"
        }
    }

    var symbolName: String {
        switch self {
        case .driving, .drivingTraffic: return "car.fill"
        case .walking:                  return "figure.walk"
        case .cycling:                  return "bicycle"
        }
    }
}

enum RouteServiceError: LocalizedError {
    case missingToken
    case requestFailed(status: Int)
    case noRouteFound

    var errorDescription: String? {
        switch self {
        case .missingToken:           return "Mapbox token is missing."
        case let .requestFailed(s):   return "Could not fetch a route (status \(s))."
        case .noRouteFound:           return "No route could be found to this place."
        }
    }
}

protocol RouteService: Sendable {
    /// Computes a route between two coordinates for the given travel profile.
    func route(from origin: Coordinate, to destination: Coordinate, profile: RouteProfile) async throws -> NavigationRoute
}

extension RouteService {
    func route(from origin: Coordinate, to destination: Coordinate) async throws -> NavigationRoute {
        try await route(from: origin, to: destination, profile: .driving)
    }
}
