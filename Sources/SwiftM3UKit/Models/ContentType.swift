/// Represents the type of content in an M3U playlist item.
///
/// IPTV playlists typically contain three types of content:
/// - Live TV channels
/// - Movies (VOD)
/// - TV Series with season/episode information
public enum ContentType: Sendable, Hashable, Codable {
    /// Live TV channel stream
    case live

    /// Video on demand (movie)
    case movie

    /// TV series with optional season and episode information
    case series(season: Int?, episode: Int?)
}

extension ContentType: Equatable {
    public static func == (lhs: ContentType, rhs: ContentType) -> Bool {
        switch (lhs, rhs) {
        case (.live, .live):
            return true
        case (.movie, .movie):
            return true
        case let (.series(lSeason, lEpisode), .series(rSeason, rEpisode)):
            return lSeason == rSeason && lEpisode == rEpisode
        default:
            return false
        }
    }
}
