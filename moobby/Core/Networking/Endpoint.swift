//
//  Endpoint.swift
//  moobby
//
//  Created by Maula Izza Azizi on 16/05/26.
//

import Foundation

/// The part of a request URL after the host: a path and optional query items.
///
/// The path is appended to ``APIConfig/baseURL``. Query items are encoded for you, so pass raw values:
///
/// ```swift
/// Endpoint(path: "/v1/forecast", queryItems: [
///     URLQueryItem(name: "latitude", value: "-6.2"),
///     URLQueryItem(name: "current", value: "temperature_2m")
/// ])
/// // https://api.open-meteo.com/v1/forecast?latitude=-6.2&current=temperature_2m
/// ```
///
/// Don't put `?` or a query string in `path`; it gets encoded as part of the path. Use `queryItems`.
struct Endpoint {
    /// The path, starting with `/`, such as `/v1/forecast`.
    let path: String
    /// Sent as `?name=value&…`. Empty means no query string.
    var queryItems: [URLQueryItem]

    /// Creates an endpoint for `path`, with no query string unless you pass `queryItems`.
    init(path: String, queryItems: [URLQueryItem] = []) {
        self.path = path
        self.queryItems = queryItems
    }
}
