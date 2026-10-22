//
//  RouteScreen.swift
//  moobby
//
//  Iteration 2: where tab Rute can navigate.
//

import Foundation

/// The screens tab Rute pushes (team convention: a `Hashable` route enum with `navigationDestination(for:)`).
enum RouteScreen: Hashable {
    /// Kondisi Rute for the segment from `departure` to `destination` (AC23).
    case condition(departure: GreenLineStation, destination: GreenLineStation)
}
