//
//  RouteConditionView.swift
//  moobby
//
//  Iteration 2: Kondisi Rute.
//

import SwiftUI

/// Kondisi Rute for the user's segment.
///
/// > Note: A placeholder until Task 8 adds times, affected stations and the banner. For now it lists the
/// > segment so AC1 and AC23 can be checked.
struct RouteConditionView: View {
    let departure: GreenLineStation
    let destination: GreenLineStation

    var body: some View {
        List(GreenLineStation.segment(from: departure, to: destination)) { station in
            Text(station.name)
        }
        .navigationTitle("\(departure.shortName) – \(destination.shortName)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
