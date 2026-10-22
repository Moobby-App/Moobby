//
//  IncidentFeed.swift
//  moobby
//
//  Iteration 2: where the app's incidents come from.
//

import SwiftUI

/// Where ``IncidentFeed`` reads incidents from.
enum IncidentSource {
    /// `incidents.json` in the app bundle, through ``AppContainer/localData``.
    case placeholder
    /// The team backend, through ``GetIncidentsRequest`` and ``AppContainer/api``.
    case backend
}

/// Loads incidents for the Berita and Rute tabs, from placeholder JSON or from the backend.
///
/// Both tabs use this instead of choosing a source themselves, so switching to the real backend is a
/// one-line change to ``defaultSource`` (plus the URL in ``APIConfig/baseURL``).
///
/// ```swift
/// let incidents = try await IncidentFeed(container: container).load()
/// ```
///
/// > Important: This branch uses ``IncidentSource/placeholder`` because the backend URL is a temporary
/// > tunnel and still returns `[]` (Decisions 13 and 24). With ``IncidentSource/backend``, an empty list
/// > stays empty (AC19) and a network failure throws (AC20); there's no silent fallback to placeholder data.
struct IncidentFeed {
    /// The source every tab uses. Change it to `.backend` once ``APIConfig/baseURL`` points at the team backend.
    static let defaultSource: IncidentSource = .placeholder

    /// Shared services; provides ``AppContainer/localData`` and ``AppContainer/api``.
    let container: AppContainer
    /// Where to read from. Defaults to ``defaultSource``.
    var source: IncidentSource = IncidentFeed.defaultSource

    /// Every Green Line incident from ``source``, newest first.
    ///
    /// - Throws: A decoding or file error for placeholder data; an ``APIError`` or `URLError` for the backend.
    func load() async throws -> [Incident] {
        let incidents: [Incident]
        switch source {
        case .placeholder:
            incidents = try container.localData.incidents()
        case .backend:
            incidents = try await container.api.execute(GetIncidentsRequest())
        }
        return Incident.newestFirst(incidents)
    }
}

#if DEBUG
/// A visual check of the request URL and the feed. Open the Canvas (⌥⌘↩).
#Preview("Incident feed check") {
    @Previewable @State var lines: [String] = []

    List {
        Section("URL request (path harus /api/v1/incidents?limit=20&offset=0)") {
            Text((try? makeURL(for: GetIncidentsRequest()).absoluteString) ?? "URL tidak valid")
        }
        Section("IncidentFeed, sumber placeholder (harus 4, terbaru dulu: KBY, PLM, SDM, CSK)") {
            ForEach(lines, id: \.self) { Text($0) }
        }
    }
    .task {
        do {
            let incidents = try await IncidentFeed(container: AppContainer()).load()
            lines = incidents.map { "\($0.nearestStationId ?? "-") · \($0.title)" }
        } catch {
            lines = ["Error: \(error)"]
        }
    }
}
#endif
