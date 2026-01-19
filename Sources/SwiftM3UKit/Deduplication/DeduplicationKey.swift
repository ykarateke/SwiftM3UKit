import Foundation

/// A structured key for channel deduplication.
///
/// Contains the components used to identify duplicate channels,
/// supporting Hashable and Codable for storage and comparison.
///
/// ## Example
/// ```swift
/// let key = DeduplicationKey(
///     tvgID: "bbc.one.uk",
///     normalizedTitle: "bbc one",
///     group: "uk channels",
///     contentType: .live
/// )
///
/// print(key.compositeKey)
/// ```
public struct DeduplicationKey: Hashable, Sendable, Codable {
    /// The tvg-id attribute value (lowercased, if present).
    public let tvgID: String?

    /// Normalized title for comparison.
    public let normalizedTitle: String

    /// Group name (normalized, if present).
    public let group: String?

    /// Content type of the item.
    public let contentType: ContentType

    /// A combined key string for efficient comparison.
    public var compositeKey: String {
        var parts: [String] = []

        if let tvgID = tvgID {
            parts.append("id:\(tvgID)")
        }

        parts.append("t:\(normalizedTitle)")

        if let group = group {
            parts.append("g:\(group)")
        }

        parts.append("c:\(contentType.description)")

        return parts.joined(separator: "|")
    }

    /// Creates a new deduplication key.
    ///
    /// - Parameters:
    ///   - tvgID: Optional tvg-id attribute
    ///   - normalizedTitle: The normalized title
    ///   - group: Optional group name (normalized)
    ///   - contentType: Content type of the item
    public init(
        tvgID: String?,
        normalizedTitle: String,
        group: String?,
        contentType: ContentType
    ) {
        self.tvgID = tvgID
        self.normalizedTitle = normalizedTitle
        self.group = group
        self.contentType = contentType
    }

    /// Creates a deduplication key from an M3UItem.
    ///
    /// - Parameter item: The item to create a key for
    public init(for item: M3UItem) {
        let normalizer = TitleNormalizer()

        self.tvgID = item.epgID?.lowercased()
        self.normalizedTitle = normalizer.normalize(normalizer.sanitize(item.name))
        self.group = item.group.map { normalizer.normalize($0) }
        self.contentType = item.contentType
    }
}

/// Statistics about a deduplication operation.
public struct DeduplicationStatistics: Sendable {
    /// Number of items before deduplication.
    public let originalCount: Int

    /// Number of items after deduplication.
    public let deduplicatedCount: Int

    /// Number of duplicate items removed.
    public var duplicatesRemoved: Int {
        originalCount - deduplicatedCount
    }

    /// Percentage of items that were duplicates.
    public var duplicatePercentage: Double {
        guard originalCount > 0 else { return 0 }
        return Double(duplicatesRemoved) / Double(originalCount) * 100
    }

    /// Number of unique channels/items.
    public var uniqueCount: Int {
        deduplicatedCount
    }

    /// Creates new deduplication statistics.
    ///
    /// - Parameters:
    ///   - originalCount: Count before deduplication
    ///   - deduplicatedCount: Count after deduplication
    public init(originalCount: Int, deduplicatedCount: Int) {
        self.originalCount = originalCount
        self.deduplicatedCount = deduplicatedCount
    }
}
