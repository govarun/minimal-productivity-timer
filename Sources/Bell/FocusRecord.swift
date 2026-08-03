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
        let timestamp = ISO8601DateFormatter()
        timestamp.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return [
            timestamp.string(from: record.startedAt),
            timestamp.string(from: record.endedAt),
            String(record.plannedMinutes),
            formattedDuration(seconds: record.elapsedSeconds),
            record.outcome.rawValue,
            escape(record.goal)
        ].joined(separator: ",") + "\n"
    }

    static func formattedDuration(seconds: Int) -> String {
        let safeSeconds = max(0, seconds)
        let hours = safeSeconds / 3_600
        let minutes = (safeSeconds % 3_600) / 60
        let remainingSeconds = safeSeconds % 60
        var parts: [String] = []

        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 { parts.append("\(minutes)m") }
        if remainingSeconds > 0 || parts.isEmpty { parts.append("\(remainingSeconds)s") }

        return parts.joined(separator: " ")
    }

    static func migratedLegacyRow(_ line: String) -> String? {
        let fields = parseLine(line)
        guard fields.count >= 5 else { return nil }
        return [
            fields[1],
            "",
            fields[2],
            "",
            "started",
            escape(fields[4])
        ].joined(separator: ",") + "\n"
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
