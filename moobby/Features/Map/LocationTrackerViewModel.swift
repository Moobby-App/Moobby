//
//  LocationTrackerViewModel.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import CoreLocation
import Observation

@MainActor @Observable
final class LocationTrackerViewModel: NSObject, CLLocationManagerDelegate {
    private(set) var access: Access = .unknown
    private(set) var location: CLLocationCoordinate2D?
    private(set) var isLocationUnavailable = false
    /// Direction the device is facing, in degrees from north; nil when the compass is unavailable or unreliable.
    private(set) var heading: CLLocationDirection?
    private(set) var route: [CLLocationCoordinate2D] = []

    /// True when the user granted approximate location only. Stored, not read from the manager, so views refresh when it changes.
    private(set) var isApproximate = false

    private let manager = CLLocationManager()
    private var session: CLServiceSession?
    private var task: Task<Void, Never>?

    // Beyond this error the cone would point somewhere misleading, so it's hidden instead.
    private static let maxHeadingError: CLLocationDirection = 45

    override init() {
        super.init()
        manager.delegate = self
        // Last cached fix, so the map can open on the user before live updates arrive.
        location = manager.location?.coordinate
        isApproximate = manager.accuracyAuthorization == .reducedAccuracy
    }

    /// Called when the map appears: the system prompts once if undecided, then location and heading run on their own.
    /// Updates also run while denied so the diagnostics report denial / services off, and resume if the user re-enables access.
    func activate() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        start()
        if CLLocationManager.headingAvailable() {
            manager.headingFilter = 2
            manager.startUpdatingHeading()
        }
    }

    /// Called when the map disappears, so sensors aren't polled for a screen nobody is looking at.
    func deactivate() {
        stop()
        manager.stopUpdatingHeading()
        heading = nil
    }

    /// Heading is measured against the top of the device, so it must follow the interface orientation.
    func setHeadingOrientation(_ orientation: CLDeviceOrientation) {
        manager.headingOrientation = orientation
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let accuracy = newHeading.headingAccuracy
        // trueHeading is negative until a location fix is available.
        let direction = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            heading = accuracy >= 0 && accuracy <= Self.maxHeadingError ? direction : nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard (error as? CLError)?.code == .headingFailure else { return }
        Task { @MainActor in heading = nil }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        // Also called when the user switches precise location on or off.
        let isApproximate = manager.accuracyAuthorization == .reducedAccuracy
        Task { @MainActor in
            self.isApproximate = isApproximate
            // Services off also reports `.denied`; keep the more specific state from the diagnostics.
            if status == .denied, access == .servicesOff { return }
            access = Access(status)
        }
    }

    private func start() {
        guard task == nil else { return }
        
        session = CLServiceSession(authorization: .whenInUse)
        
        task = Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if update.authorizationDeniedGlobally {
                        access = .servicesOff
                    } else if update.authorizationDenied {
                        access = .denied
                    } else if update.authorizationRestricted {
                        access = .restricted
                    }
                    isLocationUnavailable = update.locationUnavailable
                    guard let loc = update.location else { continue }
                    access = .allowed
                    location = loc.coordinate
                    
                    if loc.horizontalAccuracy >= 0, loc.horizontalAccuracy < 50 {
                        route.append(loc.coordinate)
                    }
                }
            } catch { }
            task = nil
        }
    }
    
    private func stop() {
        task?.cancel()
        task = nil
        session = nil
    }
    
    func reset() { route.removeAll() }
}
