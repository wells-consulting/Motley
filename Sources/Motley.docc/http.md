# HTTP

Make requests with `Labrador`.

## Make a client

`Labrador` takes a ``Labrador/Configuration`` at init. Everything on the
configuration has a default, so a client with no settings works. Set the base
URL, headers and timeouts once:

```swift
let client = Labrador(
    configuration: .init(
        baseURL: URL(string: "https://api.example.com"),
        headers: ["Accept-Language": "en-US"],
        requestTimeout: 30,
        resourceTimeout: 60,
        logOptions: [.request, .response],
    )
)
```

The configuration also holds a token, a coder, a cache policy, a retry policy,
interceptors and the TLS trust policy. The rest of this guide covers the pieces
you'll reach for most.

## Build a URL

`url(for:queryItems:)` resolves a path against the base URL. With no base URL,
the path is treated as an absolute URL string.

```swift
let url = try client.url(
    for: "stations",
    queryItems: [URLQueryItem(name: "limit", value: "20")],
)
```

## Make a request

There's a method family for each verb: `get`, `post`, `put`, `patch`, `delete`,
`head` and `options`. Each has a version that returns `Data?` and a version that
decodes:

```swift
struct Station: Decodable {
    let id: String
    let name: String
}

let stations: [Station] = try await client.get(
    try client.url(for: "stations"),
    as: [Station].self,
)
```

`post`, `put`, `patch` and `delete` take a body: a `URLRequest`, raw `Data`, an
`Encodable` value, a ``MultipartForm`` or a ``URLEncodedForm``. The body is
encoded with the client's ``Jayson``.

```swift
let created: Station = try await client.post(
    try client.url(for: "stations"),
    body: newStation,
    as: Station.self,
)
```

`head` and `options` return the `HTTPURLResponse` and no body.

### Keep the response

The plain methods return just the decoded value. The `WithResponse` variants
return a ``Labrador/Response`` with the value and the HTTP response, which is
where the status code and headers live:

```swift
let response = try await client.getWithResponse(
    try client.url(for: "stations/42"),
    as: Station.self,
)

print(response.statusCode)
print(response.header("ETag") ?? "-")
print(response.value.name)
```

### Send a request you already have

`data(from:options:logging:logContext:)` takes a `URLRequest` and returns the
body and response. `request(_:as:options:logging:logContext:)` takes the same
request and decodes it.

## Forms

``MultipartForm`` builds a `multipart/form-data` body. Add fields with the
`addingField` methods, then pass the form to a request:

```swift
let url = try client.url(for: "stations")
let form = MultipartForm()
    .addingField(name: "name", value: "Station 42")
    .addingField(name: "photo", value: imageData, savingTo: "station.jpg")

try await client.post(url, form: form)
```

``URLEncodedForm`` does the same for
`application/x-www-form-urlencoded`.

## Uploads and downloads

`upload` returns an `AsyncStream` of ``Labrador/UploadEvent``. It reports
progress and finishes with the response body:

```swift
for await event in client.upload(url, data: body) {
    switch event {
    case let .progress(bytesSent, totalBytes):
        print(bytesSent, totalBytes ?? 0)
    case let .completed(data):
        print("done", data.count)
    case let .failed(error):
        print(error)
    }
}
```

`downloadInMemory` does the same for a download. `downloadToFile` writes to
disk and returns a ``Labrador/FileDownloadTransfer``. It reports a temporary
file URL, and you move the file before the system clears the temporary
directory. It can also return resume data when a download is canceled.

## Headers and auth

`header(_:)`, `setHeader(_:to:)` and `removeHeader(_:)` change the headers the
client adds to every request. `setAuth(_:)` sets a bearer token from an
``OAuthToken``:

```swift
client.setAuth(token)
```

## What the client doesn't do

It doesn't retry unless you give it a ``Labrador/RetryPolicy``. It doesn't wait
between requests unless you use a ``RateLimiter``. It also doesn't cache beyond
what `URLSession` does. It logs retries and failed status codes without being
asked; ``Labrador/LogOptions`` adds the request and response lines.

A non-2xx status throws ``LabradorError``. The error keeps the request, the
response, the body and the timing, which is enough for an error screen or a
support report.

## Trust and the local network

``Labrador/TLSTrustPolicy`` is `.system` by default. `.trustSelfSigned` accepts
a certificate the system would reject, so use it only for a server the user has
chosen to trust.

On iOS, a request to a local server can fail before the user responds to the
local network prompt. `Labrador.LocalNetworkAuthorization.request()` triggers
the prompt and waits for the response. It needs `_preflight_check._tcp` in the
app's `NSBonjourServices` list.

The next guide is <doc:retries-and-interceptors>.
