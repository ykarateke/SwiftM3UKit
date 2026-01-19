import Foundation

/// Protocol for quality analyzers.
///
/// Implement this protocol to provide custom quality analysis logic.
///
/// ## Example
/// ```swift
/// struct MyAnalyzer: QualityAnalyzing {
///     func analyze(name: String, url: URL) -> QualityInfo {
///         // Custom analysis logic
///     }
/// }
/// ```
public protocol QualityAnalyzing: Sendable {
    /// Analyzes a stream's quality based on its name and URL.
    ///
    /// - Parameters:
    ///   - name: The display name of the stream
    ///   - url: The stream URL
    /// - Returns: Quality information including score, resolution, codec, and protocol
    func analyze(name: String, url: URL) -> QualityInfo
}
