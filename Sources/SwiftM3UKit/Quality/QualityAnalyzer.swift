import Foundation

/// Default implementation of quality analysis.
///
/// QualityAnalyzer detects resolution, codec, and protocol from stream metadata
/// and calculates a quality score from 0 to 100.
///
/// ## Score Calculation
/// | Component | Points |
/// |-----------|--------|
/// | Base score | 25 |
/// | 4K | +40 |
/// | UHD | +35 |
/// | FHD | +30 |
/// | HD | +20 |
/// | SD | +10 |
/// | HEVC/H.265 | +20 |
/// | H.264 | +10 |
/// | HLS (.m3u8) | +15 |
/// | HTTPS | +10 |
/// | HTTP | +5 |
///
/// ## Example
/// ```swift
/// let analyzer = QualityAnalyzer()
/// let info = analyzer.analyze(name: "BBC One 4K HEVC", url: url)
/// print(info.score) // 100 for 4K HEVC with HLS over HTTPS
/// ```
public struct QualityAnalyzer: QualityAnalyzing, Sendable {
    /// Creates a new quality analyzer.
    public init() {}

    /// Analyzes a stream's quality based on its name and URL.
    ///
    /// - Parameters:
    ///   - name: The display name of the stream
    ///   - url: The stream URL
    /// - Returns: Quality information including score, resolution, codec, and protocol
    public func analyze(name: String, url: URL) -> QualityInfo {
        let resolution = detectResolution(from: name)
        let codec = detectCodec(from: name)
        let streamProtocol = detectProtocol(from: url)
        let score = calculateScore(resolution: resolution, codec: codec, streamProtocol: streamProtocol)
        let isExplicit = resolution != nil || codec != nil

        return QualityInfo(
            resolution: resolution,
            codec: codec,
            streamProtocol: streamProtocol,
            score: score,
            isExplicit: isExplicit
        )
    }

    // MARK: - Detection Methods

    /// Detects resolution from the stream name.
    ///
    /// - Parameter name: Stream name to analyze
    /// - Returns: Detected resolution or nil
    func detectResolution(from name: String) -> Resolution? {
        let lowercased = name.lowercased()

        // Check for 4K first (most specific)
        if lowercased.contains("4k") || name.contains("[4K]") {
            return .fourK
        }

        // Check for UHD/2160p
        if lowercased.contains("uhd") ||
           lowercased.contains("2160p") ||
           name.contains("\u{1D41C}\u{1D34}\u{1D30}") { // ᵁᴴᴰ
            return .uhd
        }

        // Check for FHD/1080p (before HD check)
        if lowercased.contains("fhd") ||
           lowercased.contains("1080p") ||
           lowercased.contains("full hd") ||
           lowercased.contains("fullhd") {
            return .fhd
        }

        // Check for HD/720p (only if not FHD/UHD)
        if lowercased.contains("720p") ||
           name.contains("\u{1D34}\u{1D30}") || // ᴴᴰ
           isHDPattern(lowercased) {
            return .hd
        }

        // Check for SD/480p
        if lowercased.contains("sd") || lowercased.contains("480p") {
            return .sd
        }

        return nil
    }

    /// Checks if the name contains HD pattern without being part of FHD/UHD.
    private func isHDPattern(_ lowercased: String) -> Bool {
        // Check for standalone "hd" that's not part of fhd, uhd, etc.
        let patterns = [
            #"\bhd\b"#,         // word boundary HD
            #"\[hd\]"#,         // [HD]
            #"\shd\s"#,         // space HD space
            #"\shd$"#,          // space HD at end
            #"^hd\s"#           // HD at start
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowercased.startIndex..., in: lowercased)
                if regex.firstMatch(in: lowercased, options: [], range: range) != nil {
                    // Make sure it's not FHD or UHD
                    if !lowercased.contains("fhd") &&
                       !lowercased.contains("uhd") &&
                       !lowercased.contains("full hd") {
                        return true
                    }
                }
            }
        }

        return false
    }

    /// Detects codec from the stream name.
    ///
    /// - Parameter name: Stream name to analyze
    /// - Returns: Detected codec or nil
    func detectCodec(from name: String) -> Codec? {
        let lowercased = name.lowercased()

        // Check for H.265/HEVC
        if lowercased.contains("hevc") ||
           lowercased.contains("h.265") ||
           lowercased.contains("h265") ||
           lowercased.contains("x265") {
            return .h265
        }

        // Check for H.264/AVC
        if lowercased.contains("h.264") ||
           lowercased.contains("h264") ||
           lowercased.contains("avc") ||
           lowercased.contains("x264") {
            return .h264
        }

        return nil
    }

    /// Detects streaming protocol from the URL.
    ///
    /// - Parameter url: Stream URL to analyze
    /// - Returns: Detected protocol
    func detectProtocol(from url: URL) -> StreamProtocol {
        let urlString = url.absoluteString.lowercased()
        let pathExtension = url.pathExtension.lowercased()

        // Check for HLS (.m3u8)
        if pathExtension == "m3u8" || urlString.contains(".m3u8") {
            return .hls
        }

        // Check for HTTPS
        if url.scheme?.lowercased() == "https" {
            return .https
        }

        // Default to HTTP
        return .http
    }

    /// Calculates quality score based on detected attributes.
    ///
    /// - Parameters:
    ///   - resolution: Detected resolution
    ///   - codec: Detected codec
    ///   - streamProtocol: Detected protocol
    /// - Returns: Score from 0 to 100
    func calculateScore(resolution: Resolution?, codec: Codec?, streamProtocol: StreamProtocol) -> Int {
        var score = 25 // Base score

        // Resolution points
        if let resolution = resolution {
            switch resolution {
            case .fourK:
                score += 40
            case .uhd:
                score += 35
            case .fhd:
                score += 30
            case .hd:
                score += 20
            case .sd:
                score += 10
            }
        }

        // Codec points
        if let codec = codec {
            switch codec {
            case .h265:
                score += 20
            case .h264:
                score += 10
            case .unknown:
                break
            }
        }

        // Protocol points
        switch streamProtocol {
        case .hls:
            score += 15
        case .https:
            score += 10
        case .http:
            score += 5
        }

        return min(score, 100)
    }
}
