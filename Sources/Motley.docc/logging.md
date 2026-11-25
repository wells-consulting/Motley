# Logging

Write log lines with `Timber`.

## Make a logger

`Timber` writes to `os.Logger`. The subsystem defaults to
`"consulting.wells.Motley"` and the category defaults to the file that made the
logger:

```swift
let log = Timber(category: "network")

log.debug("Building the request")
log.info("Loaded 42 stations")
log.notice("The server sent a new header")
log.error("The request failed")
```

The levels are ``TimberLogLevel``: `debug`, `info`, `notice` and `error`.

Each call records the file, function and line. ``Timber/Formatting`` changes
what a line includes:

```swift
let quiet = Timber(
    category: "network",
    formatting: [.omitSourceLocation],
)
```

Use `.omitSourceLocation` for a line that's already clear, and
`.decorateSourceLocation` when you want the location in the message instead of
after it.

## Put a job in the label

``Timber/Context`` adds a task-local label, so one line says which job it came
from:

```swift
await Timber.Context.withValue("settings") {
    log.info("Loading the account")
}
```

The label follows `async let`, task groups and actor hops. Only
`Task.detached` starts without it. `withPurpose` adds a second level, so a call
says why it fired as well as where it came from.

`Timber.Context.logCall` logs a call with the label in front.
`Timber.Context.Detail.summaryOnly` turns that off for a batch job, leaving the
scope's start and finish lines.

## Persist to a file

Bind a ``Timber/Channel`` at init to keep entries at or above a level:

```swift
let channel = Timber.Channel(
    name: "network",
    directory: logsDirectory,
    rotation: .bySize(thresholdBytes: 1_000_000),
)

let log = Timber(
    channel: channel,
    minimumPersistedLevel: .notice,
)
```

The channel writes `<name>.jsonl`, one JSON entry per line. `bySize` renames the
current file to `<name>.jsonl.1` when it reaches the threshold and starts a new
one. `byCountAndAge` keeps at most `maxEntries` and drops anything older than
`maxAge` seconds, rewriting the file when the cap is exceeded.

Read the entries back with `entries`, which merges the rotated file and the
current one, oldest first. `maxReadEntries` caps the result to the newest
entries. `deleteAll` removes the files and bumps the generation, so a write
that started before the delete is dropped.

The write is a task, so a line may not be on disk the instant the call returns.
`appendSync` and `deleteAllSync` are there for a caller that can't wait.

The category on a persisted entry comes from the call site, not from the logger.
Pass `category:` on a call when the file name isn't the right label. The
category given to `Timber`'s init only labels the `os.Logger` pair.

## Log an error

`Timber.do` runs a closure and logs anything it throws. Cancellation is a
request to stop, so it isn't logged:

```swift
log.do("saving settings") {
    try settings.save()
}
```

The async forms return `nil` when the closure throws.

## Opaque lines

``TimberLineStore`` keeps plain lines instead of `TimberLogEntry` values. Use it
for an audit trail or a file another tool reads. It rotates the same way and
never touches `os.Logger`.

The next guide is <doc:json>.
