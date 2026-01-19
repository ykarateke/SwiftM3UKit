import Foundation

/// A protocol for normalizing channel identifiers for deduplication.
///
/// Implementations generate consistent keys for M3UItems that should
/// be considered duplicates of each other.
///
/// ## Example
/// ```swift
/// struct MyNormalizer: ChannelNormalizing {
///     func normalizedKey(for item: M3UItem) -> String {
///         item.epgID ?? item.name.lowercased()
///     }
/// }
/// ```
public protocol ChannelNormalizing: Sendable {
    /// Generates a normalized key for deduplication.
    ///
    /// Items with the same key are considered duplicates.
    ///
    /// - Parameter item: The M3U item to generate a key for
    /// - Returns: A string key for deduplication
    func normalizedKey(for item: M3UItem) -> String
}
