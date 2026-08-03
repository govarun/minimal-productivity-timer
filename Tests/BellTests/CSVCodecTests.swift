import Foundation

@main
enum CSVCodecTests {
    @MainActor
    static func main() {
        check(CSVCodec.escape("Ship the timer") == "Ship the timer", "plain goal")
        check(
            CSVCodec.escape("Ship, then say \"done\"") == "\"Ship, then say \"\"done\"\"\"",
            "spreadsheet escaping"
        )

        let instant = Date(timeIntervalSince1970: 1_700_000_000)
        let canceledRecord = FocusRecord(
            startedAt: instant,
            endedAt: instant.addingTimeInterval(754),
            plannedMinutes: 45,
            elapsedSeconds: 754,
            goal: "Ship Bell",
            outcome: .canceled
        )
        let canceledRow = CSVCodec.row(for: canceledRecord)
        check(canceledRow.contains(",45,12m 34s,canceled,Ship Bell\n"), "clean canceled row")

        let completedRecord = FocusRecord(
            startedAt: instant,
            endedAt: instant.addingTimeInterval(45 * 60),
            plannedMinutes: 45,
            elapsedSeconds: 45 * 60,
            goal: "Ship Bell",
            outcome: .completed
        )
        let completedRow = CSVCodec.row(for: completedRecord)
        check(completedRow.contains(",45,45m,completed ✓,Ship Bell\n"), "completed marker")

        check(CSVCodec.formattedDuration(seconds: 0) == "0s", "zero duration")
        check(CSVCodec.formattedDuration(seconds: 59) == "59s", "seconds duration")
        check(CSVCodec.formattedDuration(seconds: 60) == "1m", "minute duration")
        check(CSVCodec.formattedDuration(seconds: 3_667) == "1h 1m 7s", "hour duration")

        let legacy = "2026-01-01T00:00:00Z,2026-01-01T00:00:12Z,30,committed,Ship Bell"
        check(
            CSVCodec.migratedLegacyRow(legacy) == "2026-01-01T00:00:12Z,,30,,started,Ship Bell\n",
            "legacy row migration"
        )

        checkLogMigrationAndAppend(canceledRecord: canceledRecord, completedRecord: completedRecord)

        check(TimerMath.displayMinutes(secondsRemaining: 35 * 60, intervalMinutes: 35) == 35, "starts at 35")
        check(TimerMath.displayMinutes(secondsRemaining: 34 * 60 + 59, intervalMinutes: 35) == 35, "holds the five-minute bucket")
        check(TimerMath.displayMinutes(secondsRemaining: 30 * 60, intervalMinutes: 35) == 30, "changes at the boundary")
        check(TimerMath.displayMinutes(secondsRemaining: 5 * 60, intervalMinutes: 35) == 5, "enters the final-five state")
        check(TimerMath.displayMinutes(secondsRemaining: 0, intervalMinutes: 35) == 0, "ends at zero")
        check(TimerMath.displayMinutes(secondsRemaining: 37 * 60, intervalMinutes: 37) == 37, "custom duration stays exact")
        check(TimerMath.displayMinutes(secondsRemaining: 32 * 60, intervalMinutes: 37) == 32, "custom duration steps after five minutes")

        let progress = TimerMath.steppedProgress(secondsRemaining: 30 * 60, intervalMinutes: 35)
        check(abs(progress - (5.0 / 35.0)) < 0.000_001, "ring steps with the label")
        print("Bell behavior checks passed")
    }

    @MainActor
    private static func checkLogMigrationAndAppend(
        canceledRecord: FocusRecord,
        completedRecord: FocusRecord
    ) {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("BellTests-\(UUID().uuidString)", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }

        let logURL = directory.appendingPathComponent("focus-log.csv")
        let legacyContents = CSVCodec.legacyHeader + "\n"
            + "2026-01-01T00:00:00Z,2026-01-01T00:00:12Z,30,committed,Legacy goal\n"
        try? legacyContents.write(to: logURL, atomically: true, encoding: .utf8)

        let log = FocusLog(fileManager: fileManager, directoryURL: directory)
        let migrated = (try? String(contentsOf: log.fileURL, encoding: .utf8)) ?? ""
        let backup = directory.appendingPathComponent("focus-log-legacy.csv")
        check(migrated.hasPrefix(CSVCodec.header), "new log header")
        check(migrated.contains(",,30,,started,Legacy goal\n"), "legacy status remains honest")
        check(fileManager.fileExists(atPath: backup.path), "legacy backup")

        try? log.append(canceledRecord)
        try? log.append(completedRecord)
        let appended = (try? String(contentsOf: log.fileURL, encoding: .utf8)) ?? ""
        check(appended.contains(",45,12m 34s,canceled,Ship Bell\n"), "canceled append")
        check(appended.contains(",45,45m,completed ✓,Ship Bell\n"), "completed append")
        check(log.latestGoal() == "Ship Bell", "latest goal")
    }

    private static func check(_ condition: @autoclosure () -> Bool, _ label: String) {
        guard condition() else {
            fputs("Failed: \(label)\n", stderr)
            exit(1)
        }
    }
}
