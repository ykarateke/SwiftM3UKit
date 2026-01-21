import Testing
import Foundation
@testable import SwiftM3UKit

@Suite("Integration Tests")
struct IntegrationTests {

    // MARK: - File-based Tests

    @Test("Parse sample small M3U file")
    func parseSampleSmallFile() async throws {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "sample_small", withExtension: "m3u", subdirectory: "Resources") else {
            Issue.record("Could not find sample_small.m3u in test resources")
            return
        }

        let parser = M3UParser()
        let playlist = try await parser.parse(from: url)

        #expect(playlist.items.count == 6)
        #expect(playlist.channels.count == 3)
        #expect(playlist.movies.count == 1)
        #expect(playlist.series.count == 2)
    }

    @Test("Parse malformed M3U file gracefully")
    func parseMalformedFile() async throws {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "malformed", withExtension: "m3u", subdirectory: "Resources") else {
            Issue.record("Could not find malformed.m3u in test resources")
            return
        }

        let parser = M3UParser()
        let playlist = try await parser.parse(from: url)

        // Should parse what it can, skipping malformed entries
        #expect(playlist.items.count >= 2) // At least valid entries
    }

    @Test("Parse sample large M3U file")
    func parseSampleLargeFile() async throws {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "sample_large", withExtension: "m3u", subdirectory: "Resources") else {
            Issue.record("Could not find sample_large.m3u in test resources")
            return
        }

        let parser = M3UParser()
        let playlist = try await parser.parse(from: url)

        #expect(playlist.items.count == 22)
        #expect(playlist.channels.count == 9)  // Updated: improved movie sequel detection
        #expect(playlist.movies.count == 6)     // Updated: one item now correctly classified as movie
        #expect(playlist.series.count == 7)
    }

    // MARK: - Streaming Tests

    @Test("Stream parse from data")
    func streamParseFromData() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Test",Channel 1
        http://example.com/ch1
        #EXTINF:-1 group-title="Test",Channel 2
        http://example.com/ch2
        #EXTINF:-1 group-title="Test",Channel 3
        http://example.com/ch3
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        var count = 0
        for item in playlist.items {
            count += 1
            #expect(item.group == "Test")
        }
        #expect(count == 3)
    }

    // MARK: - Custom Classifier Tests

    @Test("Use custom classifier")
    func useCustomClassifier() async throws {
        struct AlwaysLiveClassifier: ContentClassifying {
            func classify(name: String, group: String?, attributes: [String: String], url: URL?) -> ContentType {
                return .live
            }
        }

        let content = """
        #EXTM3U
        #EXTINF:-1,Movie (2020)
        http://example.com/movie
        #EXTINF:-1,Series S01E01
        http://example.com/series
        """

        let parser = M3UParser()
        await parser.setClassifier(AlwaysLiveClassifier())

        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.channels.count == 2)
        #expect(playlist.movies.count == 0)
        #expect(playlist.series.count == 0)
    }

    // MARK: - URL Validation

    @Test("Parse various URL schemes")
    func parseVariousUrlSchemes() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,HTTP Stream
        http://example.com/stream
        #EXTINF:-1,HTTPS Stream
        https://secure.example.com/stream
        #EXTINF:-1,RTMP Stream
        rtmp://live.example.com/app/stream
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items.count == 3)
        #expect(playlist.items[0].url.scheme == "http")
        #expect(playlist.items[1].url.scheme == "https")
        #expect(playlist.items[2].url.scheme == "rtmp")
    }

    // MARK: - Identifiable Tests

    @Test("Items have unique IDs")
    func itemsHaveUniqueIds() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        #EXTINF:-1,Channel 2
        http://example.com/ch2
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let ids = Set(playlist.items.map(\.id))
        #expect(ids.count == playlist.items.count)
    }

    // MARK: - Codable Tests

    @Test("M3UItem is Codable")
    func itemIsCodable() throws {
        let item = M3UItem(
            name: "Test Channel",
            url: URL(string: "http://example.com/stream")!,
            group: "Test Group",
            logo: URL(string: "http://example.com/logo.png"),
            epgID: "test.channel",
            contentType: .live,
            duration: nil,
            attributes: ["tvg-name": "Test"]
        )

        let encoded = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(M3UItem.self, from: encoded)

        #expect(decoded.name == item.name)
        #expect(decoded.url == item.url)
        #expect(decoded.group == item.group)
        #expect(decoded.epgID == item.epgID)
    }

    @Test("ContentType series is Codable")
    func seriesContentTypeIsCodable() throws {
        let contentType = ContentType.series(season: 1, episode: 5)

        let encoded = try JSONEncoder().encode(contentType)
        let decoded = try JSONDecoder().decode(ContentType.self, from: encoded)

        if case let .series(season, episode) = decoded {
            #expect(season == 1)
            #expect(episode == 5)
        } else {
            Issue.record("Expected series content type")
        }
    }

    // MARK: - v1.1 Feature Tests

    @Test("Parse EXTINF with xui-id and timeshift attributes")
    func parseXuiIDAndTimeshift() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 xui-id="3" timeshift="10" tvg-id="ch1" group-title="Sports",ESPN HD
        http://example.com/espn
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items.count == 1)
        let item = playlist.items[0]
        #expect(item.xuiID == "3")
        #expect(item.timeshift == 10)
        #expect(item.name == "ESPN HD")
    }

    @Test("Parse Turkish IPTV content classification")
    func parseTurkishIPTV() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="▱ ULUSAL",Kanal D ᴬⱽᴿᵁᴾᴬ
        http://example.com/kanald
        #EXTINF:-1 group-title="NETFLiX DiZiLERi",Stranger Things S01E01
        http://example.com/stranger
        #EXTINF:-1 group-title="SiNEMA",Inception [4K]
        http://example.com/inception
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items.count == 3)
        #expect(playlist.channels.count == 1)
        #expect(playlist.series.count == 1)
        #expect(playlist.movies.count == 1)
    }

    @Test("Parse EXT-X-SESSION-DATA directive")
    func parseExtSessionData() async throws {
        let content = """
        #EXTM3U
        #EXT-X-SESSION-DATA:DATA-ID="com.xui.1_5_13"
        #EXTINF:-1 group-title="Test",Channel 1
        http://example.com/ch1
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        // Session data is parsed but not stored in items - just verify parsing doesn't fail
        #expect(playlist.items.count == 1)
    }

    @Test("M3UItem with new properties is Codable")
    func itemWithNewPropertiesIsCodable() throws {
        let item = M3UItem(
            name: "Test Channel",
            url: URL(string: "http://example.com/stream")!,
            group: "Test Group",
            logo: URL(string: "http://example.com/logo.png"),
            epgID: "test.channel",
            contentType: .live,
            duration: nil,
            attributes: ["xui-id": "5", "timeshift": "30"],
            xuiID: "5",
            timeshift: 30
        )

        let encoded = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(M3UItem.self, from: encoded)

        #expect(decoded.xuiID == "5")
        #expect(decoded.timeshift == 30)
    }

    // MARK: - Series Statistics Tests

    @Test("Parse series with episode information")
    func parseSeriesWithEpisodes() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Netflix Dizileri",Breaking Bad S01E01
        http://example.com/bb_s1e1
        #EXTINF:-1 group-title="Netflix Dizileri",Breaking Bad S01E02
        http://example.com/bb_s1e2
        #EXTINF:-1 group-title="Netflix Dizileri",Breaking Bad S01E03
        http://example.com/bb_s1e3
        #EXTINF:-1 group-title="Netflix Dizileri",Breaking Bad S02E01
        http://example.com/bb_s2e1
        #EXTINF:-1 group-title="Netflix Dizileri",Breaking Bad S02E02
        http://example.com/bb_s2e2
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.series.count == 5)
        #expect(playlist.uniqueSeriesCount == 1)
        #expect(playlist.totalEpisodeCount == 5)

        let seriesInfo = playlist.seriesGrouped.first!
        #expect(seriesInfo.name == "Breaking Bad")
        #expect(seriesInfo.seasonCount == 2)
        #expect(seriesInfo.episodeCount == 5)
    }

    @Test("Parse multiple series")
    func parseMultipleSeries() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="HBO Dizileri",Game of Thrones S01E01
        http://example.com/got_s1e1
        #EXTINF:-1 group-title="HBO Dizileri",Game of Thrones S01E02
        http://example.com/got_s1e2
        #EXTINF:-1 group-title="Netflix Dizileri",Stranger Things S01E01
        http://example.com/st_s1e1
        #EXTINF:-1 group-title="Netflix Dizileri",Stranger Things S01E02
        http://example.com/st_s1e2
        #EXTINF:-1 group-title="Netflix Dizileri",Stranger Things S02E01
        http://example.com/st_s2e1
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.series.count == 5)
        #expect(playlist.uniqueSeriesCount == 2)
        #expect(playlist.totalEpisodeCount == 5)

        // Series should be sorted by episode count
        let topSeries = playlist.seriesGrouped.first!
        #expect(topSeries.name == "Stranger Things")
        #expect(topSeries.episodeCount == 3)
        #expect(topSeries.seasonCount == 2)
    }

    @Test("Series episode info contains correct data")
    func seriesEpisodeInfoCorrect() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Test Dizileri",Test Show S03E05
        http://example.com/test
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let seriesInfo = playlist.seriesGrouped.first!
        let episode = seriesInfo.episodes.first!

        #expect(episode.season == 3)
        #expect(episode.episode == 5)
        #expect(episode.item.name == "Test Show S03E05")
        #expect(episode.item.url.absoluteString == "http://example.com/test")
    }

    @Test("Series with nil season/episode still counted")
    func seriesWithNilSeasonEpisode() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Netflix Dizileri",Unknown Series
        http://example.com/unknown
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        // Should be classified as series because of "Dizileri" group
        #expect(playlist.series.count == 1)
        #expect(playlist.uniqueSeriesCount == 1)

        let seriesInfo = playlist.seriesGrouped.first!
        #expect(seriesInfo.name == "Unknown Series")
        #expect(seriesInfo.episodes.first?.season == nil)
        #expect(seriesInfo.episodes.first?.episode == nil)
    }

    @Test("Real playlist patterns - VOD movies should not be classified as live")
    func vodMoviesShouldNotBeLive() async throws {
        let m3u = """
        #EXTM3U
        #EXTINF:-1 xui-id="809650" group-title="4K",Yeni Hayata Hazırlık [4K HDR] (2025)
        https://example.com/play#.mkv
        #EXTINF:-1 xui-id="809340" group-title="AKSiYON & MACERA",The Shadow's Edge (2025)
        https://example.com/vod#.mp4
        #EXTINF:-1 xui-id="809313" group-title="KOMEDi & ROMANTiK",Good Fortune (2025)
        https://example.com/movie.avi
        #EXTINF:-1 xui-id="706526" group-title="▱ TÜRK ADAPTIF",Kanal D Drama (1080p)
        https://example.com/live.m3u8
        """

        let playlist = try await M3UParser().parse(data: Data(m3u.utf8))

        // First 3 should be movies (VOD)
        #expect(playlist.items[0].contentType == .movie, "4K group with .mkv should be .movie")
        #expect(playlist.items[1].contentType == .movie, "Genre group with .mp4 should be .movie")
        #expect(playlist.items[2].contentType == .movie, "Genre group with .avi should be .movie")

        // Last one should be live (HLS stream)
        #expect(playlist.items[3].contentType == .live, "Live channel with .m3u8 should be .live")
    }
}
