import Foundation
import SwiftM3UKit

@main
struct PlaylistAnalyzer {
    static func main() async throws {
        let playlistPath = "docs/playlist_5gykarateke_plus.m3u"
        let url = URL(fileURLWithPath: playlistPath)

        print("=" .padding(toLength: 60, withPad: "=", startingAt: 0))
        print("SwiftM3UKit v1.4 - Performance Comparison")
        print("=" .padding(toLength: 60, withPad: "=", startingAt: 0))
        print()

        let parser = M3UParser()

        // Test 1: Normal parse (3 runs)
        print("Test 1: Normal parse() - 3 runs")
        print("-" .padding(toLength: 40, withPad: "-", startingAt: 0))
        var normalTimes: [TimeInterval] = []

        for i in 1...3 {
            let start = Date()
            let playlist = try await parser.parse(from: url)
            let elapsed = Date().timeIntervalSince(start)
            normalTimes.append(elapsed)
            print("  Run \(i): \(String(format: "%.3f", elapsed))s (\(playlist.items.count) items)")
        }
        let avgNormal = normalTimes.reduce(0, +) / Double(normalTimes.count)
        print("  Average: \(String(format: "%.3f", avgNormal))s")

        print()

        // Test 2: Parse with statistics (3 runs)
        print("Test 2: parseWithStatistics() - 3 runs")
        print("-" .padding(toLength: 40, withPad: "-", startingAt: 0))
        var statsTimes: [TimeInterval] = []

        for i in 1...3 {
            let start = Date()
            let result = try await parser.parseWithStatistics(from: url)
            let elapsed = Date().timeIntervalSince(start)
            statsTimes.append(elapsed)
            print("  Run \(i): \(String(format: "%.3f", elapsed))s (\(result.playlist.items.count) items, \(result.warnings.count) warnings)")
        }
        let avgStats = statsTimes.reduce(0, +) / Double(statsTimes.count)
        print("  Average: \(String(format: "%.3f", avgStats))s")

        print()

        // Test 3: Deduplication overhead
        print("Test 3: Deduplication overhead")
        print("-" .padding(toLength: 40, withPad: "-", startingAt: 0))

        let playlist = try await parser.parse(from: url)

        // Just getting stats (no actual dedup)
        let statsStart = Date()
        let dedupStats = playlist.deduplicationStatistics
        let statsTime = Date().timeIntervalSince(statsStart)
        print("  deduplicationStatistics: \(String(format: "%.3f", statsTime))s")
        print("    -> \(dedupStats.duplicatesRemoved) duplicates found")

        // Actual deduplication
        let dedupStart = Date()
        let deduped = playlist.deduplicated()
        let dedupTime = Date().timeIntervalSince(dedupStart)
        print("  deduplicated(): \(String(format: "%.3f", dedupTime))s")
        print("    -> \(playlist.items.count) -> \(deduped.items.count) items")

        // Find duplicates
        let findStart = Date()
        let groups = playlist.findDuplicates()
        let findTime = Date().timeIntervalSince(findStart)
        print("  findDuplicates(): \(String(format: "%.3f", findTime))s")
        print("    -> \(groups.count) duplicate groups")

        print()

        // Test 4: Title processing overhead
        print("Test 4: Title processing overhead (all items)")
        print("-" .padding(toLength: 40, withPad: "-", startingAt: 0))

        let titleStart = Date()
        var cleanCount = 0
        for item in playlist.items {
            _ = item.cleanTitle
            _ = item.normalizedTitle
            cleanCount += 1
        }
        let titleTime = Date().timeIntervalSince(titleStart)
        print("  cleanTitle + normalizedTitle: \(String(format: "%.3f", titleTime))s")
        print("    -> \(cleanCount) items processed")

        print()

        // Summary
        print("=" .padding(toLength: 60, withPad: "=", startingAt: 0))
        print("SUMMARY")
        print("=" .padding(toLength: 60, withPad: "=", startingAt: 0))
        print("Normal parse avg:        \(String(format: "%.3f", avgNormal))s")
        print("With statistics avg:     \(String(format: "%.3f", avgStats))s")
        let overhead = ((avgStats - avgNormal) / avgNormal) * 100
        print("Statistics overhead:     \(String(format: "%.1f", overhead))%")
        print()
        print("Deduplication time:      \(String(format: "%.3f", dedupTime))s")
        print("Title processing time:   \(String(format: "%.3f", titleTime))s")
        print()

        let totalNewFeatures = dedupTime + titleTime
        let percentOfParse = (totalNewFeatures / avgNormal) * 100
        print("New features total:      \(String(format: "%.3f", totalNewFeatures))s")
        print("As % of parse time:      \(String(format: "%.1f", percentOfParse))%")
    }
}
