# JSON

Read and write JSON with `Jayson`.

## Use the shared coder

``Jayson/shared`` is ready to use. It encodes ISO 8601 dates, pretty-prints with
sorted keys, accepts JSON5 and leaves `\u0000` escapes alone:

```swift
let data = try Jayson.shared.encode(station)
let decoded = try Jayson.shared.decode(Station.self, from: data)
```

`encode` takes a value and returns `Data`. `decode` takes a type and `Data`, or
a type and a `String`. `string(from:)` encodes straight to text, and `stringify`
does the same but returns `nil` instead of throwing.

## Change the settings

``Jayson/Configuration`` holds the encoder and decoder settings. Make a coder
when a call needs something different:

```swift
let coder = Jayson(
    configuration: .init(
        dateDecodingStrategy: .secondsSince1970,
        outputFormatting: [.sortedKeys],
        allowsJSON5: false,
        stripNullEscapes: true,
    )
)
```

The defaults are the property names for keys, ISO 8601 for dates, pretty output
with sorted keys, JSON5 on, and null-escape stripping off.

`stripNullEscapes` removes literal `\u0000` text before decoding. Some servers
send it inside strings; without the flag, the decoder keeps it.

## Let one field fail

``SafeDecodable`` wraps one element and decodes it to `nil` when it fails. Use it
on an array when one bad row shouldn't lose the rest:

```swift
let rows = try Jayson.shared.decode(
    [SafeDecodable<Row>].self,
    from: data,
)

let goodRows = rows.compactMap(\.value)
```

It catches every decoding error for that element, including a missing key, so
don't use it where a missing key is a bug you want to see.

## A missing Bool means false

``DefaultFalse`` turns a missing key into `false`, so the property doesn't have
to be optional:

```swift
struct Settings: Codable {
    @DefaultFalse var verified: Bool
}
```

`{}` decodes to `false`. A present `true` or `false` decodes as you'd expect.

## Errors

A failed encode or decode throws ``JaysonError``. It has the process (`encode`
or `decode`), a summary, the coding path in `details`, and the JSON text when
there was data to keep. <doc:errors> has the rest.

The next guide is <doc:secure-storage>.
