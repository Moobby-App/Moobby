//
//  MapView.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

//
//  MapView.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import SwiftUI
import MapKit

/// The Map tab: the user's dot and heading, the route, search, traffic, and a status banner when location isn't available.
///
/// It starts and stops `tracker` with its own visibility, and keeps search and place lookups in a ``MapViewModel``.
/// The camera frames the user once, on the first fix; after that it stays where the user leaves it.
struct MapView: View {
    /// Location state, owned by ``ContentView``.
    let tracker: LocationTrackerViewModel
    @State private var model = MapViewModel()
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var cameraHeading: CLLocationDirection = 0
    @State private var hasFramedUser = false
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var showsTraffic = false
    @State private var listSheet: ListSheet?

    /// The list sheets opened from the buttons above the carousel.
    private enum ListSheet: String, Identifiable {
        case routeDisruption = "Route Disruption"
        case nearbyModes = "Nearby Modes"
        var id: Self { self }
    }

    private static let localSpan: CLLocationDistance = 1_000
    private static let approximateSpan: CLLocationDistance = 10_000

    private var nearbyTransitList: [NearbyTransitPoint] {
        model.nearbyTransits(from: tracker.location)
    }

    var body: some View {
        Map(position: $camera) {
            // 1. User Location Annotation (Original code from your teammate)
            if tracker.isApproximate {
                UserAnnotation()
            } else {
                UserAnnotation {
                    Button(action: showCurrentPlace) {
                        LocationIndicator(heading: tracker.heading.map { $0 - cameraHeading })
                    }
                    .buttonStyle(.plain)
                }
            }

            // 2. User Route Polyline
            if tracker.route.count > 1 {
                MapPolyline(coordinates: tracker.route)
                    .stroke(.blue, lineWidth: 5)
            }

            // 3. MILESTONE 0B: Corridor Line & KRL Green Line Stations
            // The real track from OpenStreetMap, not straight lines between stations.
            MapPolyline(coordinates: GreenLineTrack.coordinates)
                .stroke(.green, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

            if model.showCorridorRadiusCircle {
                if model.activeMode == .corridorIncidents {
                    // Scenario A: 3 km radius around each station along the Green Line corridor
                    ForEach(model.stations) { station in
                        MapCircle(center: station.coordinate, radius: MapViewModel.maxRadiusMeters)
                            .foregroundStyle(.green.opacity(0.05))
                            .stroke(.green.opacity(0.25), lineWidth: 1)
                    }
                } else if let userCoord = tracker.location {
                    // Scenario B: 3 km radius centered on the user's current GPS position
                    MapCircle(center: userCoord, radius: MapViewModel.maxRadiusMeters)
                        .foregroundStyle(.blue.opacity(0.08))
                        .stroke(.blue.opacity(0.4), lineWidth: 1.5)
                }
            }

            ForEach(model.stations) { station in
                Annotation(station.name, coordinate: station.coordinate) {
                    VStack(spacing: 2) {
                        Image(systemName: "tram.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Color.green)
                            .clipShape(Circle())
                        Text(station.id)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }

            // 4. MILESTONE 1 (Scenario A): Pins for News/Disruptions within the 3 km corridor
            ForEach(model.corridorIncidents) { incident in
                Annotation(incident.locationName, coordinate: incident.coordinate) {
                    Button {
                        model.selectedIncident = incident
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: incident.isVerified ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text(incident.nearestStationId)
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(incident.isVerified ? Color.red : Color.orange)
                        .clipShape(Capsule())
                        .shadow(radius: 2)
                    }
                }
            }

            // 5. MILESTONE 1 (Scenario B): Pins for Modes/Transit Points within 3 km of the user
            if model.activeMode == .nearbyTransit {
                ForEach(nearbyTransitList) { transit in
                    Annotation(transit.name, coordinate: transit.coordinate) {
                        Button {
                            model.selectedTransit = transit
                        } label: {
                            Image(systemName: "bus.fill")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                    }
                }
            }

            // 6. MKLocalSearch Results
            ForEach(model.results, id: \.self) { Marker(item: $0) }
        }
        .mapStyle(.standard(pointsOfInterest: .all, showsTraffic: showsTraffic))
        .mapControls {
            MapCompass()
        }
        .onMapCameraChange(frequency: .continuous) {
            cameraHeading = $0.camera.heading
            visibleRegion = $0.region
        }
        .overlay {
            if isWaitingForFirstFix {
                Rectangle().fill(.background).ignoresSafeArea()
            }
        }
        .overlay(alignment: .top) {
            greenLineHeaderBar
        }
        .overlay(alignment: .bottomTrailing) {
            MapControls(showsTraffic: $showsTraffic, canRecenter: tracker.location != nil, recenter: recenter)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                HStack {
                    Button(ListSheet.routeDisruption.rawValue, systemImage: "exclamationmark.triangle.fill") {
                        listSheet = .routeDisruption
                    }
                    Button(ListSheet.nearbyModes.rawValue, systemImage: "bus.fill") {
                        listSheet = .nearbyModes
                    }
                }
                .buttonStyle(.glass)
                milestoneCarouselPanel
                LocationStatusView(tracker: tracker)
//                MapSearchBar(query: $model.query, search: search)
            }
        }
        .onAppear {
            tracker.activate()
            updateHeadingOrientation()
        }
        .onDisappear { tracker.deactivate() }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .mapItemDetailSheet(item: $model.selectedPlace, displaysMap: false)
        .sheet(item: $model.selectedIncident) { incident in
            incidentDetailSheet(incident)
        }
        .sheet(item: $model.selectedTransit) { transit in
            transitDetailSheet(transit)
        }
        .sheet(item: $listSheet) { sheet in
            listSheetContent(sheet)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
        .alert(model.errorMessage ?? "", isPresented: $model.isShowingError) { }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateHeadingOrientation()
        }
        .onChange(of: tracker.location != nil, initial: true) { frameUserOnce() }
    }

    // MARK: - Subviews for Milestone 0B & Milestone 1
    private var greenLineHeaderBar: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("KRL Green Line")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("Tanah Abang ↔ Rangkasbitung")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    // Required by the ODbL for the track geometry in GreenLineTrack.
                    Link("Track © OpenStreetMap contributors",
                         destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("View Corridor") {
                    withAnimation {
                        camera = .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: -6.2650, longitude: 106.7200),
                                span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.22)
                            )
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.mini)
            }

            Picker("Scenario Mode", selection: $model.activeMode) {
                ForEach(CommuteScenarioMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var milestoneCarouselPanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if model.activeMode == .corridorIncidents {
                    ForEach(model.corridorIncidents) { incident in
                        Button {
                            withAnimation {
                                camera = .region(
                                    MKCoordinateRegion(
                                        center: incident.coordinate,
                                        latitudinalMeters: 1_500,
                                        longitudinalMeters: 1_500
                                    )
                                )
                            }
                            model.selectedIncident = incident
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(incident.isVerified ? "Verified" : "Nearby Info (Unverified)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(incident.isVerified ? .red : .orange)
                                    Spacer()
                                    Text("\(String(format: "%.2f", incident.distanceToStationKm)) km from \(incident.nearestStationId)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Text(incident.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Text(incident.sourceName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .frame(width: 260, alignment: .leading)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                } else {
                    if nearbyTransitList.isEmpty {
                        Text("No transit points found within 3 km of your current position. Try setting the Simulator's location near a Green Line station.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(10)
                            .frame(width: 300, alignment: .leading)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ForEach(nearbyTransitList) { transit in
                            Button {
                                withAnimation {
                                    camera = .region(
                                        MKCoordinateRegion(
                                            center: transit.coordinate,
                                            latitudinalMeters: 1_200,
                                            longitudinalMeters: 1_200
                                        )
                                    )
                                }
                                model.selectedTransit = transit
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(transit.mode)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.blue)
                                        Spacer()
                                        if let dist = transit.straightLineDistanceKm {
                                            Text("\(String(format: "%.2f", dist)) km (straight-line)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Text(transit.name)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(transit.routesInfo)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(10)
                                .frame(width: 250, alignment: .leading)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    /// Same layout as `SheetContent` in ``SheetsDemoView``: a title, the body, and a Done button.
    private func listSheetContent(_ sheet: ListSheet) -> some View {
        NavigationStack {
            List {
                switch sheet {
                case .routeDisruption:
                    ForEach(model.corridorIncidents) { incident in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(incident.isVerified ? "Verified" : "Nearby Info (Unverified)")
                                .typography(.caption)
                                .foregroundStyle(incident.isVerified ? .red : .orange)
                            Text(incident.title)
                                .typography(.body)
                            Text("\(incident.locationName) · \(String(format: "%.2f", incident.distanceToStationKm)) km from \(incident.nearestStationId)")
                                .typography(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                case .nearbyModes:
                    if nearbyTransitList.isEmpty {
                        Text("No transit points found within 3 km of your current position.")
                            .typography(.body)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(nearbyTransitList) { transit in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transit.mode)
                                .typography(.caption)
                                .foregroundStyle(.blue)
                            Text(transit.name)
                                .typography(.body)
                            Text(transit.routesInfo)
                                .typography(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(sheet.rawValue)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { listSheet = nil }
                }
            }
        }
    }

    private func incidentDetailSheet(_ incident: CorridorIncident) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text(incident.isVerified ? "VERIFIED OPERATIONAL DISRUPTION" : "CORRIDOR-ADJACENT INCIDENT (UNVERIFIED)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(incident.isVerified ? .red : .orange)

                Text(incident.title)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Location: \(incident.locationName)", systemImage: "mappin.and.ellipse")
                    Label("Nearest Station: \(incident.nearestStationName) (\(String(format: "%.2f", incident.distanceToStationKm)) km straight-line)", systemImage: "tram.fill")
                    Label("Time: \(incident.publishedAt)", systemImage: "clock")
                    Label("Source: \(incident.sourceName)", systemImage: "newspaper")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                Text(incident.isVerified
                     ? "This information comes from operational sources and directly impacts KRL Green Line service."
                     : "This incident falls within ≤ 3 km of the Green Line route. Geographic proximity doesn't always stop train operations, but it can affect access around stations.")
                    .font(.footnote)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding()
            .navigationTitle("Route Incident Details")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private func transitDetailSheet(_ transit: NearbyTransitPoint) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text(transit.mode.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)

                Text(transit.name)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Service / Routes: \(transit.routesInfo)", systemImage: "bus.fill")
                    if let dist = transit.straightLineDistanceKm {
                        Label("Straight-Line Distance: \(String(format: "%.2f", dist)) km from your position", systemImage: "ruler")
                    }
                    Label("Walking Distance: Not available in this prototype", systemImage: "figure.walk")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                Text("Prototype Note: The distance shown is straight-line distance within ≤ 3 km of the user's location, not the actual walking route distance.")
                    .font(.footnote)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding()
            .navigationTitle("Transit Point Details")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private func frameUserOnce() {
        guard !hasFramedUser, let region = localRegion else { return }
        hasFramedUser = true
        camera = .region(region)
    }

    private func recenter() {
        if let region = localRegion {
            withAnimation { camera = .region(region) }
        }
    }

    private func search() {
        Task {
            if await model.search(in: visibleRegion) {
                withAnimation { camera = .automatic }
            }
        }
    }

    private func showCurrentPlace() {
        guard let coordinate = tracker.location else { return }
        Task { await model.showPlace(at: coordinate) }
    }

    private var isWaitingForFirstFix: Bool {
        guard !hasFramedUser else { return false }
        return switch tracker.access {
        case .unknown: true
        case .allowed: !tracker.isLocationUnavailable
        default: false
        }
    }

    private var localRegion: MKCoordinateRegion? {
        guard let coordinate = tracker.location else { return nil }
        let span = tracker.isApproximate ? Self.approximateSpan : Self.localSpan
        return MKCoordinateRegion(center: coordinate, latitudinalMeters: span, longitudinalMeters: span)
    }

    private func updateHeadingOrientation() {
        let orientation = UIDevice.current.orientation
        guard orientation.isPortrait || orientation.isLandscape,
              let clOrientation = CLDeviceOrientation(rawValue: Int32(orientation.rawValue)) else { return }
        tracker.setHeadingOrientation(clOrientation)
    }
}

