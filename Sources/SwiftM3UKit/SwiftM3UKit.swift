// SwiftM3UKit - IPTV M3U/EXTM3U Parser Framework
// Copyright (c) 2025. MIT License.

/// SwiftM3UKit is a modern, memory-efficient M3U/EXTM3U parser designed for IPTV applications.
///
/// ## Overview
/// SwiftM3UKit provides a Swift 6 compatible parser for M3U playlists with support for:
/// - Streaming parsing for large files
/// - Automatic content classification (Live TV, Movies, Series)
/// - Full async/await support
/// - Strict concurrency safety
///
/// ## Quick Start
/// ```swift
/// import SwiftM3UKit
///
/// // Parse a playlist
/// let parser = M3UParser()
/// let playlist = try await parser.parse(from: url)
///
/// // Access content by type
/// for channel in playlist.channels {
///     print(channel.name)
/// }
///
/// for movie in playlist.movies {
///     print(movie.name)
/// }
/// ```
///
/// ## Streaming Parse
/// For large files, use streaming to maintain constant memory usage:
/// ```swift
/// for try await item in parser.parseStream(from: url) {
///     process(item)
/// }
/// ```
///
/// ## Topics
///
/// ### Essentials
/// - ``M3UParser``
/// - ``M3UPlaylist``
/// - ``M3UItem``
///
/// ### Content Types
/// - ``ContentType``
/// - ``ContentClassifier``
/// - ``ContentClassifying``
///
/// ### Errors
/// - ``M3UParserError``

// Re-export all public types
@_exported import Foundation
