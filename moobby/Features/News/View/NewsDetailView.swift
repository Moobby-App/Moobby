//
//  NewsDetailView.swift
//  moobby
//
//  Iteration 2: Detail Berita.
//

import SwiftUI

/// Detail Berita: everything known about one incident, as a grouped list (Apple HIG: a detail view
/// with a headline and labeled rows, built from standard components).
///
/// Covers AC18 (title, category, station, published time, source and verification status).
struct NewsDetailView: View {
    let incident: Incident

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(incident.categoryLabel, systemImage: "exclamationmark.triangle.fill")
                        .typography(.caption)
                        .foregroundStyle(.orange)
                    Text(incident.title)
                        .typography(.title)
                    if let summary = incident.summary {
                        Text(summary)
                            .typography(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Informasi") {
                LabeledContent("Stasiun terdekat", value: incident.nearestStationName ?? "Belum diketahui")
                if let location = incident.locationName {
                    LabeledContent("Lokasi", value: location)
                }
                if let distance = incident.distanceToStationKm {
                    LabeledContent("Jarak ke stasiun", value: distance.formatted(.number.precision(.fractionLength(2))) + " km")
                }
                LabeledContent("Waktu terbit", value: incident.detailTime)
            }

            Section("Sumber") {
                LabeledContent("Dilaporkan oleh", value: incident.sourceName ?? "Belum diketahui")
                LabeledContent("Status") {
                    Label(
                        incident.isVerified ? "Terverifikasi" : "Belum terverifikasi",
                        systemImage: incident.isVerified ? "checkmark.seal.fill" : "questionmark.circle"
                    )
                    .foregroundStyle(incident.isVerified ? .green : .secondary)
                }
            }
        }
        .navigationTitle("Detail Berita")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension Incident {
    /// ``publishedDate`` in full, such as `"18 Oktober 2026 12.40"`, or "Belum diketahui".
    var detailTime: String {
        guard let date = publishedDate else { return "Belum diketahui" }
        return date.formatted(
            .dateTime.day().month(.wide).year().hour().minute().locale(Locale(identifier: "id_ID"))
        )
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        NewsDetailView(incident: Incident.previewSamples[0])
    }
}
#endif
