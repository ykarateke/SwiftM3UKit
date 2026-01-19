import Foundation

/// A default implementation of title normalization and sanitization.
///
/// TitleNormalizer provides comprehensive text processing including:
/// - Turkish character normalization (ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u)
/// - Case normalization
/// - Whitespace normalization
/// - Prefix/suffix removal
/// - Quality tag removal
/// - Bracket content removal
///
/// ## Example
/// ```swift
/// let normalizer = TitleNormalizer()
///
/// // Turkish normalization
/// normalizer.normalizeTurkish("Türkçe") // "Turkce"
///
/// // Full normalization
/// normalizer.normalize("BBC One HD") // "bbc one hd"
///
/// // Sanitization
/// normalizer.sanitize("TR: BBC One [HD]") // "BBC One"
/// ```
public struct TitleNormalizer: TitleNormalizing, Sendable {
    // MARK: - Pre-compiled Regex (Performance Optimization)

    /// Pre-compiled regex for square bracket removal.
    private static let bracketRegex = try! NSRegularExpression(pattern: "\\[.*?\\]")

    /// Pre-compiled regex for parentheses removal.
    private static let parenRegex = try! NSRegularExpression(pattern: "\\(.*?\\)")

    /// Pre-compiled regex for whitespace collapsing.
    private static let whitespaceRegex = try! NSRegularExpression(pattern: "\\s+")

    /// Turkish characters set for quick presence check.
    private static let turkishChars: Set<Character> = Set("çÇğĞıİöÖşŞüÜ")

    /// Common prefixes to remove during sanitization.
    private static let commonPrefixes: [String] = [
        "TR:", "TR :", "TR|", "TR |",
        "UK:", "UK :", "UK|", "UK |",
        "US:", "US :", "US|", "US |",
        "DE:", "DE :", "DE|", "DE |",
        "FR:", "FR :", "FR|", "FR |",
        "ES:", "ES :", "ES|", "ES |",
        "IT:", "IT :", "IT|", "IT |",
        "NL:", "NL :", "NL|", "NL |",
        "VIP:", "VIP :", "VIP|", "VIP |",
        "HEVC:", "HEVC :", "HEVC|", "HEVC |",
        "FHD:", "FHD :", "FHD|", "FHD |",
        "HD:", "HD :", "HD|", "HD |",
        "SD:", "SD :", "SD|", "SD |",
        "4K:", "4K :", "4K|", "4K |",
        "UHD:", "UHD :", "UHD|", "UHD |"
    ]

    /// Pre-compiled uppercased prefixes for O(1) comparison.
    private static let commonPrefixesUppercased: [String] = commonPrefixes.map { $0.uppercased() }

    /// Quality-related suffixes and tags to remove.
    private static let qualityTags: [String] = [
        "HD", "FHD", "UHD", "4K", "8K",
        "SD", "LQ", "HQ",
        "HEVC", "H264", "H.264", "H265", "H.265",
        "1080p", "1080i", "720p", "720i", "480p", "480i",
        "2160p", "4320p",
        "HDR", "HDR10", "HDR10+", "Dolby Vision",
        "Atmos", "DTS", "AAC", "AC3",
        "+", "PLUS"
    ]

    /// Pre-compiled uppercased quality tags Set for O(1) lookup.
    private static let qualityTagsUppercased: Set<String> = Set(qualityTags.map { $0.uppercased() })

    /// Creates a new title normalizer.
    public init() {}

    /// Normalizes Turkish characters to their ASCII equivalents.
    ///
    /// - Parameter text: Text containing Turkish characters
    /// - Returns: Text with Turkish characters replaced by ASCII equivalents
    ///
    /// ## Example
    /// ```swift
    /// normalizer.normalizeTurkish("Türkçe Şarkılar") // "Turkce Sarkilar"
    /// ```
    public func normalizeTurkish(_ text: String) -> String {
        // Quick check: skip processing if no Turkish characters present
        guard text.contains(where: { Self.turkishChars.contains($0) }) else {
            return text
        }

        return String(text.map { char in
            switch char {
            case "ç": return Character("c")
            case "Ç": return Character("C")
            case "ğ": return Character("g")
            case "Ğ": return Character("G")
            case "ı": return Character("i")
            case "İ": return Character("I")
            case "ö": return Character("o")
            case "Ö": return Character("O")
            case "ş": return Character("s")
            case "Ş": return Character("S")
            case "ü": return Character("u")
            case "Ü": return Character("U")
            default: return char
            }
        })
    }

    /// Normalizes a title for comparison purposes.
    ///
    /// Applies the following transformations:
    /// 1. Turkish character normalization
    /// 2. Lowercase conversion
    /// 3. Whitespace trimming and collapsing
    ///
    /// - Parameter title: The original title
    /// - Returns: A normalized version suitable for comparison
    public func normalize(_ title: String) -> String {
        var result = normalizeTurkish(title)
        result = result.lowercased()
        result = collapseWhitespace(result)
        result = result.trimmingCharacters(in: .whitespaces)
        return result
    }

    /// Sanitizes a title for display purposes.
    ///
    /// Removes:
    /// - Common country/quality prefixes (TR:, UK:, HD:, etc.)
    /// - Bracketed content ([HD], (TR), etc.)
    /// - Quality tags at the end of the title
    ///
    /// - Parameter title: The original title
    /// - Returns: A cleaned version suitable for display
    public func sanitize(_ title: String) -> String {
        var result = title

        // Remove common prefixes
        result = removeCommonPrefixes(result)

        // Remove bracketed content
        result = removeBracketedContent(result)

        // Remove quality tags from the end
        result = removeTrailingQualityTags(result)

        // Final cleanup
        result = collapseWhitespace(result)
        result = result.trimmingCharacters(in: .whitespaces)

        return result
    }

    // MARK: - Private Helpers

    private func removeCommonPrefixes(_ text: String) -> String {
        let uppercased = text.uppercased()  // Single uppercase call

        for (index, prefixUpper) in Self.commonPrefixesUppercased.enumerated() {
            if uppercased.hasPrefix(prefixUpper) {
                let result = String(text.dropFirst(Self.commonPrefixes[index].count))
                return result.trimmingCharacters(in: .whitespaces)
            }
        }
        return text
    }

    private func removeBracketedContent(_ text: String) -> String {
        var result = text
        let fullRange = NSRange(result.startIndex..., in: result)

        // Remove square brackets [...] using pre-compiled regex
        result = Self.bracketRegex.stringByReplacingMatches(
            in: result,
            range: fullRange,
            withTemplate: ""
        )

        // Remove parentheses (...) using pre-compiled regex
        let newRange = NSRange(result.startIndex..., in: result)
        result = Self.parenRegex.stringByReplacingMatches(
            in: result,
            range: newRange,
            withTemplate: ""
        )

        // Remove pipe-separated suffixes
        if let pipeIndex = result.firstIndex(of: "|") {
            result = String(result[..<pipeIndex])
        }

        return result
    }

    private func removeTrailingQualityTags(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespaces)

        // Keep removing quality tags from the end using Set-based lookup
        var changed = true
        while changed {
            changed = false
            let uppercased = result.uppercased()  // Single uppercase per iteration

            // Find the last word and check if it's a quality tag
            if let lastSpaceIndex = uppercased.lastIndex(of: " ") {
                let lastWord = String(uppercased[uppercased.index(after: lastSpaceIndex)...])
                if Self.qualityTagsUppercased.contains(lastWord) {
                    result = String(result[..<result.index(result.endIndex, offsetBy: -(lastWord.count + 1))])
                    result = result.trimmingCharacters(in: .whitespaces)
                    changed = true
                }
            }
        }

        return result
    }

    private func collapseWhitespace(_ text: String) -> String {
        let range = NSRange(text.startIndex..., in: text)
        return Self.whitespaceRegex.stringByReplacingMatches(
            in: text,
            range: range,
            withTemplate: " "
        )
    }
}
