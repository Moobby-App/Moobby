//
//  Access.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import CoreLocation

/// Whether the app can use location, in the terms the UI cares about.
///
/// Unlike `CLAuthorizationStatus`, it tells apart Location Services being off for the whole device
/// (``servicesOff``) from this app being denied (``denied``), since the fix is different.
enum Access {
    /// Not asked yet, or not known yet.
    case unknown
    /// When In Use or Always was granted.
    case allowed
    /// The user turned location off for this app.
    case denied
    /// Blocked by Screen Time or a device profile; the user may not be able to change it.
    case restricted
    /// Location Services is off for the whole device.
    case servicesOff
}

extension Access {
    /// Maps an authorization status. It can't produce ``servicesOff``; only live updates report that.
    init(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways: self = .allowed
        case .denied: self = .denied
        case .restricted: self = .restricted
        case .notDetermined: self = .unknown
        @unknown default: self = .unknown
        }
    }
}
