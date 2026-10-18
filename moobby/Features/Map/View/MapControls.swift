//
//  MapControls.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import SwiftUI

/// Apple Maps–style floating stack: traffic toggle above recenter, sharing one glass capsule.
struct MapControls: View {
    /// Whether the map draws live traffic; the top button toggles it.
    @Binding var showsTraffic: Bool
    /// Enables the location button; pass false until there's a position to go to.
    let canRecenter: Bool
    /// Called when the location button is tapped.
    let recenter: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(showsTraffic ? "Hide Traffic" : "Show Traffic", systemImage: "car.fill", action: toggleTraffic)
                .foregroundStyle(showsTraffic ? Color.accentColor : .primary)
                .frame(minWidth: 44, minHeight: 44)
            Button("Show My Location", systemImage: "location", action: recenter)
                .frame(minWidth: 44, minHeight: 44)
                .disabled(!canRecenter)
        }
        .labelStyle(.iconOnly)
        .font(.title3)
        .padding(.vertical, 4)
        .glassEffect(.regular.interactive(), in: .capsule)
        .padding()
    }

    private func toggleTraffic() {
        showsTraffic.toggle()
    }
}
