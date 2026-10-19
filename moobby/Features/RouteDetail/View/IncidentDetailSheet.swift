//
//  IncidentDetailSheet.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI

/// Everything about one ``CorridorIncident``, plus other ways to travel from its station.
///
/// Opened from an incident card in ``RouteDetailView``.
struct IncidentDetailSheet: View {
    let incident: CorridorIncident
    /// From ``RouteStatusLogic/alternatives(for:model:)``.
    let alternatives: [NearbyTransitPoint]

    @Environment(\.dismiss) private var dismiss
    @State private var showsAlternatives = false

    private var status: LegStatus { RouteStatusLogic.status(of: incident) }
    private var tint: Color { status.tint }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            IncidentMarker(size: 28, color: tint)
                            Text(RouteStatusLogic.categoryLabel(incident.category))
                                .font(.headline)
                                .foregroundStyle(tint)
                        }
                        Text(incident.title)
                            .font(.body.weight(.semibold))
                        Text(incident.isVerified ? "Terverifikasi dari sumber resmi operator" : "Belum terverifikasi")
                            .font(.caption.bold())
                            .foregroundStyle(incident.isVerified ? tint : .secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Detail") {
                    Label(incident.locationName, systemImage: "mappin.and.ellipse")
                    // distanceToStationKm is hand-entered; show it exactly as given.
                    Label("\(incident.nearestStationName) (\(String(describing: incident.distanceToStationKm)) km, garis lurus)", systemImage: "tram.fill")
                    Label(incident.publishedAt, systemImage: "clock")
                    Label(incident.sourceName, systemImage: "newspaper")
                }
                .font(.subheadline)

                Section {
                    if alternatives.isEmpty {
                        Text("Belum ada alternatif dalam \(RouteStatusLogic.alternativeRadiusKm.formatted()) km")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if status == .disrupted || showsAlternatives {
                        ForEach(alternatives) { AlternativeRow(transit: $0) }
                    } else {
                        Button("Lihat alternatif") {
                            withAnimation(.spring) { showsAlternatives = true }
                        }
                    }
                } header: {
                    Text("Alternatif transportasi")
                } footer: {
                    Text("Jarak dihitung garis lurus dari \(incident.nearestStationName), bukan jarak jalan kaki.")
                }
            }
            .tint(tint)
            .navigationTitle("Detail Gangguan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview("Terverifikasi") {
    let incident = CorridorIncident.curatedSamples[0]
    IncidentDetailSheet(incident: incident, alternatives: RouteStatusLogic.alternatives(for: incident, model: MapViewModel()))
}

#Preview("Belum terverifikasi") {
    let incident = CorridorIncident.curatedSamples[2]
    IncidentDetailSheet(incident: incident, alternatives: RouteStatusLogic.alternatives(for: incident, model: MapViewModel()))
}
