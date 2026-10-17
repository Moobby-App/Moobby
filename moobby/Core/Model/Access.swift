//
//  Access.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import CoreLocation

enum Access {
    case unknown
    case allowed
    case denied
    case restricted
    case servicesOff
}

extension Access {
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
