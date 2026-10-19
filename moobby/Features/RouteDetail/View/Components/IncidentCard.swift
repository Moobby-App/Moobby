//
//  IncidentCard.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI

/// A leg's incident, or the "nothing reported" card when `incident` is `nil`.
struct IncidentCard: View {
    let incident: CorridorIncident?
    let status: LegStatus

    @State private var isVisible = false

    private static let background = Color(red: 0xDD / 255, green: 0xDD / 255, blue: 0xDD / 255)

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            badge
            VStack(alignment: .leading, spacing: 6) {
                if let incident {
                    tags(for: incident)
                    Text(incident.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(titleColor)
                        .lineLimit(2)
                    // distanceToStationKm is hand-entered; show it exactly as given.
                    Text("\(incident.locationName) • \(incident.nearestStationName) (\(String(describing: incident.distanceToStationKm)) km)")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.8))
                    Text("\(incident.publishedAt) • \(incident.sourceName)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Belum ada laporan gangguan di jalur ini")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(titleColor)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Self.background, in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .opacity(isVisible ? 1 : 0)
        .onAppear { withAnimation(.easeIn(duration: 0.3)) { isVisible = true } }
    }

    @ViewBuilder
    private var badge: some View {
        switch status {
        case .disrupted:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.red, in: .circle)
                .accessibilityLabel("Gangguan")
        case .caution:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.orange, in: .circle)
                .accessibilityLabel("Waspada")
        case .clear:
            Text("SAFE")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background(Color(red: 0x3F / 255, green: 0x9B / 255, blue: 0x48 / 255), in: .rect(cornerRadius: 6))
        }
    }

    @ViewBuilder
    private func tags(for incident: CorridorIncident) -> some View {
        if status == .disrupted && incident.isVerified {
            tag("Gangguan Operasional", color: titleColor)
        } else if !incident.isVerified {
            tag("Belum terverifikasi", color: .secondary)
        }
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(Capsule().strokeBorder(color.opacity(0.5), lineWidth: 1))
    }

    private var titleColor: Color {
        switch status {
        case .disrupted: Color(red: 0x8B / 255, green: 0x1A / 255, blue: 0x12 / 255)
        case .caution: Color(red: 0x8A / 255, green: 0x5A / 255, blue: 0x00 / 255)
        case .clear: Color(red: 0x2E / 255, green: 0x6B / 255, blue: 0x34 / 255)
        }
    }
}

#Preview {
    VStack {
        IncidentCard(incident: CorridorIncident.curatedSamples[0], status: .disrupted)
        IncidentCard(incident: CorridorIncident.curatedSamples[1], status: .caution)
        IncidentCard(incident: nil, status: .clear)
    }
    .padding()
}
