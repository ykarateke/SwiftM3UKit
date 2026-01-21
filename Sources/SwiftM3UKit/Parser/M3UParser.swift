import Foundation

/// A memory-efficient M3U/EXTM3U parser using async/await.
///
/// The parser supports both synchronous parsing from `Data` and streaming parsing
/// from URLs. For large files, use the streaming methods to maintain constant memory usage.
///
/// ## Basic Usage
/// ```swift
/// let parser = M3UParser()
///
/// // Parse from URL
/// let playlist = try await parser.parse(from: url)
///
/// // Parse from Data
/// let playlist = try await parser.parse(data: m3uData)
///
/// // Stream items one at a time (memory efficient for large files)
/// for try await item in parser.parseStream(from: url) {
///     print(item.name)
/// }
/// ```
///
/// ## Custom Classifier
/// ```swift
/// let parser = M3UParser()
/// await parser.setClassifier(MyCustomClassifier())
/// ```
public actor M3UParser {
    private let lexer: M3ULexer
    private var classifier: any ContentClassifying

    /// Creates a new M3U parser with the default content classifier.
    public init() {
        self.lexer = M3ULexer()
        self.classifier = ContentClassifier()
    }

    /// Sets a custom content classifier.
    ///
    /// - Parameter classifier: The classifier to use for determining content types
    public func setClassifier(_ classifier: some ContentClassifying) {
        self.classifier = classifier
    }

    // MARK: - Parsing Methods

    /// Parses an M3U playlist from a URL.
    ///
    /// This method loads the entire file into memory before parsing.
    /// For large files, consider using `parseStream(from:)` instead.
    ///
    /// - Parameter url: The URL to parse (file or HTTP/HTTPS)
    /// - Returns: A complete playlist with all items
    /// - Throws: `M3UParserError` if parsing fails
    public func parse(from url: URL) async throws -> M3UPlaylist {
        let data: Data

        if url.isFileURL {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw M3UParserError.fileNotFound
            }
            data = try Data(contentsOf: url)
        } else {
            do {
                let (downloadedData, _) = try await URLSession.shared.data(from: url)
                data = downloadedData
            } catch {
                throw M3UParserError.networkError(error)
            }
        }

        return try await parse(data: data)
    }

    /// Parses an M3U playlist from Data.
    ///
    /// - Parameter data: The raw M3U data
    /// - Returns: A complete playlist with all items
    /// - Throws: `M3UParserError` if parsing fails
    public func parse(data: Data) async throws -> M3UPlaylist {
        guard let content = decodeData(data) else {
            throw M3UParserError.encodingError
        }

        let tokens = lexer.tokenize(content: content)
        let items = processTokens(tokens)

        return M3UPlaylist(items: items)
    }

    /// Streams M3U items from a URL one at a time.
    ///
    /// This is the most memory-efficient way to parse large M3U files.
    /// Items are yielded as they are parsed, without loading the entire file.
    ///
    /// - Parameter url: The URL to parse
    /// - Returns: An async stream of M3U items
    ///
    /// ## Example
    /// ```swift
    /// for try await item in parser.parseStream(from: url) {
    ///     process(item)
    /// }
    /// ```
    public func parseStream(from url: URL) -> AsyncThrowingStream<M3UItem, Error> {
        let lexer = self.lexer
        let classifier = self.classifier

        return AsyncThrowingStream(bufferingPolicy: .bufferingNewest(100)) { continuation in
            Task {
                do {
                    var pendingExtinf: (duration: Int, attributes: [String: String], title: String)?
                    var pendingExtgrp: String?
                    var isValidM3U = false
                    var lineNumber = 0

                    func processLine(_ line: String) {
                        lineNumber += 1
                        let token = lexer.tokenize(line: line)

                        switch token {
                        case .extm3u:
                            isValidM3U = true

                        case let .extinf(duration, attributes, title):
                            pendingExtinf = (duration, attributes, title)

                        case let .extgrp(name):
                            pendingExtgrp = name

                        case let .url(streamURL):
                            if let extinf = pendingExtinf {
                                let group = pendingExtgrp ?? extinf.attributes["group-title"]
                                let item = Self.createItemStatic(
                                    extinf: extinf,
                                    url: streamURL,
                                    groupOverride: group,
                                    classifier: classifier
                                )
                                continuation.yield(item)
                            }
                            pendingExtinf = nil
                            pendingExtgrp = nil

                        case .extSessionData:
                            // Session data is metadata, not an item - ignore for now
                            break

                        case .comment, .unknown:
                            break
                        }
                    }

                    if url.isFileURL {
                        for try await line in AsyncLineReader(url: url) {
                            processLine(line)
                        }
                    } else {
                        for try await line in AsyncURLLineReader(url: url) {
                            processLine(line)
                        }
                    }

                    if !isValidM3U && lineNumber > 0 {
                        continuation.finish(throwing: M3UParserError.invalidFormat)
                    } else {
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: M3UParserError.streamInterrupted)
                }
            }
        }
    }

    // MARK: - Parse with Statistics

    /// Parses an M3U playlist from a URL with detailed statistics.
    ///
    /// Returns the playlist along with parse statistics and warnings.
    /// Use this when you need visibility into parse quality.
    ///
    /// - Parameter url: The URL to parse (file or HTTP/HTTPS)
    /// - Returns: A ParseResult containing playlist, statistics, and warnings
    /// - Throws: `M3UParserError` if parsing fails
    ///
    /// ## Example
    /// ```swift
    /// let result = try await parser.parseWithStatistics(from: url)
    /// print("Items: \(result.playlist.items.count)")
    /// print("Success rate: \(result.statistics.successRate * 100)%")
    /// ```
    public func parseWithStatistics(from url: URL) async throws -> ParseResult {
        let data: Data

        if url.isFileURL {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw M3UParserError.fileNotFound
            }
            data = try Data(contentsOf: url)
        } else {
            do {
                let (downloadedData, _) = try await URLSession.shared.data(from: url)
                data = downloadedData
            } catch {
                throw M3UParserError.networkError(error)
            }
        }

        return try await parseWithStatistics(data: data)
    }

    /// Parses an M3U playlist from Data with detailed statistics.
    ///
    /// Returns the playlist along with parse statistics and warnings.
    ///
    /// - Parameter data: The raw M3U data
    /// - Returns: A ParseResult containing playlist, statistics, and warnings
    /// - Throws: `M3UParserError` if parsing fails
    public func parseWithStatistics(data: Data) async throws -> ParseResult {
        let startTime = Date()

        guard let content = decodeData(data) else {
            throw M3UParserError.encodingError
        }

        let tokens = lexer.tokenize(content: content)
        let lines = content.components(separatedBy: .newlines)
        let result = processTokensWithStatistics(tokens: tokens, totalLines: lines.count)

        let parseTime = Date().timeIntervalSince(startTime)

        let statistics = ParseStatistics(
            totalLines: lines.count,
            successCount: result.items.count,
            failureCount: result.failureCount,
            warningCount: result.warnings.count,
            parseTime: parseTime,
            orphanedExtinfCount: result.orphanedCount,
            duplicateURLCount: result.duplicateCount,
            invalidURLCount: result.invalidURLCount
        )

        return ParseResult(
            playlist: M3UPlaylist(items: result.items),
            statistics: statistics,
            warnings: result.warnings
        )
    }

    private func processTokensWithStatistics(
        tokens: [M3UToken],
        totalLines: Int
    ) -> (items: [M3UItem], warnings: [ParseWarning], failureCount: Int, orphanedCount: Int, duplicateCount: Int, invalidURLCount: Int) {
        var items: [M3UItem] = []
        var warnings: [ParseWarning] = []
        var pendingExtinf: (duration: Int, attributes: [String: String], title: String, lineNumber: Int)?
        var pendingExtgrp: String?
        var seenURLs: Set<String> = []
        var orphanedCount = 0
        var duplicateCount = 0
        let invalidURLCount = 0
        var lineNumber = 0

        for token in tokens {
            lineNumber += 1

            switch token {
            case .extm3u:
                continue

            case let .extinf(duration, attributes, title):
                // Check for orphaned previous EXTINF
                if let previous = pendingExtinf {
                    orphanedCount += 1
                    warnings.append(ParseWarning(
                        lineNumber: previous.lineNumber,
                        severity: .warning,
                        type: .orphanedExtinf,
                        message: "EXTINF without corresponding URL",
                        rawContent: previous.title
                    ))
                }
                pendingExtinf = (duration, attributes, title, lineNumber)

            case let .extgrp(name):
                pendingExtgrp = name

            case let .url(url):
                if let extinf = pendingExtinf {
                    // Check for duplicate URLs
                    let urlString = url.absoluteString
                    if seenURLs.contains(urlString) {
                        duplicateCount += 1
                        warnings.append(ParseWarning(
                            lineNumber: lineNumber,
                            severity: .info,
                            type: .duplicateEntry,
                            message: "Duplicate URL detected",
                            rawContent: urlString
                        ))
                    } else {
                        seenURLs.insert(urlString)
                    }

                    let group = pendingExtgrp ?? extinf.attributes["group-title"]
                    let item = createItemSync(extinf: (extinf.0, extinf.1, extinf.2), url: url, groupOverride: group)
                    items.append(item)
                }
                pendingExtinf = nil
                pendingExtgrp = nil

            case .extSessionData:
                break

            case .comment:
                break

            case .unknown:
                break
            }
        }

        // Check for final orphaned EXTINF
        if let previous = pendingExtinf {
            orphanedCount += 1
            warnings.append(ParseWarning(
                lineNumber: previous.lineNumber,
                severity: .warning,
                type: .orphanedExtinf,
                message: "EXTINF without corresponding URL at end of file",
                rawContent: previous.title
            ))
        }

        return (items, warnings, 0, orphanedCount, duplicateCount, invalidURLCount)
    }

    private static func createItemStatic(
        extinf: (duration: Int, attributes: [String: String], title: String),
        url: URL,
        groupOverride: String?,
        classifier: any ContentClassifying
    ) -> M3UItem {
        let group = groupOverride ?? extinf.attributes["group-title"]
        let contentType = classifier.classify(
            name: extinf.title,
            group: group,
            attributes: extinf.attributes,
            url: url
        )

        // Extract xui-id and timeshift from attributes
        let xuiID = extinf.attributes["xui-id"]
        let timeshift = extinf.attributes["timeshift"].flatMap { Int($0) }

        // Extract catchup attributes
        let catchup = extinf.attributes["catchup"]
        let catchupSource = extinf.attributes["catchup-source"]
        let catchupDays = extinf.attributes["catchup-days"].flatMap { Int($0) }
        let catchupCorrection = extinf.attributes["catchup-correction"].flatMap { Int($0) }

        // Extract tvg-rec attribute (only returns true if "1" or "true")
        let tvgRec: Bool? = extinf.attributes["tvg-rec"].flatMap {
            ($0 == "1" || $0.lowercased() == "true") ? true : nil
        }

        return M3UItem(
            name: extinf.title,
            url: url,
            group: group,
            logo: extinf.attributes["tvg-logo"].flatMap { URL(string: $0) },
            epgID: extinf.attributes["tvg-id"],
            contentType: contentType,
            duration: extinf.duration == -1 ? nil : extinf.duration,
            attributes: extinf.attributes,
            xuiID: xuiID,
            timeshift: timeshift,
            catchup: catchup,
            catchupSource: catchupSource,
            catchupDays: catchupDays,
            catchupCorrection: catchupCorrection,
            tvgRec: tvgRec
        )
    }

    // MARK: - Private Methods

    private func decodeData(_ data: Data) -> String? {
        // Try UTF-8 first
        if let string = String(data: data, encoding: .utf8) {
            return string
        }

        // Try Latin-1
        if let string = String(data: data, encoding: .isoLatin1) {
            return string
        }

        // Try Windows-1252
        if let string = String(data: data, encoding: .windowsCP1252) {
            return string
        }

        return nil
    }

    private func processTokens(_ tokens: [M3UToken]) -> [M3UItem] {
        var items: [M3UItem] = []
        var pendingExtinf: (duration: Int, attributes: [String: String], title: String)?
        var pendingExtgrp: String?

        for token in tokens {
            switch token {
            case .extm3u:
                continue

            case let .extinf(duration, attributes, title):
                pendingExtinf = (duration, attributes, title)

            case let .extgrp(name):
                pendingExtgrp = name

            case let .url(url):
                if let extinf = pendingExtinf {
                    let group = pendingExtgrp ?? extinf.attributes["group-title"]
                    let item = createItemSync(extinf: extinf, url: url, groupOverride: group)
                    items.append(item)
                }
                pendingExtinf = nil
                pendingExtgrp = nil

            case .extSessionData:
                // Session data is metadata, not an item - ignore for now
                break

            case .comment, .unknown:
                break
            }
        }

        return items
    }

    private func createItem(
        extinf: (duration: Int, attributes: [String: String], title: String),
        url: URL,
        groupOverride: String?
    ) async -> M3UItem {
        let group = groupOverride ?? extinf.attributes["group-title"]
        let contentType = classifier.classify(
            name: extinf.title,
            group: group,
            attributes: extinf.attributes,
            url: url
        )

        // Extract xui-id and timeshift from attributes
        let xuiID = extinf.attributes["xui-id"]
        let timeshift = extinf.attributes["timeshift"].flatMap { Int($0) }

        // Extract catchup attributes
        let catchup = extinf.attributes["catchup"]
        let catchupSource = extinf.attributes["catchup-source"]
        let catchupDays = extinf.attributes["catchup-days"].flatMap { Int($0) }
        let catchupCorrection = extinf.attributes["catchup-correction"].flatMap { Int($0) }

        // Extract tvg-rec attribute (only returns true if "1" or "true")
        let tvgRec: Bool? = extinf.attributes["tvg-rec"].flatMap {
            ($0 == "1" || $0.lowercased() == "true") ? true : nil
        }

        return M3UItem(
            name: extinf.title,
            url: url,
            group: group,
            logo: extinf.attributes["tvg-logo"].flatMap { URL(string: $0) },
            epgID: extinf.attributes["tvg-id"],
            contentType: contentType,
            duration: extinf.duration == -1 ? nil : extinf.duration,
            attributes: extinf.attributes,
            xuiID: xuiID,
            timeshift: timeshift,
            catchup: catchup,
            catchupSource: catchupSource,
            catchupDays: catchupDays,
            catchupCorrection: catchupCorrection,
            tvgRec: tvgRec
        )
    }

    private func createItemSync(
        extinf: (duration: Int, attributes: [String: String], title: String),
        url: URL,
        groupOverride: String?
    ) -> M3UItem {
        let group = groupOverride ?? extinf.attributes["group-title"]
        let contentType = classifier.classify(
            name: extinf.title,
            group: group,
            attributes: extinf.attributes,
            url: url
        )

        // Extract xui-id and timeshift from attributes
        let xuiID = extinf.attributes["xui-id"]
        let timeshift = extinf.attributes["timeshift"].flatMap { Int($0) }

        // Extract catchup attributes
        let catchup = extinf.attributes["catchup"]
        let catchupSource = extinf.attributes["catchup-source"]
        let catchupDays = extinf.attributes["catchup-days"].flatMap { Int($0) }
        let catchupCorrection = extinf.attributes["catchup-correction"].flatMap { Int($0) }

        // Extract tvg-rec attribute (only returns true if "1" or "true")
        let tvgRec: Bool? = extinf.attributes["tvg-rec"].flatMap {
            ($0 == "1" || $0.lowercased() == "true") ? true : nil
        }

        return M3UItem(
            name: extinf.title,
            url: url,
            group: group,
            logo: extinf.attributes["tvg-logo"].flatMap { URL(string: $0) },
            epgID: extinf.attributes["tvg-id"],
            contentType: contentType,
            duration: extinf.duration == -1 ? nil : extinf.duration,
            attributes: extinf.attributes,
            xuiID: xuiID,
            timeshift: timeshift,
            catchup: catchup,
            catchupSource: catchupSource,
            catchupDays: catchupDays,
            catchupCorrection: catchupCorrection,
            tvgRec: tvgRec
        )
    }
}
