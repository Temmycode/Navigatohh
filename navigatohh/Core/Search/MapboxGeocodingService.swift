//
//  MapboxGeocodingService.swift
//  navigatohh
//
//  GeocodingService backed by the Mapbox Geocoding v6 REST API, called directly with
//  URLSession (no extra SDK). Uses the public access token.
//
//  Docs: https://docs.mapbox.com/api/search/geocoding-v6/
//

import Foundation

struct MapboxGeocodingService: GeocodingService {
    private let accessToken: String
    private let session: URLSession

    init(accessToken: String, session: URLSession = .shared) {
        self.accessToken = accessToken
        self.session = session
    }

    func search(query: String, proximity: Coordinate?) async throws -> [PointOfInterest] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard accessToken.hasPrefix("pk."), !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "https://api.mapbox.com/search/geocode/v6/forward")!
        var items = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "limit", value: "8"),
            URLQueryItem(name: "access_token", value: accessToken),
        ]
        if let proximity {
            items.append(URLQueryItem(name: "proximity", value: "\(proximity.longitude),\(proximity.latitude)"))
        }
        components.queryItems = items

        let (data, response) = try await session.data(from: components.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(GeocodeResponse.self, from: data)

        return decoded.features.compactMap { feature -> PointOfInterest? in
            let coords = feature.geometry.coordinates
            guard coords.count == 2 else { return nil }
            let coordinate = Coordinate(latitude: coords[1], longitude: coords[0])
            let name = feature.properties.name ?? "Unnamed place"
            let address = feature.properties.placeFormatted ?? feature.properties.fullAddress
            let category = PlaceCategory(
                mapboxClass: feature.properties.poiCategory?.first,
                maki: feature.properties.maki
            )
            return PointOfInterest.transient(
                name: name,
                coordinate: coordinate,
                category: category,
                address: address
            )
        }
    }
}

// MARK: - Geocoding v6 response

private struct GeocodeResponse: Decodable {
    let features: [Feature]

    struct Feature: Decodable {
        let geometry: Geometry
        let properties: Properties
    }

    struct Geometry: Decodable {
        let coordinates: [Double]   // [lon, lat]
    }

    struct Properties: Decodable {
        let name: String?
        let placeFormatted: String?
        let fullAddress: String?
        let featureType: String?
        let maki: String?
        let poiCategory: [String]?
    }
}
