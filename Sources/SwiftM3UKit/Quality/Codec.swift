/// Represents video codec types.
///
/// Codec information is detected from stream names using patterns like "HEVC", "H.265", "x264", etc.
///
/// ## Example
/// ```swift
/// let codec: Codec = .h265
/// print(codec > .h264) // true (HEVC is more efficient)
/// ```
public enum Codec: Int, Sendable, Codable, Comparable {
    /// Unknown or undetected codec
    case unknown = 0

    /// H.264/AVC codec
    case h264 = 1

    /// H.265/HEVC codec
    case h265 = 2

    public static func < (lhs: Codec, rhs: Codec) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
