//
//  RouteSelectionView.swift
//  moobby
//
//  Iteration 2: tab Rute, Pilih Rute Perjalanan.
//

import SwiftUI

/// Tab Rute: two search fields and the station list. Picking both stations opens Kondisi Rute.
///
/// It owns the tab's `NavigationStack`, bound to ``RouteSelectionViewModel/path``, so the ViewModel can
/// open Kondisi Rute after the second pick.
struct RouteSelectionView: View {
    @State private var viewModel: RouteSelectionViewModel
    @FocusState private var focusedField: RouteSelectionViewModel.Field?

    init(viewModel: RouteSelectionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            List {
                Section {
                    StationFields(viewModel: viewModel, focusedField: $focusedField)
                }

                Section {
                    if viewModel.visibleStations.isEmpty {
                        ContentUnavailableView("Stasiun tidak ditemukan", systemImage: "magnifyingglass")
                    } else {
                        ForEach(viewModel.visibleStations) { station in
                            StationPickerRow(
                                station: station,
                                isDisabled: viewModel.isDisabled(station)
                            ) {
                                viewModel.select(station)
                                focusedField = viewModel.departure == nil ? .departure : .destination
                                if viewModel.departure != nil, viewModel.destination != nil {
                                    focusedField = nil
                                }
                            }
                        }
                    }
                } header: {
                    Text(viewModel.activeField == .departure ? "Pilih stasiun keberangkatan" : "Pilih stasiun tujuan")
                }
            }
            .navigationTitle("Pilih Rute Perjalanan")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: focusedField) { _, field in
                if let field { viewModel.activeField = field }
            }
            .navigationDestination(for: RouteScreen.self) { screen in
                switch screen {
                case .condition(let departure, let destination):
                    RouteConditionView(viewModel: RouteConditionViewModel(
                        container: viewModel.container,
                        departure: departure,
                        destination: destination
                    ))
                }
            }
        }
    }
}

/// The two search fields, joined by a line like the design: departure on top, destination below.
private struct StationFields: View {
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

/// One station in the picker list. Disabled for the destination when it's already the departure.
private struct StationPickerRow: View {
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

#Preview {
    RouteSelectionView(viewModel: RouteSelectionViewModel(container: AppContainer()))
}
