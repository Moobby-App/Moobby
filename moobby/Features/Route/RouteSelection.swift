//
//  RouteSelection.swift
//  moobby
//
//  Iteration 2: the route the user picked, shared by tab Rute and tab Berita.
//

import SwiftUI

/// The departure and destination the user picked in this session, shared between tabs.
///
/// ``ContentView`` creates one with `@State` and passes it to both tabs: tab Rute writes it, tab Berita
/// reads it to show only news on the route (AC28). It isn't saved, so it's empty every time the app opens
/// (Decision 5), and it isn't in ``AppContainer`` because it's session state, not a service (Decision 15).
@Observable @MainActor
final class RouteSelection {

    /// The picked departure station, or `nil` until both stations are picked.
    private(set) var departure: GreenLineStation?
    /// The picked destination station, or `nil` until both stations are picked.
    private(set) var destination: GreenLineStation?

    init() {}

    /// The picked segment in travel order, or `nil` when no route is picked.
    var segment: [GreenLineStation]? {
        guard let departure, let destination else { return nil }
        return GreenLineStation.segment(from: departure, to: destination)
    }

    /// `"Kebayoran – Cisauk"`, or `nil` when no route is picked.
    var title: String? {
        guard let departure, let destination else { return nil }
        return "\(departure.shortName) – \(destination.shortName)"
    }

    /// Records a picked route.
    func set(departure: GreenLineStation, destination: GreenLineStation) {
        self.departure = departure
        self.destination = destination
    }

    /// Forgets the route, for example when the user clears a station field.
    func clear() {
        departure = nil
        destination = nil
    }
}
