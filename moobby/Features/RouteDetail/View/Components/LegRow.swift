//
//  LegRow.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI

/// The "Green Line · 7 Stop" toggle of a leg. Expanded, ``RouteDetailView`` draws the leg station by station.
///
/// The count is of ``GreenLineStation/all``, a subset of the line's real stops, so there's no travel time:
/// one per stop would be a guess.
struct LegRow: View {
    let stations: [GreenLineStation]
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.spring) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 4) {
                Text("Green Line · \(stations.count) Stop")
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            }
            .font(.caption.bold())
            .foregroundStyle(Color.greenLine)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityValue(isExpanded ? "Terbuka" : "Tertutup")
    }
}

#Preview {
    @Previewable @State var isExpanded = true
    LegRow(stations: Array(GreenLineStation.all.prefix(7)), isExpanded: $isExpanded)
        .padding()
}
