import Foundation

@MainActor
final class FocusLog {
    let fileURL: URL
    private let pendingURL: URL

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("Bell", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("focus-log.csv")
        pendingURL = directory.appendingPathComponent("pending-focus-log.csv")

        if !fileManager.fileExists(atPath: fileURL.path) {
            try? CSVCodec.header.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    func append(_ record: FocusRecord) throws {
        let row = Data(CSVCodec.row(for: record).utf8)
        do {
            try flushPendingRows()
            try append(row, to: fileURL)
        } catch {
            try? append(row, to: pendingURL, createIfNeeded: true)
            throw error
        }
    }

    func latestCommittedGoal() -> String? {
        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else { return nil }
        for line in contents.split(whereSeparator: \.isNewline).dropFirst().reversed() {
            let fields = parseCSVLine(String(line))
            if fields.count >= 5, fields[3] == FocusRecord.Outcome.committed.rawValue, !fields[4].isEmpty {
                return fields[4]
            }
        }
        return nil
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var field = ""
        var insideQuotes = false
        var index = line.startIndex

        while index < line.endIndex {
            let character = line[index]
            if character == "\"" {
                let next = line.index(after: index)
                if insideQuotes, next < line.endIndex, line[next] == "\"" {
                    field.append("\"")
                    index = line.index(after: next)
                    continue
                }
                insideQuotes.toggle()
            } else if character == ",", !insideQuotes {
                fields.append(field)
                field = ""
            } else {
                field.append(character)
            }
            index = line.index(after: index)
        }

        fields.append(field)
        return fields
    }

    private func flushPendingRows() throws {
        guard FileManager.default.fileExists(atPath: pendingURL.path) else { return }
        let pending = try Data(contentsOf: pendingURL)
        guard !pending.isEmpty else {
            try? FileManager.default.removeItem(at: pendingURL)
            return
        }
        try append(pending, to: fileURL)
        try FileManager.default.removeItem(at: pendingURL)
    }

    private func append(_ data: Data, to url: URL, createIfNeeded: Bool = false) throws {
        if createIfNeeded, !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }
}
