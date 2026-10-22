//
//  RouteSelectionView.swift
//  moobby
//
//  Iteration 2: tab Rute.
//

import SwiftUI

/// Tab Rute: pick a departure and a destination station.
///
/// > Note: A placeholder until Task 7 adds the station pickers.
struct RouteSelectionView: View {
    var body: some View {
        ContentUnavailableView("Pilih Rute Perjalanan", systemImage: "tram")
            .navigationTitle("Rute")
    }
}

#Preview {
    NavigationStack {
        RouteSelectionView()
    }
}
