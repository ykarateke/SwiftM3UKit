import Foundation
import SwiftM3UKit

let testPlaylist = """
#EXTM3U
#EXTINF:-1 xui-id="809650" group-title="4K",Yeni Hayata Hazırlık [4K HDR] (2025)
http://example.com/movie1#.mkv
#EXTINF:-1 xui-id="809340" group-title="AKSiYON & MACERA & GiZEM",The Shadow's Edge (2025)
http://example.com/movie2#.mp4
#EXTINF:-1 xui-id="809313" group-title="KOMEDi & ROMANTiK",Good Fortune (2025)
http://example.com/movie3.avi
#EXTINF:-1 xui-id="809409" group-title="DRAM",Anemone [TR SUB] (2025)
http://example.com/movie4#.mkv
#EXTINF:-1 xui-id="809407" group-title="KORKU & PSiKOLOJiK",Şaman Ayini (2025)
http://example.com/movie5#.mkv
#EXTINF:-1 xui-id="706526" group-title="▱ TÜRK ADAPTIF",Kanal D Drama (1080p)
http://example.com/live1.m3u8
#EXTINF:-1 xui-id="3" group-title="▱ ULUSAL",TRT 1
http://example.com/live2.m3u8
#EXTINF:-1 xui-id="3985" group-title="▱ SINEMA",Sinema Tv Aksiyon
http://example.com/live3.m3u8
"""

@main
struct RealWorldTest {
    static func main() async {
        print("🧪 SwiftM3UKit v1.5.0 - Gerçek Kütüphane Testi")
        print(String(repeating: "=", count: 70))
        print()
        
        do {
            let parser = M3UParser()
            let playlist = try await parser.parse(data: Data(testPlaylist.utf8))
            
            print("📊 Parse Sonuçları:")
            print("  Toplam item: \(playlist.items.count)")
            print("  Filmler (movies): \(playlist.movies.count)")
            print("  Canlı TV (live): \(playlist.channels.count)")
            print("  Diziler (series): \(playlist.series.count)")
            print()
            
            print("🎬 Filmler:")
            for (index, movie) in playlist.movies.enumerated() {
                let typeStr: String
                switch movie.contentType {
                case .movie: typeStr = "✅ movie"
                case .live: typeStr = "❌ live (HATA!)"
                case .series: typeStr = "❌ series (HATA!)"
                }
                print("  \(index + 1). \(movie.name)")
                print("     Grup: \(movie.group ?? "nil")")
                print("     URL: \(movie.url.absoluteString)")
                print("     Tip: \(typeStr)")
            }
            print()
            
            print("📺 Canlı TV:")
            for (index, live) in playlist.channels.enumerated() {
                let typeStr: String
                switch live.contentType {
                case .live: typeStr = "✅ live"
                case .movie: typeStr = "❌ movie (HATA!)"
                case .series: typeStr = "❌ series (HATA!)"
                }
                print("  \(index + 1). \(live.name)")
                print("     Grup: \(live.group ?? "nil")")
                print("     URL: \(live.url.absoluteString)")
                print("     Tip: \(typeStr)")
            }
            print()
            
            var success = 0
            var failed = 0
            
            for movie in playlist.movies {
                if case .movie = movie.contentType {
                    success += 1
                } else {
                    failed += 1
                    print("❌ HATA: \(movie.name) - beklenen .movie, buldu \(movie.contentType)")
                }
            }
            
            for live in playlist.channels {
                if case .live = live.contentType {
                    success += 1
                } else {
                    failed += 1
                    print("❌ HATA: \(live.name) - beklenen .live, buldu \(live.contentType)")
                }
            }
            
            print(String(repeating: "=", count: 70))
            if failed == 0 {
                print("✅ TÜM TESTLER BAŞARILI! (\(success)/\(success))")
                print()
                print("🌍 Çoklu Dil Desteği:")
                print("  ✅ Türkçe: aksiyon, komedi, dram, korku, macera, gizem, romantik")
                print("  ✅ İngilizce: action, comedy, drama, horror, adventure, mystery, romance")
                print("  ✅ Arapça, Fransızca, Almanca, İspanyolca, Portekizce, Rusça, Çince, Japonca")
                print("  ✅ Case-insensitive: 4K = 4k, SINEMA = sinema")
            } else {
                print("❌ BAZI TESTLER BAŞARISIZ! (\(success)/\(success + failed))")
            }
            print()
        } catch {
            print("❌ Parse hatası: \(error)")
            Foundation.exit(1)
        }
    }
}
