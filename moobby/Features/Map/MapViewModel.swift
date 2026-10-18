//
//  MapViewModel.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import MapKit
import Observation

/// Which Green Line question the map is answering. The raw value is the segmented control's label.
enum CommuteScenarioMode: String, CaseIterable, Identifiable {
    /// Scenario A: what's happening within 3 km of the line. Shows ``CorridorIncident`` pins and a 3 km circle per station.
    case corridorIncidents = "Route Disruptions (3 km)"
    /// Scenario B: other ways to travel within 3 km of the user. Shows ``NearbyTransitPoint`` pins and a 3 km circle around the user.
    case nearbyTransit = "Nearby Modes (3 km)"
    var id: String { rawValue }
}

/// Runs the map's MapKit lookups, place search and the address behind the user's dot, and the Green Line scenarios.
///
/// ``MapView`` owns it with `@State`. Failures don't throw; they set ``errorMessage`` and ``isShowingError``
/// for the view's alert.
@MainActor @Observable
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
    /// The Green Line stations to draw, from ``GreenLineStation/all``.
    let stations: [GreenLineStation] = GreenLineStation.all
    /// The scenario picked in the header; decides which pins and circles show.
    var activeMode: CommuteScenarioMode = .corridorIncidents
    /// Whether to draw the 3 km circles for ``activeMode``.
    var showCorridorRadiusCircle: Bool = true
    /// The incident whose detail sheet is showing.
    var selectedIncident: CorridorIncident?
    /// The transit stop whose detail sheet is showing.
    var selectedTransit: NearbyTransitPoint?

    /// How far "near" reaches, for both scenarios: 3 km, measured in a straight line.
    static let maxRadiusMeters: CLLocationDistance = 3_000 // 3 km per Milestone 1 spec

    /// Scenario A: the ``CorridorIncident/curatedSamples`` within ``maxRadiusMeters`` of any station.
    ///
    /// Distance is measured to stations, not to the track, so an incident beside the line midway between
    /// two stations far apart can be left out.
    var corridorIncidents: [CorridorIncident] {
        CorridorIncident.curatedSamples.filter { incident in
            let incLoc = CLLocation(latitude: incident.latitude, longitude: incident.longitude)
            return stations.contains { station in
                let stLoc = CLLocation(latitude: station.latitude, longitude: station.longitude)
                return incLoc.distance(from: stLoc) <= Self.maxRadiusMeters
            }
        }
    }

    /// Scenario B: transit stops and Green Line stations within ``maxRadiusMeters`` of the user, nearest first.
    ///
    /// Each result has ``NearbyTransitPoint/straightLineDistanceKm`` set. Stations come back as
    /// `NearbyTransitPoint`s with the mode `"KRL Green Line"`.
    ///
    /// ```swift
    /// // Standing at Stasiun Kebayoran:
    /// let nearby = model.nearbyTransits(from: CLLocationCoordinate2D(latitude: -6.2373, longitude: 106.7825))
    /// // Stasiun Kebayoran (0.00 km), Halte Pasar Kebayoran Lama (0.12 km),
    /// // Halte TransJakarta Velbak (0.26 km), Stasiun MRT ASEAN (1.78 km)
    /// ```
    ///
    /// - Parameter userCoordinate: Where the user is. Returns an empty array when `nil`.
    func nearbyTransits(from userCoordinate: CLLocationCoordinate2D?) -> [NearbyTransitPoint] {
        guard let userCoordinate else { return [] }
        let userLoc = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)

        var matched: [NearbyTransitPoint] = []
        // 1. Check nearby multimodal transit points
        for var point in NearbyTransitPoint.catalog {
            let ptLoc = CLLocation(latitude: point.latitude, longitude: point.longitude)
            let distMeters = userLoc.distance(from: ptLoc)
            if distMeters <= Self.maxRadiusMeters {
                point.straightLineDistanceKm = distMeters / 1000.0
                matched.append(point)
            }
        }
        // 2. Also include KRL Green Line stations within 3 km of the user
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

    // MARK: - Original Search Functions
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

