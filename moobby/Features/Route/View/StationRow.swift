//
//  StationRow.swift
//  moobby
//
//  Iteration 2: one station on the Kondisi Rute timeline.
//

import SwiftUI

/// One station on the timeline: the green line, a marker, the name and the estimated time.
///
/// Affected stations show ⚠️ instead of a circle (Covers AC10, AC25). Not-affected stations show a
/// plain circle (AC11).
struct StationRow: View {
    let status: RouteConditionViewModel.StationStatus
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(spacing: 14) {
            marker
                .frame(width: 28)

            Text(status.station.shortName)
                .typography(.body)

            Spacer()

            if let time = status.estimatedTime {
                Text(time, format: .dateTime.hour().minute().locale(Locale(identifier: "id_ID")))
                    .monospacedDigit()
                    .typography(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
        .accessibilityValue(status.isAffected ? "Ada gangguan" : "")
    }

    /// The line above and below, with ⚠️ or a circle in the middle.
    private var marker: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isFirst ? .clear : Color.green)
                .frame(width: 3)
            if status.isAffected {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow, .orange)
                    .symbolRenderingMode(.palette)
            } else {
                Circle()
                    .strokeBorder(.green, lineWidth: 3)
                    .background(Circle().fill(.background))
                    .frame(width: 16, height: 16)
            }
            Rectangle()
                .fill(isLast ? .clear : Color.green)
                .frame(width: 3)
        }
    }
}
