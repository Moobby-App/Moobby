//
//  RouteSelectionViewModel.swift
//  moobby
//
//  Iteration 2: state and logic for Pilih Rute Perjalanan.
//

import SwiftUI

/// Picking a departure and a destination station on tab Rute.
///
/// Both fields start empty every time the app opens; nothing is saved (Decision 5). Once both stations
/// are picked, ``path`` gets Kondisi Rute pushed onto it.
@Observable @MainActor
final class RouteSelectionViewModel {

    /// Which search field the station list fills.
    enum Field: Hashable {
        case departure
        case destination
    }

    /// The tab's navigation stack. ``RouteSelectionView`` binds its `NavigationStack` to it.
    var path: [RouteScreen] = []

    /// The field the user is typing in; the list filters by its text.
    var activeField: Field = .departure

    /// Text in "cari stasiun keberangkatan".
    private(set) var departureQuery = ""
    /// Text in "cari stasiun tujuan".
    private(set) var destinationQuery = ""

    /// The picked departure station, if any.
    private(set) var departure: GreenLineStation?
    /// The picked destination station, if any.
    private(set) var destination: GreenLineStation?

    /// Every station, in line order. 17 of 20 until Cikoya, Tenjo and Jatake are added.
    private let allStations = GreenLineStation.fullLine

    /// The stations matching the active field's text, in line order. All of them when the text is empty.
    ///
    /// Matching ignores case and accents and skips the "Stasiun " prefix, so "jurang" finds Jurangmangu.
    ///
    /// Covers AC21 (all stations, in order) and AC22 (filter while typing).
    var visibleStations: [GreenLineStation] {
        let query = (activeField == .departure ? departureQuery : destinationQuery)
            .trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return allStations }
        return allStations.filter { $0.shortName.localizedStandardContains(query) }
    }

    /// Whether `station` can't be picked: the departure station can't also be the destination (Decision 20).
    func isDisabled(_ station: GreenLineStation) -> Bool {
        activeField == .destination && station.id == departure?.id
    }

    /// Updates a field's text. Typing over a picked station clears that pick.
    func setQuery(_ text: String, for field: Field) {
        switch field {
        case .departure:
            departureQuery = text
            if text != departure?.shortName { departure = nil }
        case .destination:
            destinationQuery = text
            if text != destination?.shortName { destination = nil }
        }
    }

    /// Picks `station` for the active field, moves to the other field, and opens Kondisi Rute once both
    /// stations are picked.
    ///
    /// Covers AC23.
    func select(_ station: GreenLineStation) {
        guard !isDisabled(station) else { return }

        switch activeField {
        case .departure:
            departure = station
            departureQuery = station.shortName
            if destination?.id == station.id {
                destination = nil
                destinationQuery = ""
            }
            activeField = .destination
        case .destination:
            destination = station
            destinationQuery = station.shortName
        }

        if let departure, let destination {
            path = [.condition(departure: departure, destination: destination)]
        }
    }
}
