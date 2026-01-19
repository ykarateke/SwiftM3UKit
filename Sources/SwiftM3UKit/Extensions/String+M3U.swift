import Foundation

extension String {
    /// Trims whitespace and normalizes line endings.
    var m3uNormalized: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    /// Checks if the string is a valid M3U URL.
    var isValidM3UURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme == "http" || url.scheme == "https" || url.scheme == "rtmp" || url.scheme == "rtsp"
    }

    /// Extracts the file extension from a URL string.
    var urlFileExtension: String? {
        guard let url = URL(string: self) else { return nil }
        let ext = url.pathExtension.lowercased()
        return ext.isEmpty ? nil : ext
    }
}
