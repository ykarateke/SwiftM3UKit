# SwiftM3UKit

A modern, memory-efficient M3U/EXTM3U parser framework for IPTV applications.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%20|%20tvOS%2015%20|%20macOS%2012-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Swift 6 Ready**: Full strict concurrency support with `Sendable` types
- **Memory Efficient**: Streaming parser using `AsyncSequence` for large files (100K+ items)
- **Content Classification**: Automatic detection of Live TV, Movies, and TV Series
- **Quality Score Engine**: Automatic quality detection and scoring (resolution, codec, protocol)
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
    .package(url: "https://github.com/ykarateke/SwiftM3UKit", from: "1.3.0")
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

## Content Types

SwiftM3UKit automatically classifies content:

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

## Series Statistics

Group and analyze TV series:

```swift
// Get all series grouped with their episodes
for series in playlist.seriesGrouped {
    print("\(series.name)")
    print("  Seasons: \(series.seasonCount)")
    print("  Episodes: \(series.episodeCount)")

    for ep in series.episodes {
        if let s = ep.season, let e = ep.episode {
            print("    S\(s)E\(e)")
        }
    }
}
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

Tested with real-world IPTV playlists:

| Metric | Value |
|--------|-------|
| File Size | 34.2 MB |
| Total Items | 110,703 |
| Live Channels | 2,148 |
| Movies | 15,051 |
| Series Episodes | 93,504 |
| Unique Series | 2,096 |

## License

SwiftM3UKit is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## Author

Created by [Yasin Karateke](https://github.com/ykarateke)
