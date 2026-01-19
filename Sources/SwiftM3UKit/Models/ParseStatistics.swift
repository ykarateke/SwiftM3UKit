import Foundation

/// Statistics about a parse operation.
///
/// Contains metrics about the parsing process including success/failure counts,
/// timing information, and various warning counts.
///
/// ## Example
/// ```swift
/// let result = try await parser.parseWithStatistics(from: url)
/// print("Success rate: \(result.statistics.successRate * 100)%")
/// print("Parse time: \(result.statistics.parseTime)s")
/// ```
public struct ParseStatistics: Sendable, Codable {
    /// Total number of lines processed.
    public let totalLines: Int

    /// Number of items successfully parsed.
    public let successCount: Int

    /// Number of items that failed to parse.
    public let failureCount: Int

    /// Number of warnings generated during parsing.
    public let warningCount: Int

    /// Time taken to complete the parse operation in seconds.
    public let parseTime: TimeInterval

    /// Number of EXTINF lines without corresponding URLs.
    public let orphanedExtinfCount: Int

    /// Number of duplicate URLs detected.
    public let duplicateURLCount: Int

    /// Number of invalid URLs encountered.
    public let invalidURLCount: Int

    /// Success rate as a value between 0 and 1.
    ///
    /// Calculated as successCount / (successCount + failureCount).
    /// Returns 1.0 if there are no items.
    public var successRate: Double {
        let total = successCount + failureCount
        guard total > 0 else { return 1.0 }
        return Double(successCount) / Double(total)
    }

    /// Creates a new ParseStatistics instance.
    ///
    /// - Parameters:
    ///   - totalLines: Total lines processed
    ///   - successCount: Successfully parsed items
    ///   - failureCount: Failed parse attempts
    ///   - warningCount: Number of warnings
    ///   - parseTime: Time taken to parse
    ///   - orphanedExtinfCount: EXTINF lines without URLs
    ///   - duplicateURLCount: Duplicate URLs detected
    ///   - invalidURLCount: Invalid URLs encountered
    public init(
        totalLines: Int,
        successCount: Int,
        failureCount: Int,
        warningCount: Int,
        parseTime: TimeInterval,
        orphanedExtinfCount: Int,
        duplicateURLCount: Int = 0,
        invalidURLCount: Int = 0
    ) {
        self.totalLines = totalLines
        self.successCount = successCount
        self.failureCount = failureCount
        self.warningCount = warningCount
        self.parseTime = parseTime
        self.orphanedExtinfCount = orphanedExtinfCount
        self.duplicateURLCount = duplicateURLCount
        self.invalidURLCount = invalidURLCount
    }
}
