import Foundation

@MainActor
final class FocusLog {
    let fileURL: URL
    private let pendingURL: URL
    private let legacyBackupURL: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default, directoryURL: URL? = nil) {
        self.fileManager = fileManager
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = directoryURL ?? base.appendingPathComponent("Bell", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("focus-log.csv")
        pendingURL = directory.appendingPathComponent("pending-focus-log.csv")
        legacyBackupURL = directory.appendingPathComponent("focus-log-legacy.csv")

        if !fileManager.fileExists(atPath: fileURL.path) {
            try? CSVCodec.header.write(to: fileURL, atomically: true, encoding: .utf8)
        } else {
            migrateLegacyLogIfNeeded()
        }
        normalizeCurrentLogIfNeeded()
        migratePendingRowsIfNeeded()
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

    func latestGoal() -> String? {
        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else { return nil }
        for line in contents.split(whereSeparator: \.isNewline).dropFirst().reversed() {
            let fields = CSVCodec.parseLine(String(line))
            let goal = fields.count >= 6 ? fields[5] : (fields.count >= 5 ? fields[4] : "")
            if !goal.isEmpty { return goal }
        }
        return nil
    }

    private func migrateLegacyLogIfNeeded() {
        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else { return }
        let lines = contents.split(whereSeparator: \.isNewline).map(String.init)
        guard lines.first == CSVCodec.legacyHeader else { return }

        if !fileManager.fileExists(atPath: legacyBackupURL.path) {
            try? fileManager.copyItem(at: fileURL, to: legacyBackupURL)
        }

        let migratedRows = lines.dropFirst().compactMap(CSVCodec.migratedLegacyRow)
        let migratedContents = CSVCodec.header + migratedRows.joined()
        try? migratedContents.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func migratePendingRowsIfNeeded() {
        guard
            fileManager.fileExists(atPath: pendingURL.path),
            let contents = try? String(contentsOf: pendingURL, encoding: .utf8)
        else { return }

        let lines = contents.split(whereSeparator: \.isNewline).map(String.init)
        let migratedRows = lines.compactMap { line -> String? in
            let fields = CSVCodec.parseLine(line)
            return fields.count == 5
                ? CSVCodec.migratedLegacyRow(line)
                : CSVCodec.normalizedCurrentRow(line)
        }
        let normalizedContents = migratedRows.joined()
        if normalizedContents != contents {
            try? normalizedContents.write(to: pendingURL, atomically: true, encoding: .utf8)
        }
    }

    private func normalizeCurrentLogIfNeeded() {
        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else { return }
        let lines = contents.split(whereSeparator: \.isNewline).map(String.init)
        guard lines.first == CSVCodec.header.trimmingCharacters(in: .newlines) else { return }

        let normalizedRows = lines.dropFirst().compactMap(CSVCodec.normalizedCurrentRow)
        let normalizedContents = CSVCodec.header + normalizedRows.joined()
        if normalizedContents != contents {
            try? normalizedContents.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    private func flushPendingRows() throws {
        guard fileManager.fileExists(atPath: pendingURL.path) else { return }
        let pending = try Data(contentsOf: pendingURL)
        guard !pending.isEmpty else {
            try? fileManager.removeItem(at: pendingURL)
            return
        }
        try append(pending, to: fileURL)
        try fileManager.removeItem(at: pendingURL)
    }

    private func append(_ data: Data, to url: URL, createIfNeeded: Bool = false) throws {
        if createIfNeeded, !fileManager.fileExists(atPath: url.path) {
            fileManager.createFile(atPath: url.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }
}
