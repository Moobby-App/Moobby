//
//  LocalData.swift
//  moobby
//
//  Iteration 2: placeholder data bundled with the app as JSON.
//

import SwiftUI

/// Reads the prototype's local data: placeholder incidents, TransJakarta stops, and the travel schedule.
///
/// Get it from ``AppContainer/localData``; previews and tests can pass their own.
protocol LocalDataProviding {
    /// Placeholder incidents, used while the backend returns an empty list (SPEC Constraints → Data).
    func incidents() throws -> [Incident]
    /// TransJakarta stops connected to Green Line stations.
    func transJakartaStops() throws -> [TransJakartaStop]
    /// The placeholder travel schedule.
    func schedule() throws -> TravelSchedule
}

/// Why ``BundledJSONData`` couldn't read a file.
enum LocalDataError: Error {
    /// The JSON file isn't in the app bundle. Check it's under `moobby/` and run `xcodegen generate`.
    case missingFile(String)
}

/// Reads `incidents.json`, `transjakarta_stops.json` and `schedule.json` from the app bundle.
///
/// The files live in `moobby/Resources/PlaceholderData/`. XcodeGen bundles everything under `moobby/`,
/// so they're copied into the app without changes to `project.yml`.
///
/// > Note: Replace these files when the backend sends real data (SPEC open questions 9 and 10).
final class BundledJSONData: LocalDataProviding {
    private let bundle: Bundle
    private let decoder = JSONDecoder()

    /// - Parameter bundle: Where the JSON files are. Defaults to the app bundle.
    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func incidents() throws -> [Incident] {
        try load("incidents")
    }

    func transJakartaStops() throws -> [TransJakartaStop] {
        try load("transjakarta_stops")
    }

    func schedule() throws -> TravelSchedule {
        try load("schedule")
    }

    /// Decodes `name.json` from ``bundle``.
    private func load<T: Decodable>(_ name: String) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw LocalDataError.missingFile("\(name).json")
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }
}

#if DEBUG
/// The lines the "Placeholder data check" preview shows. Kept outside `#Preview` because the macro
/// doesn't allow a `let` to be set in both `do` and `catch`.
private func placeholderCheckLines() -> (incidents: [String], stops: [String], times: [String]) {
    let data = BundledJSONData()
    let kby = GreenLineStation.fullLine.first { $0.id == "KBY" }!
    let csk = GreenLineStation.fullLine.first { $0.id == "CSK" }!
    let segment = GreenLineStation.segment(from: kby, to: csk)
    let departure = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!

    do {
        let incidents = try data.incidents().map { "\($0.nearestStationId ?? "-") · \($0.title)" }
        let stops = try data.transJakartaStops().map { "\($0.stationId) · \($0.name)" }
        let times = try data.schedule().estimatedTimes(for: segment, departingAt: departure)
        let timeLines = segment.map { station in
            let time = times[station.id]?.formatted(date: .omitted, time: .shortened) ?? "-"
            return "\(time) · \(station.name)"
        }
        return (incidents, stops, timeLines)
    } catch {
        return (["Error: \(error)"], [], [])
    }
}

/// A visual check that the JSON files are bundled and decode. Open the Canvas (⌥⌘↩).
#Preview("Placeholder data check") {
    let lines = placeholderCheckLines()

    List {
        Section("incidents.json (harus 4)") {
            ForEach(lines.incidents, id: \.self) { Text($0) }
        }
        Section("transjakarta_stops.json (harus 5)") {
            ForEach(lines.stops, id: \.self) { Text($0) }
        }
        Section("schedule.json: Kebayoran 08.00 → Cisauk (harus 08.24)") {
            ForEach(lines.times, id: \.self) { Text($0) }
        }
    }
}
#endif
