//
//  MapboxMapRepresentable.swift
//  navigatohh
//
//  Bridges a Mapbox `MapView` into SwiftUI. The Mapbox Standard style ships with 3D
//  buildings and lighting, so a pitched camera is all that's needed for the 3D look.
//
//  POIs are rendered as point annotations; tapping one calls `onSelect`.
//
//  Note: targets the Mapbox Maps SDK v11 API. If you bump to a new major version, the
//  annotation / camera calls below are the most likely spots to need small adjustments.
//

import SwiftUI
import MapboxMaps

struct MapboxMapRepresentable: UIViewRepresentable {
    var places: [PointOfInterest]
    var userLocation: Coordinate?
    var onSelect: (PointOfInterest) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIView(context: Context) -> MapView {
        let center = (userLocation ?? AppConfiguration.Map.defaultCenter).clCoordinate
        let cameraOptions = CameraOptions(
            center: center,
            zoom: AppConfiguration.Map.defaultZoom,
            bearing: AppConfiguration.Map.defaultBearing,
            pitch: AppConfiguration.Map.defaultPitch
        )
        let initOptions = MapInitOptions(
            cameraOptions: cameraOptions,
            styleURI: StyleURI(rawValue: AppConfiguration.Map.styleURI) ?? .standard
        )

        let mapView = MapView(frame: .zero, mapInitOptions: initOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Show the user's location puck.
        mapView.location.options.puckType = .puck2D()

        // Annotation manager lives for the lifetime of the map view.
        let manager = mapView.annotations.makePointAnnotationManager()
        context.coordinator.annotationManager = manager
        context.coordinator.mapView = mapView

        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {
        context.coordinator.onSelect = onSelect
        context.coordinator.render(places: places)
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator {
        var onSelect: (PointOfInterest) -> Void
        weak var mapView: MapView?
        var annotationManager: PointAnnotationManager?
        private var renderedPlaceIDs: [UUID] = []

        init(onSelect: @escaping (PointOfInterest) -> Void) {
            self.onSelect = onSelect
        }

        func render(places: [PointOfInterest]) {
            let ids = places.map(\.id)
            guard ids != renderedPlaceIDs else { return }
            renderedPlaceIDs = ids

            guard let annotationManager else { return }
            annotationManager.annotations = places.map { place in
                var annotation = PointAnnotation(coordinate: place.coordinate.clCoordinate)
                annotation.iconAnchor = .bottom
                annotation.textField = place.name
                annotation.textAnchor = .top
                annotation.textOffset = [0, 0.6]
                annotation.tapHandler = { [weak self] _ in
                    self?.onSelect(place)
                    return true
                }
                return annotation
            }
        }
    }
}
