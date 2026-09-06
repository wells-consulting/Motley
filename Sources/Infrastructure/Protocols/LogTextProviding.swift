//
// Copyright 2025 Wells Consulting.
//

import Foundation

/// Types providing safe and/or redacted log text.
public protocol LogTextProviding {
    var logText: String { get }
}
