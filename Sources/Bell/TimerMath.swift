import Foundation

enum TimerMath {
    static func displayMinutes(secondsRemaining: Int, intervalMinutes: Int) -> Int {
        guard secondsRemaining > 0 else { return 0 }
        let totalSeconds = max(intervalMinutes, 1) * 60
        let elapsedSeconds = max(totalSeconds - secondsRemaining, 0)
        let completedFiveMinuteBlocks = elapsedSeconds / 300
        return max(intervalMinutes - completedFiveMinuteBlocks * 5, 1)
    }

    static func steppedProgress(secondsRemaining: Int, intervalMinutes: Int) -> Double {
        let total = max(intervalMinutes, 1)
        let displayedRemaining = min(
            displayMinutes(secondsRemaining: secondsRemaining, intervalMinutes: intervalMinutes),
            total
        )
        return min(max(Double(total - displayedRemaining) / Double(total), 0), 1)
    }
}
