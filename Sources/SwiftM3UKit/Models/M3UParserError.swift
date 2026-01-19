import Foundation

/// Errors that can occur during M3U parsing.
public enum M3UParserError: Error, Sendable {
    /// The file format is not a valid M3U/EXTM3U format
    case invalidFormat

    /// A URL in the playlist could not be parsed
    case invalidURL(String)

    /// The specified file was not found
    case fileNotFound

    /// The file encoding could not be determined or is unsupported
    case encodingError

    /// The stream was interrupted during parsing
    case streamInterrupted

    /// Network error occurred while fetching the playlist
    case networkError(Error)
}

extension M3UParserError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid M3U format. File must start with #EXTM3U header."
        case .invalidURL(let urlString):
            return "Invalid URL: \(urlString)"
        case .fileNotFound:
            return "The specified file was not found."
        case .encodingError:
            return "Unable to decode file. Unsupported or invalid encoding."
        case .streamInterrupted:
            return "Stream was interrupted during parsing."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

extension M3UParserError: Equatable {
    public static func == (lhs: M3UParserError, rhs: M3UParserError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidFormat, .invalidFormat),
             (.fileNotFound, .fileNotFound),
             (.encodingError, .encodingError),
             (.streamInterrupted, .streamInterrupted):
            return true
        case let (.invalidURL(lhs), .invalidURL(rhs)):
            return lhs == rhs
        case (.networkError, .networkError):
            return true
        default:
            return false
        }
    }
}
