//
//  AlternativeRow.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI

/// One suggested transit point: on the route's dashed alternatives branch, or in ``IncidentDetailSheet``.
struct AlternativeRow: View {
    let transit: NearbyTransitPoint
    /// Focuses the point on the map. `nil` makes the row plain text instead of a button.
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityHint("Tampilkan di peta")
        } else {
            content.accessibilityElement(children: .combine)
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 10) {
            TimelineNode(systemImage: RouteStatusLogic.symbol(forMode: transit.mode), style: .alternative(.blue))
            VStack(alignment: .leading, spacing: 3) {
                Text(transit.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text("\(transit.mode) · \(transit.routesInfo)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let km = transit.straightLineDistanceKm {
                    Text(RouteStatusLogic.distanceLabel(km: km))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.blue.opacity(0.1), in: .capsule)
                }
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .contentShape(.rect)
    }
}

#Preview {
    var transit = NearbyTransitPoint.catalog[6]
    transit.straightLineDistanceKm = 0.08
    return AlternativeRow(transit: transit) {}
        .padding()
}
