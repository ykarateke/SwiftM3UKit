# Custom Content Classifiers

Create custom classifiers to categorize content according to your needs.

## Overview

SwiftM3UKit automatically classifies content as Live TV, Movies, or Series using heuristic rules. You can replace or extend this behavior with custom classifiers.

## Default Classification

The built-in ``ContentClassifier`` uses these rules:

### Live TV Detection
- Resolution indicators: "HD", "FHD", "4K", "UHD"
- Quality tags: "HEVC", "H265"
- Sports/News groups
- Unicode indicators: °, ᴬⱽᴿᵁᴾᴬ, ᴿᴬᵂ, ᵁᴴᴰ, ᴴᴰ
- Group prefix: ▱ (Turkish IPTV live category indicator)

### Movie Detection
- Year patterns: "(2020)", "[2021]"
- Language tags: "(TR)", "(EN)"
- Multi-language groups: "movie", "film", "vod", "cinema", "sinema", "vizyon", "电影", "映画", "фильм"

### Series Detection
- Universal pattern: "S01E01", "S1E1"
- Multi-language patterns (11 languages supported)
- Group keywords: "series", "dizi", "مسلسل", "série", "剧集", "сериал"

## Multi-Language Support

The default classifier detects season/episode patterns in 11 languages:

| Language | Season Keywords | Episode Keywords |
|----------|-----------------|------------------|
| English | season | episode |
| Turkish | sezon | bölüm, bolum |
| Arabic | موسم | حلقة |
| French | saison | épisode |
| German | staffel | folge |
| Hindi | सीज़न | एपिसोड |
| Japanese | シーズン, 第X期 | エピソード, 第X話 |
| Portuguese | temporada | episódio |
| Russian | сезон | серия, эпизод |
| Chinese | 第X季 | 第X集 |
| Spanish | temporada | episodio, capítulo |

## Creating a Custom Classifier

Implement the ``ContentClassifying`` protocol:

```swift
struct MyCustomClassifier: ContentClassifying {
    func classify(
        name: String,
        group: String?,
        attributes: [String: String]
    ) -> ContentType {
        // Custom logic here

        // Check for specific group patterns
        if let group = group?.lowercased() {
            if group.contains("live") || group.contains("24/7") {
                return .live
            }
            if group.contains("film") || group.contains("cinema") {
                return .movie
            }
        }

        // Check name patterns
        let nameLower = name.lowercased()

        if nameLower.contains("s0") && nameLower.contains("e0") {
            // Extract season and episode
            return .series(season: 1, episode: 1)
        }

        return .live // Default
    }
}
```

## Using Custom Classifiers

Set your classifier on the parser:

```swift
let parser = M3UParser()
await parser.setClassifier(MyCustomClassifier())

let playlist = try await parser.parse(from: url)
```

## Extending the Default Classifier

Combine custom logic with the default:

```swift
struct ExtendedClassifier: ContentClassifying {
    private let defaultClassifier = ContentClassifier()

    func classify(
        name: String,
        group: String?,
        attributes: [String: String]
    ) -> ContentType {
        // Check for custom patterns first
        if name.hasPrefix("[LIVE]") {
            return .live
        }

        if name.hasPrefix("[VOD]") {
            return .movie
        }

        // Fall back to default (includes multi-language support)
        return defaultClassifier.classify(
            name: name,
            group: group,
            attributes: attributes
        )
    }
}
```

## Provider-Specific Classifiers

Create classifiers for specific IPTV providers:

```swift
struct TurkishIPTVClassifier: ContentClassifying {
    private let defaultClassifier = ContentClassifier()

    func classify(
        name: String,
        group: String?,
        attributes: [String: String]
    ) -> ContentType {
        guard let group = group else {
            return defaultClassifier.classify(name: name, group: nil, attributes: attributes)
        }

        let groupLower = group.lowercased()

        // Turkish-specific groups
        if groupLower.contains("ulusal") || groupLower.contains("spor") {
            return .live
        }

        if groupLower.contains("sinema") || groupLower.contains("vizyon") {
            return .movie
        }

        if groupLower.contains("dizi") {
            return extractSeriesInfo(from: name)
        }

        return defaultClassifier.classify(name: name, group: group, attributes: attributes)
    }

    private func extractSeriesInfo(from name: String) -> ContentType {
        // Extract S01E01 or Turkish patterns
        // ...
        return .series(season: nil, episode: nil)
    }
}
```

## Best Practices

1. **Performance**: Keep classification logic fast - it runs for every item
2. **Sendable**: Classifiers must be `Sendable` for use with the actor-based parser
3. **Fallbacks**: Always have a default case
4. **Testing**: Test with real playlist samples from your target providers
5. **Multi-Language**: Consider using the default classifier as a fallback to get multi-language support

## See Also

- ``ContentClassifying``
- ``ContentClassifier``
- ``ContentType``
