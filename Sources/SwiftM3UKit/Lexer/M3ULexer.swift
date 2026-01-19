import Foundation

/// A character-based lexer for M3U files.
///
/// This lexer tokenizes M3U content without using regular expressions,
/// providing better performance and more control over error handling.
///
/// ## Supported Directives
/// - `#EXTM3U` - File header
/// - `#EXTINF` - Track information with duration and attributes
/// - `#EXTGRP` - Group/category name
///
/// ## Supported Attributes
/// - `tvg-id` - EPG identifier
/// - `tvg-name` - Display name
/// - `tvg-logo` - Logo URL
/// - `group-title` - Category/group name
struct M3ULexer: Sendable {
    /// Tokenizes a single line from an M3U file.
    ///
    /// - Parameter line: A single line from the M3U file
    /// - Returns: The corresponding token for the line
    func tokenize(line: String) -> M3UToken {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            return .unknown("")
        }

        if trimmed.uppercased() == "#EXTM3U" {
            return .extm3u
        }

        if trimmed.uppercased().hasPrefix("#EXTINF:") {
            return parseExtinf(trimmed)
        }

        if trimmed.uppercased().hasPrefix("#EXTGRP:") {
            let name = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
            return .extgrp(name: name)
        }

        if trimmed.uppercased().hasPrefix("#EXT-X-SESSION-DATA:") {
            return parseExtSessionData(trimmed)
        }

        if trimmed.hasPrefix("#") {
            return .comment(trimmed)
        }

        if let url = URL(string: trimmed), url.scheme != nil {
            return .url(url)
        }

        return .unknown(trimmed)
    }

    /// Tokenizes multiple lines from an M3U file.
    ///
    /// - Parameter content: The full M3U file content
    /// - Returns: An array of tokens
    func tokenize(content: String) -> [M3UToken] {
        content.components(separatedBy: .newlines).map { tokenize(line: $0) }
    }

    // MARK: - Private Methods

    private func parseExtinf(_ line: String) -> M3UToken {
        // Remove #EXTINF: prefix (case-insensitive)
        let content = String(line.dropFirst(8))

        // Find the last comma which separates attributes from title
        var duration: Int = -1
        var attributes: [String: String] = [:]
        var title = ""

        // Parse duration and attributes section
        if let commaIndex = findLastUnquotedComma(in: content) {
            let metadataSection = String(content[..<commaIndex])
            title = String(content[content.index(after: commaIndex)...]).trimmingCharacters(in: .whitespaces)

            // Parse duration (first number before space or first attribute)
            let (parsedDuration, attributeStart) = parseDuration(from: metadataSection)
            duration = parsedDuration

            // Parse attributes
            if attributeStart < metadataSection.endIndex {
                let attributeSection = String(metadataSection[attributeStart...])
                attributes = parseAttributes(from: attributeSection)
            }
        } else {
            // No comma found, try to parse as duration only
            if let dur = Int(content.trimmingCharacters(in: .whitespaces)) {
                duration = dur
            }
        }

        return .extinf(duration: duration, attributes: attributes, title: title)
    }

    private func parseExtSessionData(_ line: String) -> M3UToken {
        // Remove #EXT-X-SESSION-DATA: prefix (20 characters)
        let content = String(line.dropFirst(20))
        // EXT-X-SESSION-DATA uses comma-separated attributes
        let attributes = parseCommaSeparatedAttributes(from: content)

        let dataID = attributes["data-id"] ?? ""
        let value = attributes["value"]

        return .extSessionData(dataID: dataID, value: value)
    }

    private func parseCommaSeparatedAttributes(from string: String) -> [String: String] {
        var attributes: [String: String] = [:]
        var index = string.startIndex

        while index < string.endIndex {
            // Skip whitespace and commas
            while index < string.endIndex && (string[index].isWhitespace || string[index] == ",") {
                index = string.index(after: index)
            }

            guard index < string.endIndex else { break }

            // Find attribute name (until '=')
            let keyStart = index
            while index < string.endIndex && string[index] != "=" && string[index] != "," && !string[index].isWhitespace {
                index = string.index(after: index)
            }

            guard index < string.endIndex && string[index] == "=" else {
                // Skip to next comma if no '=' found
                while index < string.endIndex && string[index] != "," {
                    index = string.index(after: index)
                }
                continue
            }

            let key = String(string[keyStart..<index]).lowercased()
            index = string.index(after: index) // Skip '='

            guard index < string.endIndex else { break }

            // Parse value (quoted or unquoted)
            var value = ""
            if string[index] == "\"" {
                index = string.index(after: index) // Skip opening quote
                while index < string.endIndex && string[index] != "\"" {
                    value.append(string[index])
                    index = string.index(after: index)
                }
                if index < string.endIndex {
                    index = string.index(after: index) // Skip closing quote
                }
            } else {
                // Unquoted value - read until comma or end
                while index < string.endIndex && string[index] != "," && !string[index].isWhitespace {
                    value.append(string[index])
                    index = string.index(after: index)
                }
            }

            if !key.isEmpty && !value.isEmpty {
                attributes[key] = value
            }
        }

        return attributes
    }

    private func findLastUnquotedComma(in string: String) -> String.Index? {
        var inQuotes = false
        var lastCommaIndex: String.Index?

        for index in string.indices {
            let char = string[index]

            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                lastCommaIndex = index
            }
        }

        return lastCommaIndex
    }

    private func parseDuration(from metadata: String) -> (Int, String.Index) {
        var duration = -1
        var index = metadata.startIndex

        // Skip leading whitespace
        while index < metadata.endIndex && metadata[index].isWhitespace {
            index = metadata.index(after: index)
        }

        // Collect digits and optional negative sign
        var durationString = ""
        if index < metadata.endIndex && metadata[index] == "-" {
            durationString.append("-")
            index = metadata.index(after: index)
        }

        while index < metadata.endIndex && metadata[index].isNumber {
            durationString.append(metadata[index])
            index = metadata.index(after: index)
        }

        if let parsedDuration = Int(durationString) {
            duration = parsedDuration
        }

        // Skip whitespace after duration
        while index < metadata.endIndex && metadata[index].isWhitespace {
            index = metadata.index(after: index)
        }

        return (duration, index)
    }

    private func parseAttributes(from string: String) -> [String: String] {
        var attributes: [String: String] = [:]
        var index = string.startIndex

        while index < string.endIndex {
            // Skip whitespace
            while index < string.endIndex && string[index].isWhitespace {
                index = string.index(after: index)
            }

            guard index < string.endIndex else { break }

            // Find attribute name (until '=')
            let keyStart = index
            while index < string.endIndex && string[index] != "=" && !string[index].isWhitespace {
                index = string.index(after: index)
            }

            guard index < string.endIndex && string[index] == "=" else {
                // Skip to next word if no '=' found
                while index < string.endIndex && !string[index].isWhitespace {
                    index = string.index(after: index)
                }
                continue
            }

            let key = String(string[keyStart..<index]).lowercased()
            index = string.index(after: index) // Skip '='

            guard index < string.endIndex else { break }

            // Parse value (quoted or unquoted)
            var value = ""
            if string[index] == "\"" {
                index = string.index(after: index) // Skip opening quote
                while index < string.endIndex && string[index] != "\"" {
                    value.append(string[index])
                    index = string.index(after: index)
                }
                if index < string.endIndex {
                    index = string.index(after: index) // Skip closing quote
                }
            } else {
                // Unquoted value - read until whitespace
                while index < string.endIndex && !string[index].isWhitespace {
                    value.append(string[index])
                    index = string.index(after: index)
                }
            }

            if !key.isEmpty && !value.isEmpty {
                attributes[key] = value
            }
        }

        return attributes
    }
}
