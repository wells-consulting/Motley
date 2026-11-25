//
// Copyright 2025 Wells Consulting.
//

import Foundation

/// A single persisted log entry produced by Timber.
public struct TimberLogEntry: Codable, Identifiable, Hashable, Sendable {

    /// A stable ID for the entry.
    public let id: UUID

    /// When the line was logged.
    public let timestamp: Date

    /// How serious the line is.
    public let level: TimberLogLevel

    /// The subsystem the logger was created with.
    public let subsystem: String

    /// The category the line was logged under.
    public let category: String

    /// The message, without the source decoration.
    public let message: String

    /// The file the call came from.
    public let file: String

    /// The function the call came from.
    public let function: String

    /// The line the call came from.
    public let line: UInt

    /// Creates an entry. The logger fills this in; callers rarely do.
    public init(
        id: UUID = .init(),
        timestamp: Date = .now,
        level: TimberLogLevel,
        subsystem: String = "",
        category: String = "",
        message: String,
        file: String,
        function: String,
        line: UInt,
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.subsystem = subsystem
        self.category = category
        self.message = message
        self.file = file
        self.function = function
        self.line = line
    }

    private enum CodingKeys: String, CodingKey {
        case id, timestamp, level, subsystem, category, message, file, function, line
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.level = try container.decode(TimberLogLevel.self, forKey: .level)
        self.subsystem = try container.decodeIfPresent(String.self, forKey: .subsystem) ?? ""
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        self.message = try container.decode(String.self, forKey: .message)
        self.file = try container.decode(String.self, forKey: .file)
        self.function = try container.decode(String.self, forKey: .function)
        self.line = try container.decode(UInt.self, forKey: .line)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(level, forKey: .level)
        try container.encode(subsystem, forKey: .subsystem)
        try container.encode(category, forKey: .category)
        try container.encode(message, forKey: .message)
        try container.encode(file, forKey: .file)
        try container.encode(function, forKey: .function)
        try container.encode(line, forKey: .line)
    }
}
