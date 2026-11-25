# Secure Storage

Keep small values in the keychain with `Keeper`.

## Store a value

``Keeper`` is a keychain-backed key-value store. Values are `Codable`, encoded
with ``Jayson``, and stored as generic-password items under the service and key:

```swift
let keeper = Keeper()
try keeper.save(token, forKey: "oauth-token")
```

Read it back with the same type:

```swift
let token = try keeper.load(OAuthToken.self, forKey: "oauth-token")
```

`exists(key:)` checks without loading. `delete(key:)` removes the item and does
nothing when it isn't there.

The service defaults to the app's bundle identifier. Pass one explicitly when
two apps or an app and its extension share a keychain:

```swift
let keeper = Keeper(
    service: "com.example.shared",
    accessGroup: "TEAMID.com.example.shared",
)
```

## Choose keys carefully

The key is the account name on the keychain item. Use a stable string, not a
user-visible name, and keep the same key across launches. Changing the key
looks like a missing value, not a rename.

A short prefix keeps keys apart when a service holds more than one thing:

```swift
try keeper.save(refreshToken, forKey: "auth.refresh-token")
```

## Tests and previews

``InMemoryKeeper`` has the same methods and keeps everything in a dictionary.
It throws the same ``KeeperError`` cases, so code that catches one catches the
other:

```swift
let keeper: any SecureStoring = InMemoryKeeper()
try keeper.save(token, forKey: "oauth-token")
```

``SecureStoring`` is the protocol. Take it in a type that needs storage, then
pass `Keeper` in the app and `InMemoryKeeper` in a test.

## What can go wrong

A ``KeeperError`` says which operation failed and keeps the `OSStatus` from the
Security framework:

| Case | What happened |
| --- | --- |
| Item not found | `load` asked for a key that isn't there. |
| Save failed | The keychain refused the write. A locked keychain does this. |
| Load failed | The keychain returned something that isn't data. |
| Delete failed | The keychain refused the delete. |
| Encoding or decoding failed | `Jayson` couldn't turn the value into data, or back. |

`load` is the one to handle first. A missing token usually means the user
hasn't signed in, not that something is broken.

The next guide is <doc:errors>.
