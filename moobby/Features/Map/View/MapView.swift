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

struct MapView: View {
    let tracker: LocationTrackerViewModel
    @State private var model = MapViewModel()
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var cameraHeading: CLLocationDirection = 0
    @State private var hasFramedUser = false
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var showsTraffic = false

    private static let localSpan: CLLocationDistance = 1_000
    private static let approximateSpan: CLLocationDistance = 10_000

    private var nearbyTransitList: [NearbyTransitPoint] {
        model.nearbyTransits(from: tracker.location)
    }

    var body: some View {
        Map(position: $camera) {
            // 1. Anotasi Lokasi Pengguna (Kode Asli Teman Anda)
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

            // 2. Jejak Perjalanan Pengguna
            if tracker.route.count > 1 {
                MapPolyline(coordinates: tracker.route)
                    .stroke(.blue, lineWidth: 5)
            }

            // 3. MILESTONE 0B: Garis Koridor & Stasiun KRL Green Line
            MapPolyline(coordinates: model.stations.map(\.coordinate))
                .stroke(.green, lineWidth: 4)

            if model.showCorridorRadiusCircle {
                if model.activeMode == .corridorIncidents {
                    // Skenario A: Radius 3 km di sepanjang stasiun koridor Green Line
                    ForEach(model.stations) { station in
                        MapCircle(center: station.coordinate, radius: MapViewModel.maxRadiusMeters)
                            .foregroundStyle(.green.opacity(0.05))
                            .stroke(.green.opacity(0.25), lineWidth: 1)
                    }
                } else if let userCoord = tracker.location {
                    // Skenario B: Radius 3 km berpusat pada posisi GPS pengguna saat ini
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

            // 4. MILESTONE 1 (Skenario A): Pin Berita/Gangguan Koridor 3 km
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

            // 5. MILESTONE 1 (Skenario B): Pin Moda/Titik Transit dalam Radius 3 km Pengguna
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

            // 6. Hasil Pencarian MKLocalSearch
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
                milestoneCarouselPanel
                LocationStatusView(tracker: tracker)
                MapSearchBar(query: $model.query, search: search)
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
        .alert(model.errorMessage ?? "", isPresented: $model.isShowingError) { }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateHeadingOrientation()
        }
        .onChange(of: tracker.location != nil, initial: true) { frameUserOnce() }
    }

    // MARK: - Subviews untuk Milestone 0B & Milestone 1
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
                }
                Spacer()
                Button("Lihat Koridor") {
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

            Picker("Mode Skenario", selection: $model.activeMode) {
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
                                    Text(incident.isVerified ? "Terverifikasi" : "Info Sekitar (Belum Terverifikasi)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(incident.isVerified ? .red : .orange)
                                    Spacer()
                                    Text("\(String(format: "%.2f", incident.distanceToStationKm)) km dr \(incident.nearestStationId)")
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
                        Text("Tidak ada titik transit terdata dalam radius 3 km dari posisi Anda saat ini. Coba arahkan lokasi Simulator ke area stasiun Green Line.")
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
                                            Text("\(String(format: "%.2f", dist)) km (garis lurus)")
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

    private func incidentDetailSheet(_ incident: CorridorIncident) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text(incident.isVerified ? "GANGGUAN OPERASIONAL TERVERIFIKASI" : "KEJADIAN SEKITAR KORIDOR (BELUM TERVERIFIKASI)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(incident.isVerified ? .red : .orange)

                Text(incident.title)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Lokasi: \(incident.locationName)", systemImage: "mappin.and.ellipse")
                    Label("Stasiun Terdekat: \(incident.nearestStationName) (\(String(format: "%.2f", incident.distanceToStationKm)) km garis lurus)", systemImage: "tram.fill")
                    Label("Waktu: \(incident.publishedAt)", systemImage: "clock")
                    Label("Sumber: \(incident.sourceName)", systemImage: "newspaper")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                Text(incident.isVerified
                     ? "Informasi ini berasal dari sumber operasional dan berdampak langsung pada perjalanan KRL Green Line."
                     : "Kejadian ini berada dalam koridor ≤ 3 km rute Green Line. Kedekatan geografis belum tentu menghentikan operasional kereta, namun dapat memengaruhi akses di sekitar stasiun.")
                    .font(.footnote)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding()
            .navigationTitle("Detail Kejadian Rute")
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
                    Label("Layanan / Rute: \(transit.routesInfo)", systemImage: "bus.fill")
                    if let dist = transit.straightLineDistanceKm {
                        Label("Jarak Garis Lurus: \(String(format: "%.2f", dist)) km dari posisi Anda", systemImage: "ruler")
                    }
                    Label("Jarak Berjalan Kaki: Belum tersedia pada prototype ini", systemImage: "figure.walk")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                Text("Catatan Prototype: Jarak yang ditampilkan adalah jarak garis lurus (straight-line distance) dalam radius ≤ 3 km dari lokasi pengguna, bukan jarak rute berjalan kaki aktual.")
                    .font(.footnote)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding()
            .navigationTitle("Detail Titik Transit")
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
