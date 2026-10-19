//
//  RouteDetailView.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI

/// One leg of the route with its ``LegReport`` and suggested alternatives, shared by the timeline and the map.
struct LegSummary: Identifiable {
    /// The leg's index in the route's steps.
    let id: Int
    let stations: [GreenLineStation]
    let report: LegReport
    /// Other ways to travel from every incident's station on the leg, for the map's pins. Empty when the leg is clear.
    let alternatives: [NearbyTransitPoint]
}

/// A Green Line route as a vertical timeline, with live incidents per leg and alternatives when a leg is disrupted.
///
/// The ``Tab/map`` tab shows the same legs, incidents, and alternatives on ``RouteMapView``. Selecting a card
/// recenters the map on it; selecting a pin switches back and scrolls to its card.
struct RouteDetailView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case timeline = "Timeline"
        case map = "Peta"
        var id: Self { self }
    }

    @State private var steps: [RouteStep]
    let incidents: [CorridorIncident]

    @State private var model = MapViewModel()
    @State private var tab: Tab = .timeline
    /// The incident or transit point focused in both tabs: a ``CorridorIncident/id`` or ``NearbyTransitPoint/id``.
    @State private var selectedID: String?
    /// Legs, by step index, whose "+N laporan lain" list is open.
    @State private var expandedOthers: Set<Int> = []
    /// Caution incidents, by ``CorridorIncident/id``, whose alternatives were revealed.
    @State private var revealedAlternatives: Set<String> = []
    /// Markers on an expanded leg, by ``TimelineRow/id``, whose "+N laporan lain" list is open.
    @State private var openMarkers: Set<String> = []
    /// The incident whose ``IncidentDetailSheet`` is showing.
    @State private var detailIncident: CorridorIncident?

    /// - Parameter walkMeters: The straight-line walk to `origin`; `nil` leaves the walk step out.
    init(
        origin: GreenLineStation,
        destination: GreenLineStation,
        walkMeters: Int? = nil,
        incidents: [CorridorIncident] = CorridorIncident.curatedSamples
    ) {
        _steps = State(initialValue: RouteStep.route(from: origin, to: destination, walkMeters: walkMeters))
        self.incidents = incidents
    }

    var body: some View {
        let legs = legSummaries
        VStack(spacing: 0) {
            Picker("Tampilan", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            switch tab {
            case .timeline:
                timeline(legs)
            case .map:
                RouteMapView(legs: legs, selectedID: selectedID) { id in
                    reveal(id, in: legs)
                    selectedID = id
                    tab = .timeline
                }
            }
        }
        .background(.white)
        .environment(\.colorScheme, .light)
        .navigationTitle("Detail Rute")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $detailIncident) { incident in
            IncidentDetailSheet(incident: incident, alternatives: RouteStatusLogic.alternatives(for: incident, model: model))
        }
    }

    // MARK: - Data

    private var legSummaries: [LegSummary] {
        steps.indices.compactMap { index in
            guard case .leg(let stations, _) = steps[index] else { return nil }
            let report = RouteStatusLogic.report(forLeg: stations.map(\.id), incidents: incidents)
            var seen: Set<String> = []
            let alternatives = ([report.main].compactMap { $0 } + report.others)
                .flatMap { RouteStatusLogic.alternatives(for: $0, model: model) }
                .filter { seen.insert($0.id).inserted }
            return LegSummary(id: index, stations: stations, report: report, alternatives: alternatives)
        }
    }

    /// Opens whichever collapsed list holds `id`, so a pin selected on the map has a card to scroll to.
    private func reveal(_ id: String, in legs: [LegSummary]) {
        for leg in legs {
            if leg.report.others.contains(where: { $0.id == id }) { expandedOthers.insert(leg.id) }
            for row in rows(for: leg) {
                guard case .incident(let main, let others, _, _) = row else { continue }
                if others.contains(where: { $0.id == id }) { openMarkers.insert(row.id) }
                if alternatives(near: main).contains(where: { $0.id == id }) { revealedAlternatives.insert(main.id) }
            }
        }
    }

    private func alternatives(near incident: CorridorIncident) -> [NearbyTransitPoint] {
        RouteStatusLogic.alternatives(for: incident, model: model)
    }

    private func rows(for leg: LegSummary) -> [TimelineRow] {
        RouteStatusLogic.timelineRows(stations: leg.stations, incidents: incidents)
    }

    /// True when the leg is expanded: it then draws its own first and last station, so the station steps hide.
    private var isLegExpanded: Bool {
        steps.contains { if case .leg(_, true) = $0 { true } else { false } }
    }

    private func expansion(of index: Int) -> Binding<Bool> {
        Binding {
            if case .leg(_, let isExpanded) = steps[index] { isExpanded } else { false }
        } set: { isExpanded in
            if case .leg(let stations, _) = steps[index] {
                steps[index] = .leg(stations: stations, isExpanded: isExpanded)
            }
        }
    }

    // MARK: - Timeline

    private func timeline(_ legs: [LegSummary]) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(steps.indices, id: \.self) { index in
                        stepView(index, legs: legs)
                    }
                }
                .padding()
            }
            .onAppear { scroll(proxy) }
            .onChange(of: selectedID) { scroll(proxy) }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy) {
        guard let selectedID else { return }
        withAnimation { proxy.scrollTo(selectedID, anchor: .center) }
    }

    @ViewBuilder
    private func stepView(_ index: Int, legs: [LegSummary]) -> some View {
        switch steps[index] {
        case .walk(let meters):
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    TimelineNode(systemImage: "figure.walk", style: .filled)
                    (Text("Jalan Kaki ").bold() + Text("(\(meters)m)"))
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white, in: .capsule)
                        .overlay(Capsule().strokeBorder(.black, lineWidth: 1))
                }
                .accessibilityElement(children: .combine)
                Capsule().fill(.black).frame(width: 10, height: 24).frame(width: TimelineNode.size)
            }
        case .station(let role, let station):
            if !isLegExpanded {
                HStack(spacing: 12) {
                    TimelineNode(systemImage: "tram.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(role.label).font(.caption).foregroundStyle(.secondary)
                        Text(station.name).font(.subheadline.bold())
                    }
                }
                .accessibilityElement(children: .combine)
            }
        case .leg(_, let isExpanded):
            if let leg = legs.first(where: { $0.id == index }), isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    let rows = rows(for: leg)
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        railRow(rows, at: rowIndex, legIndex: index)
                    }
                }
                .transition(.opacity)
            } else if let leg = legs.first(where: { $0.id == index }) {
                VStack(alignment: .leading, spacing: 12) {
                    LegRow(stations: leg.stations, isExpanded: expansion(of: index))
                    reports(leg)
                    if let main = leg.report.main {
                        alternatives(for: main)
                    }
                }
                .padding(.vertical, 16)
                .padding(.leading, TimelineNode.size + 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(alignment: .leading) {
                    TimelineLine(color: .greenLine)
                }
            }
        }
    }

    // MARK: - Expanded leg

    /// One station or marker on the expanded rail. The rail turns dashed on both sides of a marker.
    private func railRow(_ rows: [TimelineRow], at index: Int, legIndex: Int) -> some View {
        let row = rows[index]
        func isMarker(_ i: Int) -> Bool {
            guard rows.indices.contains(i), case .incident = rows[i] else { return false }
            return true
        }
        let top: RailSegment.Style = index == 0 ? .none : (isMarker(index) || isMarker(index - 1) ? .dashed : .solid)
        let bottom: RailSegment.Style = index == rows.count - 1 ? .none : (isMarker(index) || isMarker(index + 1) ? .dashed : .solid)

        return HStack(alignment: .center, spacing: 12) {
            VStack(spacing: 0) {
                RailSegment(style: top, nodeEdge: .bottom)
                switch row {
                case .station: TimelineNode(systemImage: "tram.fill")
                case .incident(let main, _, _, _): IncidentMarker(color: RouteStatusLogic.status(of: main).tint)
                }
                RailSegment(style: bottom, nodeEdge: .top)
            }
            .frame(width: TimelineNode.size)

            railContent(row, isFirst: index == 0, isLast: index == rows.count - 1, legIndex: legIndex)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func railContent(_ row: TimelineRow, isFirst: Bool, isLast: Bool, legIndex: Int) -> some View {
        switch row {
        case .station(let station, let number):
            VStack(alignment: .leading, spacing: 2) {
                if isFirst || isLast {
                    Text(isFirst ? StationRole.departure.label : StationRole.arrival.label)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text(station.name)
                    .font(.subheadline.bold())
                    .accessibilityLabel("\(station.name), stasiun ke-\(number)")
                if isFirst, case .leg(let stations, _) = steps[legIndex] {
                    LegRow(stations: stations, isExpanded: expansion(of: legIndex))
                        .padding(.top, 6)
                }
            }
        case .incident(let main, let others, let after, let before):
            VStack(alignment: .leading, spacing: 8) {
                railCard(main)
                    .accessibilityLabel("Gangguan di antara \(after.name) dan \(before.name). \(main.title)")
                if !others.isEmpty {
                    let isOpen = openMarkers.contains(row.id)
                    Button {
                        withAnimation(.spring) {
                            if isOpen { openMarkers.remove(row.id) } else { openMarkers.insert(row.id) }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("+\(others.count) laporan lain")
                            Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    if isOpen {
                        ForEach(others) { railCard($0).transition(.opacity) }
                    }
                }
                alternatives(for: main)
                    .padding(.top, 4)
            }
        }
    }

    private func railCard(_ incident: CorridorIncident) -> some View {
        Button {
            // Keeps the Peta tab on this incident too.
            selectedID = incident.id
            detailIncident = incident
        } label: {
            RailIncidentCard(incident: incident)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.blue, lineWidth: selectedID == incident.id ? 2 : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Lihat detail gangguan")
        .id(incident.id)
    }

    // MARK: - Collapsed leg

    @ViewBuilder
    private func reports(_ leg: LegSummary) -> some View {
        if let main = leg.report.main {
            card(main, status: leg.report.status)
        } else {
            IncidentCard(incident: nil, status: .clear)
        }
        if !leg.report.others.isEmpty {
            let isOpen = expandedOthers.contains(leg.id)
            Button {
                withAnimation(.spring) {
                    if isOpen { expandedOthers.remove(leg.id) } else { expandedOthers.insert(leg.id) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("+\(leg.report.others.count) laporan lain")
                    Image(systemName: "chevron.down").rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            if isOpen {
                ForEach(leg.report.others) { incident in
                    card(incident, status: RouteStatusLogic.status(of: incident))
                        .transition(.opacity)
                }
            }
        }
    }

    private func card(_ incident: CorridorIncident, status: LegStatus) -> some View {
        Button {
            // Keeps the Peta tab on this incident too.
            selectedID = incident.id
            detailIncident = incident
        } label: {
            IncidentCard(incident: incident, status: status)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.blue, lineWidth: selectedID == incident.id ? 2 : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Lihat detail gangguan")
        .id(incident.id)
    }

    /// Other ways to travel from `incident`'s station: shown for a disruption, behind a
    /// "Lihat alternatif" toggle for caution.
    @ViewBuilder
    private func alternatives(for incident: CorridorIncident) -> some View {
        let status = RouteStatusLogic.status(of: incident)
        let alternatives = alternatives(near: incident)
        let isOpen = status == .disrupted || revealedAlternatives.contains(incident.id)
        if status == .disrupted && alternatives.isEmpty {
            Text("Belum ada alternatif dalam \(RouteStatusLogic.alternativeRadiusKm.formatted()) km dari \(incident.nearestStationName)")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if !alternatives.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                if status == .caution {
                    Button {
                        withAnimation(.spring) {
                            if isOpen { revealedAlternatives.remove(incident.id) } else { revealedAlternatives.insert(incident.id) }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Lihat alternatif dekat \(incident.nearestStationName)")
                            Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        }
                        .font(.caption.weight(.semibold))
                    }
                    .accessibilityValue(isOpen ? "Terbuka" : "Tertutup")
                } else {
                    Text("Alternatif dekat \(incident.nearestStationName)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, TimelineNode.size + 10)
                }
                if isOpen {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(alternatives) { transit in
                            AlternativeRow(transit: transit) {
                                selectedID = transit.id
                                tab = .map
                            }
                            .id(transit.id)
                        }
                    }
                    .background(alignment: .leading) {
                        TimelineLine(color: .gray, dashed: true)
                    }
                    .transition(.opacity)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RouteDetailView(origin: GreenLineStation.all[6], destination: GreenLineStation.all[0], walkMeters: 213)
    }
}
