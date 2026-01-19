import Testing
import Foundation
@testable import SwiftM3UKit

@Suite("Parse Statistics Tests")
struct ParseStatisticsTests {

    // MARK: - Basic Statistics

    @Test("Parse with statistics returns correct counts")
    func parseWithStatisticsReturnsCorrectCounts() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        #EXTINF:-1,Channel 2
        http://example.com/ch2
        #EXTINF:-1,Channel 3
        http://example.com/ch3
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        #expect(result.playlist.items.count == 3)
        #expect(result.statistics.successCount == 3)
        #expect(result.statistics.failureCount == 0)
    }

    @Test("Success rate calculation")
    func successRateCalculation() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        #EXTINF:-1,Channel 2
        http://example.com/ch2
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        #expect(result.statistics.successRate == 1.0)
    }

    @Test("Parse time is recorded")
    func parseTimeRecorded() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        #expect(result.statistics.parseTime >= 0)
    }

    // MARK: - Orphaned EXTINF Detection

    @Test("Detect orphaned EXTINF")
    func detectOrphanedExtinf() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        #EXTINF:-1,Orphaned Channel
        #EXTINF:-1,Channel 2
        http://example.com/ch2
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        #expect(result.playlist.items.count == 2)
        #expect(result.statistics.orphanedExtinfCount == 1)
    }

    @Test("Orphaned EXTINF at end of file")
    func orphanedExtinfAtEnd() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        #EXTINF:-1,Trailing Orphan
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        #expect(result.playlist.items.count == 1)
        #expect(result.statistics.orphanedExtinfCount == 1)
    }

    // MARK: - Duplicate Detection

    @Test("Detect duplicate URLs")
    func detectDuplicateURLs() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/stream
        #EXTINF:-1,Channel 2
        http://example.com/stream
        #EXTINF:-1,Channel 3
        http://example.com/other
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        #expect(result.playlist.items.count == 3)
        #expect(result.statistics.duplicateURLCount == 1)
    }

    // MARK: - Warnings

    @Test("Warnings generated for orphaned EXTINF")
    func warningsForOrphanedExtinf() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        #EXTINF:-1,Orphaned
        #EXTINF:-1,Channel 2
        http://example.com/ch2
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        let orphanedWarnings = result.warnings(type: .orphanedExtinf)
        #expect(orphanedWarnings.count == 1)
        #expect(orphanedWarnings.first?.severity == .warning)
    }

    @Test("Warnings generated for duplicate URLs")
    func warningsForDuplicateURLs() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/stream
        #EXTINF:-1,Channel 2
        http://example.com/stream
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        let duplicateWarnings = result.warnings(type: .duplicateEntry)
        #expect(duplicateWarnings.count == 1)
        #expect(duplicateWarnings.first?.severity == .info)
    }

    @Test("Warning count matches statistics")
    func warningCountMatchesStatistics() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        #EXTINF:-1,Orphaned
        #EXTINF:-1,Channel 2
        http://example.com/stream
        #EXTINF:-1,Duplicate
        http://example.com/stream
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        #expect(result.warnings.count == result.statistics.warningCount)
    }

    // MARK: - ParseResult Methods

    @Test("Filter warnings by severity")
    func filterWarningsBySeverity() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        #EXTINF:-1,Orphaned
        #EXTINF:-1,Channel 2
        http://example.com/stream
        #EXTINF:-1,Duplicate
        http://example.com/stream
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        let warnings = result.warnings(severity: .warning)
        let infos = result.warnings(severity: .info)

        #expect(warnings.count >= 1) // orphaned
        #expect(infos.count >= 1) // duplicate
    }

    @Test("isClean property")
    func isCleanProperty() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        #expect(result.isClean) // No errors
    }

    @Test("errorCount property")
    func errorCountProperty() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        """

        let parser = M3UParser()
        let result = try await parser.parseWithStatistics(data: content.data(using: .utf8)!)

        #expect(result.errorCount == 0)
    }

    // MARK: - ParseStatistics Properties

    @Test("ParseStatistics success rate with no items")
    func successRateWithNoItems() {
        let stats = ParseStatistics(
            totalLines: 0,
            successCount: 0,
            failureCount: 0,
            warningCount: 0,
            parseTime: 0,
            orphanedExtinfCount: 0
        )

        #expect(stats.successRate == 1.0) // Default to 100% when no items
    }

    @Test("ParseStatistics is Codable")
    func parseStatisticsIsCodable() throws {
        let stats = ParseStatistics(
            totalLines: 100,
            successCount: 95,
            failureCount: 5,
            warningCount: 10,
            parseTime: 0.5,
            orphanedExtinfCount: 3,
            duplicateURLCount: 2
        )

        let encoded = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(ParseStatistics.self, from: encoded)

        #expect(decoded.totalLines == stats.totalLines)
        #expect(decoded.successCount == stats.successCount)
        #expect(decoded.failureCount == stats.failureCount)
    }

    // MARK: - ParseWarning Properties

    @Test("ParseWarning description")
    func parseWarningDescription() {
        let warning = ParseWarning(
            lineNumber: 10,
            severity: .warning,
            type: .orphanedExtinf,
            message: "Test message"
        )

        #expect(warning.description.contains("WARNING"))
        #expect(warning.description.contains("10"))
        #expect(warning.description.contains("Test message"))
    }

    @Test("ParseWarning is Hashable")
    func parseWarningIsHashable() {
        let warning1 = ParseWarning(
            lineNumber: 10,
            severity: .warning,
            type: .orphanedExtinf,
            message: "Test"
        )

        let warning2 = ParseWarning(
            lineNumber: 10,
            severity: .warning,
            type: .orphanedExtinf,
            message: "Test"
        )

        #expect(warning1 == warning2)
        #expect(warning1.hashValue == warning2.hashValue)
    }
}
