import AppKit
import Combine
import Foundation

@MainActor
final class FocusTimer: ObservableObject {
    private struct ActiveBlock {
        let startedAt: Date
        let plannedMinutes: Int
        let goal: String
    }

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
            if isRunning && !isPromptVisible {
                let now = Date()
                finishActiveBlock(as: .canceled, at: now)
                resetCountdown()
                beginActiveBlock(at: now)
            }
        }
    }

    @Published private(set) var secondsRemaining: Int
    @Published private(set) var isRunning = true
    @Published private(set) var isPromptVisible = false
    @Published private(set) var recentRecords: [FocusRecord] = []
    @Published private(set) var currentGoal: String
    @Published var draftGoal = ""
    @Published var draftIntervalMinutes: Int
    @Published var lastError: String?

    let log: FocusLog
    private var ticker: AnyCancellable?
    private var activeBlock: ActiveBlock?

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
            ?? focusLog.latestGoal()
            ?? ""
        startTicker()
        beginActiveBlock(at: Date())

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
        let now = Date()
        finishActiveBlock(as: .canceled, at: now)
        isPromptVisible = false
        draftGoal = ""
        draftIntervalMinutes = intervalMinutes
        resetCountdown()
        isRunning = true
        beginActiveBlock(at: now)
    }

    func ringNow() {
        guard !isPromptVisible else { return }
        finishActiveBlock(as: .canceled, at: Date())
        secondsRemaining = 0
        presentPrompt(goal: "")
    }

    func editCurrentGoal() {
        guard !isPromptVisible else { return }
        finishActiveBlock(as: .canceled, at: Date())
        presentPrompt(goal: currentGoal)
    }

    func quit() {
        finishActiveBlock(as: .canceled, at: Date())
        NSApplication.shared.terminate(nil)
    }

    func commitGoal() {
        let cleaned = draftGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        intervalMinutes = min(max(draftIntervalMinutes, 5), 240)

        currentGoal = cleaned
        UserDefaults.standard.set(cleaned, forKey: DefaultsKey.currentGoal)
        isPromptVisible = false
        draftGoal = ""
        resetCountdown()
        isRunning = true
        beginActiveBlock(at: Date())
    }

    private func resetCountdown() {
        secondsRemaining = intervalMinutes * 60
    }

    private func beginActiveBlock(at date: Date) {
        let cleanedGoal = currentGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedGoal.isEmpty else {
            activeBlock = nil
            return
        }
        activeBlock = ActiveBlock(
            startedAt: date,
            plannedMinutes: intervalMinutes,
            goal: cleanedGoal
        )
    }

    private func finishActiveBlock(as outcome: FocusRecord.Outcome, at date: Date) {
        guard let activeBlock else { return }
        self.activeBlock = nil

        let plannedSeconds = activeBlock.plannedMinutes * 60
        let elapsedSeconds = outcome == .completed
            ? plannedSeconds
            : max(0, min(plannedSeconds, plannedSeconds - secondsRemaining))

        // Ignore zero-length interruptions so quick settings changes do not pollute the log.
        guard outcome == .completed || elapsedSeconds > 0 else { return }

        let record = FocusRecord(
            startedAt: activeBlock.startedAt,
            endedAt: date,
            plannedMinutes: activeBlock.plannedMinutes,
            elapsedSeconds: elapsedSeconds,
            goal: activeBlock.goal,
            outcome: outcome
        )
        persist(record)
    }

    private func persist(_ record: FocusRecord) {
        do {
            try log.append(record)
            recentRecords.insert(record, at: 0)
            recentRecords = Array(recentRecords.prefix(6))
            lastError = nil
        } catch {
            // FocusLog has already preserved the row for a later retry.
            lastError = "The row is saved locally and will be retried."
        }
    }

    private func presentPrompt(goal: String) {
        draftGoal = goal
        draftIntervalMinutes = intervalMinutes
        isPromptVisible = true
        isRunning = false
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
            secondsRemaining = 0
            finishActiveBlock(as: .completed, at: Date())
            presentPrompt(goal: "")
        }
    }
}
