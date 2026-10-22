//
//  Incident.swift
//  moobby
//
//  Iteration 2: a Green Line disruption, as the team backend sends it.
//

import SwiftUI

/// A KRL Green Line disruption from the team backend (`GET /api/v1/incidents`), or from placeholder JSON.
///
/// Field names match the backend README, so the JSON decodes without `CodingKeys`. Most fields are
/// optional because the backend can leave them empty. Iteration 1's ``CorridorIncident`` requires every
/// field, so it can't decode these responses (Decision 17).
struct Incident: Decodable, Identifiable, Hashable {
    /// A unique ID from the backend.
    let id: String
    /// The headline, in Indonesian.
    let title: String
    /// A short body for the news card and Detail Berita.
    ///
    /// The backend doesn't send one yet (SPEC open question 1), so only placeholder data fills it.
    let summary: String?
    /// The kind of disruption, such as `"service_disruption"`. Shown as text; don't assume a fixed set of values.
    let category: String
    /// Where it happened, such as a street or a station.
    let locationName: String?
    /// Latitude of ``locationName``, in degrees.
    let latitude: Double?
    /// Longitude of ``locationName``, in degrees.
    let longitude: Double?
    /// The ``GreenLineStation/id`` of the closest station, such as `"SDM"`. `nil` when the backend doesn't know it.
    ///
    /// Assumed to use the same codes as ``GreenLineStation/fullLine`` (SPEC open question 6).
    let nearestStationId: String?
    /// The closest station's name, as the backend sends it.
    let nearestStationName: String?
    /// Straight-line distance to the closest station, in kilometers.
    let distanceToStationKm: Double?
    /// When the source published it, as an ISO 8601 string. Read ``publishedDate`` to use it as a date.
    let publishedAt: String?
    /// Who reported it, such as a news site or KAI Commuter.
    let sourceName: String?
    /// `"verified"` for official operator sources; anything else is unverified. Read ``isVerified`` instead.
    let verificationStatus: String

    /// True when ``verificationStatus`` is `"verified"`.
    var isVerified: Bool {
        verificationStatus == "verified"
    }

    /// ``publishedAt`` as a date, with or without fractional seconds. `nil` when it's missing or not ISO 8601.
    var publishedDate: Date? {
        guard let publishedAt else { return nil }
        if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(publishedAt) {
            return date
        }
        return try? Date.ISO8601FormatStyle().parse(publishedAt)
    }
}

extension Incident {

    /// The incidents whose ``nearestStationId`` is a station in `segment`.
    ///
    /// Incidents outside the segment, or without a station, are left out.
    ///
    /// Covers AC9 and AC12.
    static func onSegment(_ incidents: [Incident], segment: [GreenLineStation]) -> [Incident] {
        let stationIDs = Set(segment.map(\.id))
        return incidents.filter { incident in
            guard let stationID = incident.nearestStationId else { return false }
            return stationIDs.contains(stationID)
        }
    }

    /// The stations in `segment` that have at least one incident, in segment order, each listed once.
    ///
    /// Two incidents at Sudimara make Sudimara appear once, so the banner says "1 stasiun terdampak"
    /// (Decision 6).
    ///
    /// Covers AC25.
    static func affectedStations(in segment: [GreenLineStation], incidents: [Incident]) -> [GreenLineStation] {
        let affectedIDs = Set(incidents.compactMap(\.nearestStationId))
        return segment.filter { affectedIDs.contains($0.id) }
    }

    /// `incidents` sorted newest first. Incidents without a readable ``publishedDate`` go last.
    ///
    /// Covers AC16 ("latest" incidents).
    static func newestFirst(_ incidents: [Incident]) -> [Incident] {
        incidents.sorted { lhs, rhs in
            switch (lhs.publishedDate, rhs.publishedDate) {
            case let (left?, right?):
                return left > right
            case (.some, .none):
                return true
            default:
                return false
            }
        }
    }
}

#if DEBUG
extension Incident {
    /// Hand-made incidents for previews only.
    static let previewSamples: [Incident] = [
        Incident(id: "p1", title: "Gangguan persinyalan di Sudimara", summary: "Perjalanan KRL tertahan sekitar 15 menit.",
                 category: "service_disruption", locationName: "Stasiun Sudimara", latitude: nil, longitude: nil,
                 nearestStationId: "SDM", nearestStationName: "Sudimara", distanceToStationKm: 0,
                 publishedAt: "2026-10-23T07:55:00+07:00", sourceName: "Contoh", verificationStatus: "verified"),
        Incident(id: "p2", title: "Antrean penumpang di Sudimara", summary: nil,
                 category: "incident", locationName: nil, latitude: nil, longitude: nil,
                 nearestStationId: "SDM", nearestStationName: "Sudimara", distanceToStationKm: nil,
                 publishedAt: "2026-10-23T08:10:00+07:00", sourceName: "Contoh", verificationStatus: "unverified"),
        Incident(id: "p3", title: "Perbaikan wesel di Cisauk", summary: nil,
                 category: "service_disruption", locationName: nil, latitude: nil, longitude: nil,
                 nearestStationId: "CSK", nearestStationName: "Cisauk", distanceToStationKm: nil,
                 publishedAt: "2026-10-23T07:30:00+07:00", sourceName: "Contoh", verificationStatus: "verified"),
        Incident(id: "p4", title: "Gangguan di Tanah Abang", summary: nil,
                 category: "service_disruption", locationName: nil, latitude: nil, longitude: nil,
                 nearestStationId: "THB", nearestStationName: "Tanah Abang", distanceToStationKm: nil,
                 publishedAt: nil, sourceName: "Contoh", verificationStatus: "verified"),
        Incident(id: "p5", title: "Kejadian tanpa stasiun", summary: nil,
                 category: "incident", locationName: nil, latitude: nil, longitude: nil,
                 nearestStationId: nil, nearestStationName: nil, distanceToStationKm: nil,
                 publishedAt: nil, sourceName: nil, verificationStatus: "unverified")
    ]
}

/// A visual check of the incident rules while there's no unit test target. Open the Canvas (⌥⌘↩).
#Preview("Incident rules check") {
    let kby = GreenLineStation.fullLine.first { $0.id == "KBY" }!
    let csk = GreenLineStation.fullLine.first { $0.id == "CSK" }!
    let segment = GreenLineStation.segment(from: kby, to: csk)
    let onSegment = Incident.onSegment(Incident.previewSamples, segment: segment)
    let affected = Incident.affectedStations(in: segment, incidents: onSegment)

    List {
        Section("Di segmen Kebayoran → Cisauk (harus 3)") {
            ForEach(onSegment) { Text($0.title) }
        }
        Section("Stasiun terdampak (harus Sudimara, Cisauk)") {
            ForEach(affected) { Text($0.name) }
        }
        Section("Banner") {
            Text("\(affected.count) stasiun terdampak")
        }
        Section("Terbaru dulu (harus p2, p1, p3, lalu tanpa waktu)") {
            ForEach(Incident.newestFirst(onSegment)) { Text("\($0.id) · \($0.title)") }
        }
    }
}
#endif
