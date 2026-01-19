/// Represents video resolution quality levels.
///
/// Resolution is detected from stream names using patterns like "4K", "HD", "1080p", etc.
///
/// ## Example
/// ```swift
/// let resolution: Resolution = .fhd
/// print(resolution < .uhd) // true
/// ```
public enum Resolution: Int, Sendable, Codable, Comparable {
    /// Standard definition (480p)
    case sd = 0

    /// High definition (720p)
    case hd = 1

    /// Full HD (1080p)
    case fhd = 2

    /// Ultra HD (2160p)
    case uhd = 3

    /// 4K resolution
    case fourK = 4

    public static func < (lhs: Resolution, rhs: Resolution) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
