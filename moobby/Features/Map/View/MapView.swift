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

    // Matches Apple Maps' default local view: ~1 km across on iPhone, showing the nearby station, streets and landmarks.
    private static let localSpan: CLLocationDistance = 1_000
    // Approximate location is only accurate to a few km, so a neighbourhood view would be misleading.
    private static let approximateSpan: CLLocationDistance = 10_000

    var body: some View {
        Map(position: $camera) {
            if tracker.isApproximate {
                // MapKit's default draws the approximate-area circle instead of claiming a precise dot.
                // It isn't tappable either, since the address under an approximate fix would be a guess.
                UserAnnotation()
            } else {
                UserAnnotation {
                    // Annotations stay upright on screen, so offset the heading by the map's rotation.
                    Button(action: showCurrentPlace) {
                        LocationIndicator(heading: tracker.heading.map { $0 - cameraHeading })
                    }
                    .buttonStyle(.plain)
                }
            }
            if tracker.route.count > 1 {
                MapPolyline(coordinates: tracker.route)
                    .stroke(.blue, lineWidth: 5)
            }
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
        // Until the first fix, MapKit can only show a country-wide view, so show nothing rather than mislead.
        .overlay {
            if isWaitingForFirstFix {
                Rectangle().fill(.background).ignoresSafeArea()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            MapControls(showsTraffic: $showsTraffic, canRecenter: tracker.location != nil, recenter: recenter)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                LocationStatusView(tracker: tracker)
                MapSearchBar(query: $model.query, search: search)
            }
        }
        .onAppear {
            tracker.activate()
            updateHeadingOrientation()
        }
        .onDisappear { tracker.deactivate() }
        // No title on this screen, so the map runs edge to edge instead of under an empty bar.
        .toolbarVisibility(.hidden, for: .navigationBar)
        .mapItemDetailSheet(item: $model.selectedPlace, displaysMap: false)
        .alert(model.errorMessage ?? "", isPresented: $model.isShowingError) { }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateHeadingOrientation()
        }
        .onChange(of: tracker.location != nil, initial: true) { frameUserOnce() }
    }

    // Frames the user once, without animation so the map opens ready to use; after that the camera is the user's.
    private func frameUserOnce() {
        guard !hasFramedUser, let region = localRegion else { return }
        hasFramedUser = true
        camera = .region(region)
    }

    // MapUserLocationButton zooms to MapKit's own follow distance, so recenter to the same local view instead.
    private func recenter() {
        if let region = localRegion {
            withAnimation { camera = .region(region) }
        }
    }

    // Frames the results alongside the user once they arrive.
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

    // Denied, restricted or unavailable fall through to the plain map, with the status banner explaining why.
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
        // Face up / down carry no screen direction; keep the last real orientation.
        let orientation = UIDevice.current.orientation
        guard orientation.isPortrait || orientation.isLandscape,
              let clOrientation = CLDeviceOrientation(rawValue: Int32(orientation.rawValue)) else { return }
        tracker.setHeadingOrientation(clOrientation)
    }
}
