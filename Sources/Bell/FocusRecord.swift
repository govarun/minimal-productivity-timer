import Foundation

struct FocusRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let plannedMinutes: Int
    let elapsedSeconds: Int
    let goal: String
    let outcome: Outcome

    enum Outcome: String, Sendable {
        case completed = "completed ✓"
        case canceled
    }

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        plannedMinutes: Int,
        elapsedSeconds: Int,
        goal: String,
        outcome: Outcome
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedMinutes = plannedMinutes
        self.elapsedSeconds = elapsedSeconds
        self.goal = goal
        self.outcome = outcome
    }
}

enum CSVCodec {
    static let header = "started_at,ended_at,planned_minutes,elapsed,status,goal\n"
    static let legacyHeader = "prompted_at,answered_at,interval_minutes,outcome,goal"

    static func row(for record: FocusRecord) -> String {
        return [
            escape(formattedTimestamp(record.startedAt)),
            escape(formattedTimestamp(record.endedAt)),
            String(record.plannedMinutes),
            formattedDuration(seconds: record.elapsedSeconds),
            record.outcome.rawValue,
            escape(record.goal)
        ].joined(separator: ",") + "\n"
    }

    static func formattedDuration(seconds: Int) -> String {
        let safeSeconds = max(0, seconds)
        guard safeSeconds > 0 else { return "0m" }
        guard safeSeconds >= 60 else { return "<1m" }

        let roundedMinutes = Int((Double(safeSeconds) / 60).rounded())
        let hours = roundedMinutes / 60
        let minutes = roundedMinutes % 60

        if hours > 0, minutes > 0 { return "\(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(minutes)m"
    }

    static func formattedTimestamp(
        _ date: Date,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let zone = timeZone.abbreviation(for: date) ?? timeZone.identifier
        return "\(formatter.string(from: date)) \(zone)"
    }

    static func migratedLegacyRow(_ line: String) -> String? {
        let fields = parseLine(line)
        guard fields.count >= 5 else { return nil }
        return [
            escape(normalizedTimestamp(fields[1])),
            "",
            fields[2],
            "",
            "started",
            escape(fields[4])
        ].joined(separator: ",") + "\n"
    }

    static func normalizedCurrentRow(_ line: String) -> String? {
        let fields = parseLine(line)
        guard fields.count == 6 else { return nil }

        return [
            escape(normalizedTimestamp(fields[0])),
            escape(normalizedTimestamp(fields[1])),
            escape(fields[2]),
            escape(normalizedDuration(fields[3])),
            escape(fields[4]),
            escape(fields[5])
        ].joined(separator: ",") + "\n"
    }

    private static func normalizedTimestamp(_ value: String) -> String {
        guard !value.isEmpty else { return value }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return formattedTimestamp(date)
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) {
            return formattedTimestamp(date)
        }

        return value
    }

    private static func normalizedDuration(_ value: String) -> String {
        guard !value.isEmpty, value != "<1m" else { return value }

        var seconds = 0
        var foundComponent = false
        for component in value.split(separator: " ") {
            guard let suffix = component.last else { continue }
            let number = component.dropLast()
            guard let amount = Int(number) else { continue }

            switch suffix {
            case "h": seconds += amount * 3_600
            case "m": seconds += amount * 60
            case "s": seconds += amount
            default: continue
            }
            foundComponent = true
        }

        return foundComponent ? formattedDuration(seconds: seconds) : value
    }

    static func parseLine(_ line: String) -> [String] {
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

    static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
