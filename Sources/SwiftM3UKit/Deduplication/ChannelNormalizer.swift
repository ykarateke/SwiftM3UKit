import Foundation

/// A configurable channel normalizer for deduplication.
///
/// Supports multiple strategies for identifying duplicate channels
/// based on different attributes of M3UItems.
///
/// ## Example
/// ```swift
/// // Use tvg-id based deduplication
/// let normalizer = ChannelNormalizer(strategy: .tvgID)
/// let deduplicated = playlist.deduplicated(using: normalizer)
///
/// // Use composite key (tvg-id + title + group)
/// let compositeNormalizer = ChannelNormalizer(strategy: .composite)
/// let result = playlist.deduplicated(using: compositeNormalizer)
/// ```
public struct ChannelNormalizer: ChannelNormalizing, Sendable {
    /// Strategy for generating deduplication keys.
    public enum Strategy: Sendable {
        /// Use tvg-id attribute (falls back to normalized title if not present).
        case tvgID

        /// Use normalized title only.
        case title

        /// Use URL hash (ignoring auth parameters).
        case url

        /// Use composite key combining tvg-id, normalized title, and group.
        case composite

        /// Use tvg-id when available, otherwise normalized title within same group.
        case tvgIDWithFallback
    }

    /// The strategy used for generating keys.
    public let strategy: Strategy

    /// Title normalizer used for title-based strategies.
    private let titleNormalizer: TitleNormalizer

    /// Creates a new channel normalizer with the specified strategy.
    ///
    /// - Parameter strategy: The deduplication strategy to use (default: .composite)
    public init(strategy: Strategy = .composite) {
        self.strategy = strategy
        self.titleNormalizer = TitleNormalizer()
    }

    /// Generates a normalized key for the given item.
    ///
    /// - Parameter item: The M3U item to generate a key for
    /// - Returns: A string key identifying duplicates
    public func normalizedKey(for item: M3UItem) -> String {
        switch strategy {
        case .tvgID:
            return keyByTvgID(for: item)

        case .title:
            return keyByTitle(for: item)

        case .url:
            return keyByURL(for: item)

        case .composite:
            return compositeKey(for: item)

        case .tvgIDWithFallback:
            return keyByTvgIDWithFallback(for: item)
        }
    }

    // MARK: - Private Strategy Implementations

    private func keyByTvgID(for item: M3UItem) -> String {
        if let epgID = item.epgID, !epgID.isEmpty {
            return "tvg:\(epgID.lowercased())"
        }
        return keyByTitle(for: item)
    }

    private func keyByTitle(for item: M3UItem) -> String {
        let normalized = titleNormalizer.normalize(titleNormalizer.sanitize(item.name))
        return "title:\(normalized)"
    }

    private func keyByURL(for item: M3UItem) -> String {
        return "url:\(item.url.deduplicationHash)"
    }

    private func compositeKey(for item: M3UItem) -> String {
        var components: [String] = []

        // Add tvg-id if present
        if let epgID = item.epgID, !epgID.isEmpty {
            components.append("id:\(epgID.lowercased())")
        }

        // Add normalized title
        let normalized = titleNormalizer.normalize(titleNormalizer.sanitize(item.name))
        components.append("t:\(normalized)")

        // Add group if present
        if let group = item.group {
            let normalizedGroup = titleNormalizer.normalize(group)
            components.append("g:\(normalizedGroup)")
        }

        // Add content type
        components.append("c:\(item.contentType.description)")

        return components.joined(separator: "|")
    }

    private func keyByTvgIDWithFallback(for item: M3UItem) -> String {
        if let epgID = item.epgID, !epgID.isEmpty {
            return "tvg:\(epgID.lowercased())"
        }

        // Fall back to title + group
        let normalized = titleNormalizer.normalize(titleNormalizer.sanitize(item.name))
        let group = item.group.map { titleNormalizer.normalize($0) } ?? ""
        return "fallback:\(normalized)|\(group)"
    }
}

// MARK: - ContentType Description

extension ContentType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .live:
            return "live"
        case .movie:
            return "movie"
        case let .series(season, episode):
            if let s = season, let e = episode {
                return "series:s\(s)e\(e)"
            } else if let s = season {
                return "series:s\(s)"
            } else if let e = episode {
                return "series:e\(e)"
            }
            return "series"
        }
    }
}
