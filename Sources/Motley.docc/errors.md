# Errors

What each error type means and what to do about it.

## The common protocol

The errors with a summary conform to ``MotleyError``. It has a summary,
optional details, an optional underlying error, and an ``ErrorKind``:

```swift
public protocol MotleyError: LocalizedError {
    var summary: String { get }
    var details: String? { get }
    var underlyingError: (any Error)? { get }
    var errorKind: ErrorKind { get }
}
```

``ErrorKind`` is a rough guess at whether trying again can help:

| Kind | Meaning |
| --- | --- |
| `.transient` | A timeout, a dropped connection, a 429 or a 5xx. Trying again can work. |
| `.persistent` | A 4xx that won't fix itself, a bad response or a rejected credential. Trying the same call won't help. |
| `.configuration` | The app needs a different setting first: a URL, a host, a port. |
| `.unclassified` | The default when an error type doesn't say. |

Any error also gets an `errorKind` through the `Error` extension. A `URLError`
that times out or loses its connection is transient; anything else is
persistent.

## LabradorError

A request that didn't finish, or finished with a non-2xx status. It keeps the
request, the response, the raw body, the body as text and the timing. The body
text is capped at 2,000 characters.

```swift
do {
    let stations = try await client.get(url, as: [Station].self)
} catch let error as LabradorError {
    switch error.errorKind {
    case .transient:
        showRetryLater()
    case .persistent:
        show(error.summary)
    case .configuration:
        showSettings()
    case .unclassified:
        show(error.summary)
    }
}
```

`statusCode` is the typed ``Labrador/StatusCode``, `header(_:)` reads a response
header, and `response(as:)` tries the body as another type for an error screen.

The error keeps the request, so a report made from it can include the
`Authorization` header or a token in the query string. The response body can
hold one too. Redact both before you share the report.

## JaysonError

A value that couldn't be encoded or decoded. `process` says which direction,
`details` has the coding path, and `jsonText` keeps the data when there was
data. A decoding failure usually means the response isn't the shape you
expected, or a field changed.

## EarlError

A URL that couldn't be made. `urlString` is the string the builder started
with, and `urlComponents` has the parsed pieces when parsing got that far. This
is a `.configuration` error; fix the string or the base URL.

## CaseyError

A CSV file that couldn't be written. The details include the byte count and the
file name. Check the destination and the app's file access.

## KeeperError

A keychain operation that failed. `status` is the `OSStatus` from the Security
framework, and the summary says which operation it was. A missing item is the
common case; a locked keychain is the one that surprises people.

## CurrentLocationError

`denied` means the app may not read the location. `unavailable` means no fix
arrived before the deadline, including when location services are off.

## TimeoutError

``Timeout/run(for:operation:)`` threw because the work didn't finish in time.
`duration` says how long it waited. Cancellation is not this error; it's a
`CancellationError`.

## Unzipper.ReadError

A zip archive or one of its entries couldn't be read. `notAZipArchive` means the
data isn't a zip; `unsupportedEntry` means the compression isn't handled;
`corruptEntry` means the entry's data is damaged.

## Describe an error

`Error.describe(options:)` builds a multi-line report for a diagnostics screen
or a support email. ``ErrorDescriptionOptions`` chooses what goes in:

```swift
let text = error.describe(options: .verbose)
```

`.minimal` is the summary, `.basic` adds the details, and `.verbose` adds the
underlying error and the `NSError` domain and code. `urlErrorSummary` is a
shortcut for the `URLError` case, with the failing URL.

## Cancellation

A canceled task throws `CancellationError`, not a ``MotleyError``. The HTTP
client stops its retry loop and doesn't turn the cancellation into a request
failure. Let it travel; don't show it to the user.

The next guide is <doc:symbols>.
