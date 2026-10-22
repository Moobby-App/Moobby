//
//  RouteConditionViewModel.swift
//  moobby
//
//  Iteration 2: state and logic for Kondisi Rute.
//

import SwiftUI

/// Kondisi Rute for one segment: each station's estimated time and its incidents.
///
/// ``RouteConditionView`` owns it with `@State` and only draws what it says.
@Observable @MainActor
final class RouteConditionViewModel {

    /// One station on the timeline.
    struct StationStatus: Identifiable, Equatable {
        let station: GreenLineStation
        /// Estimated arrival from `schedule.json`; `nil` if the schedule is missing.
        let estimatedTime: Date?
        /// This station's incidents, newest first. Empty means not affected.
        let incidents: [Incident]

        var id: String { station.id }

        /// At least one incident belongs to this station (SPEC Rules).
        var isAffected: Bool { !incidents.isEmpty }
    }

    /// What Kondisi Rute shows.
    enum State: Equatable {
        case loading
        case loaded([StationStatus])
        case failed(String)
    }

    let departure: GreenLineStation
    let destination: GreenLineStation

    /// What the screen shows now.
    private(set) var state: State = .loading

    private let container: AppContainer

    init(container: AppContainer, departure: GreenLineStation, destination: GreenLineStation) {
        self.container = container
        self.departure = departure
        self.destination = destination
    }

    /// The header's second line, such as `"Kebayoran – Cisauk"`.
    var routeTitle: String {
        "\(departure.shortName) – \(destination.shortName)"
    }

    /// The timeline, in travel order. Empty while loading or after an error.
    var stations: [StationStatus] {
        if case .loaded(let stations) = state { return stations }
        return []
    }

    /// How many stations in the segment are affected; two incidents at one station count once.
    ///
    /// Covers AC25.
    var affectedCount: Int {
        stations.filter(\.isAffected).count
    }

    /// The banner text, such as `"2 stasiun terdampak"`. `nil` when no station is affected (AC11).
    var bannerText: String? {
        affectedCount > 0 ? "\(affectedCount) stasiun terdampak" : nil
    }

    /// Loads the first time the screen appears.
    func loadIfNeeded() async {
        guard case .loading = state else { return }
        await load()
    }

    /// Builds the timeline: the segment, each station's estimated time, and the incidents on it.
    ///
    /// Covers AC1, AC9, AC10, AC11, AC12, AC24 and AC25.
    func load() async {
        let segment = GreenLineStation.segment(from: departure, to: destination)
        do {
            let allIncidents = try await IncidentFeed(container: container).load()
            let onSegment = Incident.onSegment(allIncidents, segment: segment)
            let times = (try? container.localData.schedule())?
                .estimatedTimes(for: segment, departingAt: .now) ?? [:]

            state = .loaded(segment.map { station in
                StationStatus(
                    station: station,
                    estimatedTime: times[station.id],
                    incidents: onSegment.filter { $0.nearestStationId == station.id }
                )
            })
        } catch {
            container.log.error("Route condition failed to load: \(error)")
            state = .failed("Kondisi rute belum bisa dimuat. Periksa koneksi internet, lalu coba lagi.")
        }
    }
}
