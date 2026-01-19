# Streaming Parsing

Parse large M3U files efficiently with constant memory usage.

## Overview

When working with large IPTV playlists (10,000+ channels), loading the entire file into memory can be problematic. SwiftM3UKit provides a streaming parser that processes items one at a time using Swift's `AsyncSequence`.

## Performance

SwiftM3UKit has been tested with real-world playlists:

| Metric | Value |
|--------|-------|
| File Size | 34.2 MB |
| Total Items | 110,703 |
| Memory Usage | Constant (streaming) |

## Using Streaming Parse

The ``M3UParser/parseStream(from:)`` method returns an `AsyncThrowingStream`:

```swift
let parser = M3UParser()

for try await item in parser.parseStream(from: url) {
    // Process each item as it's parsed
    print(item.name)

    // Stop early if needed
    if item.name == "Target Channel" {
        break
    }
}
```

## Memory Benefits

| Method | Memory Usage | Best For |
|--------|-------------|----------|
| `parse(from:)` | O(n) - proportional to file size | Small files (<1000 items) |
| `parseStream(from:)` | O(1) - constant | Large files, memory-constrained devices |

## Buffering Policy

The stream uses a buffering policy of `bufferingNewest(100)`:

- Keeps the 100 most recent items in buffer
- Applies backpressure when consumer is slow
- Prevents memory issues with fast producers

## Cancellation Support

Streaming parsing supports Swift's cooperative cancellation:

```swift
let task = Task {
    for try await item in parser.parseStream(from: url) {
        // Process items
    }
}

// Cancel when needed
task.cancel()
```

## Progress Tracking

Track progress while streaming:

```swift
var count = 0

for try await item in parser.parseStream(from: url) {
    count += 1

    // Update UI every 100 items
    if count % 100 == 0 {
        await MainActor.run {
            progressLabel.text = "\(count) items loaded"
        }
    }
}
```

## Filtering While Streaming

Filter items without loading everything:

```swift
var sportChannels: [M3UItem] = []

for try await item in parser.parseStream(from: url) {
    if item.group == "Sports" {
        sportChannels.append(item)
    }
}
```

## Building Statistics While Streaming

Build series statistics without loading all items:

```swift
var seriesCount = 0
var movieCount = 0
var liveCount = 0

for try await item in parser.parseStream(from: url) {
    switch item.contentType {
    case .live:
        liveCount += 1
    case .movie:
        movieCount += 1
    case .series:
        seriesCount += 1
    }
}

print("Live: \(liveCount), Movies: \(movieCount), Series: \(seriesCount)")
```

## Error Handling in Streams

Handle errors during streaming:

```swift
do {
    for try await item in parser.parseStream(from: url) {
        // Process item
    }
} catch M3UParserError.streamInterrupted {
    print("Stream was interrupted")
} catch {
    print("Error: \(error)")
}
```

## See Also

- ``M3UParser/parseStream(from:)``
- <doc:ParsingBasics>
