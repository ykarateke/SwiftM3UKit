import Foundation

/// Quality statistics for a playlist.
public struct QualityStatistics: Sendable {
    /// Distribution of items by resolution.
    ///
    /// Key is the resolution, value is the count of items with that resolution.
    public let resolutionDistribution: [Resolution: Int]

    /// Distribution of items by codec.
    ///
    /// Key is the codec, value is the count of items with that codec.
    public let codecDistribution: [Codec: Int]

    /// Distribution of items by streaming protocol.
    ///
    /// Key is the protocol, value is the count of items with that protocol.
    public let protocolDistribution: [StreamProtocol: Int]

    /// Average quality score across all items.
    public let averageScore: Double

    /// Highest quality score in the playlist.
    public let maxScore: Int

    /// Lowest quality score in the playlist.
    public let minScore: Int

    /// Number of items with explicit quality information detected.
    public let explicitQualityCount: Int

    /// Total number of items analyzed.
    public let totalItems: Int
}

/// Quality analysis extension for M3UPlaylist.
extension M3UPlaylist {
    // MARK: - Sorting

    /// Returns items sorted by quality score in descending order.
    ///
    /// Higher quality items appear first.
    ///
    /// ## Example
    /// ```swift
    /// let ranked = playlist.sortedByQuality()
    /// for item in ranked.prefix(10) {
    ///     print("\(item.name) - Score: \(item.qualityScore)")
    /// }
    /// ```
    public func sortedByQuality() -> [M3UItem] {
        items.sorted { $0.qualityScore > $1.qualityScore }
    }

    // MARK: - Search

    /// Finds the best quality item matching a search query.
    ///
    /// Searches items by name (case-insensitive) and returns the one
    /// with the highest quality score.
    ///
    /// - Parameter query: Search string to match against item names
    /// - Returns: Best quality matching item, or nil if no match found
    ///
    /// ## Example
    /// ```swift
    /// if let best = playlist.bestQualityItem(for: "BBC One") {
    ///     print("\(best.name) - Score: \(best.qualityScore)")
    /// }
    /// ```
    public func bestQualityItem(for query: String) -> M3UItem? {
        qualityRankedItems(for: query).first
    }

    /// Returns items matching a search query, sorted by quality.
    ///
    /// Searches items by name (case-insensitive) and returns them
    /// sorted by quality score in descending order.
    ///
    /// - Parameter query: Search string to match against item names
    /// - Returns: Array of matching items sorted by quality
    ///
    /// ## Example
    /// ```swift
    /// let matches = playlist.qualityRankedItems(for: "BBC")
    /// for item in matches {
    ///     print("\(item.name) - Score: \(item.qualityScore)")
    /// }
    /// ```
    public func qualityRankedItems(for query: String) -> [M3UItem] {
        let lowercasedQuery = query.lowercased()
        return items
            .filter { $0.name.lowercased().contains(lowercasedQuery) }
            .sorted { $0.qualityScore > $1.qualityScore }
    }

    // MARK: - Filtering

    /// Returns items with at least the specified minimum resolution.
    ///
    /// - Parameter minResolution: Minimum resolution threshold
    /// - Returns: Array of items meeting the resolution requirement
    ///
    /// ## Example
    /// ```swift
    /// let hdChannels = playlist.items(minResolution: .hd)
    /// print("HD+ channels: \(hdChannels.count)")
    /// ```
    public func items(minResolution: Resolution) -> [M3UItem] {
        items.filter { item in
            guard let resolution = item.resolution else { return false }
            return resolution >= minResolution
        }
    }

    /// Returns items with at least the specified minimum quality score.
    ///
    /// - Parameter minQualityScore: Minimum quality score (0-100)
    /// - Returns: Array of items meeting the score requirement
    ///
    /// ## Example
    /// ```swift
    /// let highQuality = playlist.items(minQualityScore: 70)
    /// print("High quality items: \(highQuality.count)")
    /// ```
    public func items(minQualityScore: Int) -> [M3UItem] {
        items.filter { $0.qualityScore >= minQualityScore }
    }

    // MARK: - Statistics

    /// Quality statistics for the playlist.
    ///
    /// Calculates distribution of resolutions, codecs, protocols,
    /// and score statistics across all items.
    ///
    /// ## Example
    /// ```swift
    /// let stats = playlist.qualityStatistics
    /// print("4K channels: \(stats.resolutionDistribution[.fourK] ?? 0)")
    /// print("Average score: \(stats.averageScore)")
    /// ```
    public var qualityStatistics: QualityStatistics {
        var resolutionDist: [Resolution: Int] = [:]
        var codecDist: [Codec: Int] = [:]
        var protocolDist: [StreamProtocol: Int] = [:]
        var totalScore = 0
        var maxScore = 0
        var minScore = 100
        var explicitCount = 0

        for item in items {
            let quality = item.qualityInfo

            // Resolution distribution
            if let resolution = quality.resolution {
                resolutionDist[resolution, default: 0] += 1
            }

            // Codec distribution
            if let codec = quality.codec {
                codecDist[codec, default: 0] += 1
            }

            // Protocol distribution
            protocolDist[quality.streamProtocol, default: 0] += 1

            // Score statistics
            totalScore += quality.score
            maxScore = max(maxScore, quality.score)
            minScore = min(minScore, quality.score)

            if quality.isExplicit {
                explicitCount += 1
            }
        }

        let averageScore = items.isEmpty ? 0.0 : Double(totalScore) / Double(items.count)

        return QualityStatistics(
            resolutionDistribution: resolutionDist,
            codecDistribution: codecDist,
            protocolDistribution: protocolDist,
            averageScore: averageScore,
            maxScore: items.isEmpty ? 0 : maxScore,
            minScore: items.isEmpty ? 0 : minScore,
            explicitQualityCount: explicitCount,
            totalItems: items.count
        )
    }
}
