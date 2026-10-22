//
//  GetIncidentsRequest.swift
//  moobby
//
//  Iteration 2: the team backend's incident list.
//

import Foundation

/// `GET /api/v1/incidents`: published Green Line incidents from the team backend.
///
/// Run it through the shared client, never with `URLSession` directly:
///
/// ```swift
/// let incidents = try await container.api.execute(GetIncidentsRequest())
/// ```
///
/// The host comes from ``APIConfig/baseURL``, so this file never contains a URL. The backend README's
/// `MoobbyAPI` example isn't used because it hard-codes the host and calls `URLSession.shared` itself.
///
/// Covers AC16, AC19 and AC20 (data).
struct GetIncidentsRequest: APIRequest {
    typealias Response = [Incident]

    /// How many incidents to fetch at once. The backend README uses 20.
    var limit = 20
    /// How many to skip, for paging (`0`, `20`, `40`, …).
    var offset = 0

    var method: HTTPMethod { .get }

    var endpoint: Endpoint {
        Endpoint(path: "/api/v1/incidents", queryItems: [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ])
    }

    var body: EmptyBody? { nil }
}
