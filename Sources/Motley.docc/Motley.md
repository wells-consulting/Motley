# ``Motley``

A Swift toolkit for the apps here: HTTP, JSON, logging, CSV, secure storage,
location, fuzzy dates and the SF Symbol names.

## Overview

Motley is one module with a folder for each job. ``Labrador`` is the HTTP
client. ``Jayson`` reads and writes JSON. ``Timber`` logs to the system log and,
when you ask, to a file. ``Keeper`` keeps secrets in the keychain. ``Casey``
writes CSV, ``Earl`` builds URLs, ``FuzzyDate`` reads partial dates,
``CurrentLocation`` gets one location fix, and ``SFSymbol`` names the symbols
the apps draw.

The package builds for iOS 18, tvOS 18, watchOS 11 and macOS 15. It has no
service of its own. The shared state is the coders in ``Jayson``, the keychain
items behind ``Keeper`` and the files behind ``Timber/Channel``.

## Topics

### Guides

- <doc:getting-started>
- <doc:http>
- <doc:retries-and-interceptors>
- <doc:logging>
- <doc:json>
- <doc:secure-storage>
- <doc:errors>
- <doc:symbols>
- <doc:small-helpers>

### Essentials

- ``MotleyInfo``
- ``MotleyError``
- ``ErrorKind``

### HTTP

- ``Labrador``
- ``Labrador/Configuration``
- ``Labrador/Method``
- ``Labrador/ContentType``
- ``Labrador/StatusCode``
- ``Labrador/Response``
- ``Labrador/CachePolicy``
- ``Labrador/LogOptions``
- ``Labrador/RetryPolicy``
- ``Labrador/RetryPolicy/Backoff``
- ``Labrador/RequestOptions``
- ``Labrador/TLSTrustPolicy``
- ``Labrador/Interceptor``
- ``Labrador/DownloadEvent``
- ``Labrador/UploadEvent``
- ``Labrador/FileDownloadEvent``
- ``Labrador/FileDownloadTransfer``
- ``LabradorError``
- ``MultipartForm``
- ``URLEncodedForm``
- ``OAuthToken``
- ``RateLimiter``

### URLs

- ``Earl``
- ``EarlError``

### JSON

- ``Jayson``
- ``Jayson/Configuration``
- ``JaysonError``
- ``JaysonError/Process``
- ``SafeDecodable``
- ``DefaultFalse``

### Logging

- ``Timber``
- ``Timber/Formatting``
- ``Timber/Channel``
- ``Timber/Channel/Rotation``
- ``Timber/Context``
- ``Timber/Context/Detail``
- ``TimberLogLevel``
- ``TimberLogEntry``
- ``TimberLineStore``

### CSV

- ``Casey``
- ``CaseyError``

### Secure storage

- ``Keeper``
- ``SecureStoring``
- ``InMemoryKeeper``
- ``KeeperError``

### Location

- ``CurrentLocation``
- ``CurrentLocationAuthorization``
- ``CurrentLocationError``

### Dates

- ``FuzzyDate``
- ``FuzzyDate/Precision``
- ``FuzzyDateParser``

### Shared

- ``Message``
- ``Message/Kind``
- ``SFSymbol``
- ``Timeout``
- ``TimeoutError``
- ``Zipper``
- ``Unzipper``
- ``Unzipper/ReadError``
- ``WordList``
- ``StableIdentifier``
- ``SemanticVersion``
- ``SourceLocation``
- ``LogTextProviding``
- ``SummaryProviding``
- ``ErrorDescriptionOptions``
