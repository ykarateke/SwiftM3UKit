# ``SwiftM3UKit``

A modern, memory-efficient M3U/EXTM3U parser framework for IPTV applications.

## Overview

SwiftM3UKit is a Swift 6 compatible parser designed specifically for IPTV playlists. It provides:

- **Streaming Parsing**: Memory-efficient parsing for large files (100K+ items) using `AsyncSequence`
- **Content Classification**: Automatic detection of Live TV, Movies, and TV Series
- **Multi-Language Support**: Season/episode detection in 11 languages
- **Series Statistics**: Group and analyze TV series with episode information
- **XUI/Xtream Codes Support**: Parse provider-specific attributes
- **Full Async/Await Support**: Modern Swift concurrency
- **Strict Concurrency Safety**: All types are `Sendable`

## Getting Started

Add SwiftM3UKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/ykarateke/SwiftM3UKit", from: "1.1.0")
]
```

## Quick Example

```swift
import SwiftM3UKit

// Create a parser
let parser = M3UParser()

// Parse from URL
let playlist = try await parser.parse(from: url)

// Access content by type
print("Channels: \(playlist.channels.count)")
print("Movies: \(playlist.movies.count)")
print("Series: \(playlist.series.count)")

// Series statistics
print("Unique series: \(playlist.uniqueSeriesCount)")
print("Total episodes: \(playlist.totalEpisodeCount)")

// Iterate through grouped series
for series in playlist.seriesGrouped {
    print("\(series.name) - \(series.episodeCount) episodes")
}
```

## Supported Languages

SwiftM3UKit detects season/episode patterns in:

| Language | Season | Episode |
|----------|--------|---------|
| English | Season | Episode |
| Turkish | Sezon | Bölüm |
| Arabic | موسم | حلقة |
| French | Saison | Épisode |
| German | Staffel | Folge |
| Hindi | सीज़न | एपिसोड |
| Japanese | シーズン / 第X期 | エピソード / 第X話 |
| Portuguese | Temporada | Episódio |
| Russian | Сезон | Серия |
| Chinese | 第X季 | 第X集 |
| Spanish | Temporada | Capítulo |

## Topics

### Essentials

- <doc:GettingStarted>
- ``M3UParser``
- ``M3UPlaylist``
- ``M3UItem``

### Content Types

- ``ContentType``
- ``ContentClassifier``
- ``ContentClassifying``

### Series Statistics

- ``SeriesInfo``
- ``EpisodeInfo``

### Error Handling

- ``M3UParserError``

### Articles

- <doc:ParsingBasics>
- <doc:StreamingParsing>
- <doc:CustomClassifiers>
