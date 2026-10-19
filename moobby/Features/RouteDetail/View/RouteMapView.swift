//
//  RouteMapView.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI
import MapKit

/// The map drawn under ``RouteMapView``.
enum BaseMapStyle: String, CaseIterable, Identifiable {
    /// Apple Maps.
    case apple = "Apple Maps"
    /// OpenStreetMap tiles; needs the visible "© OpenStreetMap contributors" credit.
    case openStreetMap = "OpenStreetMap"
    /// The bundled `krl-map` schematic, opened in its own sheet.
    case krlSchematic = "Peta KRL"
    var id: Self { self }
}

/// The ``RouteDetailView`` legs on a map: one line per leg, a red dashed overlay where it's disrupted,
/// incident pins, and the suggested alternatives.
///
/// SwiftUI's `Map` can't show tile overlays, so this wraps `MKMapView`.
struct RouteMapView: View {
    let legs: [LegSummary]
    /// The pin to center on and select.
    let selectedID: String?
    /// Called with the pin's ID when the user selects one.
    let onSelectPin: (String) -> Void

    @State private var style: BaseMapStyle = .apple
    @State private var showsSchematic = false

    var body: some View {
        RouteMKMapView(legs: legs, selectedID: selectedID, usesOpenStreetMap: style == .openStreetMap, onSelectPin: onSelectPin)
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .topTrailing) {
                Menu {
                    Picker("Peta dasar", selection: styleSelection) {
                        ForEach(BaseMapStyle.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Image(systemName: "map")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Peta dasar")
                .padding()
            }
            .overlay(alignment: .bottomTrailing) {
                // The Green Line track comes from OpenStreetMap, so the credit shows on every style.
                Link("© OpenStreetMap contributors", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.85), in: .rect(cornerRadius: 4))
                    .padding(8)
            }
            .sheet(isPresented: $showsSchematic) {
                SchematicMapSheet()
            }
    }

    /// Picking the schematic opens its sheet and keeps the current map underneath.
    private var styleSelection: Binding<BaseMapStyle> {
        Binding {
            style
        } set: { newStyle in
            if newStyle == .krlSchematic { showsSchematic = true } else { style = newStyle }
        }
    }
}

// MARK: - MKMapView

private struct RouteMKMapView: UIViewRepresentable {
    let legs: [LegSummary]
    let selectedID: String?
    let usesOpenStreetMap: Bool
    let onSelectPin: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.overrideUserInterfaceStyle = .light

        var transitIDs: Set<String> = []
        for leg in legs {
            let line = RoutePolyline(path: RouteStatusLogic.path(leg.stations))
            line.color = UIColor(.greenLine)
            map.addOverlay(line, level: .aboveLabels)

            if leg.report.status == .disrupted, let main = leg.report.main {
                let stations = RouteStatusLogic.disruptedStations(around: main.nearestStationId, in: leg.stations)
                let disrupted = RoutePolyline(path: RouteStatusLogic.path(stations))
                disrupted.color = .systemRed
                disrupted.isDashed = true
                map.addOverlay(disrupted, level: .aboveLabels)
            }
            for incident in [leg.report.main].compactMap({ $0 }) + leg.report.others {
                map.addAnnotation(RouteAnnotation(
                    id: incident.id,
                    title: incident.locationName,
                    coordinate: incident.coordinate,
                    symbol: "exclamationmark.triangle.fill",
                    tint: incident.category == "service_disruption" ? .systemRed : .systemOrange
                ))
            }
            for transit in leg.alternatives where transitIDs.insert(transit.id).inserted {
                map.addAnnotation(RouteAnnotation(
                    id: transit.id,
                    title: transit.name,
                    coordinate: transit.coordinate,
                    symbol: RouteStatusLogic.symbol(forMode: transit.mode),
                    tint: .systemBlue
                ))
            }
        }

        let bounds = map.overlays.reduce(MKMapRect.null) { $0.union($1.boundingMapRect) }
        if !bounds.isNull {
            map.setVisibleMapRect(bounds, edgePadding: UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40), animated: false)
        }
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.onSelectPin = onSelectPin
        context.coordinator.showTiles(usesOpenStreetMap, on: map)
        context.coordinator.focus(selectedID, on: map)
    }

    @MainActor
    final class Coordinator: NSObject, MKMapViewDelegate {
        var onSelectPin: (String) -> Void = { _ in }
        private var tiles: MKTileOverlay?
        private var focusedID: String?

        func showTiles(_ isShown: Bool, on map: MKMapView) {
            guard isShown != (tiles != nil) else { return }
            if let tiles {
                map.removeOverlay(tiles)
                self.tiles = nil
            } else {
                let overlay = MKTileOverlay(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png")
                overlay.canReplaceMapContent = true
                // Below the route lines, which sit at .aboveLabels.
                map.addOverlay(overlay, level: .aboveRoads)
                tiles = overlay
            }
        }

        func focus(_ id: String?, on map: MKMapView) {
            guard id != focusedID else { return }
            focusedID = id
            guard let id, let pin = map.annotations.lazy.compactMap({ $0 as? RouteAnnotation }).first(where: { $0.id == id }) else { return }
            map.setRegion(MKCoordinateRegion(center: pin.coordinate, latitudinalMeters: 2_000, longitudinalMeters: 2_000), animated: true)
            map.selectAnnotation(pin, animated: true)
        }

        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            // Skip the selection focus(_:on:) just made itself.
            guard let pin = annotation as? RouteAnnotation, pin.id != focusedID else { return }
            focusedID = pin.id
            onSelectPin(pin.id)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tiles = overlay as? MKTileOverlay { return MKTileOverlayRenderer(tileOverlay: tiles) }
            guard let line = overlay as? RoutePolyline else { return MKOverlayRenderer(overlay: overlay) }
            let renderer = MKPolylineRenderer(polyline: line)
            renderer.strokeColor = line.color
            renderer.lineWidth = line.isDashed ? 4 : 6
            renderer.lineDashPattern = line.isDashed ? [6, 6] : nil
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pin = annotation as? RouteAnnotation else { return nil }
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "route") as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: pin, reuseIdentifier: "route")
            view.annotation = pin
            view.glyphImage = UIImage(systemName: pin.symbol)
            view.markerTintColor = pin.tint
            view.displayPriority = .required
            return view
        }
    }
}

private final class RoutePolyline: MKPolyline {
    var color: UIColor = .systemGreen
    var isDashed = false

    convenience init(path: [CLLocationCoordinate2D]) {
        self.init(coordinates: path, count: path.count)
    }
}

private final class RouteAnnotation: NSObject, MKAnnotation {
    /// A ``CorridorIncident/id`` or ``NearbyTransitPoint/id``.
    let id: String
    let title: String?
    let coordinate: CLLocationCoordinate2D
    let symbol: String
    let tint: UIColor

    init(id: String, title: String, coordinate: CLLocationCoordinate2D, symbol: String, tint: UIColor) {
        self.id = id
        self.title = title
        self.coordinate = coordinate
        self.symbol = symbol
        self.tint = tint
    }
}

// MARK: - Schematic

/// The bundled `krl-map` asset, pinch to zoom.
private struct SchematicMapSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 1
    @State private var settledZoom: CGFloat = 1

    var body: some View {
        NavigationStack {
            Group {
                if let image = UIImage(named: "krl-map") {
                    GeometryReader { geometry in
                        ScrollView([.horizontal, .vertical]) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width * zoom)
                                .accessibilityLabel("Peta skematik KRL")
                        }
                        .gesture(
                            MagnifyGesture()
                                .onChanged { zoom = min(max(settledZoom * $0.magnification, 1), 4) }
                                .onEnded { _ in settledZoom = zoom }
                        )
                    }
                } else {
                    ContentUnavailableView(
                        "Peta KRL belum tersedia",
                        systemImage: "map",
                        description: Text("Tambahkan aset \"krl-map\" ke Assets.xcassets.")
                    )
                }
            }
            .navigationTitle(BaseMapStyle.krlSchematic.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RouteDetailView(origin: GreenLineStation.all[6], destination: GreenLineStation.all[0], walkMeters: 213)
    }
}
