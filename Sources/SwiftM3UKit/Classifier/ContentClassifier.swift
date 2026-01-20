import Foundation

/// Default content classifier using heuristic rules for IPTV content.
///
/// The classifier analyzes the content name, group, and attributes to determine
/// whether an item is live TV, a movie, or a TV series.
///
/// ## Classification Rules
///
/// ### Live TV Detection
/// - Resolution indicators: "HD", "FHD", "4K", "UHD", "SD"
/// - Channel numbers at the start
/// - Groups containing: "news", "sports", "music", "kids", "documentary"
/// - Quality tags: "HEVC", "H265", "H264"
///
/// ### Movie Detection
/// - Year patterns: "(2020)", "[2021]", "2022"
/// - Language/country tags: "(TR)", "(EN)", "(DE)"
/// - Specific group names containing "movie", "film", "vod"
///
/// ### Series Detection
/// - Episode patterns: "S01E01", "S1E1", "Season 1", "Episode 1"
/// - Turkish patterns: "Sezon", "Bölüm"
/// - Other patterns: "Ep.", "Ep "
public struct ContentClassifier: ContentClassifying, Sendable {

    public init() {}

    /// Classifies content based on heuristic rules.
    public func classify(name: String, group: String?, attributes: [String: String]) -> ContentType {
        let nameLower = name.lowercased()
        let groupLower = group?.lowercased() ?? ""
        let originalGroup = group ?? ""

        // Check for live TV first (▱ prefix indicates live channels)
        if hasLiveGroupPrefix(in: originalGroup) {
            return .live
        }

        // Check for series (most specific patterns)
        if let seriesInfo = detectSeries(name: nameLower, group: groupLower) {
            return .series(season: seriesInfo.season, episode: seriesInfo.episode)
        }

        // Check for movie
        if isMovie(name: nameLower, group: groupLower, originalName: name) {
            return .movie
        }

        // Default to live
        return .live
    }

    // MARK: - Multi-Language Keywords

    /// Series group keywords in multiple languages
    /// 🇬🇧 English, 🇹🇷 Turkish, 🇸🇦 Arabic, 🇫🇷 French, 🇩🇪 German,
    /// 🇮🇳 Hindi, 🇯🇵 Japanese, 🇧🇷 Portuguese, 🇷🇺 Russian, 🇨🇳 Chinese, 🇪🇸 Spanish
    private let seriesGroupKeywords = [
        // English
        "series", "tv show", "tv series",
        // Turkish
        "dizi", "diziler",
        // Arabic
        "مسلسل", "مسلسلات",
        // French
        "série", "séries",
        // German
        "serie", "serien", "fernsehserie",
        // Hindi
        "सीरीज़", "धारावाहिक",
        // Japanese
        "ドラマ", "シリーズ", "連続ドラマ",
        // Portuguese
        "série", "séries", "novela",
        // Russian
        "сериал", "сериалы",
        // Chinese
        "剧集", "电视剧", "连续剧",
        // Spanish
        "serie", "series", "telenovela"
    ]

    /// Movie/Film group keywords in multiple languages
    private let movieGroupKeywords = [
        // English
        "movie", "movies", "film", "films", "vod", "cinema",
        // Turkish
        "sinema", "vizyon", "bluray", "altyazili", "dublaj", "imdb",
        // Arabic
        "فيلم", "أفلام", "سينما",
        // French
        "cinéma", "films",
        // German
        "kino", "filme",
        // Hindi
        "फ़िल्म", "फिल्में", "सिनेमा",
        // Japanese
        "映画", "ムービー",
        // Portuguese
        "filme", "filmes", "cinema",
        // Russian
        "фильм", "фильмы", "кино",
        // Chinese
        "电影", "影片",
        // Spanish
        "película", "películas", "cine",
        // Quality/Collection indicators
        "4k", "fhd", "uhd", "2160p", "1080p",
        "top", "best", "world", "classics", "collection",
        "bollywood", "marvel", "dc", "disney", "pixar"
    ]

    /// Groups that should NOT be classified as series
    private let nonSeriesGroupKeywords = [
        // English
        "movie", "film", "cinema", "concert", "documentary",
        // Turkish
        "sinema", "vizyon", "tiyatro", "stand-up", "kabare", "belgesel", "konser", "müzik", "cocuk",
        // Arabic
        "فيلم", "سينما", "وثائقي",
        // French
        "cinéma", "documentaire", "concert",
        // German
        "kino", "dokumentation", "konzert",
        // Japanese
        "映画", "ドキュメンタリー",
        // Portuguese
        "cinema", "documentário", "concerto",
        // Russian
        "фильм", "кино", "документальный",
        // Chinese
        "电影", "纪录片",
        // Spanish
        "película", "cine", "documental",
        // Quality indicators
        "4k", "fhd", "uhd", "hd", "2160p", "1080p", "720p",
        "bluray", "blu-ray", "blu ray",
        // Collection/catalog indicators
        "world", "top", "imdb", "best", "classics", "classic",
        "collection", "koleksiyon", "top 250",
        // Regional/format indicators
        "altyazili", "altyazılı", "dublaj", "yabanci", "yabancı",
        "yerli", "türk", "turkish", "diamant",
        // Genre indicators (movie-specific)
        "bollywood", "marvel", "dc", "disney", "pixar",
        "klasik", "nostalji", "yeşilçam", "yesilcam"
    ]

    // MARK: - Multi-Language Season/Episode Keywords

    /// Season keywords in multiple languages
    private let seasonKeywords = [
        // English
        "season",
        // Turkish
        "sezon",
        // Arabic
        "موسم",
        // French
        "saison",
        // German
        "staffel",
        // Hindi
        "सीज़न",
        // Japanese
        "シーズン",
        // Portuguese
        "temporada",
        // Russian
        "сезон",
        // Spanish
        "temporada"
    ]

    /// Episode keywords in multiple languages
    private let episodeKeywords = [
        // English
        "episode",
        // Turkish
        "bölüm", "bolum",
        // Arabic
        "حلقة",
        // French
        "épisode", "episode",
        // German
        "folge", "episode",
        // Hindi
        "एपिसोड",
        // Japanese
        "エピソード",
        // Portuguese
        "episódio", "episodio",
        // Russian
        "серия", "эпизод",
        // Spanish
        "episodio", "capítulo", "capitulo"
    ]

    // MARK: - Series Detection

    private func detectSeries(name: String, group: String) -> (season: Int?, episode: Int?)? {
        // Check for explicit series group keywords first
        let hasExplicitSeriesKeyword = seriesGroupKeywords.contains { group.contains($0) }

        // Check if group explicitly excludes series classification
        // But skip this check if we have an explicit series keyword
        if !hasExplicitSeriesKeyword {
            for keyword in nonSeriesGroupKeywords {
                if group.contains(keyword) {
                    // Only S01E01 pattern can override this (very specific)
                    if let match = findSeasonEpisodePattern(in: name) {
                        return match
                    }
                    return nil
                }
            }
        }

        // S01E01 pattern (most common and most reliable) - Universal
        if let match = findSeasonEpisodePattern(in: name) {
            return match
        }

        // Multi-language "Season X Episode Y" pattern
        // Handles: English, Turkish, Arabic, French, German, Hindi, Japanese, Portuguese, Russian, Spanish
        if let match = findSeasonEpisodeWordPattern(in: name) {
            return match
        }

        // Asian patterns: 第1季第5集 (Chinese), 第1期第5話 (Japanese)
        if let match = findAsianSeasonEpisodePattern(in: name) {
            return match
        }

        // Check if in series group (multi-language)
        let isInSeriesGroup = seriesGroupKeywords.contains { group.contains($0) }

        // Simple episode pattern "Ep. X" or "Ep X"
        if let episode = findEpisodeOnlyPattern(in: name) {
            return (season: nil, episode: episode)
        }

        // Check for series group keywords
        if isInSeriesGroup {
            // Found in a series group but no episode pattern - return with nil season/episode
            return (season: nil, episode: nil)
        }

        return nil
    }

    private func findSeasonEpisodePattern(in name: String) -> (season: Int?, episode: Int?)? {
        // Match S01E01, S1E1, s01e01, etc.
        var index = name.startIndex

        while index < name.endIndex {
            if name[index] == "s" {
                let seasonStart = name.index(after: index)
                var seasonEnd = seasonStart

                // Find season number
                while seasonEnd < name.endIndex && name[seasonEnd].isNumber {
                    seasonEnd = name.index(after: seasonEnd)
                }

                guard seasonEnd > seasonStart, seasonEnd < name.endIndex else {
                    index = name.index(after: index)
                    continue
                }

                let seasonStr = String(name[seasonStart..<seasonEnd])
                guard let season = Int(seasonStr) else {
                    index = name.index(after: index)
                    continue
                }

                // Check for 'e' after season
                if name[seasonEnd] == "e" {
                    let episodeStart = name.index(after: seasonEnd)
                    var episodeEnd = episodeStart

                    while episodeEnd < name.endIndex && name[episodeEnd].isNumber {
                        episodeEnd = name.index(after: episodeEnd)
                    }

                    if episodeEnd > episodeStart {
                        let episodeStr = String(name[episodeStart..<episodeEnd])
                        if let episode = Int(episodeStr) {
                            return (season: season, episode: episode)
                        }
                    }

                    return (season: season, episode: nil)
                }
            }
            index = name.index(after: index)
        }

        return nil
    }

    private func findSeasonEpisodeWordPattern(in name: String) -> (season: Int?, episode: Int?)? {
        var season: Int?
        var episode: Int?

        // Look for season keywords in multiple languages
        for keyword in seasonKeywords {
            if let seasonRange = name.range(of: keyword, options: .caseInsensitive) {
                let afterSeason = name[seasonRange.upperBound...]
                let num = extractFirstNumber(from: String(afterSeason))
                // Don't accept years as season numbers
                if let n = num, !isLikelyYear(n) {
                    season = n
                    break
                }
                // Also check before the keyword (e.g., "1 Sezon")
                if season == nil {
                    let beforeSeason = String(name[..<seasonRange.lowerBound])
                    if let n = extractLastNumber(from: beforeSeason), !isLikelyYear(n) {
                        season = n
                        break
                    }
                }
            }
        }

        // Look for episode keywords in multiple languages
        for keyword in episodeKeywords {
            if let episodeRange = name.range(of: keyword, options: .caseInsensitive) {
                let afterEpisode = name[episodeRange.upperBound...]
                let num = extractFirstNumber(from: String(afterEpisode))

                // Skip "Episode I", "Episode IV" etc. (Star Wars style)
                let afterStr = String(afterEpisode).trimmingCharacters(in: .whitespaces).lowercased()
                let startsWithRoman = afterStr.hasPrefix("i") || afterStr.hasPrefix("v") ||
                                      afterStr.hasPrefix("x") || afterStr.hasPrefix("l")
                if startsWithRoman && keyword == "episode" {
                    continue
                }

                if let n = num, !isLikelyYear(n) {
                    episode = n
                    break
                }

                // Also check before the keyword (e.g., "5 Bölüm")
                if episode == nil {
                    let beforeEpisode = String(name[..<episodeRange.lowerBound])
                    if let n = extractLastNumber(from: beforeEpisode), !isLikelyYear(n) {
                        episode = n
                        break
                    }
                }
            }
        }

        if season != nil || episode != nil {
            // Context-aware check for Turkish "Bölüm":
            // If we found episode number but NO season, and there's a year pattern,
            // it's likely a movie part (e.g., "John Wick: Bölüm 4 (2023)"),
            // not a series episode.
            if season == nil && episode != nil && hasYearPattern(in: name) {
                return nil
            }

            return (season: season, episode: episode)
        }

        return nil
    }

    /// Detects Chinese/Japanese numbered patterns like 第1季第5集
    private func findAsianSeasonEpisodePattern(in name: String) -> (season: Int?, episode: Int?)? {
        var season: Int?
        var episode: Int?

        // Chinese: 第X季 (Season), 第X集 (Episode)
        // Japanese: 第X期 (Season), 第X話 (Episode)

        // Season patterns
        let seasonPatterns = ["第(\\d+)季", "第(\\d+)期"]
        for pattern in seasonPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)),
               let range = Range(match.range(at: 1), in: name) {
                season = Int(name[range])
                break
            }
        }

        // Episode patterns
        let episodePatterns = ["第(\\d+)集", "第(\\d+)話", "第(\\d+)话"]
        for pattern in episodePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)),
               let range = Range(match.range(at: 1), in: name) {
                episode = Int(name[range])
                break
            }
        }

        if season != nil || episode != nil {
            return (season: season, episode: episode)
        }

        return nil
    }

    /// Checks if a number looks like a year (1950-2030)
    private func isLikelyYear(_ number: Int) -> Bool {
        return number >= 1950 && number <= 2030
    }

    private func findEpisodeOnlyPattern(in name: String) -> Int? {
        // Look for standalone "ep." or "ep " pattern (not part of another word)
        // Must be at start or preceded by space/punctuation
        let patterns = [" ep.", " ep ", "-ep.", "-ep "]

        for pattern in patterns {
            if let range = name.range(of: pattern) {
                let afterPattern = name[range.upperBound...]
                if let episode = extractFirstNumber(from: String(afterPattern)) {
                    // Don't accept years as episode numbers
                    if !isLikelyYear(episode) {
                        return episode
                    }
                }
            }
        }

        // Also check if name starts with "ep." or "ep "
        if name.hasPrefix("ep.") || name.hasPrefix("ep ") {
            let afterPrefix = String(name.dropFirst(3))
            if let episode = extractFirstNumber(from: afterPrefix) {
                if !isLikelyYear(episode) {
                    return episode
                }
            }
        }

        return nil
    }

    /// Detects movie sequel patterns like "Title 2", "Title 3", "Title: Part 2"
    /// Returns true if the title appears to be a movie sequel/part
    private func isMovieSequel(_ title: String) -> Bool {
        // Pattern 1: Title + single digit (2-9) + optional year or end
        // Matches: "Shrek 3", "Iron Man 3 (2013)", "Avatar 2", "Fast & Furious 7"
        let singleDigitPattern = #"(?:^|\s)([2-9])(?:\s|$|\()"#

        // Pattern 2: Explicit "Part" indicators (case-insensitive)
        // Matches: "Part 2", "Part II", "Pt. 2", "Chapter 3", "Bölüm 3" (when used as Part)
        let partPattern = #"(?i)(?:part|pt\.?|chapter)[\s:]+(?:[IVX]+|\d+)"#

        // Pattern 3: Roman numerals (II-X) as sequels
        // Matches: "Rocky II", "Rocky III", "Episode IV"
        let romanPattern = #"(?:^|\s)(II|III|IV|V|VI|VII|VIII|IX|X)(?:\s|$|\(|:)"#

        // Pattern 4: Subtitle with sequel indicator
        // Matches: "Title 2: The Sequel", "Title 3: Revenge"
        let subtitlePattern = #"(?:[2-9]|II|III|IV|V|VI|VII|VIII|IX|X):\s*(?:The|El|Le|Der|Das)"#

        let patterns = [singleDigitPattern, partPattern, romanPattern, subtitlePattern]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) != nil {
                return true
            }
        }

        return false
    }

    // MARK: - Movie Detection

    private func isMovie(name: String, group: String, originalName: String) -> Bool {
        // Check group name for movie indicators
        for keyword in movieGroupKeywords {
            if group.contains(keyword) {
                return true
            }
        }

        // Check for movie sequel patterns (e.g., "Iron Man 3", "Shrek 2")
        if isMovieSequel(originalName) {
            // Sequel detected, check if live indicators contradict
            if hasLiveIndicators(in: name, originalName: originalName) {
                return false
            }

            // Check if group contradicts
            // If group explicitly contains "series", "dizi", etc., don't override
            let seriesIndicators = ["series", "dizi", "tv show", "episode", "مسلسل", "série", "serie",
                                   "सीरीज़", "ドラマ", "сериал", "剧集", "telenovela"]
            if seriesIndicators.contains(where: { group.contains($0) }) {
                return false
            }
            return true
        }

        // Check for [4K] tag (strong movie indicator)
        if originalName.contains("[4K]") || originalName.contains("[4k]") {
            return true
        }

        // Check for year pattern (strong movie indicator)
        if hasYearPattern(in: name) && !hasLiveIndicators(in: name, originalName: originalName) {
            return true
        }

        // Check for language/country tags
        let languageTags = ["(tr)", "(en)", "(de)", "(fr)", "(es)", "(it)", "(ru)", "[tr]", "[en]"]
        for tag in languageTags {
            if name.contains(tag) && hasYearPattern(in: name) {
                return true
            }
        }

        return false
    }

    private func hasYearPattern(in name: String) -> Bool {
        // Look for 4-digit year between 1950 and 2030
        var index = name.startIndex

        while index < name.endIndex {
            let numStart = index
            var numEnd = index

            // Find start of number
            while numEnd < name.endIndex && name[numEnd].isNumber {
                numEnd = name.index(after: numEnd)
            }

            if name.distance(from: numStart, to: numEnd) == 4 {
                let numStr = String(name[numStart..<numEnd])
                if let year = Int(numStr), year >= 1950 && year <= 2030 {
                    return true
                }
            }

            if numEnd > index {
                index = numEnd
            } else {
                index = name.index(after: index)
            }
        }

        return false
    }

    private func hasLiveIndicators(in name: String, originalName: String) -> Bool {
        let liveIndicators = [
            " hd", " fhd", " uhd", " 4k", " sd",
            "|hd", "|fhd", "|uhd", "|4k", "|sd",
            "[hd]", "[fhd]", "[uhd]", "[4k]", "[sd]",
            "hevc", "h265", "h264"
        ]

        for indicator in liveIndicators {
            if name.contains(indicator) {
                return true
            }
        }

        // Check for Unicode live indicators in original name (case-sensitive)
        let unicodeLiveIndicators = [
            "°",       // Alt kaynak indicator
            "ᴬⱽᴿᵁᴾᴬ", // AVRUPA (Europe)
            "ᴿᴬᵂ",    // RAW
            "ᵁᴴᴰ",    // UHD
            "ᴴᴰ"      // HD (superscript)
        ]

        for indicator in unicodeLiveIndicators {
            if originalName.contains(indicator) {
                return true
            }
        }

        return false
    }

    /// Checks if a group name has live TV prefix indicator
    func hasLiveGroupPrefix(in group: String) -> Bool {
        // Check for ▱ prefix (common in Turkish IPTV for live categories)
        return group.hasPrefix("▱")
    }

    // MARK: - Helper Methods

    private func extractFirstNumber(from string: String) -> Int? {
        var numStr = ""
        var foundDigit = false

        for char in string {
            if char.isNumber {
                numStr.append(char)
                foundDigit = true
            } else if foundDigit {
                break
            }
        }

        return Int(numStr)
    }

    private func extractLastNumber(from string: String) -> Int? {
        var numStr = ""

        for char in string.reversed() {
            if char.isNumber {
                numStr = String(char) + numStr
            } else if !numStr.isEmpty {
                break
            }
        }

        return Int(numStr)
    }
}
