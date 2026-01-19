import Foundation

/// Title processing extension for M3UItem.
extension M3UItem {
    /// Default title normalizer used for title processing.
    private static let defaultNormalizer = TitleNormalizer()

    /// A cleaned version of the item's title.
    ///
    /// Removes common prefixes (TR:, UK:, etc.), bracketed content,
    /// and quality tags while preserving the core channel name.
    ///
    /// ## Example
    /// ```swift
    /// let item = M3UItem(name: "TR: BBC One HD [1080p]", ...)
    /// print(item.cleanTitle) // "BBC One"
    /// ```
    public var cleanTitle: String {
        Self.defaultNormalizer.sanitize(name)
    }

    /// A normalized version of the item's title for comparison.
    ///
    /// Applies Turkish character normalization, lowercase conversion,
    /// and whitespace normalization. Useful for deduplication and
    /// matching channels across different sources.
    ///
    /// ## Example
    /// ```swift
    /// let item = M3UItem(name: "Türkiye Kanalı", ...)
    /// print(item.normalizedTitle) // "turkiye kanali"
    /// ```
    public var normalizedTitle: String {
        Self.defaultNormalizer.normalize(name)
    }

    /// Returns a cleaned title using a custom normalizer.
    ///
    /// - Parameter normalizer: Custom title normalizer to use
    /// - Returns: Sanitized title
    public func cleanTitle(using normalizer: some TitleNormalizing) -> String {
        normalizer.sanitize(name)
    }

    /// Returns a normalized title using a custom normalizer.
    ///
    /// - Parameter normalizer: Custom title normalizer to use
    /// - Returns: Normalized title
    public func normalizedTitle(using normalizer: some TitleNormalizing) -> String {
        normalizer.normalize(name)
    }
}
