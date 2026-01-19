import Testing
import Foundation
@testable import SwiftM3UKit

@Suite("Deduplication Tests")
struct DeduplicationTests {

    // MARK: - Basic Deduplication

    @Test("Deduplicate identical titles")
    func deduplicateIdenticalTitles() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Sports",ESPN
        http://example.com/espn1
        #EXTINF:-1 group-title="Sports",ESPN
        http://example.com/espn2
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items.count == 2)

        let deduped = playlist.deduplicated()
        #expect(deduped.items.count == 1)
    }

    @Test("Keep highest quality duplicate")
    func keepHighestQualityDuplicate() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="UK",BBC One SD
        http://example.com/bbc-sd
        #EXTINF:-1 group-title="UK",BBC One HD
        http://example.com/bbc-hd
        #EXTINF:-1 group-title="UK",BBC One 4K
        http://example.com/bbc-4k
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let deduped = playlist.deduplicated()
        #expect(deduped.items.count == 1)
        #expect(deduped.items[0].name.contains("4K"))
    }

    @Test("Different channels not deduplicated")
    func differentChannelsNotDeduplicated() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Sports",ESPN
        http://example.com/espn
        #EXTINF:-1 group-title="Sports",Fox Sports
        http://example.com/fox
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let deduped = playlist.deduplicated()
        #expect(deduped.items.count == 2)
    }

    // MARK: - Strategy Tests

    @Test("Deduplicate by tvg-id")
    func deduplicateByTvgId() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 tvg-id="bbc.one.uk",BBC One
        http://example.com/bbc1
        #EXTINF:-1 tvg-id="bbc.one.uk",BBC 1 HD
        http://example.com/bbc2
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let normalizer = ChannelNormalizer(strategy: .tvgID)
        let deduped = playlist.deduplicated(using: normalizer)

        #expect(deduped.items.count == 1)
    }

    @Test("Deduplicate by URL")
    func deduplicateByURL() async throws {
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
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let normalizer = ChannelNormalizer(strategy: .url)
        let deduped = playlist.deduplicated(using: normalizer)

        #expect(deduped.items.count == 2)
    }

    @Test("Deduplicate by title only")
    func deduplicateByTitle() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Group1",ESPN HD
        http://example.com/espn1
        #EXTINF:-1 group-title="Group2",ESPN HD
        http://example.com/espn2
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let normalizer = ChannelNormalizer(strategy: .title)
        let deduped = playlist.deduplicated(using: normalizer)

        // Title strategy ignores group, so these are duplicates
        #expect(deduped.items.count == 1)
    }

    @Test("Deduplicate with strategy convenience method")
    func deduplicateWithStrategyConvenience() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 tvg-id="espn",ESPN
        http://example.com/espn1
        #EXTINF:-1 tvg-id="espn",ESPN HD
        http://example.com/espn2
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let deduped = playlist.deduplicated(strategy: .tvgID)
        #expect(deduped.items.count == 1)
    }

    // MARK: - Find Duplicates

    @Test("Find duplicate groups")
    func findDuplicateGroups() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Sports",ESPN SD
        http://example.com/espn-sd
        #EXTINF:-1 group-title="Sports",ESPN HD
        http://example.com/espn-hd
        #EXTINF:-1 group-title="Sports",Fox Sports
        http://example.com/fox
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let duplicates = playlist.findDuplicates()

        // Should find one group of ESPN duplicates
        #expect(duplicates.count == 1)
        #expect(duplicates[0].count == 2)
    }

    @Test("Duplicate groups sorted by quality")
    func duplicateGroupsSortedByQuality() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="UK",BBC One SD
        http://example.com/bbc-sd
        #EXTINF:-1 group-title="UK",BBC One 4K
        http://example.com/bbc-4k
        #EXTINF:-1 group-title="UK",BBC One HD
        http://example.com/bbc-hd
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let duplicates = playlist.findDuplicates()

        // First item in group should be highest quality (4K)
        #expect(duplicates[0][0].name.contains("4K"))
    }

    // MARK: - Statistics

    @Test("Deduplication statistics")
    func deduplicationStatistics() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Sports",ESPN SD
        http://example.com/espn-sd
        #EXTINF:-1 group-title="Sports",ESPN HD
        http://example.com/espn-hd
        #EXTINF:-1 group-title="Sports",Fox Sports
        http://example.com/fox
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let stats = playlist.deduplicationStatistics

        #expect(stats.originalCount == 3)
        #expect(stats.deduplicatedCount == 2)
        #expect(stats.duplicatesRemoved == 1)
        #expect(stats.duplicatePercentage > 0)
    }

    @Test("No duplicates statistics")
    func noDuplicatesStatistics() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        #EXTINF:-1,Channel 2
        http://example.com/ch2
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let stats = playlist.deduplicationStatistics

        #expect(stats.duplicatesRemoved == 0)
        #expect(stats.duplicatePercentage == 0)
    }

    // MARK: - DeduplicationKey

    @Test("DeduplicationKey from M3UItem")
    func deduplicationKeyFromItem() {
        let item = M3UItem(
            name: "TR: BBC One HD",
            url: URL(string: "http://example.com")!,
            group: "UK Channels",
            epgID: "bbc.one.uk",
            contentType: .live
        )

        let key = DeduplicationKey(for: item)

        #expect(key.tvgID == "bbc.one.uk")
        #expect(key.normalizedTitle == "bbc one")
        #expect(key.group == "uk channels")
    }

    @Test("DeduplicationKey composite key")
    func deduplicationKeyComposite() {
        let key = DeduplicationKey(
            tvgID: "bbc.one",
            normalizedTitle: "bbc one",
            group: "uk",
            contentType: .live
        )

        let composite = key.compositeKey

        #expect(composite.contains("id:bbc.one"))
        #expect(composite.contains("t:bbc one"))
        #expect(composite.contains("g:uk"))
        #expect(composite.contains("c:live"))
    }

    // MARK: - ChannelNormalizer

    @Test("ChannelNormalizer generates consistent keys")
    func channelNormalizerConsistentKeys() {
        let normalizer = ChannelNormalizer()

        let item1 = M3UItem(
            name: "BBC One HD",
            url: URL(string: "http://example.com/1")!,
            group: "UK"
        )

        let item2 = M3UItem(
            name: "BBC One HD",
            url: URL(string: "http://example.com/2")!,
            group: "UK"
        )

        #expect(normalizer.normalizedKey(for: item1) == normalizer.normalizedKey(for: item2))
    }

    @Test("ChannelNormalizer tvgIDWithFallback strategy")
    func channelNormalizerFallbackStrategy() {
        let normalizer = ChannelNormalizer(strategy: .tvgIDWithFallback)

        let itemWithID = M3UItem(
            name: "BBC One",
            url: URL(string: "http://example.com")!,
            epgID: "bbc.one"
        )

        let itemWithoutID = M3UItem(
            name: "BBC One",
            url: URL(string: "http://example.com")!
        )

        let key1 = normalizer.normalizedKey(for: itemWithID)
        let key2 = normalizer.normalizedKey(for: itemWithoutID)

        #expect(key1.hasPrefix("tvg:"))
        #expect(key2.hasPrefix("fallback:"))
    }

    // MARK: - Turkish Character Handling

    @Test("Deduplicate with Turkish characters")
    func deduplicateWithTurkishCharacters() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Türkiye Kanalı HD
        http://example.com/tr1
        #EXTINF:-1,Turkiye Kanali HD
        http://example.com/tr2
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let deduped = playlist.deduplicated()

        // With Turkish normalization, these should be considered duplicates
        #expect(deduped.items.count == 1)
    }

    // MARK: - Content Type Handling

    @Test("Different content types not deduplicated")
    func differentContentTypesNotDeduplicated() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Channels",Show
        http://example.com/live
        #EXTINF:7200 group-title="Movies",Show (2020)
        http://example.com/movie
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let deduped = playlist.deduplicated()

        // Different content types (live vs movie) should not be deduplicated
        #expect(deduped.items.count == 2)
    }

    // MARK: - Edge Cases

    @Test("Empty playlist deduplication")
    func emptyPlaylistDeduplication() {
        let playlist = M3UPlaylist(items: [])

        let deduped = playlist.deduplicated()
        let stats = playlist.deduplicationStatistics
        let duplicates = playlist.findDuplicates()

        #expect(deduped.items.isEmpty)
        #expect(stats.originalCount == 0)
        #expect(duplicates.isEmpty)
    }

    @Test("Single item playlist")
    func singleItemPlaylist() {
        let item = M3UItem(
            name: "Single Channel",
            url: URL(string: "http://example.com")!
        )
        let playlist = M3UPlaylist(items: [item])

        let deduped = playlist.deduplicated()
        let duplicates = playlist.findDuplicates()

        #expect(deduped.items.count == 1)
        #expect(duplicates.isEmpty) // No duplicates
    }

    @Test("Preserve original order after deduplication")
    func preserveOrderAfterDeduplication() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel A
        http://example.com/a
        #EXTINF:-1,Channel B HD
        http://example.com/b-hd
        #EXTINF:-1,Channel B SD
        http://example.com/b-sd
        #EXTINF:-1,Channel C
        http://example.com/c
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let deduped = playlist.deduplicated()

        // Should be A, B (HD kept), C
        #expect(deduped.items.count == 3)
        #expect(deduped.items[0].name == "Channel A")
        #expect(deduped.items[1].name.contains("HD"))
        #expect(deduped.items[2].name == "Channel C")
    }
}
