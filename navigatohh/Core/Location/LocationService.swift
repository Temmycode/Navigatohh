//
//  LocationService.swift
//  navigatohh
//
//  Observable wrapper around CLLocationManager. ViewModels read `currentLocation` /
//  `authorizationStatus` and call `requestPermission()` / `startUpdating()`; they never
//  touch CoreLocation directly.
//
//  CLLocationManager delivers its delegate callbacks on the thread it was created on
//  (the main thread here), so the nonisolated delegate methods safely hop back onto the
//  main actor via `MainActor.assumeIsolated`.
//

import CoreLocation
import Observation
import OSLog

@Observable
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var currentLocation: CLLocationCoordinate2D?

    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    /// True once the user has granted when-in-use (or always) authorization.
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard isAuthorized else { return }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            authorizationStatus = manager.authorizationStatus
            if isAuthorized {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        MainActor.assumeIsolated {
            currentLocation = latest.coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        AppLogger.location.error("Location update failed: \(error.localizedDescription, privacy: .public)")
    }
}
