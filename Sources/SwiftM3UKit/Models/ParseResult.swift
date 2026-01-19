import Foundation

/// Complete result of a parse operation with statistics and warnings.
///
/// Contains the parsed playlist along with detailed statistics
/// and any warnings generated during parsing.
///
/// ## Example
/// ```swift
/// let result = try await parser.parseWithStatistics(from: url)
///
/// print("Items: \(result.playlist.items.count)")
/// print("Success rate: \(result.statistics.successRate * 100)%")
///
/// if !result.warnings.isEmpty {
///     print("Warnings:")
///     for warning in result.warnings {
///         print("  - \(warning)")
///     }
/// }
/// ```
public struct ParseResult: Sendable {
    /// The parsed playlist.
    public let playlist: M3UPlaylist

    /// Statistics about the parse operation.
    public let statistics: ParseStatistics

    /// Warnings generated during parsing.
    public let warnings: [ParseWarning]

    /// Creates a new parse result.
    ///
    /// - Parameters:
    ///   - playlist: The parsed playlist
    ///   - statistics: Parse statistics
    ///   - warnings: List of warnings
    public init(
        playlist: M3UPlaylist,
        statistics: ParseStatistics,
        warnings: [ParseWarning]
    ) {
        self.playlist = playlist
        self.statistics = statistics
        self.warnings = warnings
    }

    /// Returns warnings filtered by severity.
    ///
    /// - Parameter severity: The severity level to filter by
    /// - Returns: Warnings matching the specified severity
    public func warnings(severity: ParseWarning.Severity) -> [ParseWarning] {
        warnings.filter { $0.severity == severity }
    }

    /// Returns warnings filtered by type.
    ///
    /// - Parameter type: The warning type to filter by
    /// - Returns: Warnings matching the specified type
    public func warnings(type: ParseWarning.WarningType) -> [ParseWarning] {
        warnings.filter { $0.type == type }
    }

    /// Whether the parse completed without any errors.
    public var isClean: Bool {
        warnings.allSatisfy { $0.severity != .error }
    }

    /// Number of error-level warnings.
    public var errorCount: Int {
        warnings.count { $0.severity == .error }
    }
}
