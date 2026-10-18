//
//  APIClient.swift
//  moobby
//
//  Created by Maula Izza Azizi on 16/05/26.
//

import Foundation

/// Which backend the app talks to.
///
/// - **Development** is the server you build and test against: test data, debug logging, and
///   breaking changes are fine. Debug builds (Run in Xcode) should use it.
/// - **Production** is the live server real users hit. Release builds (Archive, TestFlight, App Store)
///   must use it.
///
/// ``APIConfig/environment`` picks one, and ``APIConfig/baseURL`` maps it to a URL.
/// See <doc:Networking> for wiring each one to a build configuration.
enum AppEnvironment {
    /// The test server, for building and debugging.
    case development
    /// The live server real users hit.
    case production
}

/// Where requests go. Every ``Endpoint`` path is resolved against ``baseURL``.
///
/// Both environments point at Open-Meteo for now, and ``environment`` is fixed to `.development`.
/// When the app gets its own backend, give each case its own URL and choose the environment per
/// build configuration; <doc:Networking> shows how.
enum APIConfig {
    /// The backend this build talks to.
    static let environment: AppEnvironment = .development

    /// Scheme and host for ``environment``, such as `https://api.open-meteo.com`. Don't include query items.
    ///
    /// A malformed URL here is a programmer error, so it stops the app with `fatalError` instead of throwing.
    static var baseURL: URL {
        let urlString: String
        switch environment {
        case .development, .production:
            urlString = "https://api.open-meteo.com"
        }

        guard let url = URL(string: urlString) else {
            fatalError("Invalid base URL string: \(urlString)")
        }

        return url
    }
}

/// One call to the backend: its method, endpoint, optional JSON body, and the type the response decodes to.
///
/// Write one small struct per call and run it with ``APIClient/execute(_:)``:
///
/// ```swift
/// struct GetCurrentWeatherRequest: APIRequest {
///     typealias Response = CurrentWeather
///
///     let latitude: Double
///     let longitude: Double
///
///     var method: HTTPMethod { .get }
///     var endpoint: Endpoint {
///         Endpoint(path: "/v1/forecast", queryItems: [
///             URLQueryItem(name: "latitude", value: String(latitude)),
///             URLQueryItem(name: "longitude", value: String(longitude)),
///             URLQueryItem(name: "current", value: "temperature_2m")
///         ])
///     }
///     var body: EmptyBody? { nil }
/// }
/// ```
///
/// ``Body`` defaults to ``EmptyBody``, so requests without a body only return `nil`.
protocol APIRequest {

    /// What the response JSON decodes to.

    associatedtype Response: Decodable
    /// What's sent as the JSON body. Defaults to ``EmptyBody`` for requests that don't send one.
    associatedtype Body: Encodable = EmptyBody

    /// The HTTP method, such as `.get` or `.post`.
    var method: HTTPMethod { get }
    /// Path and query items, resolved against ``APIConfig/baseURL``.
    var endpoint: Endpoint { get }
    /// Encoded as JSON with a `Content-Type: application/json` header; `nil` sends no body.
    var body: Body? { get }
}

/// Builds the full URL for `request`: ``APIConfig/baseURL``, then the endpoint's path, then its query items.
///
/// ``APIClient`` calls this for you. Call it yourself only to check the URL a request produces:
///
/// ```swift
/// let url = try makeURL(for: GetCurrentWeatherRequest(latitude: -6.2, longitude: 106.8))
/// // https://api.open-meteo.com/v1/forecast?latitude=-6.2&longitude=106.8&current=temperature_2m
/// ```
///
/// - Throws: ``APIError/invalidURL`` if the parts don't form a valid URL.
func makeURL<T: APIRequest>(for request: T) throws -> URL {

    guard var components = URLComponents(
        url: APIConfig.baseURL.appendingPathComponent(request.endpoint.path),
        resolvingAgainstBaseURL: false
    ) else {
        throw APIError.invalidURL
    }

    if !request.endpoint.queryItems.isEmpty {
        components.queryItems = request.endpoint.queryItems
    }

    guard let url = components.url else {
        throw APIError.invalidURL
    }

    return url
}

/// The HTTP methods ``APIRequest`` supports.
public enum HTTPMethod: String {
    /// Reads data. Send parameters as query items, not a body.
    case get = "GET"
    /// Creates something, usually with a JSON body.
    case post = "POST"
    /// Replaces something, with the full new version as the body.
    case put = "PUT"
    /// Removes something.
    case delete = "DELETE"
}


/// Sends ``APIRequest``s and decodes their JSON responses.
///
/// Don't create one in a feature. Use the shared instance on ``AppContainer/api``:
///
/// ```swift
/// let weather = try await container.api.execute(
///     GetCurrentWeatherRequest(latitude: -6.2, longitude: 106.8)
/// )
/// ```
///
/// Pass your own `URLSession` or `JSONDecoder` to ``init(session:decoder:)`` for tests, or for a
/// decoder with different date or key strategies.
final class APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    /// - Parameters:
    ///   - session: Sends the requests. Defaults to `URLSession.shared`.
    ///   - decoder: Decodes every response. The default expects JSON keys to match property names,
    ///     so map snake_case keys with `CodingKeys`.
    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }
    
    /// Sends `request` and decodes the response as `R.Response`.
    ///
    /// Only 2xx responses are decoded; any other status throws, and the response body is dropped.
    ///
    /// - Throws:
    ///   - ``APIError/invalidURL`` if the URL can't be built.
    ///   - ``APIError/invalidResponse`` if the response isn't HTTP.
    ///   - ``APIError/httpStatusCode(_:)`` for any status outside 200–299.
    ///   - ``APIError/decoding(_:)`` if the JSON doesn't match `R.Response`.
    ///   - The `URLError` itself for network failures, such as being offline, timing out, or the task
    ///     being cancelled. These aren't wrapped in ``APIError``.
    ///   - The `EncodingError` itself if the body can't be encoded.
    func execute<R: APIRequest>(
        _ request: R
    ) async throws -> R.Response {

        let url = try makeURL(for: request)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        if let body = request.body {
            urlRequest.httpBody = try JSONEncoder().encode(body)

            urlRequest.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpStatusCode(http.statusCode)
        }

        do {
            return try decoder.decode(R.Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
