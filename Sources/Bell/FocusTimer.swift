import Combine
import Foundation

@MainActor
final class FocusTimer: ObservableObject {
    enum DefaultsKey {
        static let interval = "intervalMinutes"
        static let currentGoal = "currentGoal"
        static let behaviorVersion = "behaviorVersion"
    }

    @Published var intervalMinutes: Int {
        didSet {
            let clamped = min(max(intervalMinutes, 5), 240)
            if intervalMinutes != clamped {
                intervalMinutes = clamped
                return
            }
            UserDefaults.standard.set(intervalMinutes, forKey: DefaultsKey.interval)
            if isRunning && !isPromptVisible { resetCountdown() }
        }
    }

    @Published private(set) var secondsRemaining: Int
    @Published private(set) var isRunning = true
    @Published private(set) var isPromptVisible = false
    @Published private(set) var promptedAt: Date?
    @Published private(set) var recentRecords: [FocusRecord] = []
    @Published private(set) var currentGoal: String
    @Published var draftGoal = ""
    @Published var draftIntervalMinutes: Int
    @Published var lastError: String?

    let log: FocusLog
    private var ticker: AnyCancellable?

    init() {
        let focusLog = FocusLog()
        log = focusLog

        let defaults = UserDefaults.standard
        let behaviorVersion = defaults.integer(forKey: DefaultsKey.behaviorVersion)
        let savedInterval = defaults.integer(forKey: DefaultsKey.interval)
        let interval = behaviorVersion < 1 ? 35 : (savedInterval == 0 ? 35 : savedInterval)
        defaults.set(1, forKey: DefaultsKey.behaviorVersion)
        defaults.set(interval, forKey: DefaultsKey.interval)

        intervalMinutes = interval
        secondsRemaining = interval * 60
        draftIntervalMinutes = interval
        currentGoal = defaults.string(forKey: DefaultsKey.currentGoal)
            ?? focusLog.latestCommittedGoal()
            ?? ""
        startTicker()

        if ProcessInfo.processInfo.arguments.contains("--show-prompt") {
            DispatchQueue.main.async { [weak self] in self?.ringNow() }
        }
    }

    /// Remaining time, rounded up to the next five-minute boundary.
    var displayMinutes: Int {
        TimerMath.displayMinutes(
            secondsRemaining: secondsRemaining,
            intervalMinutes: intervalMinutes
        )
    }

    var quietTimeText: String { "\(displayMinutes)m" }

    /// The ring advances only when the displayed five-minute value changes.
    var steppedProgress: Double {
        TimerMath.steppedProgress(
            secondsRemaining: secondsRemaining,
            intervalMinutes: intervalMinutes
        )
    }

    var isFinalFiveMinutes: Bool {
        secondsRemaining > 0 && secondsRemaining <= 5 * 60
    }

    var statusText: String {
        if isPromptVisible { return "Waiting for the next focus goal" }
        if !isRunning { return "Paused at \(quietTimeText)" }
        return "\(quietTimeText) remaining"
    }

    func toggleRunning() {
        guard !isPromptVisible else { return }
        isRunning.toggle()
    }

    func restart() {
        isPromptVisible = false
        draftGoal = ""
        draftIntervalMinutes = intervalMinutes
        resetCountdown()
        isRunning = true
    }

    func ringNow() {
        guard !isPromptVisible else { return }
        promptedAt = Date()
        secondsRemaining = 0
        draftGoal = ""
        draftIntervalMinutes = intervalMinutes
        isPromptVisible = true
        isRunning = false
    }

    func editCurrentGoal() {
        guard !isPromptVisible else { return }
        promptedAt = Date()
        draftGoal = currentGoal
        draftIntervalMinutes = intervalMinutes
        isPromptVisible = true
        isRunning = false
    }

    func commitGoal() {
        let cleaned = draftGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        intervalMinutes = min(max(draftIntervalMinutes, 5), 240)

        let record = FocusRecord(
            promptedAt: promptedAt ?? Date(),
            answeredAt: Date(),
            intervalMinutes: intervalMinutes,
            goal: cleaned,
            outcome: .committed
        )

        do {
            try log.append(record)
            recentRecords.insert(record, at: 0)
            recentRecords = Array(recentRecords.prefix(6))
            lastError = nil
        } catch {
            // FocusLog has already preserved the row for a later retry.
            lastError = "The row is saved locally and will be retried."
        }

        currentGoal = cleaned
        UserDefaults.standard.set(cleaned, forKey: DefaultsKey.currentGoal)
        isPromptVisible = false
        draftGoal = ""
        resetCountdown()
        isRunning = true
    }

    private func resetCountdown() {
        secondsRemaining = intervalMinutes * 60
    }

    private func startTicker() {
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard isRunning, !isPromptVisible else { return }
        if secondsRemaining > 1 {
            secondsRemaining -= 1
        } else {
            ringNow()
        }
    }
}
