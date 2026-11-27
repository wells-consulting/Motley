# Getting Started

Add Motley to a package, make a client and read one response.

## Add the package

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/wells-consulting/Motley.git", from: "1.2.0"),
]
```

Then add the product to the target that needs it:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "Motley", package: "Motley")
    ]
)
```

## Make a request

``Labrador`` is the HTTP client. It takes a ``Labrador/Configuration`` at init,
and the configuration holds the things you'd otherwise repeat on every call:
base URL, headers, a token, a retry policy and the logging options.

```swift
import Motley

struct Status: Decodable {
    let ok: Bool
}

let client = Labrador(
    configuration: .init(
        baseURL: URL(string: "https://example.com"),
    )
)

let status = try await client.get(
    URL(string: "https://example.com/status")!,
    as: Status.self,
)
```

There's a method family for each verb: `get`, `post`, `put`, `patch`, `delete`,
`head` and `options`. A call that decodes returns your type. A call that
doesn't returns `Data?`. The `WithResponse` variants return a
``Labrador/Response`` with the decoded value and the HTTP response, which is
where the headers and status code live.

## Log one line

``Timber`` writes to `os.Logger` and, if you bind a ``Timber/Channel``, to a
file.

```swift
let log = Timber(category: "network")

log.info("Loaded \(status.ok ? "ok" : "not ok")")
log.error("The request failed")
```

Use ``Timber/Context`` when several lines belong to the same job:

```swift
await Timber.Context.withValue("settings") {
    log.info("Loading the account")
}
```

The file side is covered in <doc:logging>.

## Read and write JSON

``Jayson`` is the shared coder. It uses ISO 8601 dates, pretty-prints with
sorted keys, and accepts JSON5 by default.

```swift
let data = try Jayson.shared.encode(status)
let decoded = try Jayson.shared.decode(Status.self, from: data)
```

When one field can fail without taking the response down, wrap it in
``SafeDecodable``. When a Bool is missing and should mean `false`, use
``DefaultFalse``. <doc:json> has the rest.

## Where to go next

- <doc:http> for the client, its configuration and the request families.
- <doc:retries-and-interceptors> for retry policies, interceptors and rate
  limiting.
- <doc:logging> for `Timber` channels, rotation and reading entries back.
- <doc:json> for `Jayson`, `SafeDecodable` and `DefaultFalse`.
- <doc:secure-storage> for `Keeper` and the keychain.
- <doc:errors> for `MotleyError` and what each error type has.

The smaller modules are in <doc:small-helpers>: `Earl`, `Casey`, `FuzzyDate`
and `CurrentLocation`.
