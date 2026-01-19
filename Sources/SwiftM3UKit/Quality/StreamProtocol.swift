/// Represents streaming protocol types.
///
/// Protocol is detected from the stream URL scheme and file extension.
///
/// ## Example
/// ```swift
/// let proto: StreamProtocol = .hls
/// // HLS (.m3u8) provides adaptive streaming
/// ```
public enum StreamProtocol: Int, Sendable, Codable {
    /// Plain HTTP streaming
    case http = 0

    /// Secure HTTPS streaming
    case https = 1

    /// HTTP Live Streaming (.m3u8)
    case hls = 2
}
