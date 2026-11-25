# Retries and Interceptors

Retry a failed request and change one on the way out.

## Turn on retries

`Labrador` doesn't retry by default. Give it a ``Labrador/RetryPolicy`` at init
or per request:

```swift
let client = Labrador(
    configuration: .init(
        retryPolicy: .standard,
    )
)
```

The presets are:

| Policy | Attempts | Waits |
| --- | --- | --- |
| `.none` | 1 | None |
| `.standard` | 3 | 1s, then 5s |
| `.aggressive` | 5 | 1s, 3s, 10s, 30s |

A custom policy takes the attempt count, the backoff and the codes that should
trigger a retry:

```swift
let policy = Labrador.RetryPolicy(
    maxRetries: 3,
    backoff: .exponential(base: 1, maximum: 30),
    retryCodes: [408, 429, 500, 502, 503, 504],
)
```

``Labrador/RetryPolicy/Backoff`` has three shapes: a constant delay, exponential
backoff, and a fixed list of delays. The last delay in a fixed list is reused
when the attempts run past the list.

The default retry codes are 408, 429, 500, 502, 503 and 504. The default
`URLError` codes are a timeout, a lost connection, no internet connection, a
host that can't be reached and a host that can't be found.

## When the server says wait

A `Retry-After` or `RateLimit-Reset` header with a number of seconds replaces
the policy's delay for that retry. A hint longer than a minute is capped at a
minute, so a screen never sits on one request longer than that. An HTTP-date
`Retry-After` isn't read; the policy's backoff covers it.

## Interceptors

An interceptor sees the request before it goes out and the response before it
comes back. It gets a `proceed` closure, and it decides whether to call it:

```swift
let refresh: Labrador.Interceptor = { request, proceed in
    let (data, response) = try await proceed(request)

    guard response.statusCode == 401 else {
        return (data, response)
    }

    let token = try await refreshToken()
    var retry = request
    retry.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return try await proceed(retry)
}

let client = Labrador(
    configuration: .init(interceptors: [refresh])
)
```

`proceed` can be called zero times, once or more than once. Calling it twice is
how a token refresh retries the request without involving the retry policy.

The order is the order you think of it in: the first interceptor in the array
sees the request first and the response last. The rest stack inside it, and the
network call is in the middle.

An interceptor can also change the request before it goes out, add a header, or
return a response without calling the network at all.

## Per-request changes

``Labrador/RequestOptions`` overrides the client's settings for one call:

```swift
let options = Labrador.RequestOptions(
    retryPolicy: .none,
    skipRetry: false,
)
```

`retryPolicy` replaces the client's policy, `interceptors` adds to the client's
list, and `skipRetry` ignores the client's policy. The verb methods don't take
options. To use them, build a `URLRequest` and call
`data(from:options:...)` or `request(_:as:options:...)`.

## Pace the requests

A ``RateLimiter`` is a token bucket. The bucket starts full with `burst` tokens
and earns `requests` more every `per` seconds. Once it's empty, `acquire()`
waits for the next token:

```swift
let limiter = RateLimiter(requests: 10, per: 60, burst: 5)

try await limiter.acquire()
let data = try await client.get(url)
```

The limiter is an actor, so several tasks can share one without a lock. A task
that's canceled while waiting doesn't spend its token.

## What retries don't cover

A retry is the same request again. It doesn't refresh a token, change a body or
wait for the user. Those are interceptor jobs, or the app's.

Cancellation isn't a failure. A canceled task throws `CancellationError`, not a
``LabradorError``, and the retry loop stops.
