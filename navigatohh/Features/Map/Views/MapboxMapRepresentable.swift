//
//  MapboxMapRepresentable.swift
//  navigatohh
//
//  Bridges a Mapbox `MapView` into SwiftUI. The Mapbox Standard style ships with 3D
//  buildings and lighting, so a pitched camera is all that's needed for the 3D look.
//
//  Responsibilities:
//   - render POI annotations (tap -> onSelect)
//   - draw the active route as a line layer and frame it
//   - center on the user the first time a location fix arrives
//   - recenter on demand when `recenterRequestID` changes
//
//  Note: targets the Mapbox Maps SDK v11 API. If you bump to a new major version, the
//  annotation / camera / layer calls below are the most likely spots to need adjustment.
//

import SwiftUI
import MapboxMaps
import OSLog

struct MapboxMapRepresentable: UIViewRepresentable {
    var places: [PointOfInterest]
    var userLocation: Coordinate?
    var route: NavigationRoute?
    var recenterRequestID: Int
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
        mapView.location.options.puckType = .puck2D()

        let manager = mapView.annotations.makePointAnnotationManager()
        context.coordinator.annotationManager = manager
        context.coordinator.mapView = mapView

        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {
        context.coordinator.onSelect = onSelect
        context.coordinator.render(places: places)
        context.coordinator.updateRoute(route)
        context.coordinator.centerOnUserIfNeeded(userLocation)
        context.coordinator.handleRecenter(requestID: recenterRequestID, userLocation: userLocation)
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator {
        var onSelect: (PointOfInterest) -> Void
        weak var mapView: MapView?
        var annotationManager: PointAnnotationManager?

        private var renderedPlaceIDs: [UUID] = []
        private var renderedRouteID: UUID?
        private var didInitialCenter = false
        private var lastRecenterID = 0

        private let routeSourceID = "navi-route-source"
        private let routeLayerID = "navi-route-layer"

        init(onSelect: @escaping (PointOfInterest) -> Void) {
            self.onSelect = onSelect
        }

        // MARK: Annotations

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

        // MARK: Route

        func updateRoute(_ route: NavigationRoute?) {
            guard route?.id != renderedRouteID else { return }
            renderedRouteID = route?.id

            guard let mapView, let map = mapView.mapboxMap else { return }

            guard let route, route.waypoints.count > 1 else {
                removeRoute(from: map)
                return
            }

            let coordinates = route.waypoints.map(\.clCoordinate)
            let line = LineString(coordinates)

            do {
                if map.sourceExists(withId: routeSourceID) {
                    map.updateGeoJSONSource(withId: routeSourceID, geoJSON: .geometry(.lineString(line)))
                } else {
                    var source = GeoJSONSource(id: routeSourceID)
                    source.data = .geometry(.lineString(line))
                    try map.addSource(source)

                    var layer = LineLayer(id: routeLayerID, source: routeSourceID)
                    layer.lineColor = .constant(StyleColor(UIColor(AppColors.accent)))
                    layer.lineWidth = .constant(6)
                    layer.lineCap = .constant(.round)
                    layer.lineJoin = .constant(.round)
                    try map.addLayer(layer)
                }
            } catch {
                AppLogger.map.error("Failed to draw route: \(error.localizedDescription, privacy: .public)")
            }

            frameRoute(coordinates: coordinates, mapView: mapView)
        }

        private func removeRoute(from map: MapboxMap) {
            if map.layerExists(withId: routeLayerID) { try? map.removeLayer(withId: routeLayerID) }
            if map.sourceExists(withId: routeSourceID) { try? map.removeSource(withId: routeSourceID) }
        }

        private func frameRoute(coordinates: [CLLocationCoordinate2D], mapView: MapView) {
            guard let map = mapView.mapboxMap else { return }
            let padding = UIEdgeInsets(top: 80, left: 48, bottom: 220, right: 48)
            guard let camera = try? map.camera(
                for: coordinates,
                camera: CameraOptions(pitch: 0),
                coordinatesPadding: padding,
                maxZoom: nil,
                offset: nil
            ) else { return }
            mapView.camera.ease(to: camera, duration: 0.7)
        }

        // MARK: Camera follow / recenter

        func centerOnUserIfNeeded(_ userLocation: Coordinate?) {
            guard !didInitialCenter, let userLocation, let mapView else { return }
            didInitialCenter = true
            let camera = CameraOptions(
                center: userLocation.clCoordinate,
                zoom: 15.5,
                bearing: AppConfiguration.Map.defaultBearing,
                pitch: AppConfiguration.Map.defaultPitch
            )
            mapView.camera.ease(to: camera, duration: 0.7)
        }

        func handleRecenter(requestID: Int, userLocation: Coordinate?) {
            guard requestID != lastRecenterID else { return }
            lastRecenterID = requestID

            guard let mapView else { return }
            let center = (userLocation ?? AppConfiguration.Map.defaultCenter).clCoordinate
            let camera = CameraOptions(
                center: center,
                zoom: 15.5,
                bearing: AppConfiguration.Map.defaultBearing,
                pitch: AppConfiguration.Map.defaultPitch
            )
            mapView.camera.ease(to: camera, duration: 0.6)
        }
    }
}
