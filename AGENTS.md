# Agent guide for Motley

Motley is the Swift toolkit the apps here are built on: HTTP, JSON, logging,
CSV, secure storage, location and the SF Symbol names. Motley, Motley and
Motley each take it by version, so a change isn't theirs until it's tagged.

Read [VOICE.md](VOICE.md) before you write a comment, a doc comment, a name, a
log message, UI text or a commit message. If this file and VOICE.md disagree,
VOICE.md wins.

`motley-change` in `.agents/skills/` is the procedure: the module map, how to
prove a change, and how to tag and re-pin it. This file is the rules.

## The package

One module, `Motley`, one product, and a folder per job under `Sources/`:

- `Labrador` — the async HTTP client. Retry, interceptors, TLS trust policy.
- `Earl` — the URL builder.
- `Jayson` — JSON, with `DefaultFalse` and `SafeDecodable`.
- `Timber` — logging, channels and file rotation.
- `Casey` — CSV.
- `Keeper` — secure storage.
- `Location` — the current location.
- `FuzzyDate` — date phrasing.
- `Infrastructure` — `SFSymbol`, the `*+Extensions` helpers and the error type.

`SFSymbol` is how every repo here names a symbol. A string like
`systemName: "gear"` fails lint, and the fix belongs here, as a new case.

## Requirements

- Swift 6.4 tools, Swift 6 language mode, strict concurrency.
- iOS 18, tvOS 18, watchOS 11, macOS 15. Raising the floor breaks three apps,
  so check `Package.swift` before you use a new API.
- One dependency, `SwiftLintPlugins`, and only as a build plugin.

## Rules

- No `try?`. Handle the error, or `log.do("activity") { ... }` when a failure
  is allowed.
- No global functions or variables. Scope them to an enum.
- No `Formatter` subclasses and no `String(format:)`. FormatStyle, and
  `Text(_, format:)` in a view.
- No `DispatchQueue`. Async/await first.
- No UIKit or AppKit. This is the model and network layer; anything that draws
  belongs in Motley.
- The public API is shared by three repos, so a rename or a removed default is
  a breaking change in all three.

## Build and test

```sh
swift build
swift test
Scripts/format.sh    # swift format
```

`.swift-format` is the formatting source of truth, and SwiftLint runs as a
build plugin, so a warning is a failure.

## Doc comments

The public API is also the documentation site, so a doc comment is reference
material, not conversation.

- A summary sentence first. Add a second paragraph only for a unit, a fallback
  or a gotcha.
- `- Parameter` and `- Throws` on public methods and initializers where they
  add something. Skip `- Returns` when the summary already says it.
- One short example when the call is easier to show than to describe.
- If the name says it, skip the property. `rawValue` and Codable boilerplate
  stay blank.

## Documentation

`Sources/Motley.docc/` holds the landing page and the guides, and `.spi.yml`
names the documentation target. Build it before a tag:

```sh
xcodebuild docbuild \
  -scheme Motley \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$TMPDIR/motley-docs" \
  OTHER_DOCC_FLAGS="--warnings-as-errors" \
  -quiet
```

That catches an unresolved symbol link, not a missing comment. The generated
`SFSymbol` extension is hidden from docs; add new names there and keep the
semantic names documented.
