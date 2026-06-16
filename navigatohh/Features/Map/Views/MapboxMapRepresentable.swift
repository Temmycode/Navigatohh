//
//  MapboxMapRepresentable.swift
//  navigatohh
//
//  Bridges a Mapbox `MapView` into SwiftUI. The Mapbox Standard style ships with 3D
//  buildings and lighting, so a pitched camera is all that's needed for the 3D look.
//
//  Responsibilities:
//   - render our seed POI annotations (tap -> onSelect)
//   - make the style's BUILT-IN POIs tappable via the Interactions API (tap -> onSelect)
//   - draw the active route as a line layer and frame it
//   - show a selection marker + optionally focus the camera on the selected place
//   - center on the user the first time a location fix arrives; recenter on demand
//
//  Note: the `.standardPoi` featureset is `@_spi(Experimental)` in this SDK version.
//

import SwiftUI
import MapboxMaps
@_spi(Experimental) import MapboxMaps
import OSLog

struct MapboxMapRepresentable: UIViewRepresentable {
    var places: [PointOfInterest]
    var userLocation: Coordinate?
    var route: NavigationRoute?
    var recenterRequestID: Int
    var selectedCoordinate: Coordinate?
    var selectionFocusID: Int
    var onSelect: (PointOfInterest) -> Void
    var onDeselect: () -> Void

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

        let coordinator = context.coordinator
        coordinator.mapView = mapView
        coordinator.annotationManager = mapView.annotations.makePointAnnotationManager()
        coordinator.selectionManager = mapView.annotations.makeCircleAnnotationManager()

        // Interactions are evaluated in reverse registration order, so register the catch-all
        // map tap FIRST (lowest priority) and the POI tap LAST. A tap on a built-in POI is
        // handled by the POI interaction (returns true, stops propagation); a tap on empty map
        // falls through to the catch-all and clears the selection — like Google Maps.
        if let map = mapView.mapboxMap {
            coordinator.mapTapToken = map.addInteraction(
                TapInteraction { [weak coordinator] _ in
                    coordinator?.onDeselect()
                    return false
                }
            )
            coordinator.interactionToken = map.addInteraction(
                TapInteraction(.standardPoi) { [weak coordinator] feature, _ in
                    guard let coordinator else { return false }
                    let place = PointOfInterest.transient(
                        name: feature.name ?? "Selected place",
                        coordinate: feature.coordinate.coordinate,
                        category: PlaceCategory(mapboxClass: feature.maki, maki: feature.group)
                    )
                    coordinator.onSelect(place)
                    return true
                }
            )
        }

        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onSelect = onSelect
        coordinator.onDeselect = onDeselect
        coordinator.render(places: places)
        coordinator.updateRoute(route)
        coordinator.updateSelectionMarker(selectedCoordinate)
        coordinator.centerOnUserIfNeeded(userLocation)
        coordinator.handleRecenter(requestID: recenterRequestID, userLocation: userLocation)
        coordinator.handleSelectionFocus(id: selectionFocusID, coordinate: selectedCoordinate)
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator {
        var onSelect: (PointOfInterest) -> Void
        var onDeselect: () -> Void = {}
        weak var mapView: MapView?
        var annotationManager: PointAnnotationManager?
        var selectionManager: CircleAnnotationManager?
        var interactionToken: Cancelable?
        var mapTapToken: Cancelable?

        private var renderedPlaceIDs: [UUID] = []
        private var renderedRouteID: UUID?
        private var renderedSelection: Coordinate?
        private var didInitialCenter = false
        private var lastRecenterID = 0
        private var lastSelectionFocusID = 0

        private let routeSourceID = "navi-route-source"
        private let routeLayerID = "navi-route-layer"

        init(onSelect: @escaping (PointOfInterest) -> Void) {
            self.onSelect = onSelect
        }

        // MARK: Seed annotations

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

        // MARK: Selection marker

        func updateSelectionMarker(_ coordinate: Coordinate?) {
            guard coordinate != renderedSelection else { return }
            renderedSelection = coordinate

            guard let selectionManager else { return }
            guard let coordinate else {
                selectionManager.annotations = []
                return
            }
            var circle = CircleAnnotation(centerCoordinate: coordinate.clCoordinate)
            circle.circleRadius = 9
            circle.circleColor = StyleColor(UIColor(AppColors.accent))
            circle.circleStrokeWidth = 3
            circle.circleStrokeColor = StyleColor(UIColor.white)
            selectionManager.annotations = [circle]
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

        // MARK: Camera follow / recenter / focus

        func centerOnUserIfNeeded(_ userLocation: Coordinate?) {
            guard !didInitialCenter, let userLocation, let mapView else { return }
            didInitialCenter = true
            mapView.camera.ease(to: cameraOptions(for: userLocation), duration: 0.7)
        }

        func handleRecenter(requestID: Int, userLocation: Coordinate?) {
            guard requestID != lastRecenterID else { return }
            lastRecenterID = requestID
            guard let mapView else { return }
            let center = userLocation ?? AppConfiguration.Map.defaultCenter
            mapView.camera.ease(to: cameraOptions(for: center), duration: 0.6)
        }

        func handleSelectionFocus(id: Int, coordinate: Coordinate?) {
            guard id != lastSelectionFocusID else { return }
            lastSelectionFocusID = id
            guard let coordinate, let mapView else { return }
            mapView.camera.ease(to: cameraOptions(for: coordinate, zoom: 16), duration: 0.6)
        }

        private func cameraOptions(for coordinate: Coordinate, zoom: Double = 15.5) -> CameraOptions {
            CameraOptions(
                center: coordinate.clCoordinate,
                zoom: zoom,
                bearing: AppConfiguration.Map.defaultBearing,
                pitch: AppConfiguration.Map.defaultPitch
            )
        }
    }
}
