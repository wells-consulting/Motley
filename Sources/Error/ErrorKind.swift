//
// Copyright 2025 Wells Consulting.
// This file is part of Motley and is released under the MIT License.
//

import Foundation

/// Classifies errors by their expected recovery behavior.
public enum ErrorKind: String, Sendable {

    /// Transient failures that may succeed on retry (network timeout, temporary
    /// server error, rate limiting).
    case transient

    /// Persistent failures where retrying the same operation won't help without
    /// user intervention (bad credentials, missing resource, permission denied).
    case persistent

    /// Configuration errors where the user needs to change a setting before
    /// retrying (invalid URL, missing host, bad port).
    case configuration
}
