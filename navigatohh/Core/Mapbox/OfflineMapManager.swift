//
//  OfflineMapManager.swift
//  navigatohh
//
//  Downloads a bounded Mapbox tile pack (style pack + tile region) for the Bashorun/Bodija
//  area into the default TileStore, so the basemap renders from disk and the app works on a
//  flaky/absent connection. Downloading is a one-time, resumable operation.
//
//  Mapbox Maps SDK v11 offline APIs (OfflineManager / TileStore).
//

import Foundation
import MapboxMaps
import OSLog

enum OfflineMapError: LocalizedError {
    case invalidStyle
    case invalidOptions

    var errorDescription: String? {
        switch self {
        case .invalidStyle:   return "Invalid map style for offline download."
        case .invalidOptions: return "Could not build offline download options."
        }
    }
}

@MainActor
@Observable
final class OfflineMapManager {
    enum Status: Equatable {
        case unknown
        case notDownloaded
        case downloading(Double)   // 0...1
        case downloaded
        case failed(String)
    }

    private(set) var status: Status = .unknown

    private let regionID = "bashorun-bodija"
    private let styleURIString: String
    private let zoomRange: ClosedRange<UInt8>
    private let southWest: Coordinate
    private let northEast: Coordinate

    private let tileStore = TileStore.default
    private let offlineManager = OfflineManager()

    init() {
        self.styleURIString = AppConfiguration.Map.styleURI
        self.zoomRange = AppConfiguration.Map.offlineZoomRange
        self.southWest = AppConfiguration.Map.offlineSouthWest
        self.northEast = AppConfiguration.Map.offlineNorthEast
    }

    // MARK: - Status

    func refreshStatus() async {
        if case .downloading = status { return }
        let exists = await regionExists()
        status = exists ? .downloaded : .notDownloaded
    }

    private func regionExists() async -> Bool {
        await withCheckedContinuation { continuation in
            tileStore.allTileRegions { [regionID] result in
                switch result {
                case let .success(regions):
                    continuation.resume(returning: regions.contains { $0.id == regionID })
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }
    }

    // MARK: - Download

    func download() async {
        status = .downloading(0)
        do {
            try await loadStylePack()
            try await loadTileRegion()
            status = .downloaded
            AppLogger.map.info("Offline region '\(self.regionID, privacy: .public)' downloaded.")
        } catch {
            status = .failed(error.localizedDescription)
            AppLogger.map.error("Offline download failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func deleteRegion() {
        tileStore.removeTileRegion(forId: regionID)
        status = .notDownloaded
    }

    private func loadStylePack() async throws {
        guard let styleURI = StyleURI(rawValue: styleURIString) else { throw OfflineMapError.invalidStyle }
        guard let options = StylePackLoadOptions(
            glyphsRasterizationMode: .ideographsRasterizedLocally,
            metadata: nil,
            acceptExpired: true
        ) else { throw OfflineMapError.invalidOptions }

        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StylePack, Error>) in
            _ = offlineManager.loadStylePack(for: styleURI, loadOptions: options) { _ in
                // Style-pack progress is small; tile progress drives the UI.
            } completion: { result in
                continuation.resume(with: result)
            }
        }
    }

    private func loadTileRegion() async throws {
        guard let styleURI = StyleURI(rawValue: styleURIString) else { throw OfflineMapError.invalidStyle }

        let descriptorOptions = TilesetDescriptorOptions(styleURI: styleURI, zoomRange: zoomRange, tilesets: [])
        let descriptor = offlineManager.createTilesetDescriptor(for: descriptorOptions)

        let ring = [
            CLLocationCoordinate2D(latitude: southWest.latitude, longitude: southWest.longitude),
            CLLocationCoordinate2D(latitude: southWest.latitude, longitude: northEast.longitude),
            CLLocationCoordinate2D(latitude: northEast.latitude, longitude: northEast.longitude),
            CLLocationCoordinate2D(latitude: northEast.latitude, longitude: southWest.longitude),
            CLLocationCoordinate2D(latitude: southWest.latitude, longitude: southWest.longitude),
        ]
        let polygon = Polygon([ring])

        guard let loadOptions = TileRegionLoadOptions(
            geometry: .polygon(polygon),
            descriptors: [descriptor],
            metadata: nil,
            acceptExpired: true
        ) else { throw OfflineMapError.invalidOptions }

        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TileRegion, Error>) in
            _ = tileStore.loadTileRegion(forId: regionID, loadOptions: loadOptions) { [weak self] progress in
                let required = progress.requiredResourceCount
                let completed = progress.completedResourceCount
                let fraction = required > 0 ? Double(completed) / Double(required) : 0
                Task { @MainActor in self?.status = .downloading(fraction) }
            } completion: { result in
                continuation.resume(with: result)
            }
        }
    }
}
