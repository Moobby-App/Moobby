# Networking

Define a request as a small struct, send it with the shared client, and handle the result in a view model.

## Overview

A network call in Moobby goes through five pieces:

| Piece | Role |
|---|---|
| ``APIConfig`` | Picks the server: ``AppEnvironment`` decides, ``APIConfig/baseURL`` gives the host. |
| ``Endpoint`` | The path and query items after the host. |
| ``APIRequest`` | One call: ``HTTPMethod``, endpoint, optional body, and the response type. |
| ``APIClient`` | Builds the URL with ``makeURL(for:)``, sends the request, and decodes 2xx JSON. |
| ``APIError`` | What went wrong when it fails. |

![A request goes to makeURL(for:), which adds APIConfig's base URL, then to APIClient. A 2xx response decodes to the Response type; anything else throws APIError or URLError.](networking-flow)

The examples use [Open-Meteo](https://open-meteo.com), the API the app points at today. It's free and needs no key.

## Development and Production

An app usually talks to two servers:

- **Development**: a test server with test data. You run against it while building features, so a broken request or a bad record never touches real users.
- **Production**: the live server. Every build that reaches users, through TestFlight or the App Store, must use it.

``AppEnvironment`` names the two, and ``APIConfig`` turns the current one into a URL. Today ``APIConfig/environment`` is fixed to `.development` and both cases return Open-Meteo, so nothing changes yet. When the app gets its own backend, give each environment its own URL and choose it by build configuration:

```swift
enum APIConfig {
    #if DEBUG
    static let environment: AppEnvironment = .development
    #else
    static let environment: AppEnvironment = .production
    #endif

    static var baseURL: URL {
        let urlString: String
        switch environment {
        case .development:
            urlString = "https://dev-api.moobby.app"
        case .production:
            urlString = "https://api.moobby.app"
        }

        guard let url = URL(string: urlString) else {
            fatalError("Invalid base URL string: \(urlString)")
        }

        return url
    }
}
```

`DEBUG` is defined for the Debug configuration, which **Run** in Xcode uses. **Archive** uses Release, which doesn't define it. So builds you run while developing hit development, and anything you upload hits production. You don't have to remember to switch.

> Important: Never ship a Release build that points at development. Check ``APIConfig/environment`` before you change the `#if`.

Requests don't change between environments. Every ``Endpoint`` path is resolved against ``APIConfig/baseURL``, so the same `GetCurrentWeatherRequest` reaches whichever server is active.

## Describe the Endpoint

An ``Endpoint`` is the path plus query items. Pass raw values; they're percent-encoded for you.

```swift
Endpoint(path: "/v1/forecast", queryItems: [
    URLQueryItem(name: "latitude", value: "-6.2"),
    URLQueryItem(name: "longitude", value: "106.8"),
    URLQueryItem(name: "current", value: "temperature_2m")
])
```

Start the path with `/`, and keep `?` out of it: a query string in `path` is encoded as part of the path and the server won't see it. With no query items, `Endpoint(path: "/notes")` is enough.

## Define the Response

The response type mirrors the JSON. Open-Meteo answers the endpoint above with:

```json
{
  "latitude": -6.22,
  "longitude": 106.78,
  "current": { "time": "2026-10-18T08:30", "interval": 900, "temperature_2m": 32.9 }
}
```

Declare only the fields you use. ``APIClient``'s decoder expects keys to match property names, so map snake_case keys with `CodingKeys`:

```swift
struct CurrentWeather: Decodable, Sendable {
    let current: Current

    struct Current: Decodable, Sendable {
        let temperature: Double

        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
        }
    }
}
```

## Write the Request

Conform a struct to ``APIRequest``. Properties become the request's inputs.

```swift
struct GetCurrentWeatherRequest: APIRequest {
    typealias Response = CurrentWeather

    let latitude: Double
    let longitude: Double

    var method: HTTPMethod { .get }
    var endpoint: Endpoint {
        Endpoint(path: "/v1/forecast", queryItems: [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m")
        ])
    }
    var body: EmptyBody? { nil }
}
```

To check the URL a request builds, call ``makeURL(for:)``:

```swift
let url = try makeURL(for: GetCurrentWeatherRequest(latitude: -6.2, longitude: 106.8))
// https://api.open-meteo.com/v1/forecast?latitude=-6.2&longitude=106.8&current=temperature_2m
```

### Sending a Body

For ``HTTPMethod/post`` and ``HTTPMethod/put``, set `body` to an `Encodable` value. ``APIClient`` encodes it as JSON and adds `Content-Type: application/json`. Open-Meteo is read-only, so this example is for your own backend:

```swift
struct NewNote: Encodable {
    let title: String
}

struct Note: Decodable, Sendable {
    let id: String
    let title: String
}

struct CreateNoteRequest: APIRequest {
    typealias Response = Note

    let body: NewNote?

    var method: HTTPMethod { .post }
    var endpoint: Endpoint { Endpoint(path: "/notes") }
}

// try await container.api.execute(CreateNoteRequest(body: NewNote(title: "Groceries")))
```

Pick the method by what the call does: `.get` reads, `.post` creates, `.put` replaces, and `.delete` removes. A `.get` sends its parameters as query items, never as a body.

## Send It from a View Model

Use the client on ``AppContainer/api``. Don't create an ``APIClient`` in a feature. Keep the call in the view model, and catch errors there so the view only shows state:

```swift
@Observable @MainActor
final class WeatherViewModel {
    private let container: AppContainer

    var temperature: Double?
    var errorMessage: String?

    init(container: AppContainer) {
        self.container = container
    }

    func load(latitude: Double, longitude: Double) async {
        do {
            let weather = try await container.api.execute(
                GetCurrentWeatherRequest(latitude: latitude, longitude: longitude)
            )
            temperature = weather.current.temperature
            errorMessage = nil
        } catch APIError.httpStatusCode(400) {
            errorMessage = "That location isn't valid."
        } catch let error as URLError where error.code == .cancelled {
            return // The view went away; nothing to show.
        } catch {
            container.log.error("Weather failed: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}
```

Start it from the view with `.task { await viewModel.load(latitude: -6.2, longitude: 106.8) }`. SwiftUI cancels the task when the view disappears, which is the `.cancelled` case above.

## Handle Errors

``APIClient/execute(_:)`` throws these:

| Error | When | What to do |
|---|---|---|
| ``APIError/invalidURL`` | The base URL, path, and query items don't form a URL. | A bug: fix the ``Endpoint``. |
| ``APIError/invalidResponse`` | The response isn't HTTP. | Rare; show a generic message. |
| ``APIError/httpStatusCode(_:)`` | The server returned a status outside 200–299. Open-Meteo returns `400` for an invalid location. | Match the codes you can explain, such as `401` or `404`. |
| ``APIError/decoding(_:)`` | The JSON doesn't match `Response`. | A bug: compare the type to the real JSON. The wrapped `DecodingError` names the key. |
| `URLError` | Offline, timed out, or cancelled. These aren't wrapped in ``APIError``. | Ignore `.cancelled`; offer a retry for the others. |

Every error has a readable `localizedDescription`, so the final `catch` can always show something. ``APIError/underlyingError(_:)`` is never thrown by the client; use it if your own code needs to wrap a failure as an ``APIError``.

## Topics

### Configuration

- ``AppEnvironment``
- ``APIConfig``

### Building Requests

- ``APIRequest``
- ``Endpoint``
- ``HTTPMethod``
- ``EmptyBody``
- ``makeURL(for:)``

### Sending and Errors

- ``APIClient``
- ``APIError``
