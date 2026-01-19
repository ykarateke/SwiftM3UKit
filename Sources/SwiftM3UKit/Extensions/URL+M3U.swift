import Foundation
import CryptoKit

/// URL processing extension for M3U deduplication and comparison.
extension URL {
    /// Common authentication parameter names to strip for URL comparison.
    private static let authParameters: Set<String> = [
        "username", "password", "token", "auth", "key", "apikey",
        "api_key", "access_token", "user", "pass", "pwd"
    ]

    /// Returns a URL with authentication parameters removed.
    ///
    /// Removes common auth parameters like username, password, token, etc.
    /// Useful for comparing URLs that may have different auth credentials.
    ///
    /// ## Example
    /// ```swift
    /// let url = URL(string: "http://example.com/stream?username=user&password=pass")!
    /// print(url.strippedURL) // "http://example.com/stream"
    /// ```
    public var strippedURL: URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return self
        }

        // Filter out auth parameters
        if let queryItems = components.queryItems {
            let filteredItems = queryItems.filter { item in
                !Self.authParameters.contains(item.name.lowercased())
            }

            if filteredItems.isEmpty {
                components.queryItems = nil
            } else {
                components.queryItems = filteredItems
            }
        }

        return components.url ?? self
    }

    /// Returns a SHA256 hash of the URL suitable for deduplication.
    ///
    /// Uses the stripped URL (without auth parameters) to generate
    /// a 16-character hex string for efficient comparison.
    ///
    /// ## Example
    /// ```swift
    /// let url = URL(string: "http://example.com/stream")!
    /// print(url.deduplicationHash) // "a1b2c3d4e5f6a7b8"
    /// ```
    public var deduplicationHash: String {
        let strippedString = strippedURL.absoluteString
        let data = Data(strippedString.utf8)
        let hash = SHA256.hash(data: data)

        // Take first 8 bytes (16 hex characters) for efficiency
        return hash.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    /// Checks if this URL is equivalent to another URL.
    ///
    /// Compares URLs after stripping authentication parameters,
    /// allowing comparison of streams that differ only in credentials.
    ///
    /// - Parameter other: The URL to compare against
    /// - Returns: `true` if the URLs are equivalent
    ///
    /// ## Example
    /// ```swift
    /// let url1 = URL(string: "http://example.com/stream?username=user1")!
    /// let url2 = URL(string: "http://example.com/stream?username=user2")!
    /// print(url1.isEquivalent(to: url2)) // true
    /// ```
    public func isEquivalent(to other: URL) -> Bool {
        strippedURL.absoluteString == other.strippedURL.absoluteString
    }

    /// Returns the base URL without query parameters.
    ///
    /// Useful for grouping streams that have the same base path.
    ///
    /// ## Example
    /// ```swift
    /// let url = URL(string: "http://example.com/stream?quality=hd")!
    /// print(url.baseStreamURL) // "http://example.com/stream"
    /// ```
    public var baseStreamURL: URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return self
        }

        components.queryItems = nil
        return components.url ?? self
    }
}
