//
//  AppContainer.swift
//  moobby
//
//  Created by Maula Izza Azizi on 16/05/26.
//

import Foundation

/// The app's dependency container: one object holding the shared services every feature uses.
///
/// This is a *composition root* with *constructor injection*. ``MoobbyApp`` creates the
/// only instance at launch, and it's passed down through initializers:
/// ``MoobbyApp`` → ``ContentView`` → a feature view → its view model.
/// Nothing reaches for it globally, so every type's dependencies are visible in its `init`.
///
/// ```swift
/// @Observable @MainActor
/// final class ProfileViewModel {
///     private let container: AppContainer
///
///     init(container: AppContainer) {
///         self.container = container
///     }
///
///     func load() async {
///         do {
///             profile = try await container.api.execute(GetProfileRequest())
///         } catch {
///             container.log.error("Profile failed to load: \(error)")
///         }
///     }
/// }
/// ```
///
/// Every parameter defaults to the production implementation, so `AppContainer()` is the real app.
/// Previews and tests pass their own instead:
///
/// ```swift
/// AppContainer(store: InMemoryStore(), biometrics: AlwaysSucceedsAuthenticator())
/// ```
///
/// ### Adding a dependency
///
/// 1. Put a protocol in front of it when you'll want a fake, like ``KeyValueStore``.
/// 2. Add a `let` here and an `init` parameter that defaults to the real implementation.
/// 3. Read it through the container in the view model that needs it.
///
/// Only app-wide services belong here. View models aren't dependencies; a view owns its own with `@State`.
final class AppContainer {

    /// Logging, used as `container.log.info("…")`. See ``Log``.
    let log: Log.Type
    /// Small persistent values; ``UserDefaultStore`` in the app.
    let store: KeyValueStore
    /// Sends ``APIRequest``s to the backend.
    let api: APIClient
    /// Face ID / Touch ID; ``DeviceBiometricAuthenticator`` in the app.
    let biometrics: BiometricAuthenticating

    init(
        log: Log.Type = Log.self,
        store: KeyValueStore = UserDefaultStore(),
        api: APIClient = APIClient(),
        biometrics: BiometricAuthenticating = DeviceBiometricAuthenticator()
    ) {
        self.log = log
        self.store = store
        self.api = api
        self.biometrics = biometrics
    }
}
