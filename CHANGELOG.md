# Changelog

All notable changes to SwiftM3UKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-01-19

### Added

#### Multi-Language Support
- Season/episode detection for 11 languages:
  - English: Season/Episode
  - Turkish: Sezon/Bölüm
  - Arabic: موسم/حلقة
  - French: Saison/Épisode
  - German: Staffel/Folge
  - Hindi: सीज़न/एपिसोड
  - Japanese: シーズン/エピソード, 第X期/第X話
  - Portuguese: Temporada/Episódio
  - Russian: Сезон/Серия
  - Chinese: 第X季/第X集
  - Spanish: Temporada/Capítulo

#### Series Statistics API
- `SeriesInfo` struct for grouping series with episodes
- `EpisodeInfo` struct for episode details with season/episode numbers
- `M3UPlaylist.seriesGrouped` - all series grouped by name
- `M3UPlaylist.uniqueSeriesCount` - count of unique series
- `M3UPlaylist.totalEpisodeCount` - total episode count

#### XUI/Xtream Codes Support
- `M3UItem.xuiID` property for XUI panel ID (`xui-id` attribute)
- `M3UItem.timeshift` property for timeshift duration (`timeshift` attribute)
- `#EXT-X-SESSION-DATA` directive parsing with DATA-ID and VALUE support

#### Content Classification Improvements
- Unicode indicator detection: °, ᴬⱽᴿᵁᴾᴬ, ᴿᴬᵂ, ᵁᴴᴰ, ᴴᴰ
- Turkish group keywords: sinema, vizyon, bluray, altyazili, dublaj, imdb
- Live TV prefix detection: ▱ prefix for live categories
- Multi-language movie group keywords (11 languages)
- Multi-language series group keywords (11 languages)
- Asian character pattern detection for Chinese/Japanese

### Improved
- Episode pattern detection accuracy (avoids false positives like "Cep" → "ep")
- Year pattern filtering to prevent years (1950-2030) being detected as episode numbers
- Roman numeral handling in episode patterns (e.g., "Star Wars Episode IV")

### Performance
- Tested with 110,703 items (34.2MB file)
- Classification accuracy: 2,148 live, 15,051 movies, 93,504 series

## [1.0.0] - 2025-01-19

### Added
- Initial release of SwiftM3UKit
- `M3UParser` actor for parsing M3U/EXTM3U playlists
- `M3UPlaylist` struct with filtered accessors for channels, movies, and series
- `M3UItem` model with full attribute support
- `ContentType` enum for live, movie, and series classification
- `ContentClassifier` with heuristic classification rules
- `ContentClassifying` protocol for custom classifiers
- Streaming parser via `parseStream(from:)` for memory-efficient parsing
- Support for UTF-8, Latin-1, and Windows-1252 encodings
- Support for HTTP, HTTPS, RTMP, and RTSP URL schemes
- Full DocC documentation with tutorials and articles
- Comprehensive test suite using Swift Testing Framework
- GitHub Actions CI/CD pipeline

### Platforms
- iOS 15.0+
- tvOS 15.0+
- macOS 12.0+

### Swift Version
- Swift 6.0 with strict concurrency enabled

[Unreleased]: https://github.com/ykarateke/SwiftM3UKit/compare/1.1.0...HEAD
[1.1.0]: https://github.com/ykarateke/SwiftM3UKit/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/ykarateke/SwiftM3UKit/releases/tag/1.0.0
