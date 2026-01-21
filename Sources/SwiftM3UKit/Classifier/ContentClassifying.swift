import Foundation

/// Protocol for content type classifiers.
///
/// Implement this protocol to provide custom content classification logic.
///
/// ## Example
/// ```swift
/// struct MyCustomClassifier: ContentClassifying {
///     func classify(name: String, group: String?, attributes: [String: String], url: URL?) -> ContentType {
///         // Custom classification logic
///         if name.contains("Live") {
///             return .live
///         }
///         return .movie
///     }
/// }
///
/// let parser = M3UParser()
/// await parser.setClassifier(MyCustomClassifier())
/// ```
public protocol ContentClassifying: Sendable {
    /// Classifies content based on its metadata.
    ///
    /// - Parameters:
    ///   - name: The display name of the content
    ///   - group: The group/category name (optional)
    ///   - attributes: All parsed attributes from the M3U entry
    ///   - url: The stream URL (optional) - used for extension-based classification
    /// - Returns: The determined content type
    func classify(name: String, group: String?, attributes: [String: String], url: URL?) -> ContentType
}
