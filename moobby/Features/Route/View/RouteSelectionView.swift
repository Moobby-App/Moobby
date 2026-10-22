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

#Preview {
    RouteSelectionView(viewModel: RouteSelectionViewModel(container: AppContainer(), routeSelection: RouteSelection()))
}
