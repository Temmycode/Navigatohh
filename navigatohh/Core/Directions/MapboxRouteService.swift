//
//  MapboxRouteService.swift
//  navigatohh
//
//  RouteService backed by the Mapbox Directions REST API, called directly with
//  URLSession (no extra SDK dependency). Uses the public access token.
//
//  Docs: https://docs.mapbox.com/api/navigation/directions/
//

import Foundation

struct MapboxRouteService: RouteService {
    private let accessToken: String
    private let session: URLSession

    init(accessToken: String, session: URLSession = .shared) {
        self.accessToken = accessToken
        self.session = session
    }

    func route(from origin: Coordinate, to destination: Coordinate, profile: RouteProfile) async throws -> NavigationRoute {
        guard accessToken.hasPrefix("pk.") else { throw RouteServiceError.missingToken }

        let coordinates = "\(origin.longitude),\(origin.latitude);\(destination.longitude),\(destination.latitude)"
        var components = URLComponents(string: "https://api.mapbox.com/directions/v5/mapbox/\(profile.rawValue)/\(coordinates)")!
        components.queryItems = [
            URLQueryItem(name: "geometries", value: "geojson"),
            URLQueryItem(name: "overview", value: "full"),
            URLQueryItem(name: "access_token", value: accessToken),
        ]

        let (data, response) = try await session.data(from: components.url!)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard status == 200 else { throw RouteServiceError.requestFailed(status: status) }

        let decoded = try JSONDecoder().decode(DirectionsResponse.self, from: data)
        guard let best = decoded.routes.first else { throw RouteServiceError.noRouteFound }

        let waypoints = best.geometry.coordinates.compactMap { pair -> Coordinate? in
            guard pair.count == 2 else { return nil }
            return Coordinate(latitude: pair[1], longitude: pair[0])
        }

        return NavigationRoute(
            origin: origin,
            destination: destination,
            waypoints: waypoints,
            distanceMeters: best.distance,
            expectedTravelTime: best.duration
        )
    }
}

// MARK: - Directions API response (GeoJSON geometry)

private struct DirectionsResponse: Decodable {
    let routes: [Route]

    struct Route: Decodable {
        let distance: Double      // metres
        let duration: Double      // seconds
        let geometry: LineGeometry
    }

    struct LineGeometry: Decodable {
        let coordinates: [[Double]]   // [[lon, lat], ...]
    }
}
