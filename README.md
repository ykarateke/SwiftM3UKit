# SwiftM3UKit

A modern, memory-efficient M3U/EXTM3U parser framework for IPTV applications.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%20|%20tvOS%2015%20|%20macOS%2012-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## What's New in 1.4.3

🎯 **Major Classification Accuracy Improvements (+11%)**
- **Movie Sequel Detection**: Automatic detection of movie sequels (Title 2, Title 3, Rocky II, Part II, etc.)
- **Quality Group Keywords**: 4K WORLD, TOP 250, IMDB groups now correctly classified as movies
- **Smart Group Handling**: Disney Plus Dizileri, Netflix series groups properly prioritized
- **1,000+ items** now correctly classified in real playlists (tested with 110K+ item playlist)
- Classification accuracy improved from **85% to 96%** 🚀

🔧 **Enhanced Content Classification**
- Added support for numeric sequels: "Iron Man 3", "Jurassic Park 3", "Shrek 3"
- Roman numeral detection: "Rocky II", "Rocky III", "Rocky IV"
- Part indicators: "Part 2", "Chapter 3", "Pt. II"
- Quality indicator groups: "4k", "fhd", "uhd", "world", "top", "imdb", "best"
- Brand/franchise keywords: "marvel", "dc", "disney", "pixar", "bollywood"

✅ **Comprehensive Testing**
- 264 tests passing (7 new group parsing tests added)
- 15+ new classification test cases
- Zero regressions - all existing functionality preserved
- Real-world data validation with 110K+ item playlists

## Features

- **Swift 6 Ready**: Full strict concurrency support with `Sendable` types
- **Memory Efficient**: Streaming parser using `AsyncSequence` for large files (100K+ items)
- **Content Classification**: Automatic detection of Live TV, Movies, and TV Series
- **Quality Score Engine**: Automatic quality detection and scoring (resolution, codec, protocol)
- **Smart Deduplication**: Remove duplicate streams keeping best quality with intelligent title normalization
- **Multi-Language Support**: 11 languages including English, Turkish, Arabic, Chinese, Japanese, Russian, and more
- **Series Statistics**: Group series by name with season/episode information
- **XUI/Xtream Codes Support**: Parse `xui-id` and `timeshift` attributes
- **Catchup/Time-shift TV**: Full support for catchup attributes (`catchup`, `catchup-source`, `catchup-days`)
- **Async/Await**: Modern Swift concurrency throughout
- **Multiple Encodings**: UTF-8, Latin-1, and Windows-1252 support
- **Comprehensive Documentation**: Full DocC documentation with tutorials

## Requirements

- iOS 15.0+ / tvOS 15.0+ / macOS 12.0+
- Swift 6.0+
- Xcode 15.4+

## Installation

### Swift Package Manager

Add SwiftM3UKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ykarateke/SwiftM3UKit", from: "1.4.3")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/ykarateke/SwiftM3UKit`
3. Select version requirements

## Quick Start

```swift
import SwiftM3UKit

// Create a parser
let parser = M3UParser()

// Parse from URL
let url = URL(string: "https://example.com/playlist.m3u")!
let playlist = try await parser.parse(from: url)

// Access content by type
print("Total items: \(playlist.items.count)")
print("Live channels: \(playlist.channels.count)")
print("Movies: \(playlist.movies.count)")
print("Series episodes: \(playlist.series.count)")

// Series statistics
print("Unique series: \(playlist.uniqueSeriesCount)")
print("Total episodes: \(playlist.totalEpisodeCount)")

// Iterate through channels
for channel in playlist.channels {
    print("\(channel.name) - \(channel.url)")
}
```

## Streaming Parse (Memory Efficient)

For large playlists (tested with 100K+ items), use streaming to maintain constant memory usage:

```swift
let parser = M3UParser()

for try await item in parser.parseStream(from: url) {
    // Process each item as it's parsed
    print(item.name)
}
```

## Quality Score Engine

SwiftM3UKit automatically detects stream quality and calculates a score from 0-100:

```swift
// Find the best quality BBC stream
if let best = playlist.bestQualityItem(for: "BBC One") {
    print("\(best.name) - Score: \(best.qualityScore)")
    print("Resolution: \(best.resolution ?? .sd)")
    print("Codec: \(best.codec ?? .unknown)")
}

// Get HD and higher channels
let hdChannels = playlist.items(minResolution: .hd)

// Sort all items by quality
let ranked = playlist.sortedByQuality()

// Quality statistics
let stats = playlist.qualityStatistics
print("4K channels: \(stats.resolutionDistribution[.fourK] ?? 0)")
print("Average score: \(stats.averageScore)")
```

### Score Calculation

| Component | Points |
|-----------|--------|
| Base score | 25 |
| 4K | +40 |
| UHD (2160p) | +35 |
| FHD (1080p) | +30 |
| HD (720p) | +20 |
| SD (480p) | +10 |
| HEVC/H.265 | +20 |
| H.264 | +10 |
| HLS (.m3u8) | +15 |
| HTTPS | +10 |
| HTTP | +5 |

### Detection Patterns

**Resolution:** `4K`, `[4K]`, `UHD`, `2160p`, `FHD`, `1080p`, `Full HD`, `HD`, `720p`, `SD`, `480p`

**Codec:** `HEVC`, `H.265`, `H265`, `x265`, `H.264`, `H264`, `AVC`, `x264`

**Protocol:** `.m3u8` (HLS), `https://`, `http://`

## Smart Deduplication

Remove duplicate streams while keeping the best quality version:

```swift
// Remove duplicates (keeps highest quality)
let unique = playlist.deduplicated()
print("Removed \(playlist.items.count - unique.items.count) duplicates")

// Find duplicate groups
let groups = playlist.findDuplicates()
for group in groups {
    print("\(group.key): \(group.items.count) duplicates")
}

// Get statistics without removing
let stats = playlist.deduplicationStatistics
print("Found \(stats.duplicateCount) duplicates")
print("Unique items: \(stats.uniqueCount)")
```

### Deduplication Options

```swift
// Custom deduplication key
let unique = playlist.deduplicated(by: .url)  // By URL only
let unique = playlist.deduplicated(by: .title)  // By title only
let unique = playlist.deduplicated(by: .composite)  // Title + Group (default)

// Custom options
let options = DeduplicationOptions(
    caseSensitive: false,
    normalizeTitle: true,
    removeQualityTags: true
)
let unique = playlist.deduplicated(options: options)
```

### Title Normalization

The deduplication engine normalizes titles for accurate matching:

- Turkish characters: `ç→c`, `ğ→g`, `ı→i`, `ö→o`, `ş→s`, `ü→u`
- Quality tags removed: `HD`, `FHD`, `4K`, `HEVC`, `1080p`, etc.
- Country prefixes removed: `TR:`, `UK:`, `US:`, `DE:`, etc.
- Bracket content removed: `[HD]`, `(TR)`, etc.

## Content Types

SwiftM3UKit automatically classifies content with 96% accuracy:

```swift
for item in playlist.items {
    switch item.contentType {
    case .live:
        print("📺 \(item.name)")
    case .movie:
        print("🎬 \(item.name)")
    case .series(let season, let episode):
        print("📺 \(item.name) - S\(season ?? 0)E\(episode ?? 0)")
    }
}
```

### Classification Rules (v1.4.3+)

**Movie Detection:**
1. **Group Keywords**: `movie`, `film`, `cinema`, `4k`, `fhd`, `uhd`, `world`, `top`, `imdb`, `best`, `marvel`, `disney`, `pixar`
2. **Sequel Patterns**:
   - Numeric: "Title 2", "Title 3", "Iron Man 3"
   - Roman: "Rocky II", "III", "IV"
   - Parts: "Part 2", "Chapter 3"
3. **Year Patterns**: "(2023)", "[2021]", "2022"
4. **Quality Tags**: `[4K]`, `[FHD]`

**Series Detection:**
1. **Episode Patterns**: `S01E01`, `S1E1` (highest priority)
2. **Multi-language**: "Season 1 Episode 5", "Sezon 1 Bölüm 5", etc.
3. **Series Groups**: Groups containing "series", "dizi", "tv show"

**Live TV Detection:**
1. **Live Prefix**: `▱` symbol in group name
2. **Quality Suffixes**: "HD", "FHD", "4K", "UHD" at end of name
3. **Default**: Items not matching movie or series patterns

**Safety Checks:**
- "Fox Sports 2 HD" → Live TV (quality suffix prevents sequel detection)
- "Breaking Bad S01E01" in "4K WORLD" → Series (strong pattern overrides group)
- "Disney Plus Dizileri" → Series (explicit keyword prioritized)

## Series Statistics

### Understanding Series Counts

⚠️ **Important:** M3U playlists store each episode as a separate entry!

```swift
let playlist = try await parser.parse(from: url)

// ❌ WRONG: This counts ALL episode entries
print("Series: \(playlist.series.count)")  // 93,504 episodes

// ✅ CORRECT: This counts unique series
print("Unique series: \(playlist.uniqueSeriesCount)")  // 4,172 series
print("Total episodes: \(playlist.totalEpisodeCount)")  // 93,504 episodes
```

When you parse an IPTV playlist:
- `playlist.series` = Array of ALL episode items
- `playlist.series.count` = Total number of episodes (e.g., 93,504)
- `playlist.uniqueSeriesCount` = Number of unique series (e.g., 4,172)
- `playlist.totalEpisodeCount` = Same as `series.count` (total episodes)

### Grouping Episodes by Series

Group and analyze TV series:

```swift
// Get all series grouped with their episodes
for series in playlist.seriesGrouped {
    print("\(series.name)")
    print("  Group: \(series.group ?? "none")")
    print("  Seasons: \(series.seasonCount)")
    print("  Episodes: \(series.episodeCount)")

    // Show first few episodes
    for ep in series.episodes.prefix(5) {
        if let s = ep.season, let e = ep.episode {
            print("    S\(s)E\(e) - \(ep.item.name)")
        }
    }
}

// Example output:
// Simpsonlar - The Simpsons
//   Group: DiSNEY PLUS DiZiLERi
//   Seasons: 35
//   Episodes: 754
//     S35E8 - Simpsonlar - The Simpsons S35E08
//     S35E7 - Simpsonlar - The Simpsons S35E07
```

## Multi-Language Support

SwiftM3UKit detects season/episode patterns in 11 languages:

| Language | Season | Episode |
|----------|--------|---------|
| 🇬🇧 English | Season | Episode |
| 🇹🇷 Turkish | Sezon | Bölüm |
| 🇸🇦 Arabic | موسم | حلقة |
| 🇫🇷 French | Saison | Épisode |
| 🇩🇪 German | Staffel | Folge |
| 🇮🇳 Hindi | सीज़न | एपिसोड |
| 🇯🇵 Japanese | シーズン / 第X期 | エピソード / 第X話 |
| 🇧🇷 Portuguese | Temporada | Episódio |
| 🇷🇺 Russian | Сезон | Серия |
| 🇨🇳 Chinese | 第X季 | 第X集 |
| 🇪🇸 Spanish | Temporada | Capítulo / Episodio |

Universal patterns like `S01E01` are also supported.

### Turkish "Bölüm" Context-Aware Detection

SwiftM3UKit intelligently distinguishes between Turkish "Bölüm" meanings:

- **Movie Part:** "John Wick: Bölüm 4 (2023)" → Classified as **Movie**
- **Series Episode:** "Kurtlar Vadisi Sezon 1 Bölüm 5" → Classified as **Series**

The classifier uses context clues (year patterns, season numbers) to determine the correct classification.

## Custom Classification

Implement your own classifier:

```swift
struct MyClassifier: ContentClassifying {
    func classify(name: String, group: String?, attributes: [String: String]) -> ContentType {
        // Your logic here
        return .live
    }
}

let parser = M3UParser()
await parser.setClassifier(MyClassifier())
```

## Catchup/Time-shift TV Support

SwiftM3UKit supports catchup (time-shift TV) attributes for replaying past broadcasts:

```swift
// Get all channels with catchup support
for item in playlist.catchupItems {
    print("\(item.name)")
    print("  Mode: \(item.catchup ?? "none")")
    print("  Source: \(item.catchupSource ?? "none")")
    print("  Days: \(item.catchupDays ?? 0)")
}
```

### Supported Catchup Modes

| Mode | Description |
|------|-------------|
| `default` | Standard catchup URL |
| `append` | Append timestamp to URL |
| `shift` | Add timeshift parameter |
| `flussonic` | Flussonic media server format |
| `xc` | Xtream Codes format |

### URL Template Placeholders

| Placeholder | Description |
|-------------|-------------|
| `{utc}` | Unix timestamp (start) |
| `{start}` | Start time |
| `{end}` | End time |
| `{duration}` | Duration in seconds |
| `{Y}`, `{m}`, `{d}` | Year, month, day |
| `{H}`, `{M}`, `{S}` | Hour, minute, second |

## Supported M3U Attributes

| Attribute | Description | Property |
|-----------|-------------|----------|
| `tvg-id` | EPG identifier | `epgID` |
| `tvg-name` | Display name | `attributes["tvg-name"]` |
| `tvg-logo` | Logo URL | `logo` |
| `group-title` | Category/group | `group` |
| `xui-id` | XUI panel ID | `xuiID` |
| `timeshift` | Timeshift duration (seconds) | `timeshift` |
| `catchup` | Catchup mode (default, append, shift, flussonic, xc) | `catchup` |
| `catchup-source` | URL template for catchup streams | `catchupSource` |
| `catchup-days` | Number of days available for catchup | `catchupDays` |
| `catchup-correction` | Time correction in seconds | `catchupCorrection` |

## Supported Directives

| Directive | Description |
|-----------|-------------|
| `#EXTM3U` | Playlist header |
| `#EXTINF` | Entry information |
| `#EXTGRP` | Group/category |
| `#EXTVLCOPT` | VLC options |
| `#KODIPROP` | Kodi properties |
| `#EXT-X-SESSION-DATA` | Session metadata (XUI) |

## Error Handling

```swift
do {
    let playlist = try await parser.parse(from: url)
} catch M3UParserError.invalidFormat {
    print("Invalid M3U format")
} catch M3UParserError.fileNotFound {
    print("File not found")
} catch M3UParserError.encodingError {
    print("Encoding error")
} catch M3UParserError.networkError(let error) {
    print("Network error: \(error)")
}
```

## Documentation

Generate documentation locally:

```bash
swift package generate-documentation --target SwiftM3UKit
```

View documentation:
```bash
swift package --disable-sandbox preview-documentation --target SwiftM3UKit
```

## Performance

Tested with real-world Turkish IPTV playlist:

| Metric | Value |
|--------|-------|
| File Size | 34.2 MB |
| Total Items | 110,703 |
| Live Channels | ~200 |
| Movies | ~17,000 |
| Series Episodes | ~93,500 |
| Unique Series | ~4,100 |
| Avg Episodes/Series | ~22.6 |
| Classification Accuracy | 96% |

Parse time: ~1.5 seconds on MacBook Pro M1

### Classification Improvements (v1.4.3)

| Category | Before | After | Improvement |
|----------|--------|-------|-------------|
| Movie Detection | 85% | 96% | +11% |
| Sequel Recognition | 0% | 95% | +95% |
| Quality Groups | 0% | 100% | +100% |
| Items Fixed | - | 1,010+ | - |

## License

SwiftM3UKit is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## Author

Created by [Yasin Karateke](https://github.com/ykarateke)
