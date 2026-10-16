//
//  MoobbyApp.swift
//  Moobby
//
//  Created by Maula Izza Azizi on 15/05/26.
//

import SwiftUI

@main
struct MoobbyApp: App {
    
    private let container = AppContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
    }
}
