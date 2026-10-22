//
//  StationFields.swift
//  moobby
//
//  Iteration 2.
//

import SwiftUI

/// The two search fields, joined by a line like the design: departure on top, destination below.
struct StationFields: View {
    let viewModel: RouteSelectionViewModel
    var focusedField: FocusState<RouteSelectionViewModel.Field?>.Binding

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Circle().strokeBorder(.secondary, lineWidth: 2).frame(width: 10, height: 10)
                Rectangle().fill(.secondary).frame(width: 2, height: 28)
                Circle().fill(.green).frame(width: 10, height: 10)
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                TextField("cari stasiun keberangkatan", text: Binding(
                    get: { viewModel.departureQuery },
                    set: { viewModel.setQuery($0, for: .departure) }
                ))
                .focused(focusedField, equals: .departure)

                Divider()

                TextField("cari stasiun tujuan", text: Binding(
                    get: { viewModel.destinationQuery },
                    set: { viewModel.setQuery($0, for: .destination) }
                ))
                .focused(focusedField, equals: .destination)
            }
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
        }
        .padding(.vertical, 4)
    }
}
