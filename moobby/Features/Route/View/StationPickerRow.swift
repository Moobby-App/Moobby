//
//  StationPickerRow.swift
//  moobby
//
//  Iteration 2.
//

import SwiftUI

/// One station in the picker list. Disabled for the destination when it's already the departure.
struct StationPickerRow: View {
    let station: GreenLineStation
    let isDisabled: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
                        .typography(.body)
                    if isDisabled {
                        Text("Stasiun keberangkatan")
                            .typography(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: "tram.fill")
            }
        }
        .disabled(isDisabled)
        .foregroundStyle(isDisabled ? .secondary : .primary)
    }
}
