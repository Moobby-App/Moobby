# Moobby

An iOS app built with SwiftUI and MVVM. It has two tabs:

- **Map** opens on the area around you, with a blue location dot and a cone pointing the way your phone faces. You can search for places, turn on live traffic, and tap the dot to see your current address.
- **Components** is a catalog with one demo screen per native SwiftUI control: alerts, sheets, menus, pickers, toolbars, Face ID and more.

Requires Xcode 26 and iOS 26.5.

## Getting started

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen), and `moobby.xcodeproj` is gitignored. That keeps project settings readable in PRs and avoids `.pbxproj` merge conflicts.

```bash
brew install xcodegen
xcodegen generate
open moobby.xcodeproj
```

Re-run `xcodegen generate` whenever you add, remove, or move a Swift file. Xcode won't see the change otherwise.

Info.plist values live in `project.yml` as build settings, and each one needs the `INFOPLIST_KEY_` prefix. Without it the key never reaches Info.plist. For location, that means iOS never shows the permission prompt.

## Folder structure

```text
moobby/
├── App/            # MoobbyApp (@main) and ContentView, the root TabView
├── Core/
│   ├── DI/         # AppContainer
│   ├── Logging/    # Log
│   ├── Model/      # Shared models (Access, EmptyBody)
│   ├── Networking/ # APIClient, APIRequest, Endpoint, APIError
│   ├── Security/   # Biometric auth (BiometricAuthenticating, DeviceBiometricAuthenticator)
│   ├── Storage/    # KeyValueStore, UserDefaultStore
│   └── UI/         # DesignSystem.Typography, glassCard()
└── Features/
    ├── Map/        # LocationTrackerViewModel, MapViewModel, View/
    └── Components/ # Control catalog, one *DemoView per control
```

## How the Map tab works

- `LocationTrackerViewModel` owns Core Location. It asks for When In Use permission once, streams location with `CLLocationUpdate.liveUpdates()`, and reads the compass heading. Updates start when the map appears and stop when it disappears.
- `MapViewModel` runs place search (`MKLocalSearch`) and the address lookup behind the blue dot (`MKReverseGeocodingRequest`).
- `MapView` frames about 1 km around you on the first location fix, or 10 km if you only allowed approximate location. After that the camera stays where you leave it until you tap the location button. Until that first fix it shows "Finding your location…" instead of a country-wide map.

## Conventions

- **Dependencies come from `AppContainer`.** It's created once in `MoobbyApp` and passed down. Features don't create their own singletons for networking, storage, logging, or biometrics.
- **ViewModels** use `@Observable` and `@MainActor`, and views own them with `@State`. Don't use `ObservableObject` or `@Published`.
- **Views stay thin.** Search, lookups, and other logic go in the ViewModel. Each view type gets its own file.
- **Styling** uses the shared pieces in `Core/UI/`: `.typography(.title)` for Dynamic Type text, `.glassCard()` for Liquid Glass cards, and the system `.buttonStyle(.glass)` or `.glassProminent` for buttons.
- **Navigation** uses `navigationDestination(for:)` with a `Hashable` route enum. Don't mix it with `NavigationLink(destination:)` in the same stack.

## Adding a network request

Each request is a small struct conforming to `APIRequest`:

```swift
struct UserProfileResponse: Decodable, Sendable {
    let id: String
    let name: String
}

struct GetUserProfileRequest: APIRequest {
    typealias Response = UserProfileResponse
    var method: HTTPMethod = .get
    var endpoint = Endpoint(path: "/user")
    var body: EmptyBody? = nil
}
```

`Endpoint` resolves against `APIConfig.baseURL`, so you only give it the path and optional `queryItems`. Call it from a ViewModel:

```swift
func fetchUser() async {
    do {
        username = try await container.api.execute(GetUserProfileRequest()).name
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

Drive it from the view with `.task { await viewModel.fetchUser() }`. SwiftUI cancels the task when the view disappears.
