//
//  ContentView.swift
//  moobby
//
//  Created by Maula Izza Azizi on 15/05/26.
//

import SwiftUI

//RootView
struct ContentView: View {

    let container: AppContainer
    @State private var mapTracker = LocationTrackerViewModel()

    var body: some View {
        TabView {
            Tab("Map", systemImage: "map.fill") {
                NavigationStack {
                    MapView(tracker: mapTracker)
                }
            }

            Tab("Components", systemImage: "square.grid.2x2") {
                NavigationStack {
                    ComponentsGalleryView(container: container)
                }
            }
        }
    }
}
