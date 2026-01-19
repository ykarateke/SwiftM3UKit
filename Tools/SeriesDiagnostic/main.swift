import Foundation
import SwiftM3UKit

struct SeriesDiagnostic {
    static func main() async throws {
        let playlistPath = "docs/playlist_5gykarateke_plus.m3u"
        let url = URL(fileURLWithPath: playlistPath)

        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("SwiftM3UKit Series Grouping Diagnostic")
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print()

        print("Parsing M3U file: \(playlistPath)")
        let parser = M3UParser()
        let playlist = try await parser.parse(from: url)

        print()
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("BASIC STATISTICS")
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("Total items:                 \(playlist.items.count)")
        print("Live TV channels:            \(playlist.channels.count)")
        print("Movies:                      \(playlist.movies.count)")
        print("Series episodes (total):     \(playlist.series.count)")

        print()
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("SERIES GROUPING ANALYSIS")
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("Unique series count:         \(playlist.uniqueSeriesCount)")
        print("Total episode count:         \(playlist.totalEpisodeCount)")

        let avgEpisodesPerSeries = playlist.uniqueSeriesCount > 0
            ? Double(playlist.totalEpisodeCount) / Double(playlist.uniqueSeriesCount)
            : 0
        print("Avg episodes per series:     \(String(format: "%.1f", avgEpisodesPerSeries))")

        print()
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("TOP 20 SERIES BY EPISODE COUNT")
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))

        for (i, series) in playlist.seriesGrouped.prefix(20).enumerated() {
            let groupInfo = series.group.map { " [\($0)]" } ?? ""
            print("\(String(format: "%2d", i+1)). \(series.name)\(groupInfo)")
            print("    Episodes: \(series.episodeCount), Seasons: \(series.seasonCount)")

            // Show first 3 episode names to verify grouping
            if i < 5 {
                for (j, ep) in series.episodes.prefix(3).enumerated() {
                    let seasonEp = "S\(ep.season ?? 0)E\(ep.episode ?? 0)"
                    print("       \(j+1). \(seasonEp) - \(ep.item.name)")
                }
            }
        }

        print()
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("SERIES GROUPS ANALYSIS")
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))

        // Analyze which groups contain series
        var seriesGroupCounts: [String: Int] = [:]
        for item in playlist.series {
            let group = item.group ?? "No Group"
            seriesGroupCounts[group, default: 0] += 1
        }

        let sortedGroups = seriesGroupCounts.sorted { $0.value > $1.value }
        print("Top 15 groups with series content:")
        for (i, (group, count)) in sortedGroups.prefix(15).enumerated() {
            print("\(String(format: "%2d", i+1)). \(group): \(count) episodes")
        }

        print()
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("SAMPLE SERIES ITEMS FROM DIFFERENT GROUPS")
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))

        // Show examples from different types of series groups
        let targetGroups = [
            "TALKSHOW DiZiLERi",
            "GUNCEL TV DiZiLERi",
            "DiSNEY PLUS DiZiLERi",
            "AMAZON DiZiLERi"
        ]

        for targetGroup in targetGroups {
            let items = playlist.series.filter { $0.group == targetGroup }.prefix(3)
            if !items.isEmpty {
                print("\nGroup: \(targetGroup)")
                for item in items {
                    if case let .series(season, episode) = item.contentType {
                        let seasonEp = "S\(season ?? 0)E\(episode ?? 0)"
                        print("  - \(seasonEp) - \(item.name)")
                    }
                }
            }
        }

        print()
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("POTENTIAL ISSUES DETECTION")
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))

        // Check for series that might have quality tags causing split grouping
        var seriesWithQualityTags = 0
        var potentialSplitSeries: [String: Set<String>] = [:]

        for series in playlist.seriesGrouped {
            let name = series.name
            let qualityPatterns = ["4K", "UHD", "FHD", "HD", "SD", "HEVC", "H.264", "H.265"]

            for pattern in qualityPatterns {
                if name.contains(pattern) {
                    seriesWithQualityTags += 1

                    // Remove quality tag and see if there are other series with similar names
                    let baseName = name.replacingOccurrences(
                        of: " \(pattern)",
                        with: "",
                        options: .caseInsensitive
                    ).trimmingCharacters(in: .whitespaces)

                    if potentialSplitSeries[baseName] == nil {
                        potentialSplitSeries[baseName] = []
                    }
                    potentialSplitSeries[baseName]?.insert(name)
                    break
                }
            }
        }

        print("Series with quality tags in name: \(seriesWithQualityTags)")

        let actualSplits = potentialSplitSeries.filter { $0.value.count > 1 }
        if !actualSplits.isEmpty {
            print("\nPotential split series (same series with different quality tags):")
            for (baseName, variants) in actualSplits.prefix(10) {
                print("\nBase name: \(baseName)")
                for variant in variants {
                    let count = playlist.seriesGrouped.first { $0.name == variant }?.episodeCount ?? 0
                    print("  - \(variant) (\(count) episodes)")
                }
            }
        } else {
            print("No split series detected due to quality tags.")
        }

        print()
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("DIAGNOSIS SUMMARY")
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))

        let expectedUniqueCount = 2000...4000
        if expectedUniqueCount.contains(playlist.uniqueSeriesCount) {
            print("✓ Series grouping appears to be working correctly!")
            print("  Unique series count (\(playlist.uniqueSeriesCount)) is within expected range.")
            print()
            print("  RECOMMENDATION: User should use playlist.uniqueSeriesCount instead of")
            print("                  playlist.series.count to get the number of unique series.")
        } else if playlist.uniqueSeriesCount > 10000 {
            print("✗ Series grouping may not be working correctly!")
            print("  Unique series count (\(playlist.uniqueSeriesCount)) is too high.")
            print("  Expected range: \(expectedUniqueCount)")
            print()
            if !actualSplits.isEmpty {
                print("  POSSIBLE CAUSE: Quality tags in series names are causing splits.")
                print("  RECOMMENDATION: Improve extractSeriesName() to remove quality tags.")
            } else {
                print("  RECOMMENDATION: Investigate series name extraction logic.")
            }
        } else {
            print("✓ Series grouping working, but fewer series than expected.")
            print("  Unique series count: \(playlist.uniqueSeriesCount)")
        }

        print()
    }
}

// Entry point
Task {
    try await SeriesDiagnostic.main()
}
