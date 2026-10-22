//
//  GreenLineStation+FullLine.swift
//  moobby
//
//  Iteration 2: every station on the Green Line, and the segment between two of them.
//

import SwiftUI

/// The full KRL Green Line for iteration 2, and the segment between two stations.
///
/// Iteration 1's ``GreenLineStation/all`` lists 12 stations for its map. Iteration 2 needs every station
/// on the line, so this list lives in its own file and leaves `all` untouched.
extension GreenLineStation {

    /// Every station on the line, in the order of the spec's station list: Rangkasbitung first, Tanah Abang last.
    ///
    /// Each ``sequence`` still counts from Tanah Abang (1), as ``GreenLineStation`` documents.
    /// Codes and coordinates come from ``all`` and from Wikipedia.
    ///
    /// > Important: Cikoya (17), Tenjo (15) and Jatake (11) are missing until the backend developer
    /// > confirms their codes and coordinates (SPEC open question 8). Their sequence numbers are kept
    /// > free so nothing shifts when they're added.
    ///
    /// Covers AC21 (17 of 20 stations for now).
    static let fullLine: [GreenLineStation] = [
        GreenLineStation(id: "RK",  name: "Stasiun Rangkasbitung",  sequence: 20, latitude: -6.3524, longitude: 106.2517),
        GreenLineStation(id: "CTR", name: "Stasiun Citeras",        sequence: 19, latitude: -6.3349, longitude: 106.3326),
        GreenLineStation(id: "MJ",  name: "Stasiun Maja",           sequence: 18, latitude: -6.3314, longitude: 106.3958),
        // TODO: Cikoya (sequence 17), waiting for code and coordinates from the backend.
        GreenLineStation(id: "TGS", name: "Stasiun Tigaraksa",      sequence: 16, latitude: -6.3283, longitude: 106.4347),
        // TODO: Tenjo (sequence 15), waiting for code and coordinates from the backend.
        GreenLineStation(id: "DAR", name: "Stasiun Daru",           sequence: 14, latitude: -6.3381, longitude: 106.4925),
        GreenLineStation(id: "CJT", name: "Stasiun Cilejit",        sequence: 13, latitude: -6.3544, longitude: 106.5096),
        GreenLineStation(id: "PRP", name: "Stasiun Parung Panjang", sequence: 12, latitude: -6.3444, longitude: 106.5694),
        // TODO: Jatake (sequence 11), waiting for code and coordinates from the backend.
        GreenLineStation(id: "CC",  name: "Stasiun Cicayur",        sequence: 10, latitude: -6.3314, longitude: 106.6192),
        GreenLineStation(id: "CSK", name: "Stasiun Cisauk",         sequence: 9,  latitude: -6.3247, longitude: 106.6414),
        GreenLineStation(id: "SRP", name: "Stasiun Serpong",        sequence: 8,  latitude: -6.3204, longitude: 106.6653),
        GreenLineStation(id: "RU",  name: "Stasiun Rawa Buntu",     sequence: 7,  latitude: -6.3149, longitude: 106.6766),
        GreenLineStation(id: "SDM", name: "Stasiun Sudimara",       sequence: 6,  latitude: -6.2966, longitude: 106.7126),
        GreenLineStation(id: "JMU", name: "Stasiun Jurangmangu",    sequence: 5,  latitude: -6.2891, longitude: 106.7292),
        GreenLineStation(id: "PDJ", name: "Stasiun Pondok Ranji",   sequence: 4,  latitude: -6.2764, longitude: 106.7447),
        GreenLineStation(id: "KBY", name: "Stasiun Kebayoran",      sequence: 3,  latitude: -6.2373, longitude: 106.7825),
        GreenLineStation(id: "PLM", name: "Stasiun Palmerah",       sequence: 2,  latitude: -6.2072, longitude: 106.7972),
        GreenLineStation(id: "THB", name: "Stasiun Tanah Abang",    sequence: 1,  latitude: -6.1857, longitude: 106.8108)
    ]

    /// The stations from `departure` to `destination`, inclusive, in travel order.
    ///
    /// Works in both directions (Decision 19): Kebayoran → Cisauk and Cisauk → Kebayoran both return
    /// the stations in the order the user passes them. Returns an empty array if either station isn't
    /// in ``fullLine``.
    ///
    /// ```swift
    /// let kby = GreenLineStation.fullLine.first { $0.id == "KBY" }!
    /// let csk = GreenLineStation.fullLine.first { $0.id == "CSK" }!
    /// GreenLineStation.segment(from: kby, to: csk).map(\.id)
    /// // ["KBY", "PDJ", "JMU", "SDM", "RU", "SRP", "CSK"]
    /// ```
    ///
    /// Covers AC1 (stations in order) and is the segment AC9 and AC12 filter incidents by.
    static func segment(from departure: GreenLineStation, to destination: GreenLineStation) -> [GreenLineStation] {
        guard
            let start = fullLine.firstIndex(where: { $0.id == departure.id }),
            let end = fullLine.firstIndex(where: { $0.id == destination.id })
        else {
            return []
        }

        if start <= end {
            return Array(fullLine[start...end])
        } else {
            return Array(fullLine[end...start].reversed())
        }
    }
}

#if DEBUG
/// A quick visual check of ``GreenLineStation/segment(from:to:)`` while there's no unit test target.
/// Open the Canvas (⌥⌘↩) to see it.
#Preview("Segment check") {
    let kby = GreenLineStation.fullLine.first { $0.id == "KBY" }!
    let csk = GreenLineStation.fullLine.first { $0.id == "CSK" }!

    List {
        Section("Jumlah stasiun di fullLine") {
            Text("\(GreenLineStation.fullLine.count) (target 20, 3 menunggu backend)")
        }
        Section("Kebayoran → Cisauk") {
            ForEach(GreenLineStation.segment(from: kby, to: csk)) { Text($0.name) }
        }
        Section("Cisauk → Kebayoran") {
            ForEach(GreenLineStation.segment(from: csk, to: kby)) { Text($0.name) }
        }
    }
}
#endif
