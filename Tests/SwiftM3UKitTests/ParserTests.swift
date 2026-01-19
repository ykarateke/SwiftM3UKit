import Testing
import Foundation
@testable import SwiftM3UKit

@Suite("M3UParser Tests")
struct ParserTests {

    // MARK: - Basic Parsing

    @Test("Parse basic M3U content")
    func parseBasicContent() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 tvg-id="ch1" group-title="Test",Channel 1
        http://example.com/ch1
        #EXTINF:-1 tvg-id="ch2" group-title="Test",Channel 2
        http://example.com/ch2
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items.count == 2)
        #expect(playlist.items[0].name == "Channel 1")
        #expect(playlist.items[1].name == "Channel 2")
    }

    @Test("Parse M3U with all content types")
    func parseAllContentTypes() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Channels",BBC One HD
        http://example.com/bbc
        #EXTINF:7200 group-title="Movies",The Matrix (1999)
        http://example.com/matrix
        #EXTINF:3000 group-title="Series",Breaking Bad S01E01
        http://example.com/bb
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.channels.count == 1)
        #expect(playlist.movies.count == 1)
        #expect(playlist.series.count == 1)
    }

    // MARK: - Attribute Parsing

    @Test("Parse all EXTINF attributes")
    func parseAllAttributes() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 tvg-id="bbc1.uk" tvg-name="BBC One" tvg-logo="http://logo.com/bbc.png" group-title="UK Channels",BBC One HD
        http://example.com/bbc
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        let item = playlist.items[0]
        #expect(item.epgID == "bbc1.uk")
        #expect(item.logo?.absoluteString == "http://logo.com/bbc.png")
        #expect(item.group == "UK Channels")
        #expect(item.attributes["tvg-name"] == "BBC One")
    }

    @Test("Parse duration correctly")
    func parseDuration() async throws {
        let content = """
        #EXTM3U
        #EXTINF:7200,Movie Title
        http://example.com/movie
        #EXTINF:-1,Live Channel
        http://example.com/live
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items[0].duration == 7200)
        #expect(playlist.items[1].duration == nil) // -1 converted to nil
    }

    // MARK: - Error Handling

    @Test("Handle malformed EXTINF gracefully")
    func handleMalformedExtinf() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Valid Channel
        http://example.com/valid
        #EXTINF:invalid,Broken Duration
        http://example.com/broken
        #EXTINF:-1,Another Valid
        http://example.com/another
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        // Should parse all items, handling malformed ones gracefully
        #expect(playlist.items.count == 3)
    }

    @Test("Handle missing URLs")
    func handleMissingUrls() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        #EXTINF:-1,Channel Without URL
        #EXTINF:-1,Channel 2
        http://example.com/ch2
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        // Should only have items with valid URLs
        #expect(playlist.items.count == 2)
    }

    // MARK: - Encoding Tests

    @Test("Parse UTF-8 encoded content")
    func parseUtf8() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Türkçe Kanal
        http://example.com/tr
        #EXTINF:-1,日本語チャンネル
        http://example.com/jp
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items[0].name == "Türkçe Kanal")
        #expect(playlist.items[1].name == "日本語チャンネル")
    }

    // MARK: - EXTGRP Tests

    @Test("Parse EXTGRP directive")
    func parseExtgrp() async throws {
        let content = """
        #EXTM3U
        #EXTGRP:Sports
        #EXTINF:-1,ESPN
        http://example.com/espn
        #EXTINF:-1 group-title="Override",Fox Sports
        http://example.com/fox
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items[0].group == "Sports")
        #expect(playlist.items[1].group == "Override") // group-title overrides EXTGRP
    }

    // MARK: - Playlist Properties

    @Test("Get unique groups")
    func getUniqueGroups() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Sports",ESPN
        http://example.com/espn
        #EXTINF:-1 group-title="News",CNN
        http://example.com/cnn
        #EXTINF:-1 group-title="Sports",Fox Sports
        http://example.com/fox
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.groups.count == 2)
        #expect(playlist.groups.contains("Sports"))
        #expect(playlist.groups.contains("News"))
    }

    @Test("Get grouped items")
    func getGroupedItems() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Sports",ESPN
        http://example.com/espn
        #EXTINF:-1 group-title="Sports",Fox Sports
        http://example.com/fox
        #EXTINF:-1 group-title="News",CNN
        http://example.com/cnn
        """

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)
        let grouped = playlist.groupedByCategory

        #expect(grouped["Sports"]?.count == 2)
        #expect(grouped["News"]?.count == 1)
    }

    // MARK: - Empty/Edge Cases

    @Test("Parse empty content")
    func parseEmptyContent() async throws {
        let content = "#EXTM3U"

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items.isEmpty)
    }

    @Test("Handle Windows line endings")
    func handleWindowsLineEndings() async throws {
        let content = "#EXTM3U\r\n#EXTINF:-1,Channel\r\nhttp://example.com/ch\r\n"

        let parser = M3UParser()
        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items.count == 1)
        #expect(playlist.items[0].name == "Channel")
    }
}
