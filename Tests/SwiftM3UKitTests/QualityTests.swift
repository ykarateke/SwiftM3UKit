import Testing
import Foundation
@testable import SwiftM3UKit

@Suite("Quality Score Engine Tests")
struct QualityTests {

    let analyzer = QualityAnalyzer()

    // MARK: - Resolution Detection

    @Test("Detect 4K resolution from name")
    func detect4K() {
        let info = analyzer.analyze(name: "BBC One 4K", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .fourK)
    }

    @Test("Detect 4K resolution with brackets")
    func detect4KBrackets() {
        let info = analyzer.analyze(name: "Discovery [4K]", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .fourK)
    }

    @Test("Detect UHD resolution")
    func detectUHD() {
        let info = analyzer.analyze(name: "National Geographic UHD", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .uhd)
    }

    @Test("Detect UHD resolution from 2160p")
    func detectUHD2160p() {
        let info = analyzer.analyze(name: "Movie 2160p", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .uhd)
    }

    @Test("Detect UHD unicode indicator")
    func detectUHDUnicode() {
        let info = analyzer.analyze(name: "Filmbox \u{1D41C}\u{1D34}\u{1D30}", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .uhd)
    }

    @Test("Detect FHD resolution")
    func detectFHD() {
        let info = analyzer.analyze(name: "CNN FHD", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .fhd)
    }

    @Test("Detect FHD resolution from 1080p")
    func detectFHD1080p() {
        let info = analyzer.analyze(name: "Sports 1080p", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .fhd)
    }

    @Test("Detect Full HD resolution")
    func detectFullHD() {
        let info = analyzer.analyze(name: "Channel Full HD", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .fhd)
    }

    @Test("Detect HD resolution")
    func detectHD() {
        let info = analyzer.analyze(name: "BBC One HD", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .hd)
    }

    @Test("Detect HD resolution from 720p")
    func detectHD720p() {
        let info = analyzer.analyze(name: "Sports 720p", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .hd)
    }

    @Test("Detect HD unicode indicator")
    func detectHDUnicode() {
        let info = analyzer.analyze(name: "beIN Sports \u{1D34}\u{1D30}", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .hd)
    }

    @Test("Detect SD resolution")
    func detectSD() {
        let info = analyzer.analyze(name: "Old Channel SD", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .sd)
    }

    @Test("Detect SD resolution from 480p")
    func detectSD480p() {
        let info = analyzer.analyze(name: "Channel 480p", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .sd)
    }

    @Test("HD in FHD name should return FHD")
    func hdInFHDName() {
        let info = analyzer.analyze(name: "Channel FHD", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == .fhd)
    }

    @Test("No resolution detected for plain name")
    func noResolution() {
        let info = analyzer.analyze(name: "Plain Channel", url: URL(string: "http://example.com/stream")!)
        #expect(info.resolution == nil)
    }

    // MARK: - Codec Detection

    @Test("Detect HEVC codec")
    func detectHEVC() {
        let info = analyzer.analyze(name: "Movie HEVC", url: URL(string: "http://example.com/stream")!)
        #expect(info.codec == .h265)
    }

    @Test("Detect H.265 codec")
    func detectH265Dot() {
        let info = analyzer.analyze(name: "Movie H.265", url: URL(string: "http://example.com/stream")!)
        #expect(info.codec == .h265)
    }

    @Test("Detect H265 codec without dot")
    func detectH265NoDot() {
        let info = analyzer.analyze(name: "Movie H265", url: URL(string: "http://example.com/stream")!)
        #expect(info.codec == .h265)
    }

    @Test("Detect x265 codec")
    func detectX265() {
        let info = analyzer.analyze(name: "Movie x265", url: URL(string: "http://example.com/stream")!)
        #expect(info.codec == .h265)
    }

    @Test("Detect H.264 codec")
    func detectH264() {
        let info = analyzer.analyze(name: "Movie H.264", url: URL(string: "http://example.com/stream")!)
        #expect(info.codec == .h264)
    }

    @Test("Detect AVC codec")
    func detectAVC() {
        let info = analyzer.analyze(name: "Movie AVC", url: URL(string: "http://example.com/stream")!)
        #expect(info.codec == .h264)
    }

    @Test("Detect x264 codec")
    func detectX264() {
        let info = analyzer.analyze(name: "Movie x264", url: URL(string: "http://example.com/stream")!)
        #expect(info.codec == .h264)
    }

    @Test("No codec detected for plain name")
    func noCodec() {
        let info = analyzer.analyze(name: "Plain Channel", url: URL(string: "http://example.com/stream")!)
        #expect(info.codec == nil)
    }

    // MARK: - Protocol Detection

    @Test("Detect HLS protocol from m3u8")
    func detectHLS() {
        let info = analyzer.analyze(name: "Channel", url: URL(string: "http://example.com/stream.m3u8")!)
        #expect(info.streamProtocol == .hls)
    }

    @Test("Detect HLS protocol from m3u8 with query params")
    func detectHLSWithParams() {
        let info = analyzer.analyze(name: "Channel", url: URL(string: "http://example.com/stream.m3u8?token=abc")!)
        #expect(info.streamProtocol == .hls)
    }

    @Test("Detect HTTPS protocol")
    func detectHTTPS() {
        let info = analyzer.analyze(name: "Channel", url: URL(string: "https://example.com/stream.ts")!)
        #expect(info.streamProtocol == .https)
    }

    @Test("Detect HTTP protocol")
    func detectHTTP() {
        let info = analyzer.analyze(name: "Channel", url: URL(string: "http://example.com/stream.ts")!)
        #expect(info.streamProtocol == .http)
    }

    @Test("HLS over HTTPS still returns HLS")
    func hlsOverHTTPS() {
        let info = analyzer.analyze(name: "Channel", url: URL(string: "https://example.com/stream.m3u8")!)
        #expect(info.streamProtocol == .hls)
    }

    // MARK: - Score Calculation

    @Test("Base score for plain stream")
    func baseScore() {
        let info = analyzer.analyze(name: "Channel", url: URL(string: "http://example.com/stream")!)
        // Base 25 + HTTP 5 = 30
        #expect(info.score == 30)
    }

    @Test("Score for 4K HEVC HLS stream")
    func maxScore() {
        let info = analyzer.analyze(name: "BBC 4K HEVC", url: URL(string: "https://example.com/stream.m3u8")!)
        // Base 25 + 4K 40 + HEVC 20 + HLS 15 = 100
        #expect(info.score == 100)
    }

    @Test("Score for HD stream with HTTPS")
    func hdHTTPSScore() {
        let info = analyzer.analyze(name: "Channel HD", url: URL(string: "https://example.com/stream.ts")!)
        // Base 25 + HD 20 + HTTPS 10 = 55
        #expect(info.score == 55)
    }

    @Test("Score for FHD H.264 stream")
    func fhdH264Score() {
        let info = analyzer.analyze(name: "Channel FHD H.264", url: URL(string: "http://example.com/stream")!)
        // Base 25 + FHD 30 + H.264 10 + HTTP 5 = 70
        #expect(info.score == 70)
    }

    @Test("Score for UHD H.265 HLS stream")
    func uhdH265HLSScore() {
        let info = analyzer.analyze(name: "Channel UHD HEVC", url: URL(string: "http://example.com/stream.m3u8")!)
        // Base 25 + UHD 35 + HEVC 20 + HLS 15 = 95
        #expect(info.score == 95)
    }

    // MARK: - isExplicit Flag

    @Test("isExplicit true when resolution detected")
    func explicitWithResolution() {
        let info = analyzer.analyze(name: "Channel HD", url: URL(string: "http://example.com/stream")!)
        #expect(info.isExplicit == true)
    }

    @Test("isExplicit true when codec detected")
    func explicitWithCodec() {
        let info = analyzer.analyze(name: "Channel HEVC", url: URL(string: "http://example.com/stream")!)
        #expect(info.isExplicit == true)
    }

    @Test("isExplicit false when nothing detected")
    func explicitFalse() {
        let info = analyzer.analyze(name: "Plain Channel", url: URL(string: "http://example.com/stream")!)
        #expect(info.isExplicit == false)
    }

    // MARK: - Resolution Comparison

    @Test("Resolution comparison")
    func resolutionComparison() {
        #expect(Resolution.sd < Resolution.hd)
        #expect(Resolution.hd < Resolution.fhd)
        #expect(Resolution.fhd < Resolution.uhd)
        #expect(Resolution.uhd < Resolution.fourK)
    }

    // MARK: - Codec Comparison

    @Test("Codec comparison")
    func codecComparison() {
        #expect(Codec.unknown < Codec.h264)
        #expect(Codec.h264 < Codec.h265)
    }
}

// MARK: - M3UItem Quality Extension Tests

@Suite("M3UItem Quality Extension Tests")
struct M3UItemQualityTests {

    @Test("M3UItem qualityInfo returns correct data")
    func itemQualityInfo() {
        let item = M3UItem(
            name: "BBC One 4K HEVC",
            url: URL(string: "https://example.com/stream.m3u8")!
        )

        let quality = item.qualityInfo
        #expect(quality.resolution == .fourK)
        #expect(quality.codec == .h265)
        #expect(quality.streamProtocol == .hls)
        #expect(quality.score == 100)
    }

    @Test("M3UItem qualityScore shortcut")
    func itemQualityScore() {
        let item = M3UItem(
            name: "Channel HD",
            url: URL(string: "https://example.com/stream")!
        )

        #expect(item.qualityScore == 55)
    }

    @Test("M3UItem resolution shortcut")
    func itemResolution() {
        let item = M3UItem(
            name: "Channel FHD",
            url: URL(string: "http://example.com/stream")!
        )

        #expect(item.resolution == .fhd)
    }

    @Test("M3UItem codec shortcut")
    func itemCodec() {
        let item = M3UItem(
            name: "Channel HEVC",
            url: URL(string: "http://example.com/stream")!
        )

        #expect(item.codec == .h265)
    }
}

// MARK: - M3UPlaylist Quality Extension Tests

@Suite("M3UPlaylist Quality Extension Tests")
struct M3UPlaylistQualityTests {

    let testItems: [M3UItem] = [
        M3UItem(name: "BBC One 4K HEVC", url: URL(string: "https://example.com/bbc4k.m3u8")!),
        M3UItem(name: "BBC Two HD", url: URL(string: "https://example.com/bbc2hd.ts")!),
        M3UItem(name: "BBC Three", url: URL(string: "http://example.com/bbc3.ts")!),
        M3UItem(name: "CNN FHD H.264", url: URL(string: "http://example.com/cnn.m3u8")!),
        M3UItem(name: "Sky News UHD", url: URL(string: "https://example.com/sky.m3u8")!)
    ]

    @Test("sortedByQuality returns items in descending score order")
    func sortedByQuality() {
        let playlist = M3UPlaylist(items: testItems)
        let sorted = playlist.sortedByQuality()

        #expect(sorted[0].name == "BBC One 4K HEVC")
        #expect(sorted[0].qualityScore >= sorted[1].qualityScore)
        #expect(sorted[1].qualityScore >= sorted[2].qualityScore)
    }

    @Test("bestQualityItem returns highest quality match")
    func bestQualityItem() {
        let playlist = M3UPlaylist(items: testItems)
        let best = playlist.bestQualityItem(for: "BBC")

        #expect(best?.name == "BBC One 4K HEVC")
    }

    @Test("bestQualityItem returns nil for no match")
    func bestQualityItemNoMatch() {
        let playlist = M3UPlaylist(items: testItems)
        let best = playlist.bestQualityItem(for: "NonExistent")

        #expect(best == nil)
    }

    @Test("qualityRankedItems returns matches sorted by quality")
    func qualityRankedItems() {
        let playlist = M3UPlaylist(items: testItems)
        let ranked = playlist.qualityRankedItems(for: "BBC")

        #expect(ranked.count == 3)
        #expect(ranked[0].name == "BBC One 4K HEVC")
    }

    @Test("items(minResolution:) filters correctly")
    func itemsMinResolution() {
        let playlist = M3UPlaylist(items: testItems)
        let fhdPlus = playlist.items(minResolution: .fhd)

        // 4K, UHD, FHD should pass
        #expect(fhdPlus.count == 3)
        for item in fhdPlus {
            #expect(item.resolution != nil)
            #expect(item.resolution! >= .fhd)
        }
    }

    @Test("items(minQualityScore:) filters correctly")
    func itemsMinScore() {
        let playlist = M3UPlaylist(items: testItems)
        let highQuality = playlist.items(minQualityScore: 70)

        for item in highQuality {
            #expect(item.qualityScore >= 70)
        }
    }

    @Test("qualityStatistics calculates correctly")
    func qualityStatistics() {
        let playlist = M3UPlaylist(items: testItems)
        let stats = playlist.qualityStatistics

        #expect(stats.totalItems == 5)
        #expect(stats.resolutionDistribution[.fourK] == 1)
        #expect(stats.resolutionDistribution[.uhd] == 1)
        #expect(stats.resolutionDistribution[.fhd] == 1)
        #expect(stats.resolutionDistribution[.hd] == 1)
        #expect(stats.maxScore == 100)
        #expect(stats.explicitQualityCount == 4) // BBC Three has no explicit quality
    }

    @Test("qualityStatistics with empty playlist")
    func qualityStatisticsEmpty() {
        let playlist = M3UPlaylist(items: [])
        let stats = playlist.qualityStatistics

        #expect(stats.totalItems == 0)
        #expect(stats.averageScore == 0.0)
        #expect(stats.maxScore == 0)
        #expect(stats.minScore == 0)
    }
}
