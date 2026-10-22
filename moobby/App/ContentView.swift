//
//  ContentView.swift
//  moobby
//
//  Created by Maula Izza Azizi on 15/05/26.
//

import SwiftUI

/// The root view: a tab bar with the iteration 2 tabs, Berita and Rute.
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
///
/// > Note: Iteration 1's Map and Components tabs aren't shown any more, but their code stays in
/// > `Features/Map` and `Features/Components` (SPEC Constraints → Iteration, Decision 10).
struct ContentView: View {

    /// Shared services, created once by ``MoobbyApp``.
    let container: AppContainer

    var body: some View {
        TabView {
            Tab("Berita", systemImage: "newspaper") {
                NavigationStack {
                    NewsView()
                }
            }

            Tab("Rute", systemImage: "tram") {
                NavigationStack {
                    RouteSelectionView()
                }
            }
        }
    }
}

#Preview {
    ContentView(container: AppContainer())
}
