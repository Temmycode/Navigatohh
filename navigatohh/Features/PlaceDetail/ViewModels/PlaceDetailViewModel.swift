//
//  PlaceDetailViewModel.swift
//  navigatohh
//
//  Loads a single POI by id for PlaceDetailScreen.
//

import Observation
import Foundation
import OSLog

@MainActor
@Observable
final class PlaceDetailViewModel {
    enum LoadState: Equatable {
        case loading
        case loaded(PointOfInterest)
        case notFound
        case failed(String)
    }

    private(set) var state: LoadState = .loading

    private let placeID: UUID
    private let repository: any PlacesRepository

    init(placeID: UUID, repository: any PlacesRepository) {
        self.placeID = placeID
        self.repository = repository
    }

    func load() async {
        state = .loading
        do {
            if let place = try await repository.place(id: placeID) {
                state = .loaded(place)
            } else {
                state = .notFound
            }
        } catch {
            AppLogger.data.error("Failed to load place: \(error.localizedDescription, privacy: .public)")
            state = .failed(error.localizedDescription)
        }
    }
}
