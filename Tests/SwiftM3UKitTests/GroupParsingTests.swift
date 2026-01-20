import Testing
@testable import SwiftM3UKit

@Suite("Group Parsing Tests")
struct GroupParsingTests {

    let parser = M3UParser()

    @Test("Parse group-title attribute correctly")
    func parseGroupTitleCorrectly() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 xui-id="17" tvg-name="ATV" group-title="▱ ULUSAL",ATV °
        http://example.com/atv
        #EXTINF:-1 xui-id="794794" tvg-name="Film 1" group-title="4K WORLD",Pamuk Prenses (2025)
        http://example.com/movie1
        #EXTINF:-1 xui-id="635203" tvg-name="Film 2" group-title="TOP 250",Jurassic Park 3 (2001)
        http://example.com/movie2
        #EXTINF:-1 tvg-name="Dizi 1" group-title="Disney Plus Dizileri",The Mandalorian S01E01
        http://example.com/series1
        """

        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items.count == 4)

        // Check each item's group
        #expect(playlist.items[0].group == "▱ ULUSAL")
        #expect(playlist.items[0].name == "ATV °")

        #expect(playlist.items[1].group == "4K WORLD")
        #expect(playlist.items[1].name == "Pamuk Prenses (2025)")

        #expect(playlist.items[2].group == "TOP 250")
        #expect(playlist.items[2].name == "Jurassic Park 3 (2001)")

        #expect(playlist.items[3].group == "Disney Plus Dizileri")
        #expect(playlist.items[3].name == "The Mandalorian S01E01")
    }

    @Test("Items with same group are accessible together")
    func itemsWithSameGroupAccessibleTogether() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Movies",Film A
        http://example.com/a
        #EXTINF:-1 group-title="Movies",Film B
        http://example.com/b
        #EXTINF:-1 group-title="Series",Dizi A
        http://example.com/c
        #EXTINF:-1 group-title="Movies",Film C
        http://example.com/d
        """

        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        // Filter by group
        let movieGroup = playlist.items.filter { $0.group == "Movies" }
        let seriesGroup = playlist.items.filter { $0.group == "Series" }

        #expect(movieGroup.count == 3)
        #expect(seriesGroup.count == 1)

        #expect(movieGroup[0].name == "Film A")
        #expect(movieGroup[1].name == "Film B")
        #expect(movieGroup[2].name == "Film C")

        #expect(seriesGroup[0].name == "Dizi A")
    }

    @Test("Group affects classification correctly")
    func groupAffectsClassification() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="4K WORLD",Film Without Year
        http://example.com/movie1
        #EXTINF:-1 group-title="TOP 250",Another Film
        http://example.com/movie2
        #EXTINF:-1 group-title="▱ ULUSAL",Live Channel
        http://example.com/live1
        #EXTINF:-1 group-title="Disney Plus Dizileri",Some Show
        http://example.com/series1
        """

        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        // Verify groups are parsed
        #expect(playlist.items[0].group == "4K WORLD")
        #expect(playlist.items[1].group == "TOP 250")
        #expect(playlist.items[2].group == "▱ ULUSAL")
        #expect(playlist.items[3].group == "Disney Plus Dizileri")

        // Verify classification based on groups
        #expect(playlist.items[0].contentType == .movie, "4K WORLD should be movie")
        #expect(playlist.items[1].contentType == .movie, "TOP 250 should be movie")
        #expect(playlist.items[2].contentType == .live, "▱ ULUSAL should be live")
        if case .series = playlist.items[3].contentType {
            // Expected
        } else {
            #expect(Bool(false), "Disney Plus Dizileri should be series")
        }
    }

    @Test("Empty or missing group-title handled correctly")
    func emptyOrMissingGroupHandled() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 tvg-name="No Group",Channel Without Group
        http://example.com/ch1
        #EXTINF:-1 group-title="",Channel With Empty Group
        http://example.com/ch2
        #EXTINF:-1 group-title="Valid Group",Channel With Group
        http://example.com/ch3
        """

        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items.count == 3)

        // Item without group-title attribute
        #expect(playlist.items[0].group == nil)

        // Item with empty group-title (parser treats empty as nil)
        #expect(playlist.items[1].group == nil || playlist.items[1].group == "")

        // Item with valid group
        #expect(playlist.items[2].group == "Valid Group")
    }

    @Test("Special characters in group names preserved")
    func specialCharactersPreserved() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="▱ ULUSAL",Turkish Channel
        http://example.com/tr1
        #EXTINF:-1 group-title="Movies & Series",Mixed Content
        http://example.com/mixed
        #EXTINF:-1 group-title="Çocuk & Animasyon",Kids Channel
        http://example.com/kids
        #EXTINF:-1 group-title="SPOR | Sports",Sports Channel
        http://example.com/sports
        """

        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        #expect(playlist.items[0].group == "▱ ULUSAL")
        #expect(playlist.items[1].group == "Movies & Series")
        #expect(playlist.items[2].group == "Çocuk & Animasyon")
        #expect(playlist.items[3].group == "SPOR | Sports")
    }

    @Test("Real playlist examples - 4K WORLD group")
    func realPlaylist4KWorldGroup() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 xui-id="794794" tvg-name="Pamuk Prenses - Disney Snow White [4K] (2025)" group-title="4K WORLD",Pamuk Prenses - Disney Snow White [4K] (2025)
        http://example.com/1
        #EXTINF:-1 xui-id="635203" tvg-name="Jurassic Park 3 - 4K (2001)" group-title="4K WORLD",Jurassic Park 3 - 4K (2001)
        http://example.com/2
        #EXTINF:-1 xui-id="600724" tvg-name="Şrek Üç - Shrek 3 - FHD (2007)" group-title="4K WORLD",Şrek Üç - Shrek 3 - FHD (2007)
        http://example.com/3
        """

        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        // All items should be in 4K WORLD group
        for item in playlist.items {
            #expect(item.group == "4K WORLD", "Item '\(item.name)' should be in 4K WORLD group")
        }

        // All should be classified as movies
        for item in playlist.items {
            #expect(item.contentType == .movie, "Item '\(item.name)' in 4K WORLD should be movie")
        }
    }

    @Test("Real playlist examples - Live TV groups")
    func realPlaylistLiveTVGroups() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 xui-id="17" tvg-name="ATV °" group-title="▱ ULUSAL",ATV °
        http://example.com/atv
        #EXTINF:-1 xui-id="802986" tvg-name="Sıfır Tv" group-title="▱ SPOR",Sıfır Tv
        http://example.com/sport
        #EXTINF:-1 tvg-name="Fox Tv" group-title="▱ ULUSAL",Fox Tv
        http://example.com/fox
        """

        let playlist = try await parser.parse(data: content.data(using: .utf8)!)

        // Check groups
        #expect(playlist.items[0].group == "▱ ULUSAL")
        #expect(playlist.items[1].group == "▱ SPOR")
        #expect(playlist.items[2].group == "▱ ULUSAL")

        // All should be classified as live (▱ prefix)
        for item in playlist.items {
            #expect(item.contentType == .live, "Item '\(item.name)' with ▱ prefix should be live")
        }
    }
}
