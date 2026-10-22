//
//  LocationPermission.swift
//  moobby
//
//  Iteration 2: Moobby's own location permission, checked before opening Apple Maps.
//

import CoreLocation

/// Whether Moobby may use the user's location.
enum LocationPermissionStatus {
    /// The user hasn't been asked yet.
    case notDetermined
    /// "While Using the App" or "Always".
    case allowed
    /// Denied, or restricted (for example by parental controls).
    case denied
}

/// Checks and asks for Moobby's location permission. Get it from ``AppContainer/locationPermission``;
/// previews and tests can pass their own.
protocol LocationPermissionProviding {
    /// The current permission, without asking.
    var status: LocationPermissionStatus { get }
    /// Asks for "While Using the App" if the user hasn't been asked yet, then returns the answer.
    @MainActor func requestIfNeeded() async -> LocationPermissionStatus
}

/// The real permission, through `CLLocationManager`.
///
/// Launch the app with `-simulateLocationDenied` to make it always report ``LocationPermissionStatus/denied``,
/// so a UI test can check AC15 without touching the simulator's settings (SPEC Notes for the Agent).
final class DeviceLocationPermission: NSObject, LocationPermissionProviding, CLLocationManagerDelegate {

    /// Set by the `-simulateLocationDenied` launch argument.
    private let simulatesDenied = ProcessInfo.processInfo.arguments.contains("-simulateLocationDenied")

    /// Created on the main actor when the app first asks; kept so its delegate callback arrives.
    private var manager: CLLocationManager?
    /// Waiting for the user's answer to the permission alert.
    private var continuation: CheckedContinuation<LocationPermissionStatus, Never>?

    var status: LocationPermissionStatus {
        if simulatesDenied { return .denied }
        return Self.map(CLLocationManager().authorizationStatus)
    }

    @MainActor
    func requestIfNeeded() async -> LocationPermissionStatus {
        let current = status
        guard current == .notDetermined else { return current }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            let manager = CLLocationManager()
            manager.delegate = self
            self.manager = manager
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let answer = Self.map(manager.authorizationStatus)
        // Called once as soon as the delegate is set, before the user answers; wait for a real answer.
        guard answer != .notDetermined else { return }
        Task { @MainActor in
            self.continuation?.resume(returning: answer)
            self.continuation = nil
            self.manager = nil
        }
    }

    private static func map(_ status: CLAuthorizationStatus) -> LocationPermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorizedWhenInUse, .authorizedAlways: .allowed
        default: .denied
        }
    }
}
