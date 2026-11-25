# Small Helpers

URLs, CSV, fuzzy dates and one location fix.

## URLs

``Earl`` builds a URL one piece at a time. A `nil` value is ignored, so an
optional can go straight in:

```swift
let url = try Earl("https://example.com/api")
    .path("v1")
    .path("stations")
    .query("active", true)
    .query("limit", 50)
    .query("cursor", nextCursor)
    .build()
```

`build()` needs a scheme and a host, and throws ``EarlError`` when it doesn't
have them. The throwing init checks the string the same way. `absoluteString`
shows the URL text without building it.

`path` splits on slashes, so `.path("v1/stations")` adds two segments. Dates in
a query use ISO 8601 unless the builder was given another formatter.

`URL.from(_:)` is the one-line version when you have a string and want a
``EarlError`` instead of `nil`.

## CSV

``Casey`` collects rows and writes them to a file:

```swift
let csv = Casey(headerRow: "name,age,city")
csv.addRow("Alice,30,Portland")
csv.addRow("Bob,25,Seattle")
try csv.save(to: fileURL)
```

`text` returns the rows without the header. The header is added when you save,
so save once. Saving the same instance twice adds the header twice.

`saveToDownloadsFolder(filename:)` is the same write, pointed at the user's
Downloads folder. ``CaseyError`` says which write failed and includes the byte
count.

## Fuzzy dates

``FuzzyDate`` reads a date that may only have a year, or a year and a month:

```swift
let date = FuzzyDate("2024-06")
date?.precision      // .yearMonth
date?.displayString  // "June 2024"
```

A partial date fills the missing parts with the earliest value: a year becomes
January 1, and a year and month becomes the 1st. That makes sorting and
comparison work, but it doesn't mean the original string had a day.

`displayString` keeps the original precision. `monthYearString` always shows a
month and year, or just the year for a year-only value. `age(at:)` counts whole
years to a reference date.

``FuzzyDateParser`` is a shim over the same parsing. New code can use
``FuzzyDate`` directly.

## One location fix

``CurrentLocation`` asks for permission and waits for a fix:

```swift
let location = CurrentLocation()
let coordinate = try await location.locate(timeout: .seconds(10))
```

The first call triggers the system prompt. A refusal throws
``CurrentLocationError/denied``. No fix before the deadline, or location
services turned off, throws ``CurrentLocationError/unavailable``.

The app needs a location usage description in its `Info.plist`. Without one,
the prompt never appears and the call ends as unavailable.

## Deadlines

``Timeout`` puts a deadline around async work:

```swift
let value = try await Timeout.run(for: .seconds(5)) {
    try await load()
}
```

When the deadline passes, the work is canceled and the call throws
``TimeoutError``. `duration` says how long it waited. Cancellation from the
caller is a `CancellationError`, not a timeout.

## Zip files

``Zipper`` builds an archive from a temporary directory:

```swift
let zipper = Zipper(filename: "export")
try zipper.addText("name,age\nAlice,30", as: "people.csv")
try zipper.addDirectory(contentsOf: mediaDirectory, as: "media")
let archive = try zipper.zipit()
```

`zipit()` removes the staging directory and returns the archive's URL, or `nil`
when the copy failed. The archive is in the temporary directory, so move it
before the system clears that directory.

``Unzipper`` reads an archive in memory. It handles stored and DEFLATE entries,
which is what an `.xlsx` workbook uses. It doesn't handle encryption or zip64,
and it reads the whole archive at once.

```swift
let zip = try Unzipper(data: data)
let sheet = try zip.contents(of: "xl/worksheets/sheet1.xml")
```

## Words and versions

``WordList`` has the adjectives and nouns behind the two-word names.
`randomCode(words:)` takes them in turn, so an odd count ends on an adjective.

``StableIdentifier`` makes a two-word phrase from a keychain seed. Two launches
with the same seed get the same phrase, which is useful for correlating a
diagnostics report. It isn't a device identifier, and if the keychain is
unavailable the phrase is new on each launch.

```swift
let identifier = StableIdentifier()
print(identifier.phrase)  // "amber_harbor"
```

``SemanticVersion`` parses `"v1.2.3"` or `"1.2.3"` into `major`, `minor` and
`patch`. A missing patch is zero, and two versions compare by those three
numbers.
