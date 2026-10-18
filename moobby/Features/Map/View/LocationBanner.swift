//
//  LocationBanner.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import SwiftUI

/// A rounded message card above the search bar, with an optional button that opens the app's Settings page.
struct LocationBanner: View {
    /// What's wrong and, if possible, how to fix it.
    let message: String
    /// Shows Open Settings; use it only when the user can fix the problem there.
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
