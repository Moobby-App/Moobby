//
//  RailIncidentCard.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI

/// The gray card beside an ``IncidentMarker`` on the expanded rail: category, headline, and where the report came from.
struct RailIncidentCard: View {
    let incident: CorridorIncident

    @State private var isVisible = false

    private static let background = Color(red: 0xDD / 255, green: 0xDD / 255, blue: 0xDD / 255)

    private var status: LegStatus { RouteStatusLogic.status(of: incident) }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            IncidentMarker(size: 24, color: status.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(RouteStatusLogic.categoryLabel(incident.category))
                    .font(.subheadline.bold())
                    .foregroundStyle(status.titleColor)
                Text(incident.title)
                    .font(.caption)
                    .foregroundStyle(.black)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text("\(incident.publishedAt) • \(incident.sourceName)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if !incident.isVerified {
                        Text("Belum terverifikasi")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .overlay(Capsule().strokeBorder(.secondary, lineWidth: 1))
                            .fixedSize()
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Self.background, in: .rect(cornerRadius: 12))
        .opacity(isVisible ? 1 : 0)
        .onAppear { withAnimation(.easeIn(duration: 0.3)) { isVisible = true } }
    }
}

#Preview {
    VStack {
        RailIncidentCard(incident: CorridorIncident.curatedSamples[0])
        RailIncidentCard(incident: CorridorIncident.curatedSamples[2])
    }
    .padding()
}
