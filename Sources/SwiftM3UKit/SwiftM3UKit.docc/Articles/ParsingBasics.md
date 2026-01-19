# Parsing Basics

Understand how SwiftM3UKit parses M3U files and the data it extracts.

## Overview

M3U (M3U8) files are playlist formats used extensively in IPTV streaming. SwiftM3UKit parses both basic M3U and Extended M3U (EXTM3U) formats.

## M3U File Format

A typical EXTM3U file looks like this:

```
#EXTM3U
#EXTINF:-1 tvg-id="bbc1" tvg-logo="http://logo.com/bbc.png" group-title="UK Channels",BBC One HD
http://stream.example.com/bbc1
#EXTINF:-1 tvg-id="cnn" group-title="News",CNN International
http://stream.example.com/cnn
```

### Key Components

- **#EXTM3U**: Header indicating an extended M3U file
- **#EXTINF**: Entry information with duration and attributes
- **URL**: The actual stream URL

### Supported Attributes

SwiftM3UKit recognizes these standard attributes:

| Attribute | Description | Maps to |
|-----------|-------------|---------|
| `tvg-id` | EPG identifier | ``M3UItem/epgID`` |
| `tvg-name` | Display name | ``M3UItem/attributes`` |
| `tvg-logo` | Logo URL | ``M3UItem/logo`` |
| `group-title` | Category/group | ``M3UItem/group`` |
| `xui-id` | XUI panel ID | ``M3UItem/xuiID`` |
| `timeshift` | Timeshift duration (seconds) | ``M3UItem/timeshift`` |

### Supported Directives

| Directive | Description |
|-----------|-------------|
| `#EXTM3U` | Playlist header |
| `#EXTINF` | Entry information |
| `#EXTGRP` | Group/category |
| `#EXTVLCOPT` | VLC options |
| `#KODIPROP` | Kodi properties |
| `#EXT-X-SESSION-DATA` | Session metadata (XUI) |

## The Parsing Pipeline

SwiftM3UKit uses a two-stage parsing approach:

### 1. Lexical Analysis

The lexer converts raw text into tokens:

```
#EXTINF:-1 tvg-id="bbc1" xui-id="123",BBC One
→ Token.extinf(duration: -1, attributes: ["tvg-id": "bbc1", "xui-id": "123"], title: "BBC One")

#EXT-X-SESSION-DATA:DATA-ID="com.xui.1",VALUE="metadata"
→ Token.extSessionData(dataID: "com.xui.1", value: "metadata")

http://example.com/stream
→ Token.url(URL(...))
```

### 2. Semantic Parsing

The parser combines tokens into ``M3UItem`` instances, applying content classification.

## Duration Handling

The duration field in `#EXTINF` has special meaning:

- **-1**: Live stream (no fixed duration)
- **Positive integer**: Duration in seconds (VOD content)

```swift
// Duration is nil for live streams
if let duration = item.duration {
    print("VOD content: \(duration) seconds")
} else {
    print("Live stream")
}
```

## XUI/Xtream Codes Attributes

For Xtream Codes/XUI panels, additional attributes are parsed:

```swift
// XUI panel ID for API integration
if let xuiID = item.xuiID {
    print("XUI ID: \(xuiID)")
}

// Timeshift support
if let timeshift = item.timeshift {
    print("Can rewind \(timeshift) seconds")
}
```

## Encoding Support

SwiftM3UKit automatically detects and handles multiple encodings:

1. UTF-8 (preferred)
2. ISO-8859-1 (Latin-1)
3. Windows-1252

This ensures compatibility with playlists from various sources.

## See Also

- ``M3UParser``
- ``M3UItem``
- <doc:StreamingParsing>
