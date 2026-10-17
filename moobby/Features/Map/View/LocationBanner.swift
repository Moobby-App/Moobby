//
//  LocationBanner.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import SwiftUI

struct LocationBanner: View {
    let message: String
    let showsSettings: Bool
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 8) {
            Text(message).multilineTextAlignment(.center)
            if showsSettings {
                Button("Open Settings", action: openSettings)
            }
        }
        .padding().background(.regularMaterial, in: .rect(cornerRadius: 16))
        .padding()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
