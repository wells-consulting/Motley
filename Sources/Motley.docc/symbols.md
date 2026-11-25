# Symbols

Name SF Symbols with `SFSymbol`.

## Use a symbol

``SFSymbol`` wraps the name Apple uses for an SF Symbol. The value is the
string, so it goes straight into SwiftUI:

```swift
import SwiftUI

Image(systemName: SFSymbol.gear.rawValue)
```

The point is the name. A `systemName: "gear"` string fails lint, and a typo
fails at runtime with a blank image. A symbol that doesn't exist fails to
compile.

## Start with the semantic names

Seven aliases cover the states and actions the apps repeat:

| Name | Symbol |
| --- | --- |
| `.error` | A filled triangle with an exclamation mark |
| `.success` | A checkmark in a circle |
| `.warning` | A triangle with an exclamation mark |
| `.cancel` | An X in a circle |
| `.download` | A down arrow in a circle |
| `.refresh` | A circular arrow |
| `.share` | An up arrow out of a square |

Reach for these first. They're the ones ``Message/Kind`` uses, and they keep
the same meaning across the apps.

## The generated names

The package has a constant for every symbol in Apple's catalog, named after the
symbol with dots and hyphens turned into underscores:

```swift
SFSymbol.exclamationmark_triangle_fill   // "exclamationmark.triangle.fill"
SFSymbol.airpods_chargingcase_wireless   // "airpods.chargingcase.wireless"
```

That's 6,985 constants, so they aren't listed in this documentation. Browse
them in Apple's [SF Symbols](https://developer.apple.com/sf-symbols/) app and
then use the name with underscores. The generated file is
`Sources/Infrastructure/SFSymbol/SFSymbol+Generated.swift`.

The generated extension is hidden from DocC with
`@_documentation(visibility: internal)`. The type and the semantic aliases are
the documented part.

## Add a name

If the name you want isn't generated yet, add it next to the semantic aliases:

```swift
public extension SFSymbol {
    static let sidebar = Self(rawValue: "sidebar.left")
}
```

Keep the constant name the same as the symbol with dots replaced by
underscores. That keeps search predictable and makes the generated names and
the hand-written ones look alike.

A symbol is `Codable`, so it persists as its string. Renaming a constant doesn't
change what's saved; changing its `rawValue` does.

## Availability

Apple adds symbols in new OS releases. A symbol from a newer release draws
nothing on an older one, so check the availability when you pick a name that's
newer than the platform floor.

The next guide is <doc:small-helpers>.
