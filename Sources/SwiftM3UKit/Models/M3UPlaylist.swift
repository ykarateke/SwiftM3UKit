import Foundation

/// Represents a complete M3U playlist with convenience accessors for different content types.
///
/// The playlist provides filtered views for channels (live), movies, and series content.
///
/// ## Example
/// ```swift
/// let parser = M3UParser()
/// let playlist = try await parser.parse(from: url)
///
/// print("Total items: \(playlist.items.count)")
/// print("Live channels: \(playlist.channels.count)")
/// print("Movies: \(playlist.movies.count)")
/// print("Series: \(playlist.series.count)")
/// ```
public struct M3UPlaylist: Sendable {
    /// All items in the playlist
    public let items: [M3UItem]

    /// Creates a new playlist with the given items.
    ///
    /// - Parameter items: Array of M3U items
    public init(items: [M3UItem]) {
        self.items = items
    }

    /// Live TV channels (items with `.live` content type)
    public var channels: [M3UItem] {
        items.filter { $0.contentType == .live }
    }

    /// Movies (items with `.movie` content type)
    public var movies: [M3UItem] {
        items.filter {
            if case .movie = $0.contentType {
                return true
            }
            return false
        }
    }

    /// TV series (items with `.series` content type)
    public var series: [M3UItem] {
        items.filter {
            if case .series = $0.contentType {
                return true
            }
            return false
        }
    }

    /// Returns items grouped by their group name.
    ///
    /// - Returns: Dictionary where keys are group names and values are arrays of items
    public var groupedByCategory: [String: [M3UItem]] {
        Dictionary(grouping: items) { $0.group ?? "Uncategorized" }
    }

    /// Returns all unique group names in the playlist.
    public var groups: [String] {
        Array(Set(items.compactMap(\.group))).sorted()
    }

    // MARK: - Series Statistics

    /// Information about a TV series including all its episodes
    public struct SeriesInfo: Sendable, Hashable {
        /// Name of the series (extracted from episode names)
        public let name: String

        /// Group/category the series belongs to
        public let group: String?

        /// All episodes in this series
        public let episodes: [EpisodeInfo]

        /// Number of unique seasons
        public var seasonCount: Int {
            Set(episodes.compactMap(\.season)).count
        }

        /// Total number of episodes
        public var episodeCount: Int {
            episodes.count
        }
    }

    /// Information about a single episode
    public struct EpisodeInfo: Sendable, Hashable {
        /// The full M3U item for this episode
        public let item: M3UItem

        /// Season number (nil if unknown)
        public let season: Int?

        /// Episode number (nil if unknown)
        public let episode: Int?
    }

    /// Returns series grouped with their episodes.
    ///
    /// This method analyzes all series items and groups them by series name,
    /// extracting season and episode information from each item.
    ///
    /// - Returns: Array of SeriesInfo containing grouped episodes
    public var seriesGrouped: [SeriesInfo] {
        // Group series by name (everything before S01E01 pattern)
        var seriesMap: [String: (group: String?, episodes: [EpisodeInfo])] = [:]

        for item in series {
            guard case let .series(season, episode) = item.contentType else { continue }

            // Extract series name from item name
            let seriesName = extractSeriesName(from: item.name)
            let key = "\(seriesName)|\(item.group ?? "")"

            if seriesMap[key] == nil {
                seriesMap[key] = (group: item.group, episodes: [])
            }

            let episodeInfo = EpisodeInfo(item: item, season: season, episode: episode)
            seriesMap[key]!.episodes.append(episodeInfo)
        }

        return seriesMap.map { key, value in
            let name = key.components(separatedBy: "|").first ?? key
            return SeriesInfo(name: name, group: value.group, episodes: value.episodes)
        }.sorted { $0.episodeCount > $1.episodeCount }
    }

    /// Total number of unique series (not episodes)
    public var uniqueSeriesCount: Int {
        seriesGrouped.count
    }

    /// Total number of episodes across all series
    public var totalEpisodeCount: Int {
        seriesGrouped.reduce(0) { $0 + $1.episodeCount }
    }

    // MARK: - Private Helpers

    private func extractSeriesName(from name: String) -> String {
        let lowercased = name.lowercased()

        // Find S01E01 pattern and extract everything before it
        if let range = lowercased.range(of: "s\\d{1,2}e\\d{1,2}", options: .regularExpression) {
            let beforePattern = String(name[..<range.lowerBound])
            return beforePattern
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                .trimmingCharacters(in: .whitespaces)
        }

        // If no pattern found, return the full name
        return name
    }
}

extension M3UPlaylist: Equatable {
    public static func == (lhs: M3UPlaylist, rhs: M3UPlaylist) -> Bool {
        lhs.items == rhs.items
    }
}

extension M3UPlaylist: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(items)
    }
}
