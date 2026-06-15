//
//  MapboxConfigurator.swift
//  navigatohh
//
//  Sets the Mapbox access token once at launch. Called from navigatohhApp.init()
//  before any MapView is created.
//

import Foundation
import MapboxMaps
import OSLog

enum MapboxConfigurator {
    static func configure() {
        let token = AppSecrets.mapboxPublicToken
        guard token.hasPrefix("pk.") else {
            AppLogger.map.error(
                "Mapbox public token is missing or invalid. Set MAPBOX_PUBLIC_TOKEN in Config/Secrets.xcconfig."
            )
            return
        }
        MapboxOptions.accessToken = token
        AppLogger.map.info("Mapbox configured.")
    }
}
