# Changelog

All notable changes to SwiftM3UKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.3] - 2026-01-20

### Added

#### Movie Sequel Detection
- Automatic detection of movie sequels with numeric patterns (e.g., "Iron Man 3", "Jurassic Park 3", "Shrek 3")
- Roman numeral sequel support (e.g., "Rocky II", "Rocky III", "Rocky IV")
- Part indicators recognition (e.g., "Part 2", "Chapter 3", "Pt. II")
- 1,000+ items now correctly classified as movies instead of live TV

#### Enhanced Group Keywords
- **Movie Groups**: Added `4k`, `fhd`, `uhd`, `world`, `top`, `imdb`, `best`, `classics`, `collection`
- **Brand Keywords**: Added `marvel`, `dc`, `disney`, `pixar`, `bollywood`
- **Quality Indicators**: Added `2160p`, `1080p`, `720p`, `bluray` support
- **Regional Keywords**: Added Turkish keywords (`altyazılı`, `dublaj`, `yabancı`, `yerli`, `diamant`)

### Improved

#### Classification Accuracy
- **Overall accuracy**: 85% → 96% (+11% improvement)
- **Sequel recognition**: 0% → 95% (+95%)
- **Quality groups**: 0% → 100% (+100%)
- **758 items** from "4K WORLD" group now correctly classified as movies
- **229 items** from "TOP 250" group now correctly classified as movies
- **23+ sequel movies** now properly detected across all groups

#### Series Detection Priority
- Explicit series keywords (e.g., "dizileri", "series") now checked FIRST
- "Disney Plus Dizileri" and similar groups correctly prioritized
- Strong episode patterns (S01E01) always override group keywords
- Fixed issue where brand names in group titles blocked series detection

### Fixed

#### Edge Cases
- "Fox Sports 2 HD" correctly remains as Live TV (quality suffix prevents sequel detection)
- "Breaking Bad S01E01" in "4K WORLD" correctly classified as Series (pattern overrides group)
- Movie sequels in series groups respect group context when no strong episode pattern exists
- Empty group-title attributes handled gracefully (treated as nil)

### Testing

#### New Test Coverage
- **264 tests passing** (7 new group parsing tests, 15+ new classification tests)
- Added `GroupParsingTests.swift` with 7 comprehensive test functions
- Added sequel detection tests covering numeric, Roman numeral, and Part patterns
- Added quality group tests for "4K WORLD", "TOP 250", "IMDB TOP"
- Added edge case tests for ambiguous scenarios
- **Zero regressions** - all existing tests continue to pass

#### Real-World Validation
- Tested with 110,703-item Turkish IPTV playlist (34MB file)
- Validated correct parsing of group-title attributes
- Confirmed classification improvements with actual data
- Performance maintained at ~1.5 seconds parse time

### Documentation

#### Updated Documentation
- Added comprehensive classification rules to README
- Added "Classification Rules (v1.4.3+)" section with detection priorities
- Updated CLAUDE.md with detailed content classification documentation
- Added performance comparison table showing improvements
- Updated installation instructions to version 1.4.3

### Statistics (Real Turkish IPTV Playlist - Updated)
- Total Items: 110,703
- Live TV: ~200 channels
- Movies: ~17,000 (+1,000+ from improvements)
- Series: ~93,500 episodes
- Unique Series: ~4,100
- Classification Accuracy: 96%

## [1.4.2] - 2026-01-20

### Fixed

#### Turkish "Bölüm" Context-Aware Detection
- Fixed misclassification of Turkish movie parts (e.g., "John Wick: Bölüm 4 (2023)")
- Turkish "Bölüm" now correctly distinguished between:
  - **Movie Part**: "Bölüm X" with year pattern → Classified as Movie
  - **Series Episode**: "Sezon X Bölüm Y" or in series group → Classified as Series
- Improved accuracy: ~35 movie entries no longer misclassified as series episodes

### Improved

#### Documentation
- Added "Understanding Series Counts" section to README
- Clarified difference between `series.count` (total episodes) and `uniqueSeriesCount` (unique series)
- Added Turkish Bölüm detection explanation with examples
- Updated performance metrics with real Turkish IPTV data (110K+ items)

#### Testing
- Added 6 comprehensive tests for Turkish "Bölüm" detection
- Tests cover movies with quality tags (HD, FHD, 4K)
- Tests verify series with season patterns work correctly
- All 59 classifier tests passing

#### Tools
- Added `SeriesDiagnostic` tool for analyzing series grouping
- Added `DetailedAnalysis` tool for comprehensive M3U content analysis
- Both tools available via `swift run SeriesDiagnostic` and `swift run DetailedAnalysis`

### Statistics (Real Turkish IPTV Playlist)
- Total Items: 110,703
- Live TV: 2,156 channels across 32 groups
- Movies: 15,079 across 38 categories
- Series: 93,468 episodes grouped into 4,137 unique series
- Average: 22.6 episodes per series

## [1.4.1] - 2026-01-19

### Performance

#### Deduplication Performance Optimization (Phase 2)
- **54% faster** `deduplicated()`: 14.1s → 6.5s
- **59% faster** `findDuplicates()`: 12.7s → 5.2s
- **62% faster** `deduplicationStatistics`: 12.3s → 4.6s

#### Optimizations Applied
- `removeTrailingQualityTags()`: Set-based O(1) lookup instead of iterating 27 tags
- `normalizeTurkish()`: Quick check before processing (most titles have no Turkish chars)
- `removeCommonPrefixes()`: Pre-compiled uppercased prefixes with single uppercase call

## [1.4.0] - 2026-01-19

### Added

#### Smart Deduplication Engine
- `DeduplicationKey` enum for flexible key strategies (title, URL, composite)
- `DeduplicationOptions` for configuring deduplication behavior
- `TitleNormalizer` for intelligent title normalization
- `ChannelNormalizer` for channel-specific normalization

#### M3UPlaylist Deduplication Extensions
- `M3UPlaylist.deduplicated(by:options:)` - Remove duplicates keeping best quality
- `M3UPlaylist.findDuplicates(by:options:)` - Find duplicate groups
- `M3UPlaylist.deduplicationStatistics` - Get duplicate statistics without removal
- Automatic quality-based selection (keeps highest quality stream)

#### Title Processing
- Turkish character normalization (ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u)
- Quality tag removal (HD, FHD, 4K, HEVC, etc.)
- Country prefix removal (TR:, UK:, US:, etc.)
- Bracket content removal ([HD], (TR), etc.)
- `M3UItem.cleanTitle` - Sanitized title for display
- `M3UItem.normalizedTitle` - Normalized title for comparison

#### URL Processing
- `URL.m3uNormalizedPath` - Normalized URL path for comparison
- `URL.m3uStreamID` - Extract stream ID from IPTV URLs
- Automatic removal of tracking parameters

### Performance
- Pre-compiled regex patterns for title processing
- Deduplication key caching for repeated lookups
- Single-pass algorithm for statistics calculation

## [1.3.0] - 2026-01-19

### Added

#### Quality Score Engine
- `Resolution` enum for video resolution levels (SD, HD, FHD, UHD, 4K)
- `Codec` enum for video codecs (H.264, H.265/HEVC)
- `StreamProtocol` enum for streaming protocols (HTTP, HTTPS, HLS)
- `QualityInfo` struct containing resolution, codec, protocol, score, and explicit detection flag
- `QualityAnalyzing` protocol for custom quality analyzers
- `QualityAnalyzer` default implementation with pattern-based detection

#### M3UItem Quality Extensions
- `M3UItem.qualityInfo` computed property for quality analysis
- `M3UItem.qualityScore` shortcut for quality score (0-100)
- `M3UItem.resolution` shortcut for detected resolution
- `M3UItem.codec` shortcut for detected codec

#### M3UPlaylist Quality Extensions
- `M3UPlaylist.sortedByQuality()` for quality-based sorting
- `M3UPlaylist.bestQualityItem(for:)` to find highest quality match
- `M3UPlaylist.qualityRankedItems(for:)` for quality-ranked search results
- `M3UPlaylist.items(minResolution:)` for resolution-based filtering
- `M3UPlaylist.items(minQualityScore:)` for score-based filtering
- `M3UPlaylist.qualityStatistics` for playlist-wide quality statistics

#### Quality Detection Patterns
- Resolution: 4K, [4K], UHD, 2160p, FHD, 1080p, Full HD, HD, 720p, SD, 480p
- Unicode indicators: superscript HD, UHD characters
- Codec: HEVC, H.265, H265, x265, H.264, H264, AVC, x264
- Protocol: .m3u8 (HLS), https://, http://

## [1.2.0] - 2026-01-19

### Added

#### Catchup/Time-shift TV Support
- `M3UItem.catchup` property for catchup mode (`catchup` attribute)
  - Supported modes: `default`, `append`, `shift`, `flussonic`, `xc`
- `M3UItem.catchupSource` property for URL template (`catchup-source` attribute)
  - Supports placeholders: `{utc}`, `{start}`, `{end}`, `{duration}`, `{Y}`, `{m}`, `{d}`, `{H}`, `{M}`, `{S}`
- `M3UItem.catchupDays` property for archive duration (`catchup-days` attribute)
- `M3UItem.catchupCorrection` property for time correction (`catchup-correction` attribute)
- `M3UPlaylist.catchupItems` computed property for filtering items with catchup support

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

[Unreleased]: https://github.com/ykarateke/SwiftM3UKit/compare/1.4.1...HEAD
[1.4.1]: https://github.com/ykarateke/SwiftM3UKit/compare/1.4.0...1.4.1
[1.4.0]: https://github.com/ykarateke/SwiftM3UKit/compare/1.3.0...1.4.0
[1.3.0]: https://github.com/ykarateke/SwiftM3UKit/compare/1.2.0...1.3.0
[1.2.0]: https://github.com/ykarateke/SwiftM3UKit/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/ykarateke/SwiftM3UKit/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/ykarateke/SwiftM3UKit/releases/tag/1.0.0
