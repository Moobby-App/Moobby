# ``moobby``

A SwiftUI map and native-controls catalog, built with MVVM.

## Overview

Moobby has two tabs. **Map** follows your location with a heading cone, place search, and live traffic. **Components** shows one demo screen per native SwiftUI control.

Dependencies come from ``AppContainer``, which ``MoobbyApp`` creates once and passes down. View models are `@Observable` and `@MainActor`, and views own them with `@State`.

## Topics

### App

- ``MoobbyApp``
- ``ContentView``
- ``AppContainer``

### Map

- <doc:Map>

### Components Catalog

- <doc:UsingComponents>
- ``UIComponentDemo``
- ``ComponentsGalleryView``
- ``FaceIDDemoViewModel``

### Networking

- <doc:Networking>

### Security

- ``BiometricAuthenticating``
- ``DeviceBiometricAuthenticator``

### Storage

- ``KeyValueStore``
- ``UserDefaultStore``

### Logging and UI

- ``Log``
- ``DesignSystem``
- ``AppEnvironment``
