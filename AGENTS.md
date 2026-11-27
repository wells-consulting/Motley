# Agent guide for Motley

Motley is the Swift toolkit our apps are built on: HTTP, JSON, logging, CSV,
secure storage, location and the SF Symbol names. They take it by version, so a
change isn't live until it's tagged.

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
- iOS 18, tvOS 18, watchOS 11, macOS 15. Raising the floor breaks the apps that
  use it, so check `Package.swift` before you use a new API.
- One dependency, `SwiftLintPlugins`, and only as a build plugin.

## Rules

- No `try?`. Handle the error, or `log.do("activity") { ... }` when a failure
  is allowed.
- No global functions or variables. Scope them to an enum.
- No `Formatter` subclasses and no `String(format:)`. FormatStyle, and
  `Text(_, format:)` in a view.
- No `DispatchQueue`. Async/await first.
- No UIKit or AppKit. This is the model and network layer; anything that draws
  belongs in the app.
- The public API is shared by more than one repo, so a rename or a removed
  default is a breaking change in all of them.

## Build and test

```sh
swift build
swift test
Scripts/format.sh    # swift format
```

`.swift-format` is the formatting source of truth, and SwiftLint runs as a
build plugin, so a warning is a failure.

## Tags

A tag is permanent once it's pushed. Apps pin Motley by version, and SwiftPM
remembers the revision it first saw for each version, so a tag that moves
fails the resolve on every machine that already had the old one. That's why
`v1.1.0` had to be replaced by `v1.2.0` instead of fixed in place.

- `.githooks/pre-push` refuses a push that moves or deletes a tag the remote
  already has. Turn the hooks on in a clone with
  `git config core.hooksPath .githooks`.
- To release a change, bump `MotleyInfo.version` and tag a number nobody has
  used. If the hook fires, that's the answer, not an obstacle.
- `Scripts/check-tags.sh` compares the local tags with `github` by commit, for
  when one has already moved.

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
