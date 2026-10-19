//
//  RouteStatusLogic.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import CoreLocation

/// What ``RouteStatusLogic/report(forLeg:incidents:)`` found for one leg.
struct LegReport: Equatable {
    /// The worst status among ``main`` and ``others``; `.clear` when there are none.
    let status: LegStatus
    /// The most severe incident, shown as the leg's card. `nil` when the leg is clear.
    let main: CorridorIncident?
    /// The rest, most severe first, behind the "+N laporan lain" row.
    let others: [CorridorIncident]
}

/// The pure rules behind ``RouteDetailView``: how bad a leg is, and what to take instead.
enum RouteStatusLogic {
    /// Unverified reports and non-service incidents count as caution within this distance of a station.
    static let cautionRadiusKm = 1.0
    /// Alternatives must be within this straight-line distance of the disrupted station.
    static let alternativeRadiusKm = 2.5
    /// How many alternatives to suggest.
    static let maxAlternatives = 3

    /// How much one incident affects a leg: `.disrupted` for a verified service disruption,
    /// `.caution` for anything else within ``cautionRadiusKm``, `.clear` when it's farther out.
    static func status(of incident: CorridorIncident) -> LegStatus {
        if incident.isVerified && incident.category == "service_disruption" { return .disrupted }
        return incident.distanceToStationKm <= cautionRadiusKm ? .caution : .clear
    }

    /// Rates a leg from the incidents whose ``CorridorIncident/nearestStationId`` is one of its stations.
    ///
    /// Incidents at other stations are ignored, and so are ones rated `.clear`, so a clear leg never
    /// shows a card for a report it decided doesn't matter.
    static func report(forLeg stationIds: [String], incidents: [CorridorIncident]) -> LegReport {
        let ranked = incidents
            .filter { stationIds.contains($0.nearestStationId) && status(of: $0) > .clear }
            .sorted {
                let (a, b) = (status(of: $0), status(of: $1))
                return a != b ? a > b : $0.distanceToStationKm < $1.distanceToStationKm
            }
        guard let main = ranked.first else { return LegReport(status: .clear, main: nil, others: []) }
        return LegReport(status: status(of: main), main: main, others: Array(ranked.dropFirst()))
    }

    /// The expanded leg: a row per station, and each station's incidents as a marker right after it
    /// (right before it for the last station, so the marker stays on the rail). Incidents off the leg are ignored.
    static func timelineRows(stations: [GreenLineStation], incidents: [CorridorIncident]) -> [TimelineRow] {
        guard stations.count > 1 else { return [] }
        var rows: [TimelineRow] = []
        for (index, station) in stations.enumerated() {
            let report = report(forLeg: [station.id], incidents: incidents)
            let isLast = index == stations.count - 1
            let marker = report.main.map {
                TimelineRow.incident(
                    main: $0,
                    others: report.others,
                    after: isLast ? stations[index - 1] : station,
                    before: isLast ? station : stations[index + 1]
                )
            }
            if isLast, let marker { rows.append(marker) }
            rows.append(.station(station, number: index + 1))
            if !isLast, let marker { rows.append(marker) }
        }
        return rows
    }

    /// The marker card's title for a ``CorridorIncident/category``.
    static func categoryLabel(_ category: String) -> String {
        category == "service_disruption" ? "Gangguan Layanan" : "Kecelakaan"
    }

    /// Other ways to travel from the station of `incident`, nearest first, using ``MapViewModel/nearbyTransits(from:)``.
    @MainActor
    static func alternatives(for incident: CorridorIncident, model: MapViewModel) -> [NearbyTransitPoint] {
        guard let station = GreenLineStation.all.first(where: { $0.id == incident.nearestStationId }) else { return [] }
        return filterAlternatives(model.nearbyTransits(from: station.coordinate))
    }

    /// Keeps points within ``alternativeRadiusKm`` that aren't on the Green Line, nearest first,
    /// up to ``maxAlternatives``.
    static func filterAlternatives(_ points: [NearbyTransitPoint]) -> [NearbyTransitPoint] {
        let kept = points.filter { point in
            // `krl-` IDs are the Green Line stations nearbyTransits(from:) adds.
            let isOnLine = point.id.hasPrefix("krl-") || point.mode.localizedCaseInsensitiveContains("KRL")
            return !isOnLine && (point.straightLineDistanceKm ?? .infinity) <= alternativeRadiusKm
        }
        return Array(kept.sorted { ($0.straightLineDistanceKm ?? .infinity) < ($1.straightLineDistanceKm ?? .infinity) }
            .prefix(maxAlternatives))
    }

    /// The SF Symbol for a free-text ``NearbyTransitPoint/mode``.
    static func symbol(forMode mode: String) -> String {
        let rules: [(String, String)] = [
            ("transjakarta", "bus.fill"),
            ("mrt", "tram.fill"),
            ("krl", "tram.fill"),
            ("shuttle", "bus"),
            ("bsd link", "bus"),
            ("angkot", "car.fill")
        ]
        return rules.first { mode.localizedCaseInsensitiveContains($0.0) }?.1 ?? "mappin.circle.fill"
    }

    /// `"± 0.4 km (garis lurus)"`: straight-line distance, labelled so it isn't read as walking distance.
    static func distanceLabel(km: Double) -> String {
        String(format: "± %.1f km (garis lurus)", km)
    }

    /// The real track between the first and last of `stations`, for the map.
    static func path(_ stations: [GreenLineStation]) -> [CLLocationCoordinate2D] {
        guard let first = stations.first, let last = stations.last else { return [] }
        let track = GreenLineTrack.coordinates
        // ponytail: nearest track point by squared degrees; fine at Jakarta's latitude and station spacing.
        func nearest(_ c: CLLocationCoordinate2D) -> Int {
            track.indices.min {
                pow(track[$0].latitude - c.latitude, 2) + pow(track[$0].longitude - c.longitude, 2)
                    < pow(track[$1].latitude - c.latitude, 2) + pow(track[$1].longitude - c.longitude, 2)
            } ?? 0
        }
        let (a, b) = (nearest(first.coordinate), nearest(last.coordinate))
        return Array(track[min(a, b)...max(a, b)])
    }

    /// The stations either side of `stationId` within the leg, for the red dashed overlay on the map.
    static func disruptedStations(around stationId: String, in stations: [GreenLineStation]) -> [GreenLineStation] {
        guard let index = stations.firstIndex(where: { $0.id == stationId }) else { return [] }
        return Array(stations[max(index - 1, 0)...min(index + 1, stations.count - 1)])
    }

    /// The station nearest `coordinate`, and the straight-line walk to it in meters.
    static func nearestStation(to coordinate: CLLocationCoordinate2D) -> (station: GreenLineStation, meters: Int)? {
        let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return GreenLineStation.all
            .map { ($0, Int(here.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)))) }
            .min { $0.1 < $1.1 }
    }
}
