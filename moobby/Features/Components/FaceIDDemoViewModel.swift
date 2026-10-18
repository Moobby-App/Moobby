//
//  FaceIDDemoViewModel.swift
//  moobby
//
//  Created by Maula Izza Azizi on 18/07/26.
//

import Foundation
import LocalAuthentication
import Observation

@Observable
@MainActor
/// Drives ``FaceIDDemoView``: asks ``BiometricAuthenticating`` to authenticate and reports the outcome as a ``Status``.
final class FaceIDDemoViewModel {

    /// Where the authentication attempt stands.
    enum Status: Equatable {
        case idle
        case authenticating
        case success
        /// Failed or was cancelled; carries the message to show.
        case failure(String)
    }

    private let container: AppContainer

    /// Outcome of the latest attempt; ``reset()`` returns it to `.idle`.
    var status: Status = .idle

    init(container: AppContainer) {
        self.container = container
    }

    /// Name of the biometry this device has, e.g. "Face ID" or "Touch ID".
    var biometryLabel: String {
        switch container.biometrics.biometryType() {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        default: "Biometric Authentication"
        }
    }

    /// Shows the system biometric prompt and sets ``status`` to `.success` or `.failure`.
    /// Errors never escape; they become a `.failure` message.
    func authenticate() async {
        status = .authenticating

        do {
            let success = try await container.biometrics.authenticate(
                reason: "Authenticate to unlock this demo."
            )
            status = success ? .success : .failure("Authentication was not completed.")
        } catch {
            container.log.warning("Biometric authentication failed: \(error.localizedDescription)")
            status = .failure(error.localizedDescription)
        }
    }

    /// Clears the last result so the demo can run again.
    func reset() {
        status = .idle
    }
}
