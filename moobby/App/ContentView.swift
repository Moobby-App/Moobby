//
//  ContentView.swift
//  moobby
//
//  Created by Maula Izza Azizi on 15/05/26.
//

import SwiftUI

/// The root view: a tab bar with the Map and Components tabs.
///
/// It receives the app's one ``AppContainer`` from ``MoobbyApp`` and passes it to each tab that
/// needs services, so a feature gets its dependencies through its initializer:
///
/// ```swift
/// Tab("Profile", systemImage: "person") {
///     NavigationStack {
///         ProfileView(viewModel: ProfileViewModel(container: container))
///     }
/// }
/// ```
///
/// Don't create another `AppContainer` here or in a feature; outside previews and tests there's only one.
struct ContentView: View {

    /// Shared services, created once by ``MoobbyApp``.
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
