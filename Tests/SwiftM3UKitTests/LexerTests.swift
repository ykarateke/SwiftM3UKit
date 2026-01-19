import Testing
@testable import SwiftM3UKit

@Suite("M3ULexer Tests")
struct LexerTests {

    let lexer = M3ULexer()

    // MARK: - Header Tests

    @Test("Tokenize EXTM3U header")
    func tokenizeHeader() {
        let token = lexer.tokenize(line: "#EXTM3U")
        #expect(token == .extm3u)
    }

    @Test("Tokenize EXTM3U header case insensitive")
    func tokenizeHeaderCaseInsensitive() {
        let token = lexer.tokenize(line: "#extm3u")
        #expect(token == .extm3u)
    }

    // MARK: - EXTINF Tests

    @Test("Tokenize basic EXTINF")
    func tokenizeBasicExtinf() {
        let token = lexer.tokenize(line: "#EXTINF:-1,Channel Name")

        if case let .extinf(duration, _, title) = token {
            #expect(duration == -1)
            #expect(title == "Channel Name")
        } else {
            Issue.record("Expected extinf token")
        }
    }

    @Test("Tokenize EXTINF with attributes")
    func tokenizeExtinfWithAttributes() {
        let line = #"#EXTINF:-1 tvg-id="bbc1" tvg-logo="http://example.com/logo.png" group-title="UK",BBC One"#
        let token = lexer.tokenize(line: line)

        if case let .extinf(duration, attributes, title) = token {
            #expect(duration == -1)
            #expect(title == "BBC One")
            #expect(attributes["tvg-id"] == "bbc1")
            #expect(attributes["tvg-logo"] == "http://example.com/logo.png")
            #expect(attributes["group-title"] == "UK")
        } else {
            Issue.record("Expected extinf token")
        }
    }

    @Test("Tokenize EXTINF with positive duration")
    func tokenizeExtinfWithDuration() {
        let token = lexer.tokenize(line: "#EXTINF:3600,Movie Title")

        if case let .extinf(duration, _, title) = token {
            #expect(duration == 3600)
            #expect(title == "Movie Title")
        } else {
            Issue.record("Expected extinf token")
        }
    }

    @Test("Tokenize EXTINF with special characters in title")
    func tokenizeExtinfWithSpecialChars() {
        let token = lexer.tokenize(line: "#EXTINF:-1,Channel (HD) [EN] 4K")

        if case let .extinf(_, _, title) = token {
            #expect(title == "Channel (HD) [EN] 4K")
        } else {
            Issue.record("Expected extinf token")
        }
    }

    // MARK: - EXTGRP Tests

    @Test("Tokenize EXTGRP")
    func tokenizeExtgrp() {
        let token = lexer.tokenize(line: "#EXTGRP:Sports Channels")

        if case let .extgrp(name) = token {
            #expect(name == "Sports Channels")
        } else {
            Issue.record("Expected extgrp token")
        }
    }

    // MARK: - URL Tests

    @Test("Tokenize valid HTTP URL")
    func tokenizeHttpUrl() {
        let token = lexer.tokenize(line: "http://example.com/stream")

        if case let .url(url) = token {
            #expect(url.absoluteString == "http://example.com/stream")
        } else {
            Issue.record("Expected url token")
        }
    }

    @Test("Tokenize valid HTTPS URL")
    func tokenizeHttpsUrl() {
        let token = lexer.tokenize(line: "https://secure.example.com/stream")

        if case let .url(url) = token {
            #expect(url.absoluteString == "https://secure.example.com/stream")
        } else {
            Issue.record("Expected url token")
        }
    }

    @Test("Tokenize RTMP URL")
    func tokenizeRtmpUrl() {
        let token = lexer.tokenize(line: "rtmp://stream.example.com/live")

        if case let .url(url) = token {
            #expect(url.scheme == "rtmp")
        } else {
            Issue.record("Expected url token")
        }
    }

    // MARK: - Comment Tests

    @Test("Tokenize comment")
    func tokenizeComment() {
        let token = lexer.tokenize(line: "# This is a comment")

        if case let .comment(text) = token {
            #expect(text == "# This is a comment")
        } else {
            Issue.record("Expected comment token")
        }
    }

    // MARK: - Unknown Tests

    @Test("Tokenize empty line")
    func tokenizeEmptyLine() {
        let token = lexer.tokenize(line: "")
        #expect(token == .unknown(""))
    }

    @Test("Tokenize whitespace line")
    func tokenizeWhitespaceLine() {
        let token = lexer.tokenize(line: "   ")
        #expect(token == .unknown(""))
    }

    @Test("Tokenize invalid line")
    func tokenizeInvalidLine() {
        let token = lexer.tokenize(line: "random text without scheme")
        #expect(token == .unknown("random text without scheme"))
    }

    // MARK: - Batch Tokenization

    @Test("Tokenize multiple lines")
    func tokenizeMultipleLines() {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel 1
        http://example.com/ch1
        #EXTINF:-1,Channel 2
        http://example.com/ch2
        """

        let tokens = lexer.tokenize(content: content)

        #expect(tokens.count == 5)
        #expect(tokens[0] == .extm3u)

        if case .extinf = tokens[1] {
            // Pass
        } else {
            Issue.record("Expected extinf token at index 1")
        }

        if case .url = tokens[2] {
            // Pass
        } else {
            Issue.record("Expected url token at index 2")
        }
    }

    // MARK: - XUI Attribute Tests

    @Test("Tokenize EXTINF with xui-id attribute")
    func tokenizeExtinfWithXuiID() {
        let line = #"#EXTINF:-1 xui-id="3" tvg-id="ch1",Channel Name"#
        let token = lexer.tokenize(line: line)

        if case let .extinf(_, attributes, _) = token {
            #expect(attributes["xui-id"] == "3")
        } else {
            Issue.record("Expected extinf token")
        }
    }

    @Test("Tokenize EXTINF with timeshift attribute")
    func tokenizeExtinfWithTimeshift() {
        let line = #"#EXTINF:-1 timeshift="10" tvg-id="ch1",Channel Name"#
        let token = lexer.tokenize(line: line)

        if case let .extinf(_, attributes, _) = token {
            #expect(attributes["timeshift"] == "10")
        } else {
            Issue.record("Expected extinf token")
        }
    }

    @Test("Tokenize EXTINF with both xui-id and timeshift")
    func tokenizeExtinfWithXuiIDAndTimeshift() {
        let line = #"#EXTINF:-1 xui-id="5" timeshift="30" group-title="Sports",ESPN HD"#
        let token = lexer.tokenize(line: line)

        if case let .extinf(_, attributes, title) = token {
            #expect(attributes["xui-id"] == "5")
            #expect(attributes["timeshift"] == "30")
            #expect(attributes["group-title"] == "Sports")
            #expect(title == "ESPN HD")
        } else {
            Issue.record("Expected extinf token")
        }
    }

    // MARK: - EXT-X-SESSION-DATA Tests

    @Test("Tokenize EXT-X-SESSION-DATA directive")
    func tokenizeExtSessionData() {
        let line = #"#EXT-X-SESSION-DATA:DATA-ID="com.xui.1_5_13""#
        let token = lexer.tokenize(line: line)

        if case let .extSessionData(dataID, value) = token {
            #expect(dataID == "com.xui.1_5_13")
            #expect(value == nil)
        } else {
            Issue.record("Expected extSessionData token")
        }
    }

    @Test("Tokenize EXT-X-SESSION-DATA with value")
    func tokenizeExtSessionDataWithValue() {
        let line = #"#EXT-X-SESSION-DATA:DATA-ID="com.example",VALUE="test_value""#
        let token = lexer.tokenize(line: line)

        if case let .extSessionData(dataID, value) = token {
            #expect(dataID == "com.example")
            #expect(value == "test_value")
        } else {
            Issue.record("Expected extSessionData token")
        }
    }

    @Test("Tokenize EXT-X-SESSION-DATA case insensitive")
    func tokenizeExtSessionDataCaseInsensitive() {
        let line = #"#ext-x-session-data:DATA-ID="com.test""#
        let token = lexer.tokenize(line: line)

        if case let .extSessionData(dataID, _) = token {
            #expect(dataID == "com.test")
        } else {
            Issue.record("Expected extSessionData token")
        }
    }
}
