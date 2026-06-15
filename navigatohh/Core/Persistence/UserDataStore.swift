//
//  UserDataStore.swift
//  navigatohh
//
//  Observable wrapper around the SwiftData store for user data: favorite places and recent
//  destinations. Exposes plain `PointOfInterest` arrays so views/components stay decoupled
//  from the persistence models. Falls back to an in-memory store if the disk store fails.
//

import Foundation
import SwiftData
import OSLog

@MainActor
@Observable
final class UserDataStore {
    private(set) var favorites: [PointOfInterest] = []
    private(set) var recents: [PointOfInterest] = []

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }
    private let recentsLimit = 12

    init() {
        do {
            container = try ModelContainer(for: SavedPlace.self, RecentDestination.self)
        } catch {
            AppLogger.data.error("SwiftData disk store unavailable, using in-memory: \(error.localizedDescription, privacy: .public)")
            // In-memory fallback should never fail; if it does, crashing here is acceptable.
            container = try! ModelContainer(
                for: SavedPlace.self, RecentDestination.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
        refresh()
    }

    // MARK: - Reads

    func refresh() {
        favorites = fetchSaved().map(\.pointOfInterest)
        recents = fetchRecents().map(\.pointOfInterest)
    }

    func isFavorite(_ id: UUID) -> Bool {
        favorites.contains { $0.id == id }
    }

    // MARK: - Mutations

    func toggleFavorite(_ place: PointOfInterest) {
        let id = place.id
        let descriptor = FetchDescriptor<SavedPlace>(predicate: #Predicate { $0.placeID == id })
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        } else {
            context.insert(SavedPlace(from: place))
        }
        save()
        refresh()
    }

    func recordVisit(_ place: PointOfInterest) {
        let id = place.id
        let descriptor = FetchDescriptor<RecentDestination>(predicate: #Predicate { $0.placeID == id })
        if let existing = try? context.fetch(descriptor).first {
            existing.visitedAt = Date()
        } else {
            context.insert(RecentDestination(from: place))
        }
        save()
        refresh()
    }

    func clearRecents() {
        for recent in fetchRecents(limit: 1000) {
            context.delete(recent)
        }
        save()
        refresh()
    }

    // MARK: - Helpers

    private func fetchSaved() -> [SavedPlace] {
        let descriptor = FetchDescriptor<SavedPlace>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetchRecents(limit: Int? = nil) -> [RecentDestination] {
        var descriptor = FetchDescriptor<RecentDestination>(sortBy: [SortDescriptor(\.visitedAt, order: .reverse)])
        descriptor.fetchLimit = limit ?? recentsLimit
        return (try? context.fetch(descriptor)) ?? []
    }

    private func save() {
        do {
            try context.save()
        } catch {
            AppLogger.data.error("SwiftData save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
