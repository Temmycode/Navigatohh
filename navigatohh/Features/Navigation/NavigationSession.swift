//
//  NavigationSession.swift
//  navigatohh
//
//  Shared, observable navigation state. Lives in AppDependencies so any screen can start
//  or read a route: e.g. PlaceDetail starts navigation, and the Map draws it.
//

import Observation
import OSLog

@MainActor
@Observable
final class NavigationSession {
    enum State: Equatable {
        case idle
        case routing
        case active
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var route: NavigationRoute?
    private(set) var destination: PointOfInterest?
    var profile: RouteProfile = .driving

    private let routeService: any RouteService
    private let locationService: LocationService
    private let userDataStore: UserDataStore

    init(routeService: any RouteService, locationService: LocationService, userDataStore: UserDataStore) {
        self.routeService = routeService
        self.locationService = locationService
        self.userDataStore = userDataStore
    }

    var isNavigating: Bool {
        if case .active = state { return true }
        return false
    }

    /// Computes and starts a route from the user's current location to a place.
    func start(to place: PointOfInterest) async {
        guard let origin = locationService.currentLocation?.coordinate else {
            state = .failed("Your current location isn't available yet.")
            AppLogger.map.error("Navigation start failed: no current location.")
            return
        }

        destination = place
        state = .routing
        do {
            let computed = try await routeService.route(from: origin, to: place.coordinate, profile: profile)
            route = computed
            state = .active
            userDataStore.recordVisit(place)
            AppLogger.map.info("Route to \(place.name, privacy: .public): \(computed.formattedDistance, privacy: .public), \(computed.formattedTravelTime, privacy: .public)")
        } catch {
            state = .failed(error.localizedDescription)
            AppLogger.map.error("Route computation failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Changes the travel profile, recomputing the active route to the same destination.
    func changeProfile(_ newProfile: RouteProfile) async {
        guard newProfile != profile else { return }
        profile = newProfile
        if let destination, isNavigating {
            await start(to: destination)
        }
    }

    func end() {
        route = nil
        destination = nil
        state = .idle
    }
}
