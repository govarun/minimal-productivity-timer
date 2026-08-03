import Foundation

@main
enum CSVCodecTests {
    static func main() {
        check(CSVCodec.escape("Ship the timer") == "Ship the timer", "plain goal")
        check(
            CSVCodec.escape("Ship, then say \"done\"") == "\"Ship, then say \"\"done\"\"\"",
            "spreadsheet escaping"
        )

        let instant = Date(timeIntervalSince1970: 1_700_000_000)
        let record = FocusRecord(
            promptedAt: instant,
            answeredAt: instant.addingTimeInterval(12),
            intervalMinutes: 45,
            goal: "Ship Bell",
            outcome: .committed
        )
        let row = CSVCodec.row(for: record)
        check(row.contains(",45,committed,Ship Bell\n"), "stable CSV columns")

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

    private static func check(_ condition: @autoclosure () -> Bool, _ label: String) {
        guard condition() else {
            fputs("Failed: \(label)\n", stderr)
            exit(1)
        }
    }
}
