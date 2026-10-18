//
//  LocationStatusView.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import SwiftUI

/// Explains why the user's position isn't on the map, if it isn't.
struct LocationStatusView: View {
    /// The state to explain.
    let tracker: LocationTrackerViewModel

    var body: some View {
        switch tracker.access {
        case .denied:
            LocationBanner(message: "Location access is off for this app. Turn it on to see where you are.", showsSettings: true)
        case .servicesOff:
            LocationBanner(message: "Location Services are turned off. Turn them on in Settings › Privacy & Security.", showsSettings: true)
        case .restricted:
            LocationBanner(message: "Location access is restricted on this device.", showsSettings: false)
        case .unknown, .allowed where tracker.location == nil:
            if tracker.isLocationUnavailable {
                LocationBanner(message: "Can't find your location right now.", showsSettings: false)
            } else {
                Label { Text("Finding your location…") } icon: { ProgressView() }
                    .padding().background(.regularMaterial, in: .capsule)
                    .padding()
            }
        default:
            EmptyView()
        }
    }
}
