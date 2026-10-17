//
//  LocationIndicator.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import SwiftUI
import CoreLocation

/// Apple Maps–style blue dot, with a light-blue cone toward the device heading when the compass is reliable.
struct LocationIndicator: View {
    /// Degrees clockwise from the top of the screen; nil hides the cone.
    let heading: CLLocationDirection?

    var body: some View {
        ZStack {
            if let heading {
                Cone()
                    .fill(RadialGradient(colors: [.blue.opacity(0.45), .blue.opacity(0)],
                                         center: .center, startRadius: 0, endRadius: 44))
                    .frame(width: 88, height: 88)
                    .rotationEffect(.degrees(heading))
            }
            Circle()
                .fill(.blue)
                .frame(width: 16, height: 16)
                .padding(3)
                .background(.white, in: .circle)
                .shadow(color: .blue.opacity(0.4), radius: 6)
        }
        .accessibilityElement()
        .accessibilityLabel("Your location")
        .accessibilityHint("Shows the address of your current location")
    }
}
