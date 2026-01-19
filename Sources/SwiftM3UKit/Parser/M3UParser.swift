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
            attributes: extinf.attributes
        )

        // Extract xui-id and timeshift from attributes
        let xuiID = extinf.attributes["xui-id"]
        let timeshift = extinf.attributes["timeshift"].flatMap { Int($0) }

        // Extract catchup attributes
        let catchup = extinf.attributes["catchup"]
        let catchupSource = extinf.attributes["catchup-source"]
        let catchupDays = extinf.attributes["catchup-days"].flatMap { Int($0) }
        let catchupCorrection = extinf.attributes["catchup-correction"].flatMap { Int($0) }

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
            catchupCorrection: catchupCorrection
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
            attributes: extinf.attributes
        )

        // Extract xui-id and timeshift from attributes
        let xuiID = extinf.attributes["xui-id"]
        let timeshift = extinf.attributes["timeshift"].flatMap { Int($0) }

        // Extract catchup attributes
        let catchup = extinf.attributes["catchup"]
        let catchupSource = extinf.attributes["catchup-source"]
        let catchupDays = extinf.attributes["catchup-days"].flatMap { Int($0) }
        let catchupCorrection = extinf.attributes["catchup-correction"].flatMap { Int($0) }

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
            catchupCorrection: catchupCorrection
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
            attributes: extinf.attributes
        )

        // Extract xui-id and timeshift from attributes
        let xuiID = extinf.attributes["xui-id"]
        let timeshift = extinf.attributes["timeshift"].flatMap { Int($0) }

        // Extract catchup attributes
        let catchup = extinf.attributes["catchup"]
        let catchupSource = extinf.attributes["catchup-source"]
        let catchupDays = extinf.attributes["catchup-days"].flatMap { Int($0) }
        let catchupCorrection = extinf.attributes["catchup-correction"].flatMap { Int($0) }

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
            catchupCorrection: catchupCorrection
        )
    }
}
