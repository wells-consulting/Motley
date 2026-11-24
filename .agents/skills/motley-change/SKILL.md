---
name: motley-change
description: Use when changing Motley, the shared Swift package: adding or fixing something in Labrador, Earl, Jayson, Timber, Casey, Keeper, Location or FuzzyDate; running its tests; or releasing a version the apps can pin.
---

# Changing Motley

`AGENTS.md` carries the rules. This is the procedure around them.

## 1. Modules

| Module | Job |
|---|---|
| `Labrador` | HTTP |
| `Earl` | `urlBuilder()` |
| `Jayson` | JSON |
| `Timber` | logging |
| `Casey` | CSV |
| `Keeper` | storage helpers |
| `Location` | location |
| `FuzzyDate` | date phrasing |
| `Infrastructure` | shared internals |

`SFSymbol` lives here too and every app draws symbols through it. No file may name an SF Symbol as a string.

## 2. Rules that bite

- No `try?`. Handle it, or `log.do("activity") { ... }` when a failure is allowed.
- No global functions or variables. Scope them to an enum: `enum Global { static ... }`.
- No `Formatter` subclasses, no C-style `String(format:)`. FormatStyle and `Text(_, format:)`.
- No `DispatchQueue`. Swift 6.2 strict concurrency, async/await first.
- One type per file, sorted imports, trailing commas, attributes on their own line.

## 3. Prove it

```sh
swift build
swift test
Scripts/format.sh    # swift format
```

SwiftLint runs as a build plugin, so a warning is a failure, not a note.

## 4. Release, because the apps pin a version

Motley is consumed by **Motley**, **Motley** and **Motley**, all by version. A change isn't visible to them until it's tagged.

1. Commit with the repo's style: `v1.2.3 – Adds the retry-after header`. An assistant's body ends with `Assisted-by: AI (<model>)`, never a `Co-Authored-By` or "Generated with" line.
2. Tag it with `git tag -a v1.2.3 -m "v1.2.3"`, so the tag carries a tagger and a date.
3. Push the branch and the tag by name:

   ```sh
   git push github main
   git push github v1.2.3
   ```

   `git remote -v` shows which remote the consumers clone; `github` is the one they resolve from.
4. Raise the pin in every consumer:
   - Motley: `Package.swift` `.package(url: ...Motley, from:)`
   - Motley and Motley: `XCRemoteSwiftPackageReference` `minimumVersion` in `project.pbxproj`, then
     `xcodebuild -resolvePackageDependencies -project <name>.xcodeproj -scheme <name>`

Motley's own bump then flows on to its consumers; release it the same way rather than stopping at the pin.

## Checklist

- [ ] No `try?`, no SF Symbol strings, no global free functions
- [ ] `swift build` and `swift test` pass, lint clean
- [ ] Formatted
- [ ] An assistant's commit ends `Assisted-by: AI (<model>)`, with no `Co-Authored-By`
- [ ] Tagged and pushed if the apps need it
- [ ] Consumers' pins raised and resolved
