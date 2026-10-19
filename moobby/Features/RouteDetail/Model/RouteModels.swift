//
//  RouteModels.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI
import CoreLocation

extension Color {
    /// KRL Green Line brand color, #5DBB63, for the timeline rail and the map polyline.
    static let greenLine = Color(red: 0x5D / 255, green: 0xBB / 255, blue: 0x63 / 255)
    /// The incident marker on the expanded rail, #E8504A.
    static let incidentRed = Color(red: 0xE8 / 255, green: 0x50 / 255, blue: 0x4A / 255)
}

/// What a station is to the route: where it starts or where it ends.
enum StationRole: Hashable {
    case departure, arrival

    /// The small label above the station name.
    var label: String {
        switch self {
        case .departure: "Berangkat dari"
        case .arrival: "Tujuan"
        }
    }
}

/// One row of the route timeline in ``RouteDetailView``.
enum RouteStep: Hashable {
    /// Walking to the first station, in straight-line meters.
    case walk(distanceMeters: Int)
    /// A station the route starts or ends at.
    case station(role: StationRole, station: GreenLineStation)
    /// Riding the Green Line. `stations` are in travel order and include both ends.
    case leg(stations: [GreenLineStation], isExpanded: Bool)

    /// The Green Line route from `origin` to `destination`, in either direction.
    ///
    /// Starts with a walk step when `walkMeters` is given. Returns no steps when they're the same station.
    static func route(from origin: GreenLineStation, to destination: GreenLineStation, walkMeters: Int? = nil) -> [RouteStep] {
        guard origin != destination else { return [] }
        let range = min(origin.sequence, destination.sequence)...max(origin.sequence, destination.sequence)
        var stations = GreenLineStation.all.filter { range.contains($0.sequence) }
        if origin.sequence > destination.sequence { stations.reverse() }
        return (walkMeters.map { [.walk(distanceMeters: $0)] } ?? []) + [
            .station(role: .departure, station: origin),
            .leg(stations: stations, isExpanded: false),
            .station(role: .arrival, station: destination)
        ]
    }
}

/// How a leg is doing, from the incidents near its stations. Ordered by severity: `.clear < .caution < .disrupted`.
enum LegStatus: Comparable {
    /// No incident near this leg's stations. Not proof that it's safe, only that nothing was reported.
    case clear
    /// Something nearby that may slow the trip: an unverified report, or an event around the line.
    case caution
    /// A verified ``CorridorIncident`` with category `"service_disruption"`: the train service itself is affected.
    case disrupted

    /// Badge and marker color: red for a verified service disruption, orange for caution.
    var tint: Color {
        switch self {
        case .disrupted: .incidentRed
        case .caution: .orange
        case .clear: Color(red: 0x3F / 255, green: 0x9B / 255, blue: 0x48 / 255)
        }
    }

    /// Darker text on the gray incident cards: dark red, dark amber, or dark green.
    var titleColor: Color {
        switch self {
        case .disrupted: Color(red: 0x8B / 255, green: 0x1A / 255, blue: 0x12 / 255)
        case .caution: Color(red: 0x8A / 255, green: 0x5A / 255, blue: 0x00 / 255)
        case .clear: Color(red: 0x2E / 255, green: 0x6B / 255, blue: 0x34 / 255)
        }
    }
}

/// One row of an expanded leg, built by ``RouteStatusLogic/timelineRows(stations:incidents:)``.
enum TimelineRow: Identifiable, Equatable {
    /// A station on the leg. `number` is its 1-based position in the trip.
    case station(GreenLineStation, number: Int)
    /// A marker on the rail between `after` and `before`: the most severe incident there, and the rest, most severe first.
    case incident(main: CorridorIncident, others: [CorridorIncident], after: GreenLineStation, before: GreenLineStation)

    var id: String {
        switch self {
        case .station(let station, _): "station-\(station.id)"
        case .incident(let main, _, _, _): "incident-\(main.id)"
        }
    }
}
