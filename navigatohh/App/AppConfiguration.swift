//
//  AppConfiguration.swift
//  navigatohh
//
//  Static, app-wide configuration: the default map framing for the Bashorun/Bodija area,
//  the Mapbox style, and feature flags. Values here are safe to tweak as the app evolves.
//

import Foundation

enum AppConfiguration {

    // MARK: - Map defaults (centred on the Bashorun/Bodija area of Ibadan)

    enum Map {
        /// Initial camera centre — roughly between Bodija and Bashorun.
        static let defaultCenter = Coordinate(latitude: 7.4380, longitude: 3.9180)
        static let defaultZoom: Double = 13.5
        /// Camera pitch in degrees — tilt gives the 3D perspective.
        static let defaultPitch: Double = 60
        static let defaultBearing: Double = 0

        /// Mapbox Standard style — ships with 3D buildings and lighting out of the box.
        static let styleURI = "mapbox://styles/mapbox/standard"

        // MARK: Offline region (bounding box covering Bashorun/Bodija)

        /// South-west corner of the offline download area.
        static let offlineSouthWest = Coordinate(latitude: 7.405, longitude: 3.880)
        /// North-east corner of the offline download area.
        static let offlineNorthEast = Coordinate(latitude: 7.470, longitude: 3.945)
        /// Zoom levels to cache offline (neighbourhood → street level).
        static let offlineZoomRange: ClosedRange<UInt8> = 10...16
    }

    // MARK: - Feature flags

    enum FeatureFlags {
        /// Toggles the experimental RealityKit/SceneKit immersive tab.
        static let immersiveModeEnabled = true
    }
}
