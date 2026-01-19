# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SwiftM3UKit is a modern, memory-efficient M3U/EXTM3U parser framework for IPTV applications built with Swift 6. It provides streaming parsing capabilities for large playlists (100K+ items), automatic content classification (Live TV, Movies, TV Series), quality scoring, and smart deduplication.

**Key capabilities:**
- Parse M3U/EXTM3U playlists from URLs or Data
- Stream-based parsing for constant memory usage with large files
- Automatic quality detection and scoring (resolution, codec, protocol)
- Smart deduplication with title normalization
- Multi-language series detection (11 languages)
- Catchup/time-shift TV support
- XUI/Xtream Codes attribute parsing
- Full Swift 6 strict concurrency support

## Development Commands

### Building and Testing
```bash
# Build the package
swift build

# Run all tests
swift test

# Run tests for a specific target
swift test --filter SwiftM3UKitTests

# Run a specific test
swift test --filter SwiftM3UKitTests.ParserTests/testParseBasicPlaylist
```

### Code Quality
```bash
# Run SwiftLint (if installed)
swiftlint

# Auto-fix SwiftLint issues
swiftlint --fix

# Run SwiftFormat (if installed)
swiftformat .
```

### Documentation
```bash
# Generate DocC documentation
swift package generate-documentation --target SwiftM3UKit

# Preview documentation locally
swift package --disable-sandbox preview-documentation --target SwiftM3UKit
```

### Command-Line Tool
```bash
# Build the PlaylistAnalyzer tool
swift build --product PlaylistAnalyzer

# Run the analyzer
swift run PlaylistAnalyzer <path-to-m3u-file>
```

## Architecture

### Core Components

**Parsing Pipeline:**
1. **M3ULexer** (`Lexer/M3ULexer.swift`) - Character-based tokenizer that converts raw M3U text into structured tokens without regex
2. **M3UParser** (`Parser/M3UParser.swift`) - Actor-based parser that processes tokens into M3UItem objects
3. **M3UPlaylist** (`Models/M3UPlaylist.swift`) - Collection container with convenience accessors for different content types

**Data Flow:**
```
Raw M3U Text → M3ULexer → M3UToken[] → M3UParser → M3UItem[] → M3UPlaylist
```

### Key Design Patterns

**Actor Isolation:**
- `M3UParser` is an actor for thread-safe parsing
- Custom classifier can be injected via `setClassifier(_:)`
- All parsing methods are async

**Streaming Architecture:**
- `parseStream(from:)` returns `AsyncThrowingStream<M3UItem, Error>`
- `AsyncLineReader` and `AsyncURLLineReader` provide line-by-line iteration
- Tokens are processed on-the-fly without loading entire file

**Protocol-Based Classification:**
- `ContentClassifying` protocol allows custom classification logic
- Default `ContentClassifier` supports 11 languages for series detection
- Content types: `.live`, `.movie`, `.series(season: Int?, episode: Int?)`

**Extension-Based Features:**
- Quality features in `Extensions/M3UItem+Quality.swift` and `M3UPlaylist+Quality.swift`
- Deduplication in `Extensions/M3UPlaylist+Deduplication.swift`
- Title processing in `Extensions/M3UItem+Title.swift`

### Module Organization

```
Sources/SwiftM3UKit/
├── SwiftM3UKit.swift          # Public API exports and documentation
├── Models/                     # Core data structures
│   ├── M3UItem.swift          # Single playlist item
│   ├── M3UPlaylist.swift      # Collection of items
│   ├── ContentType.swift      # Enum: .live, .movie, .series
│   ├── M3UParserError.swift   # Error types
│   ├── ParseResult.swift      # Parse result with statistics
│   ├── ParseStatistics.swift  # Detailed parse metrics
│   └── ParseWarning.swift     # Parse warnings
├── Parser/                     # Parsing logic
│   └── M3UParser.swift        # Main parser actor
├── Lexer/                      # Tokenization
│   ├── M3ULexer.swift         # Tokenizer implementation
│   └── M3UToken.swift         # Token types
├── Classifier/                 # Content classification
│   ├── ContentClassifying.swift    # Protocol
│   └── ContentClassifier.swift     # Default implementation
├── Quality/                    # Quality analysis
│   ├── QualityAnalyzing.swift      # Protocol
│   ├── QualityAnalyzer.swift       # Implementation
│   ├── Resolution.swift            # Enum: .fourK, .uhd, .fhd, etc.
│   ├── Codec.swift                 # Enum: .hevc, .h264, etc.
│   ├── StreamProtocol.swift        # Enum: .hls, .http, etc.
│   └── QualityInfo.swift           # Extracted quality metadata
├── Deduplication/              # Smart deduplication
│   ├── ChannelNormalizing.swift    # Protocol
│   ├── ChannelNormalizer.swift     # Title normalization
│   └── DeduplicationKey.swift      # Key strategies
├── TitleProcessing/            # Title utilities
│   ├── TitleNormalizing.swift      # Protocol
│   └── TitleNormalizer.swift       # Implementation
└── Extensions/                 # Feature extensions
    ├── M3UItem+Quality.swift
    ├── M3UItem+Title.swift
    ├── M3UPlaylist+Quality.swift
    ├── M3UPlaylist+Deduplication.swift
    ├── String+M3U.swift
    └── URL+M3U.swift
```

### Important Implementation Details

**Token Types:**
- `.extm3u` - Playlist header
- `.extinf(duration, attributes, title)` - Entry with metadata
- `.extgrp(name)` - Group directive
- `.url(URL)` - Stream URL
- `.extSessionData(dataID, value)` - Session metadata
- `.comment(String)` - Comment line
- `.unknown(String)` - Unrecognized line

**Supported M3U Attributes:**
- `tvg-id`, `tvg-name`, `tvg-logo`, `group-title` - Standard EPG attributes
- `xui-id`, `timeshift` - XUI/Xtream Codes
- `catchup`, `catchup-source`, `catchup-days`, `catchup-correction` - Time-shift TV
- `tvg-rec` - Recording capability

**Quality Score Calculation:**
- Base: 25 points
- Resolution: 4K (+40), UHD (+35), FHD (+30), HD (+20), SD (+10)
- Codec: HEVC (+20), H.264 (+10)
- Protocol: HLS (+15), HTTPS (+10), HTTP (+5)
- Maximum score: 100

**Deduplication Strategy:**
- Keys: `.url`, `.title`, `.composite` (title + group)
- Title normalization removes quality tags, country prefixes, brackets
- Turkish character normalization (ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u)
- Keeps highest quality item from each duplicate group

## Testing

Tests are organized by feature area:
- `ParserTests.swift` - Core parsing functionality
- `LexerTests.swift` - Tokenization
- `ClassifierTests.swift` - Content classification
- `QualityTests.swift` - Quality detection and scoring
- `DeduplicationTests.swift` - Deduplication logic
- `TitleProcessingTests.swift` - Title normalization
- `IntegrationTests.swift` - End-to-end scenarios
- `ParseStatisticsTests.swift` - Parse metrics
- `URLProcessingTests.swift` - URL handling

Test resources are in `Tests/SwiftM3UKitTests/Resources/`.

## Code Style

**SwiftLint Configuration:**
- Enforces Swift API design guidelines
- Line length limit: disabled
- File length: warning at 500 lines, error at 1000
- Function body length: warning at 60 lines, error at 100
- Many opt-in rules enabled for consistency

**Key Conventions:**
- All public types conform to `Sendable` for Swift 6 strict concurrency
- Public types implement `Codable` where appropriate
- Use `actor` for types requiring isolation (e.g., `M3UParser`)
- Prefer protocol-based design for extensibility
- Extensions organize features by domain (Quality, Deduplication, etc.)

## Platform Requirements

- iOS 15.0+ / tvOS 15.0+ / macOS 12.0+
- Swift 6.0+
- Xcode 15.4+

## Common Patterns

**Adding a new M3U attribute:**
1. Add property to `M3UItem` struct
2. Update `M3UItem.init()` parameters
3. Parse in `M3UParser.createItem()` / `createItemStatic()` / `createItemSync()`
4. Add corresponding test

**Adding a new content type:**
1. Update `ContentType` enum
2. Extend `ContentClassifier` detection logic
3. Add language-specific patterns if needed
4. Update `M3UPlaylist` accessors if needed

**Adding a new quality metric:**
1. Update `Resolution`, `Codec`, or `StreamProtocol` enum
2. Extend detection patterns in `QualityAnalyzer`
3. Adjust score calculation if needed
4. Add tests for new patterns
