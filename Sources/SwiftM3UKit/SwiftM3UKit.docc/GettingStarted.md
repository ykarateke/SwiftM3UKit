# Getting Started with SwiftM3UKit

Learn how to parse M3U playlists and access their content.

## Overview

SwiftM3UKit makes it easy to parse M3U/EXTM3U playlists commonly used for IPTV streaming. This guide covers the basics of parsing and accessing playlist content.

## Adding the Package

Add SwiftM3UKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ykarateke/SwiftM3UKit", from: "1.1.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["SwiftM3UKit"])
]
```

## Basic Parsing

The ``M3UParser`` actor is your main entry point for parsing M3U files:

```swift
import SwiftM3UKit

let parser = M3UParser()

// Parse from a URL
let url = URL(string: "https://example.com/playlist.m3u")!
let playlist = try await parser.parse(from: url)

// Parse from local file
let fileURL = URL(fileURLWithPath: "/path/to/playlist.m3u")
let playlist = try await parser.parse(from: fileURL)

// Parse from Data
let data = try Data(contentsOf: fileURL)
let playlist = try await parser.parse(data: data)
```

## Accessing Content

The ``M3UPlaylist`` provides convenient accessors for different content types:

```swift
// All items
for item in playlist.items {
    print(item.name)
}

// Live TV channels only
for channel in playlist.channels {
    print("\(channel.name) - \(channel.url)")
}

// Movies only
for movie in playlist.movies {
    print("\(movie.name) - Duration: \(movie.duration ?? 0)s")
}

// TV Series only
for episode in playlist.series {
    if case let .series(season, episode) = episode.contentType {
        print("S\(season ?? 0)E\(episode ?? 0)")
    }
}
```

## Series Statistics

SwiftM3UKit can group series and provide statistics:

```swift
// Get unique series count
print("Total series: \(playlist.uniqueSeriesCount)")
print("Total episodes: \(playlist.totalEpisodeCount)")

// Get series grouped with their episodes
for series in playlist.seriesGrouped {
    print("\(series.name)")
    print("  Group: \(series.group ?? "Unknown")")
    print("  Seasons: \(series.seasonCount)")
    print("  Episodes: \(series.episodeCount)")

    // Access individual episodes
    for ep in series.episodes {
        print("    S\(ep.season ?? 0)E\(ep.episode ?? 0): \(ep.item.name)")
    }
}
```

## Working with Groups

Items can be organized by their group/category:

```swift
// Get all unique group names
let groups = playlist.groups // ["Sports", "News", "Movies", ...]

// Get items grouped by category
let grouped = playlist.groupedByCategory
for (groupName, items) in grouped {
    print("\(groupName): \(items.count) items")
}
```

## Accessing XUI Attributes

For Xtream Codes/XUI panels, additional attributes are available:

```swift
for item in playlist.items {
    // XUI panel ID
    if let xuiID = item.xuiID {
        print("XUI ID: \(xuiID)")
    }

    // Timeshift support (in seconds)
    if let timeshift = item.timeshift {
        print("Timeshift: \(timeshift)s")
    }
}
```

## Error Handling

Handle parsing errors appropriately:

```swift
do {
    let playlist = try await parser.parse(from: url)
} catch M3UParserError.invalidFormat {
    print("Not a valid M3U file")
} catch M3UParserError.fileNotFound {
    print("File not found")
} catch M3UParserError.encodingError {
    print("Could not decode file")
} catch M3UParserError.networkError(let error) {
    print("Network error: \(error)")
}
```

## Next Steps

- Learn about memory-efficient parsing in <doc:StreamingParsing>
- Customize content classification in <doc:CustomClassifiers>
