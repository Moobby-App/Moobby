//
//  RouteHeader.swift
//  moobby
//
//  Iteration 2.
//

import SwiftUI

/// The route card: "Green Line", the segment, and ⚠️ when any station is affected.
struct RouteHeader: View {
    let routeTitle: String
    let showsWarning: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tram.fill")
                .font(.title2)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Green Line")
                    .bold()
                    .typography(.body)
                Text(routeTitle)
                    .typography(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if showsWarning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Ada gangguan di rute ini")
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}
