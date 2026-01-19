import Foundation

/// A protocol for normalizing and sanitizing M3U item titles.
///
/// Implementations can provide custom normalization logic for
/// comparing titles across different sources or cleaning up
/// display names.
///
/// ## Example
/// ```swift
/// struct MyNormalizer: TitleNormalizing {
///     func normalize(_ title: String) -> String {
///         title.lowercased()
///     }
///
///     func sanitize(_ title: String) -> String {
///         title.trimmingCharacters(in: .whitespaces)
///     }
/// }
/// ```
public protocol TitleNormalizing: Sendable {
    /// Normalizes a title for comparison purposes.
    ///
    /// Normalized titles should be consistent across different
    /// representations of the same channel/content.
    ///
    /// - Parameter title: The original title
    /// - Returns: A normalized version of the title
    func normalize(_ title: String) -> String

    /// Sanitizes a title for display purposes.
    ///
    /// Removes common prefixes, suffixes, brackets, and quality tags
    /// while preserving the core channel/content name.
    ///
    /// - Parameter title: The original title
    /// - Returns: A cleaned version of the title
    func sanitize(_ title: String) -> String
}
