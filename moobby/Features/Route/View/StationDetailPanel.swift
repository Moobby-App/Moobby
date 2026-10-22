//
//  StationDetailPanel.swift
//  moobby
//
//  Iteration 2: Detail Berita inside an affected station on Kondisi Rute.
//

import SwiftUI

/// The open "Detail Berita" of an affected station: its incidents, then its TransJakarta stops as chips.
///
/// This is the in-timeline detail, not the full Detail Berita page on tab Berita (SPEC Screens and States).
///
/// Covers AC26, AC10 (each incident's source and time), AC13 (chips) and AC14 (no chips when there are
/// no stops). Tapping a chip opens walking directions (AC27) or the location alert (AC15).
struct StationDetailPanel: View {
    let status: RouteConditionViewModel.StationStatus
    /// Called when the user taps a stop chip.
    let onSelectStop: (TransJakartaStop) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(status.incidents) { incident in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gangguan")
                        .bold()
                        .typography(.body)
                    Text(incident.title)
                        .typography(.caption)
                    if let description = incident.cardDescription {
                        Text(description)
                            .typography(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(sourceLine(for: incident))
                        .typography(.caption)
                        .foregroundStyle(.orange)
                }
                .accessibilityElement(children: .combine)
            }

            if !status.stops.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Halte TransJakarta terdekat")
                        .typography(.caption)
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(status.stops) { stop in
                                Button {
                                    onSelectStop(stop)
                                } label: {
                                    Label(stop.name, systemImage: "figure.walk")
                                        .typography(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.secondary.opacity(0.15), in: .capsule)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Buka rute jalan kaki ke halte di Apple Maps")
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 16)
    }

    /// `"DetikNews · 18 Okt, 12.40"`, or just the source when the time is unknown.
    private func sourceLine(for incident: Incident) -> String {
        let source = incident.sourceName ?? "Sumber belum diketahui"
        guard let date = incident.publishedDate else { return source }
        let time = date.formatted(
            .dateTime.day().month(.abbreviated).hour().minute().locale(Locale(identifier: "id_ID"))
        )
        return "\(source) · \(time)"
    }
}
