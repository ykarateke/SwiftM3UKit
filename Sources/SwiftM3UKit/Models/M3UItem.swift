import Foundation

/// Represents a single item in an M3U playlist.
///
/// An M3U item contains metadata about a media stream including its name,
/// URL, group information, logo, EPG ID, and content type.
///
/// ## Example
/// ```swift
/// let item = M3UItem(
///     name: "BBC One HD",
///     url: URL(string: "http://example.com/stream")!,
///     group: "UK Channels",
///     logo: URL(string: "http://example.com/logo.png"),
///     epgID: "bbc.one.uk",
///     contentType: .live,
///     duration: -1,
///     attributes: ["tvg-name": "BBC One HD"]
/// )
/// ```
public struct M3UItem: Sendable, Hashable, Identifiable, Codable {
    /// Unique identifier for the item
    public let id: UUID

    /// Display name of the channel or media
    public let name: String

    /// Stream URL
    public let url: URL

    /// Group/category name (from group-title attribute)
    public let group: String?

    /// Logo/icon URL (from tvg-logo attribute)
    public let logo: URL?

    /// Electronic Program Guide ID (from tvg-id attribute)
    public let epgID: String?

    /// Type of content (live, movie, or series)
    public let contentType: ContentType

    /// Duration in seconds (-1 for live streams)
    public let duration: Int?

    /// All parsed attributes from the EXTINF line
    public let attributes: [String: String]

    /// XUI panel ID (from xui-id attribute)
    public let xuiID: String?

    /// Timeshift duration in seconds (from timeshift attribute)
    public let timeshift: Int?

    /// Catchup mode (default, append, shift, flussonic, xc)
    public let catchup: String?

    /// URL template for catchup streams
    public let catchupSource: String?

    /// Number of days available for catchup
    public let catchupDays: Int?

    /// Time correction in seconds for catchup
    public let catchupCorrection: Int?

    /// Creates a new M3U item.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - name: Display name of the media
    ///   - url: Stream URL
    ///   - group: Optional group/category name
    ///   - logo: Optional logo URL
    ///   - epgID: Optional EPG identifier
    ///   - contentType: Type of content
    ///   - duration: Duration in seconds (-1 for live)
    ///   - attributes: Additional parsed attributes
    ///   - xuiID: Optional XUI panel ID
    ///   - timeshift: Optional timeshift duration in seconds
    ///   - catchup: Optional catchup mode (default, append, shift, flussonic, xc)
    ///   - catchupSource: Optional URL template for catchup streams
    ///   - catchupDays: Optional number of days available for catchup
    ///   - catchupCorrection: Optional time correction in seconds for catchup
    public init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        group: String? = nil,
        logo: URL? = nil,
        epgID: String? = nil,
        contentType: ContentType = .live,
        duration: Int? = nil,
        attributes: [String: String] = [:],
        xuiID: String? = nil,
        timeshift: Int? = nil,
        catchup: String? = nil,
        catchupSource: String? = nil,
        catchupDays: Int? = nil,
        catchupCorrection: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.group = group
        self.logo = logo
        self.epgID = epgID
        self.contentType = contentType
        self.duration = duration
        self.attributes = attributes
        self.xuiID = xuiID
        self.timeshift = timeshift
        self.catchup = catchup
        self.catchupSource = catchupSource
        self.catchupDays = catchupDays
        self.catchupCorrection = catchupCorrection
    }
}
