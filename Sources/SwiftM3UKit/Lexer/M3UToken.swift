import Foundation

/// Represents a token in the M3U file format.
///
/// The lexer produces these tokens from raw M3U file content,
/// which are then processed by the parser to create M3UItem instances.
enum M3UToken: Sendable, Equatable {
    /// The #EXTM3U header that indicates an extended M3U file
    case extm3u

    /// An #EXTINF line with duration, attributes, and title
    /// - Parameters:
    ///   - duration: The duration in seconds (-1 for live streams)
    ///   - attributes: Key-value pairs from the line (tvg-id, tvg-logo, etc.)
    ///   - title: The display title/name of the media
    case extinf(duration: Int, attributes: [String: String], title: String)

    /// An #EXTGRP line indicating a group/category
    case extgrp(name: String)

    /// An #EXT-X-SESSION-DATA line containing session metadata
    /// - Parameters:
    ///   - dataID: The DATA-ID attribute value
    ///   - value: The optional VALUE attribute
    case extSessionData(dataID: String, value: String?)

    /// A valid URL line
    case url(URL)

    /// A comment line (starts with # but not a known directive)
    case comment(String)

    /// An unrecognized line
    case unknown(String)
}
