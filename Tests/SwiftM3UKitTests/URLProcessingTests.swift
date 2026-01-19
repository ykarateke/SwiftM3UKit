import Testing
import Foundation
@testable import SwiftM3UKit

@Suite("URL Processing Tests")
struct URLProcessingTests {

    // MARK: - Auth Parameter Stripping

    @Test("Strip username parameter")
    func stripUsernameParameter() {
        let url = URL(string: "http://example.com/stream?username=user123")!
        let stripped = url.strippedURL

        #expect(stripped.absoluteString == "http://example.com/stream")
    }

    @Test("Strip password parameter")
    func stripPasswordParameter() {
        let url = URL(string: "http://example.com/stream?password=secret")!
        let stripped = url.strippedURL

        #expect(stripped.absoluteString == "http://example.com/stream")
    }

    @Test("Strip multiple auth parameters")
    func stripMultipleAuthParameters() {
        let url = URL(string: "http://example.com/stream?username=user&password=pass&token=abc123")!
        let stripped = url.strippedURL

        #expect(stripped.absoluteString == "http://example.com/stream")
    }

    @Test("Preserve non-auth parameters")
    func preserveNonAuthParameters() {
        let url = URL(string: "http://example.com/stream?quality=hd&format=ts")!
        let stripped = url.strippedURL

        #expect(stripped.absoluteString.contains("quality=hd"))
        #expect(stripped.absoluteString.contains("format=ts"))
    }

    @Test("Strip auth but preserve other parameters")
    func stripAuthPreserveOthers() {
        let url = URL(string: "http://example.com/stream?username=user&quality=hd&password=pass")!
        let stripped = url.strippedURL

        #expect(stripped.absoluteString.contains("quality=hd"))
        #expect(!stripped.absoluteString.contains("username"))
        #expect(!stripped.absoluteString.contains("password"))
    }

    @Test("Handle URL without query parameters")
    func handleURLWithoutQuery() {
        let url = URL(string: "http://example.com/stream")!
        let stripped = url.strippedURL

        #expect(stripped.absoluteString == "http://example.com/stream")
    }

    // MARK: - Deduplication Hash

    @Test("Generate deduplication hash")
    func generateDeduplicationHash() {
        let url = URL(string: "http://example.com/stream")!
        let hash = url.deduplicationHash

        #expect(hash.count == 16) // 8 bytes = 16 hex chars
    }

    @Test("Same URLs produce same hash")
    func sameURLsSameHash() {
        let url1 = URL(string: "http://example.com/stream")!
        let url2 = URL(string: "http://example.com/stream")!

        #expect(url1.deduplicationHash == url2.deduplicationHash)
    }

    @Test("Different URLs produce different hash")
    func differentURLsDifferentHash() {
        let url1 = URL(string: "http://example.com/stream1")!
        let url2 = URL(string: "http://example.com/stream2")!

        #expect(url1.deduplicationHash != url2.deduplicationHash)
    }

    @Test("URLs with different auth produce same hash")
    func differentAuthSameHash() {
        let url1 = URL(string: "http://example.com/stream?username=user1&password=pass1")!
        let url2 = URL(string: "http://example.com/stream?username=user2&password=pass2")!

        #expect(url1.deduplicationHash == url2.deduplicationHash)
    }

    // MARK: - URL Equivalence

    @Test("Same URLs are equivalent")
    func sameURLsEquivalent() {
        let url1 = URL(string: "http://example.com/stream")!
        let url2 = URL(string: "http://example.com/stream")!

        #expect(url1.isEquivalent(to: url2))
    }

    @Test("Different URLs not equivalent")
    func differentURLsNotEquivalent() {
        let url1 = URL(string: "http://example.com/stream1")!
        let url2 = URL(string: "http://example.com/stream2")!

        #expect(!url1.isEquivalent(to: url2))
    }

    @Test("URLs with different auth are equivalent")
    func differentAuthEquivalent() {
        let url1 = URL(string: "http://example.com/stream?username=user1")!
        let url2 = URL(string: "http://example.com/stream?username=user2")!

        #expect(url1.isEquivalent(to: url2))
    }

    @Test("URLs with different non-auth params not equivalent")
    func differentNonAuthNotEquivalent() {
        let url1 = URL(string: "http://example.com/stream?quality=hd")!
        let url2 = URL(string: "http://example.com/stream?quality=sd")!

        #expect(!url1.isEquivalent(to: url2))
    }

    // MARK: - Base Stream URL

    @Test("Get base stream URL")
    func getBaseStreamURL() {
        let url = URL(string: "http://example.com/stream?quality=hd&format=ts")!
        let base = url.baseStreamURL

        #expect(base.absoluteString == "http://example.com/stream")
    }

    @Test("Base URL without query unchanged")
    func baseURLNoQuery() {
        let url = URL(string: "http://example.com/stream")!
        let base = url.baseStreamURL

        #expect(base.absoluteString == "http://example.com/stream")
    }

    // MARK: - Edge Cases

    @Test("Handle complex IPTV URL")
    func handleComplexIPTVURL() {
        let url = URL(string: "http://server.com:8080/live/username/password/12345.ts")!
        let stripped = url.strippedURL

        // Path-based auth is not stripped (only query params)
        #expect(stripped.absoluteString == "http://server.com:8080/live/username/password/12345.ts")
    }

    @Test("Handle URL with port")
    func handleURLWithPort() {
        let url = URL(string: "http://example.com:8080/stream?username=user")!
        let stripped = url.strippedURL

        #expect(stripped.absoluteString == "http://example.com:8080/stream")
    }

    @Test("Handle HTTPS URL")
    func handleHTTPSURL() {
        let url = URL(string: "https://secure.example.com/stream?token=secret")!
        let stripped = url.strippedURL

        #expect(stripped.absoluteString == "https://secure.example.com/stream")
    }

    @Test("Handle case-insensitive auth params")
    func handleCaseInsensitiveAuth() {
        let url1 = URL(string: "http://example.com/stream?USERNAME=user")!
        let url2 = URL(string: "http://example.com/stream?Token=abc")!

        // Note: Current implementation converts to lowercase for comparison
        let stripped1 = url1.strippedURL
        let stripped2 = url2.strippedURL

        #expect(stripped1.absoluteString == "http://example.com/stream")
        #expect(stripped2.absoluteString == "http://example.com/stream")
    }
}
