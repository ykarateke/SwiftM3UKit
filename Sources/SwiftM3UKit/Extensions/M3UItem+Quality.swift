import Foundation

/// Quality analysis extension for M3UItem.
extension M3UItem {
    /// Default quality analyzer used for quality analysis.
    private static let defaultAnalyzer = QualityAnalyzer()

    /// Quality information for this item.
    ///
    /// Analyzes the item's name and URL to determine resolution, codec,
    /// streaming protocol, and quality score.
    ///
    /// ## Example
    /// ```swift
    /// let item: M3UItem = ...
    /// let quality = item.qualityInfo
    /// print("Score: \(quality.score)")
    /// print("Resolution: \(quality.resolution?.description ?? "unknown")")
    /// ```
    public var qualityInfo: QualityInfo {
        Self.defaultAnalyzer.analyze(name: name, url: url)
    }

    /// Quality score from 0 to 100.
    ///
    /// Higher scores indicate better quality streams.
    /// Score is calculated based on resolution, codec, and streaming protocol.
    ///
    /// ## Example
    /// ```swift
    /// let item: M3UItem = ...
    /// print("Quality: \(item.qualityScore)")
    /// ```
    public var qualityScore: Int {
        qualityInfo.score
    }

    /// Detected video resolution.
    ///
    /// Returns nil if resolution cannot be determined from the stream name.
    ///
    /// ## Example
    /// ```swift
    /// if let resolution = item.resolution {
    ///     print("Resolution: \(resolution)")
    /// }
    /// ```
    public var resolution: Resolution? {
        qualityInfo.resolution
    }

    /// Detected video codec.
    ///
    /// Returns nil if codec cannot be determined from the stream name.
    ///
    /// ## Example
    /// ```swift
    /// if let codec = item.codec {
    ///     print("Codec: \(codec)")
    /// }
    /// ```
    public var codec: Codec? {
        qualityInfo.codec
    }
}
