# Motley

A motley assortment of handy Swift bits: HTTP, JSON, logging, CSV, secure
storage, location, fuzzy dates and the SF Symbol names.

[![Documentation](https://img.shields.io/badge/documentation-DocC-blue)](https://swiftpackageindex.com/wells-consulting/motley/documentation/motley)

Swift 6.4, Swift 6 language mode, strict concurrency.

## Platforms

| Platform | Minimum |
| --- | --- |
| iOS | 18 |
| tvOS | 18 |
| watchOS | 11 |
| macOS | 15 |

The package is Apple platforms only. `Keeper` uses the Security framework,
`Location` uses CoreLocation, and `Timber` uses `os.Logger`.

## Install

```swift
dependencies: [
    .package(url: "https://github.com/wells-consulting/Motley.git", from: "1.2.0"),
]
```

Add the product to the target that needs it:

```swift
.product(name: "Motley", package: "Motley")
```

## What's inside

| Folder | Job |
| --- | --- |
| `Labrador` | An async HTTP client with retries, interceptors and TLS trust. |
| `Earl` | A URL builder. |
| `Jayson` | JSON encoding and decoding. |
| `Timber` | `os.Logger` output, with optional file persistence. |
| `Casey` | A CSV writer. |
| `Keeper` | A keychain-backed key-value store. |
| `Location` | One location fix, with a deadline. |
| `FuzzyDate` | Dates that may only have a year, or a year and a month. |
| `Infrastructure` | `SFSymbol`, `Message`, `Timeout`, zip files and the shared helpers. |

## Usage

```swift
import Motley

let client = Labrador(
    configuration: .init(baseURL: URL(string: "https://api.example.com"))
)

let data = try await client.get(
    URL(string: "https://api.example.com/status")!
)
```

```swift
let log = Timber(category: "app")
log.info("Loaded the account")
```

```swift
let data = try Jayson.shared.encode(account)
let account = try Jayson.shared.decode(Account.self, from: data)
```

`Labrador` doesn't retry, cache or wait between requests unless you configure
it to. Failures are `LabradorError` values, and they keep the request,
response and body for a report.

## Documentation

The DocC guides cover the HTTP client, retries and interceptors, logging, JSON,
secure storage, errors and the symbols.

- [Motley](https://swiftpackageindex.com/wells-consulting/motley/documentation/motley)
- [Getting Started](https://swiftpackageindex.com/wells-consulting/motley/documentation/motley/getting-started)

## Testing

```sh
swift test
swift format lint --strict --configuration .swift-format --recursive Sources
```

## License

MIT. See `LICENSE`.
