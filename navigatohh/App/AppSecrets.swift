//
//  AppSecrets.swift
//  navigatohh
//
//  Reads secret/config values that are injected at build time from Config/Secrets.xcconfig
//  into the generated Info.plist. Keeping this behind one type means no raw token strings
//  are scattered across the codebase.
//

import Foundation

enum AppSecrets {
    /// Mapbox PUBLIC access token (starts with "pk."). Injected via
    /// `INFOPLIST_KEY_MBXAccessToken = $(MAPBOX_PUBLIC_TOKEN)`.
    static var mapboxPublicToken: String {
        infoValue(for: "MBXAccessToken") ?? ""
    }

    private static func infoValue(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty else {
            return nil
        }
        return value
    }
}
