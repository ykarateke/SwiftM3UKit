import Foundation

/// A warning generated during M3U parsing.
///
/// Warnings indicate potential issues that don't prevent parsing
/// but may indicate data quality problems.
///
/// ## Example
/// ```swift
/// let result = try await parser.parseWithStatistics(from: url)
/// for warning in result.warnings {
///     print("[\(warning.severity)] Line \(warning.lineNumber): \(warning.message)")
/// }
/// ```
public struct ParseWarning: Sendable, Codable, Hashable {
    /// Severity level of the warning.
    public enum Severity: String, Sendable, Codable, Hashable {
        /// Informational message, not necessarily a problem.
        case info
        /// Warning that may indicate a problem.
        case warning
        /// Error that prevented parsing of an item.
        case error
    }

    /// Type of warning encountered.
    public enum WarningType: String, Sendable, Codable, Hashable {
        /// EXTINF line without a corresponding URL.
        case orphanedExtinf
        /// URL that could not be parsed.
        case invalidURL
        /// Required attribute is missing.
        case missingRequiredAttribute
        /// Duplicate URL detected.
        case duplicateEntry
        /// EXTINF line could not be parsed.
        case malformedExtinf
        /// Unknown or unsupported directive.
        case unknownDirective
        /// Encoding issue with the content.
        case encodingIssue
    }

    /// Line number where the warning occurred.
    public let lineNumber: Int

    /// Severity of the warning.
    public let severity: Severity

    /// Type of warning.
    public let type: WarningType

    /// Human-readable description of the warning.
    public let message: String

    /// Raw content that caused the warning (if available).
    public let rawContent: String?

    /// Creates a new parse warning.
    ///
    /// - Parameters:
    ///   - lineNumber: Line number in the source file
    ///   - severity: Severity level
    ///   - type: Type of warning
    ///   - message: Description of the issue
    ///   - rawContent: Original content that caused the warning
    public init(
        lineNumber: Int,
        severity: Severity,
        type: WarningType,
        message: String,
        rawContent: String? = nil
    ) {
        self.lineNumber = lineNumber
        self.severity = severity
        self.type = type
        self.message = message
        self.rawContent = rawContent
    }
}

extension ParseWarning: CustomStringConvertible {
    public var description: String {
        "[\(severity.rawValue.uppercased())] Line \(lineNumber): \(message)"
    }
}
