import Foundation
import SwiftM3UKit

struct DetailedAnalysis {
    static func main() async throws {
        let playlistPath = "docs/playlist_5gykarateke_plus.m3u"
        let url = URL(fileURLWithPath: playlistPath)

        print("🔍 SwiftM3UKit - Detaylı İçerik Analizi")
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print()

        let parser = M3UParser()
        let playlist = try await parser.parse(from: url)

        // GENEL İSTATİSTİKLER
        print("📊 GENEL İSTATİSTİKLER")
        print("-" .padding(toLength: 80, withPad: "-", startingAt: 0))
        print("Toplam içerik sayısı:        \(playlist.items.count)")
        print("Canlı TV kanalları:          \(playlist.channels.count)")
        print("Filmler:                     \(playlist.movies.count)")
        print("Dizi bölümleri (toplam):     \(playlist.series.count)")
        print("Benzersiz dizi sayısı:       \(playlist.uniqueSeriesCount)")
        print()

        // CANLI TV KANALLARI
        print("📺 CANLI TV KANALLARI - GRUPLAR")
        print("-" .padding(toLength: 80, withPad: "-", startingAt: 0))
        var liveGroups: [String: Int] = [:]
        for channel in playlist.channels {
            let group = channel.group ?? "Grup Yok"
            liveGroups[group, default: 0] += 1
        }
        let sortedLive = liveGroups.sorted { $0.value > $1.value }
        print("Toplam \(sortedLive.count) farklı grup:")
        for (i, (group, count)) in sortedLive.prefix(20).enumerated() {
            print("\(String(format: "%2d", i+1)). \(group): \(count) kanal")
        }
        print()

        // FİLMLER
        print("🎬 FİLMLER - GRUPLAR")
        print("-" .padding(toLength: 80, withPad: "-", startingAt: 0))
        var movieGroups: [String: Int] = [:]
        for movie in playlist.movies {
            let group = movie.group ?? "Grup Yok"
            movieGroups[group, default: 0] += 1
        }
        let sortedMovies = movieGroups.sorted { $0.value > $1.value }
        print("Toplam \(sortedMovies.count) farklı grup:")
        for (i, (group, count)) in sortedMovies.prefix(25).enumerated() {
            print("\(String(format: "%2d", i+1)). \(group): \(count) film")
        }
        print()

        // DİZİLER
        print("📺 DİZİLER - GRUPLAR")
        print("-" .padding(toLength: 80, withPad: "-", startingAt: 0))
        var seriesGroups: [String: Int] = [:]
        for series in playlist.series {
            let group = series.group ?? "Grup Yok"
            seriesGroups[group, default: 0] += 1
        }
        let sortedSeries = seriesGroups.sorted { $0.value > $1.value }
        print("Toplam \(sortedSeries.count) farklı grup:")
        for (i, (group, count)) in sortedSeries.enumerated() {
            print("\(String(format: "%2d", i+1)). \(group): \(count) bölüm")
        }
        print()

        // EN POPÜLER DİZİLER
        print("⭐ EN POPÜLER 30 DİZİ")
        print("-" .padding(toLength: 80, withPad: "-", startingAt: 0))
        for (i, series) in playlist.seriesGrouped.prefix(30).enumerated() {
            let groupInfo = series.group.map { " [\($0)]" } ?? ""
            print("\(String(format: "%2d", i+1)). \(series.name)\(groupInfo)")
            print("    \(series.episodeCount) bölüm, \(series.seasonCount) sezon")
        }
        print()

        // KALİTE İSTATİSTİKLERİ
        print("💎 KALİTE İSTATİSTİKLERİ")
        print("-" .padding(toLength: 80, withPad: "-", startingAt: 0))

        var resolutions: [String: Int] = [:]
        var codecs: [String: Int] = [:]
        var protocols: [String: Int] = [:]

        for item in playlist.items {
            if let res = item.resolution {
                resolutions["\(res)", default: 0] += 1
            }
            if let codec = item.codec {
                codecs["\(codec)", default: 0] += 1
            }
            let proto = item.qualityInfo.streamProtocol
            protocols["\(proto)", default: 0] += 1
        }

        print("\nÇözünürlük Dağılımı:")
        for (res, count) in resolutions.sorted(by: { $0.value > $1.value }) {
            let percentage = Double(count) / Double(playlist.items.count) * 100
            print("  \(res): \(count) (\(String(format: "%.1f", percentage))%)")
        }

        print("\nCodec Dağılımı:")
        for (codec, count) in codecs.sorted(by: { $0.value > $1.value }) {
            let percentage = Double(count) / Double(playlist.items.count) * 100
            print("  \(codec): \(count) (\(String(format: "%.1f", percentage))%)")
        }

        print("\nProtokol Dağılımı:")
        for (proto, count) in protocols.sorted(by: { $0.value > $1.value }) {
            let percentage = Double(count) / Double(playlist.items.count) * 100
            print("  \(proto): \(count) (\(String(format: "%.1f", percentage))%)")
        }
        print()

        // ÖRNEKLER
        print("📋 ÖRNEK İÇERİKLER")
        print("-" .padding(toLength: 80, withPad: "-", startingAt: 0))

        print("\n🔴 Örnek Canlı TV Kanalları (5 adet):")
        for (i, channel) in playlist.channels.prefix(5).enumerated() {
            print("\(i+1). \(channel.name)")
            print("   Grup: \(channel.group ?? "yok")")
            print("   URL: \(channel.url.absoluteString.prefix(60))...")
        }

        print("\n🎬 Örnek Filmler (5 adet):")
        for (i, movie) in playlist.movies.prefix(5).enumerated() {
            print("\(i+1). \(movie.name)")
            print("   Grup: \(movie.group ?? "yok")")
            if let res = movie.resolution, let codec = movie.codec {
                print("   Kalite: \(res), \(codec)")
            }
        }

        print("\n📺 Örnek Dizi Bölümleri (5 adet):")
        for (i, episode) in playlist.series.prefix(5).enumerated() {
            print("\(i+1). \(episode.name)")
            print("   Grup: \(episode.group ?? "yok")")
            if case let .series(season, ep) = episode.contentType {
                print("   Sezon: \(season ?? 0), Bölüm: \(ep ?? 0)")
            }
        }
        print()

        // CATCHUP DESTEĞİ
        print("⏰ CATCHUP (GERİ İZLEME) DESTEĞİ")
        print("-" .padding(toLength: 80, withPad: "-", startingAt: 0))
        let catchupItems = playlist.items.filter { $0.catchup != nil }
        print("Catchup destekli kanal sayısı: \(catchupItems.count)")

        if !catchupItems.isEmpty {
            print("\nÖrnek catchup kanalları:")
            for (i, item) in catchupItems.prefix(5).enumerated() {
                print("\(i+1). \(item.name)")
                print("   Mod: \(item.catchup ?? "yok")")
                print("   Gün sayısı: \(item.catchupDays ?? 0)")
            }
        }
        print()

        // ÖZET
        print("📈 ÖZET")
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("✅ Parse işlemi başarılı!")
        print("   • \(playlist.items.count) toplam içerik")
        print("   • \(liveGroups.count) canlı TV grubu")
        print("   • \(movieGroups.count) film grubu")
        print("   • \(seriesGroups.count) dizi grubu")
        print("   • \(playlist.uniqueSeriesCount) benzersiz dizi")
        print("   • Ortalama \(String(format: "%.1f", Double(playlist.totalEpisodeCount) / Double(playlist.uniqueSeriesCount))) bölüm/dizi")
        print()
    }
}

// Entry point
Task {
    try await DetailedAnalysis.main()
}
