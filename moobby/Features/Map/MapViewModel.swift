//
//  MapViewModel.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

//
//  MapViewModel.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import MapKit
import Observation

enum CommuteScenarioMode: String, CaseIterable, Identifiable {
    case corridorIncidents = "Gangguan Rute (3 km)"
    case nearbyTransit = "Moda Sekitar (3 km)"
    var id: String { rawValue }
}

@MainActor @Observable
/// Runs the map's MapKit lookups: place search, and the address behind the user's dot.
///
/// ``MapView`` owns it with `@State`. Failures don't throw; they set ``errorMessage`` and ``isShowingError``
/// for the view's alert.
final class MapViewModel {
    /// The search text. Clearing it also clears ``results``.
    var query = "" {
        didSet { if query.isEmpty { results = [] } }
    }
    /// Places from the last search, shown as markers.
    private(set) var results: [MKMapItem] = []
    /// The place whose card is showing, e.g. the address under the user's dot.
    var selectedPlace: MKMapItem?
    /// A sentence for the user explaining the last failure.
    var errorMessage: String?
    /// Drives the error alert; set together with ``errorMessage``.
    var isShowingError = false

    // MARK: - Milestone 0B & Milestone 1 State
    let stations: [GreenLineStation] = GreenLineStation.all
    var activeMode: CommuteScenarioMode = .corridorIncidents
    var showCorridorRadiusCircle: Bool = true
    var selectedIncident: CorridorIncident?
    var selectedTransit: NearbyTransitPoint?

    static let maxRadiusMeters: CLLocationDistance = 3_000 // 3 km sesuai spesifikasi Milestone 1

    /// Skenario A: Menyaring berita yang berada dalam radius <= 3 km dari stasiun mana pun di sepanjang koridor Green Line
    var corridorIncidents: [CorridorIncident] {
        CorridorIncident.curatedSamples.filter { incident in
            let incLoc = CLLocation(latitude: incident.latitude, longitude: incident.longitude)
            return stations.contains { station in
                let stLoc = CLLocation(latitude: station.latitude, longitude: station.longitude)
                return incLoc.distance(from: stLoc) <= Self.maxRadiusMeters
            }
        }
    }

    /// Skenario B: Mencari titik transit/moda alternatif dalam radius <= 3 km dari posisi GPS pengguna saat ini
    func nearbyTransits(from userCoordinate: CLLocationCoordinate2D?) -> [NearbyTransitPoint] {
        guard let userCoordinate else { return [] }
        let userLoc = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)

        var matched: [NearbyTransitPoint] = []
        // 1. Cek titik transit multimoda sekitar
        for var point in NearbyTransitPoint.catalog {
            let ptLoc = CLLocation(latitude: point.latitude, longitude: point.longitude)
            let distMeters = userLoc.distance(from: ptLoc)
            if distMeters <= Self.maxRadiusMeters {
                point.straightLineDistanceKm = distMeters / 1000.0
                matched.append(point)
            }
        }
        // 2. Sertakan juga stasiun KRL Green Line yang masuk radius 3 km pengguna
        for station in stations {
            let stLoc = CLLocation(latitude: station.latitude, longitude: station.longitude)
            let distMeters = userLoc.distance(from: stLoc)
            if distMeters <= Self.maxRadiusMeters {
                matched.append(
                    NearbyTransitPoint(
                        id: "krl-\(station.id)",
                        name: station.name,
                        mode: "KRL Green Line",
                        routesInfo: "Lin Rangkasbitung ↔ Tanah Abang (Urutan #\(station.sequence))",
                        latitude: station.latitude,
                        longitude: station.longitude,
                        straightLineDistanceKm: distMeters / 1000.0
                    )
                )
            }
        }
        return matched.sorted { ($0.straightLineDistanceKm ?? 99) < ($1.straightLineDistanceKm ?? 99) }
    }

    // MARK: - Fungsi Pencarian Asli
    /// Searches around what's on screen; returns true when there are results to frame.
    func search(in region: MKCoordinateRegion?) async -> Bool {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let region { request.region = region }
        do {
            results = try await MKLocalSearch(request: request).start().mapItems
        } catch MKError.placemarkNotFound {
            results = []
            show("No places found for “\(query)”.")
        } catch {
            show("Search isn't available right now. Check your connection and try again.")
        }
        return !results.isEmpty
    }

    /// Looks up the address under a coordinate and opens MapKit's own place card for it.
    func showPlace(at coordinate: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return }
        do {
            selectedPlace = try await request.mapItems.first
        } catch {
            show("Can't find the address for your location right now.")
        }
    }

    private func show(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
}
