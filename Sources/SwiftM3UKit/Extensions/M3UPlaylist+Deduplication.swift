import Foundation

/// Deduplication extension for M3UPlaylist.
extension M3UPlaylist {
    /// Default channel normalizer for deduplication.
    private static let defaultNormalizer = ChannelNormalizer()

    /// Returns a deduplicated playlist keeping the highest quality duplicate.
    ///
    /// When multiple items have the same deduplication key, the one
    /// with the highest quality score is retained.
    ///
    /// ## Example
    /// ```swift
    /// let deduped = playlist.deduplicated()
    /// print("Before: \(playlist.items.count)")
    /// print("After: \(deduped.items.count)")
    /// ```
    public func deduplicated() -> M3UPlaylist {
        deduplicated(using: Self.defaultNormalizer)
    }

    /// Returns a deduplicated playlist using a custom normalizer.
    ///
    /// - Parameter normalizer: The channel normalizer to use
    /// - Returns: A new playlist with duplicates removed
    public func deduplicated(using normalizer: some ChannelNormalizing) -> M3UPlaylist {
        // Pre-compute keys once (key cache optimization)
        let keyCache: [UUID: String] = Dictionary(
            uniqueKeysWithValues: items.map { ($0.id, normalizer.normalizedKey(for: $0)) }
        )

        // Single-pass: find best item and track index for order preservation
        var bestItems: [String: (item: M3UItem, index: Int)] = [:]

        for (index, item) in items.enumerated() {
            let key = keyCache[item.id]!

            if let existing = bestItems[key] {
                // Keep the higher quality item
                if item.qualityScore > existing.item.qualityScore {
                    bestItems[key] = (item, index)
                }
            } else {
                bestItems[key] = (item, index)
            }
        }

        // Sort by original index to preserve order
        let deduplicatedItems = bestItems.values
            .sorted { $0.index < $1.index }
            .map { $0.item }

        return M3UPlaylist(items: deduplicatedItems)
    }

    /// Finds groups of duplicate items in the playlist.
    ///
    /// Returns arrays of items that share the same deduplication key.
    /// Only groups with more than one item are returned.
    ///
    /// ## Example
    /// ```swift
    /// let duplicateGroups = playlist.findDuplicates()
    /// for group in duplicateGroups {
    ///     print("Duplicates of '\(group.first!.name)':")
    ///     for item in group {
    ///         print("  - \(item.name) (score: \(item.qualityScore))")
    ///     }
    /// }
    /// ```
    public func findDuplicates() -> [[M3UItem]] {
        findDuplicates(using: Self.defaultNormalizer)
    }

    /// Finds groups of duplicate items using a custom normalizer.
    ///
    /// - Parameter normalizer: The channel normalizer to use
    /// - Returns: Arrays of duplicate item groups
    public func findDuplicates(using normalizer: some ChannelNormalizing) -> [[M3UItem]] {
        // Pre-compute keys once (key cache optimization)
        let keyCache: [UUID: String] = Dictionary(
            uniqueKeysWithValues: items.map { ($0.id, normalizer.normalizedKey(for: $0)) }
        )

        var groups: [String: [M3UItem]] = [:]

        for item in items {
            let key = keyCache[item.id]!
            groups[key, default: []].append(item)
        }

        // Only return groups with duplicates, sorted by quality
        return groups.values
            .filter { $0.count > 1 }
            .map { $0.sorted { $0.qualityScore > $1.qualityScore } }
            .sorted { $0.count > $1.count }
    }

    /// Statistics about duplicates in the playlist.
    ///
    /// ## Example
    /// ```swift
    /// let stats = playlist.deduplicationStatistics
    /// print("Original: \(stats.originalCount)")
    /// print("Unique: \(stats.uniqueCount)")
    /// print("Duplicates: \(stats.duplicatesRemoved) (\(stats.duplicatePercentage)%)")
    /// ```
    public var deduplicationStatistics: DeduplicationStatistics {
        deduplicationStatistics(using: Self.defaultNormalizer)
    }

    /// Statistics about duplicates using a custom normalizer.
    ///
    /// - Parameter normalizer: The channel normalizer to use
    /// - Returns: Deduplication statistics
    public func deduplicationStatistics(using normalizer: some ChannelNormalizing) -> DeduplicationStatistics {
        // Use Set directly with map for efficient unique key counting
        let uniqueKeys = Set(items.map { normalizer.normalizedKey(for: $0) })

        return DeduplicationStatistics(
            originalCount: items.count,
            deduplicatedCount: uniqueKeys.count
        )
    }

    /// Returns a deduplicated playlist using a specific strategy.
    ///
    /// Convenience method for common deduplication strategies.
    ///
    /// - Parameter strategy: The deduplication strategy to use
    /// - Returns: A new playlist with duplicates removed
    ///
    /// ## Example
    /// ```swift
    /// // Deduplicate by tvg-id
    /// let byID = playlist.deduplicated(strategy: .tvgID)
    ///
    /// // Deduplicate by URL
    /// let byURL = playlist.deduplicated(strategy: .url)
    /// ```
    public func deduplicated(strategy: ChannelNormalizer.Strategy) -> M3UPlaylist {
        deduplicated(using: ChannelNormalizer(strategy: strategy))
    }
}
