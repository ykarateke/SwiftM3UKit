/// Contains quality information for a stream.
///
/// QualityInfo aggregates resolution, codec, protocol, and calculated score
/// for a stream based on analysis of its name and URL.
///
/// ## Example
/// ```swift
/// let item: M3UItem = ...
/// let quality = item.qualityInfo
/// print("Score: \(quality.score)")
/// print("Resolution: \(quality.resolution?.description ?? "unknown")")
/// ```
public struct QualityInfo: Sendable, Codable, Hashable {
    /// Detected video resolution (nil if unknown)
    public let resolution: Resolution?

    /// Detected video codec (nil if unknown)
    public let codec: Codec?

    /// Detected streaming protocol
    public let streamProtocol: StreamProtocol

    /// Quality score from 0 to 100
    public let score: Int

    /// Whether quality information was explicitly detected from metadata
    ///
    /// `true` if resolution or codec was detected from the stream name.
    /// `false` if only base score and protocol were applied.
    public let isExplicit: Bool

    /// Creates a new QualityInfo instance.
    ///
    /// - Parameters:
    ///   - resolution: Video resolution
    ///   - codec: Video codec
    ///   - streamProtocol: Streaming protocol
    ///   - score: Quality score (0-100)
    ///   - isExplicit: Whether quality was explicitly detected
    public init(
        resolution: Resolution?,
        codec: Codec?,
        streamProtocol: StreamProtocol,
        score: Int,
        isExplicit: Bool
    ) {
        self.resolution = resolution
        self.codec = codec
        self.streamProtocol = streamProtocol
        self.score = score
        self.isExplicit = isExplicit
    }
}
