import Foundation

struct FocusRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let promptedAt: Date
    let answeredAt: Date
    let intervalMinutes: Int
    let goal: String
    let outcome: Outcome

    enum Outcome: String, Sendable {
        case committed
        case skipped
    }

    init(
        id: UUID = UUID(),
        promptedAt: Date,
        answeredAt: Date,
        intervalMinutes: Int,
        goal: String,
        outcome: Outcome
    ) {
        self.id = id
        self.promptedAt = promptedAt
        self.answeredAt = answeredAt
        self.intervalMinutes = intervalMinutes
        self.goal = goal
        self.outcome = outcome
    }
}

enum CSVCodec {
    static let header = "prompted_at,answered_at,interval_minutes,outcome,goal\n"

    static func row(for record: FocusRecord) -> String {
        let timestamp = ISO8601DateFormatter()
        timestamp.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return [
            timestamp.string(from: record.promptedAt),
            timestamp.string(from: record.answeredAt),
            String(record.intervalMinutes),
            record.outcome.rawValue,
            escape(record.goal)
        ].joined(separator: ",") + "\n"
    }

    static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
