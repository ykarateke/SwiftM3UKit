import Foundation

/// An async sequence that reads lines from a URL efficiently.
///
/// This reader uses FileHandle's async bytes to read files line by line,
/// maintaining constant memory usage regardless of file size.
struct AsyncLineReader: AsyncSequence {
    typealias Element = String

    let url: URL

    init(url: URL) {
        self.url = url
    }

    func makeAsyncIterator() -> AsyncLineIterator {
        AsyncLineIterator(url: url)
    }
}

/// Iterator for AsyncLineReader that yields lines one at a time.
struct AsyncLineIterator: AsyncIteratorProtocol {
    typealias Element = String

    private var fileHandle: FileHandle?
    private var byteIterator: FileHandle.AsyncBytes.AsyncIterator?
    private var buffer: [UInt8] = []
    private var isFinished = false

    init(url: URL) {
        do {
            fileHandle = try FileHandle(forReadingFrom: url)
            byteIterator = fileHandle?.bytes.makeAsyncIterator()
        } catch {
            isFinished = true
        }
    }

    mutating func next() async throws -> String? {
        guard !isFinished else { return nil }

        guard var iterator = byteIterator else {
            isFinished = true
            return nil
        }

        buffer.removeAll(keepingCapacity: true)

        while let byte = try await iterator.next() {
            byteIterator = iterator

            if byte == UInt8(ascii: "\n") {
                // Handle Windows-style line endings (CR+LF)
                if buffer.last == UInt8(ascii: "\r") {
                    buffer.removeLast()
                }
                return String(decoding: buffer, as: UTF8.self)
            }

            buffer.append(byte)
        }

        // Handle final line without newline
        isFinished = true

        if buffer.isEmpty {
            try? fileHandle?.close()
            return nil
        }

        // Handle potential CR at end of file
        if buffer.last == UInt8(ascii: "\r") {
            buffer.removeLast()
        }

        try? fileHandle?.close()
        return String(decoding: buffer, as: UTF8.self)
    }
}

/// An async sequence that reads lines from Data.
struct AsyncDataLineReader: AsyncSequence {
    typealias Element = String

    let data: Data

    init(data: Data) {
        self.data = data
    }

    func makeAsyncIterator() -> AsyncDataLineIterator {
        AsyncDataLineIterator(data: data)
    }
}

/// Iterator for AsyncDataLineReader.
struct AsyncDataLineIterator: AsyncIteratorProtocol {
    typealias Element = String

    private let lines: [String]
    private var currentIndex: Int = 0

    init(data: Data) {
        // Try UTF-8 first, then Latin-1 as fallback
        let content: String
        if let utf8String = String(data: data, encoding: .utf8) {
            content = utf8String
        } else if let latin1String = String(data: data, encoding: .isoLatin1) {
            content = latin1String
        } else if let windowsString = String(data: data, encoding: .windowsCP1252) {
            content = windowsString
        } else {
            content = ""
        }

        lines = content.components(separatedBy: .newlines)
    }

    mutating func next() async -> String? {
        guard currentIndex < lines.count else { return nil }

        let line = lines[currentIndex]
        currentIndex += 1
        return line
    }
}

/// An async sequence that reads lines from a remote URL.
struct AsyncURLLineReader: AsyncSequence {
    typealias Element = String

    let url: URL

    init(url: URL) {
        self.url = url
    }

    func makeAsyncIterator() -> AsyncURLLineIterator {
        AsyncURLLineIterator(url: url)
    }
}

/// Iterator for AsyncURLLineReader.
struct AsyncURLLineIterator: AsyncIteratorProtocol {
    typealias Element = String

    private var dataIterator: AsyncDataLineIterator?
    private var hasStarted = false
    private let url: URL

    init(url: URL) {
        self.url = url
    }

    mutating func next() async throws -> String? {
        if !hasStarted {
            hasStarted = true
            let (data, _) = try await URLSession.shared.data(from: url)
            dataIterator = AsyncDataLineIterator(data: data)
        }

        return await dataIterator?.next()
    }
}
