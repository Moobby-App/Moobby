//
//  APIError.swift
//  moobby
//
//  Created by Maula Izza Azizi on 16/05/26.
//

import Foundation

/// Failures ``APIClient`` reports. `localizedDescription` gives a short message for each one.
///
/// Match the cases you handle differently, and fall back to the message for the rest:
///
/// ```swift
/// do {
///     weather = try await container.api.execute(request)
/// } catch APIError.httpStatusCode(400) {
///     errorMessage = "That location isn't valid."
/// } catch let error as URLError where error.code == .cancelled {
///     return // The view went away; nothing to show.
/// } catch {
///     container.log.error("Weather failed: \(error)")
///     errorMessage = error.localizedDescription
/// }
/// ```
///
/// Network failures, such as being offline or timing out, arrive as `URLError`, not ``APIError``.
enum APIError: Error, LocalizedError {
    /// The base URL, path, and query items didn't form a valid URL.
    case invalidURL
    /// The response wasn't an HTTP response.
    case invalidResponse
    /// The server answered with a status outside 200–299, for example `404` or `500`.
    case httpStatusCode(Int)
    /// The response JSON didn't match the request's `Response` type. The associated `DecodingError` names the key.
    case decoding(Error)
    /// Wraps another error. ``APIClient`` doesn't throw this; it's here for code that wants to wrap a failure as an ``APIError``.
    case underlyingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpStatusCode(let code):
            return "HTTP error \(code)"
        case .decoding(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .underlyingError(let error):
            return error.localizedDescription
        }
    }
}
