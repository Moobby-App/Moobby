//
//  NewsViewModel.swift
//  moobby
//
//  Iteration 2: state and logic for tab Berita.
//

import SwiftUI

/// The state of tab Berita: loading, the incidents, or an error.
///
/// ``NewsView`` owns it with `@State` and only draws what it says.
@Observable @MainActor
final class NewsViewModel {

    /// What tab Berita shows.
    enum State: Equatable {
        /// Waiting for incidents (Screens and States → Loading).
        case loading
        /// Incidents, newest first. Empty means "Belum ada informasi gangguan" (AC19).
        case loaded([Incident])
        /// Loading failed; the message is shown with a "Coba lagi" button (AC20).
        case failed(String)
    }

    /// How many incidents the tab shows before "Lihat semua berita" (SPEC Screens and States).
    static let previewLimit = 3

    /// What the tab shows now.
    private(set) var state: State = .loading

    private let container: AppContainer
    /// The route picked in tab Rute, if any.
    private let routeSelection: RouteSelection

    init(container: AppContainer, routeSelection: RouteSelection) {
        self.container = container
        self.routeSelection = routeSelection
    }

    /// Every loaded Green Line incident, newest first. Empty while loading or after an error.
    /// Semua Berita shows these (AC17).
    var incidents: [Incident] {
        if case .loaded(let incidents) = state { return incidents }
        return []
    }

    /// The picked route's title, such as `"Kebayoran – Cisauk"`, or `nil` before a route is picked.
    var routeTitle: String? {
        routeSelection.title
    }

    /// The incidents tab Berita is about: all of them before a route is picked, then only those on the
    /// route's segment (SPEC Rules → News relevance).
    ///
    /// Covers AC16 and AC28.
    var relevantIncidents: [Incident] {
        guard let segment = routeSelection.segment else { return incidents }
        return Incident.onSegment(incidents, segment: segment)
    }

    /// The cards on the tab: the newest ``previewLimit`` relevant incidents.
    ///
    /// Covers AC16.
    var latestIncidents: [Incident] {
        Array(relevantIncidents.prefix(Self.previewLimit))
    }

    /// The count label, such as `"3 berita"`: how many relevant incidents there are (AC28).
    var countLabel: String {
        "\(relevantIncidents.count) berita"
    }

    /// Loads incidents the first time the tab appears; later appearances keep what's there.
    func loadIfNeeded() async {
        guard case .loading = state else { return }
        await load()
    }

    /// Loads incidents through ``IncidentFeed``. Called again by "Coba lagi" and pull to refresh.
    ///
    /// Covers AC16, AC19 and AC20.
    func load() async {
        do {
            let incidents = try await IncidentFeed(container: container).load()
            state = .loaded(incidents)
        } catch {
            container.log.error("News failed to load: \(error)")
            state = .failed("Berita belum bisa dimuat. Periksa koneksi internet, lalu coba lagi.")
        }
    }
}
