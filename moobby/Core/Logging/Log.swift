//
//  Log.swift
//  moobby
//
//  Created by Maula Izza Azizi on 16/05/26.
//

import Foundation
import os

/// App logging, written to Apple's unified log.
///
/// Call it through the container so the dependency stays visible in the type's `init`:
///
/// ```swift
/// container.log.info("Search returned \(results.count) places")
/// container.log.warning("Heading unavailable, hiding the cone")
/// container.log.error("Request failed: \(error)")
/// ```
///
/// Code without a container, like ``APIClient``, can call `Log.error("…")` directly.
///
/// Pick the level by what someone reading the log needs:
/// - ``info(_:)``: normal events worth tracing, like a screen loading or a request finishing.
/// - ``warning(_:)``: something went wrong, but the app recovered.
/// - ``error(_:)``: an operation failed and the user saw it, or will.
///
/// Messages appear in Xcode's console while debugging. On a device or simulator, open Console.app and
/// filter by subsystem `com.appleacademy.moobby`, or from Terminal:
///
/// ```bash
/// xcrun simctl spawn booted log stream --level info --predicate 'subsystem == "com.appleacademy.moobby"'
/// ```
///
/// Messages are logged as public, so they're readable outside Xcode. Never log personal data:
/// names, email addresses, tokens, or exact locations.
enum Log {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "moobby",
        category: "app"
    )

    /// Logs a normal event worth tracing.
    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    /// Logs a problem the app recovered from.
    static func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    /// Logs a failed operation.
    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
