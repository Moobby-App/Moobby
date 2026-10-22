//
//  StationRow.swift
//  moobby
//
//  Iteration 2: one station on the Kondisi Rute timeline.
//

import SwiftUI

/// One station on the timeline: the green line, a marker, the name, the estimated time, and for an
/// affected station a "Detail Berita" toggle.
///
/// Affected stations show ⚠️ instead of a circle (Covers AC10, AC25); others show a plain circle (AC11)
/// and have no toggle (AC26).
struct StationRow: View {
    let status: RouteConditionViewModel.StationStatus
    let isFirst: Bool
    let isLast: Bool
    let isExpanded: Bool
    let onToggleDetail: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            marker
                .frame(width: 28)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
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
                .frame(minHeight: 32)
                .accessibilityElement(children: .combine)
                .accessibilityValue(status.isAffected ? "Ada gangguan" : "")

                if status.isAffected {
                    Button(action: onToggleDetail) {
                        HStack(spacing: 4) {
                            Text("Detail Berita")
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        }
                        .typography(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(isExpanded ? "Tutup detail gangguan" : "Buka detail gangguan")

                    if isExpanded {
                        StationDetailPanel(status: status)
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    /// The line above and below, with ⚠️ or a circle near the top.
    private var marker: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isFirst ? .clear : Color.green)
                .frame(width: 3, height: 14)
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
                .frame(maxHeight: .infinity)
        }
    }
}
