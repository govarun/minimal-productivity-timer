import AppKit
import SwiftUI

struct PromptView: View {
    @EnvironmentObject private var timer: FocusTimer
    @FocusState private var goalFocused: Bool
    @FocusState private var customMinutesFocused: Bool
    @State private var promptHovered = false
    @State private var customMinutesText = "35"
    @State private var customDurationActive = true

    private let quietSize = CGSize(width: 230, height: 216)
    private let promptSize = CGSize(width: 350, height: 126)
    private let durationPresets = [30, 45, 60]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if timer.isPromptVisible {
                prompt
                    .padding(.top, 26)
            } else {
                dial
                    .padding(.top, 9)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 9)
            }

            quitButton
                .padding(.top, timer.isPromptVisible ? 0 : 1)
                .padding(.trailing, timer.isPromptVisible ? 1 : 3)
        }
        .frame(
            width: timer.isPromptVisible ? promptSize.width : quietSize.width,
            height: timer.isPromptVisible ? promptSize.height : quietSize.height
        )
        .background {
            WindowAccessor { window in
                configureWindow(window, contentSize: timer.isPromptVisible ? promptSize : quietSize)
            }
        }
        .onAppear(perform: prepareDurationEditor)
        .onChange(of: timer.isPromptVisible) { _, visible in
            if visible { prepareDurationEditor() }
        }
    }

    private var dial: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(timer.isFinalFiveMinutes ? 0.175 : 0.125))
                .background(GlassMaterial().clipShape(Circle()))

            Circle()
                .stroke(Color.white.opacity(timer.isFinalFiveMinutes ? 0.11 : 0.07), lineWidth: 1)

            Circle()
                .inset(by: 10)
                .stroke(Color.white.opacity(timer.isFinalFiveMinutes ? 0.064 : 0.05), lineWidth: 7)

            Circle()
                .inset(by: 10)
                .trim(from: 0, to: timer.steppedProgress)
                .stroke(
                    Color(white: 0.78).opacity(timer.isFinalFiveMinutes ? 0.42 : 0.29),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 14) {
                Text(timer.quietTimeText)
                    .font(.system(size: 38, weight: .ultraLight, design: .rounded))
                    .tracking(-2.4)
                    .monospacedDigit()
                    .foregroundStyle(Color.white.opacity(timer.isFinalFiveMinutes ? 0.56 : 0.42))

                goalLine
            }
        }
        .frame(width: 198, height: 198)
    }

    private var goalLine: some View {
        Button(action: timer.editCurrentGoal) {
            HStack(spacing: 3) {
                Text("Goal:")
                    .fontWeight(.bold)
                Text(timer.currentGoal.isEmpty ? "—" : timer.currentGoal)
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(Color.white.opacity(timer.isFinalFiveMinutes ? 0.48 : 0.33))
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: 144)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Edit goal and duration")
        .accessibilityLabel("Edit goal and duration")
    }

    private var prompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Highest value driver", text: $timer.draftGoal)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .focused($goalFocused)
                    .onSubmit(submit)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(goalFocused ? 0.34 : 0.20), lineWidth: 1)
                    }

                Button(action: submit) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.90))
                        .frame(width: 44, height: 40)
                        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Save goal")
                .accessibilityLabel("Save goal")
            }

            HStack(spacing: 6) {
                ForEach(durationPresets, id: \.self) { minutes in
                    durationChip(minutes)
                }
                customMinutesField
            }
        }
        .padding(14)
        .frame(width: 350, height: 100)
        .background {
            ZStack {
                GlassMaterial()
                Color.black.opacity(promptIsActive ? 0.58 : 0.07)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(promptIsActive ? 0.22 : 0.12), lineWidth: 1)
        }
        .onHover { promptHovered = $0 }
    }

    private var promptIsActive: Bool {
        promptHovered || goalFocused || customMinutesFocused
    }

    private func durationChip(_ minutes: Int) -> some View {
        let selected = !customDurationActive && timer.draftIntervalMinutes == minutes
        return Button("\(minutes) min") {
            timer.draftIntervalMinutes = minutes
            customDurationActive = false
            customMinutesFocused = false
        }
        .font(.system(size: 10, weight: .semibold, design: .rounded))
        .foregroundStyle(Color.white.opacity(selected ? 0.84 : 0.48))
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(Color.white.opacity(selected ? 0.07 : 0.025), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(selected ? 0.24 : 0.10), lineWidth: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(minutes) minutes")
    }

    private var customMinutesField: some View {
        HStack(spacing: 2) {
            TextField("other", text: $customMinutesText)
                .textFieldStyle(.plain)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.78))
                .focused($customMinutesFocused)
                .onChange(of: customMinutesText) { _, value in
                    guard let minutes = Int(value), (5...240).contains(minutes) else { return }
                    timer.draftIntervalMinutes = minutes
                    customDurationActive = true
                }
                .onSubmit(submit)
                .frame(width: 34)

            Text("min")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.40))
        }
        .padding(.horizontal, 8)
        .frame(width: 70, height: 24)
        .background(Color.white.opacity(customDurationActive ? 0.07 : 0.025), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(customDurationActive ? 0.24 : 0.10), lineWidth: 1)
        }
    }

    private var quitButton: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Color(white: 0.46).opacity(0.88))
                .frame(width: 30, height: 30)
                .contentShape(Circle())
        }
        .buttonStyle(SubtleQuitButtonStyle())
        .help("Quit Bell")
        .accessibilityLabel("Quit Bell")
    }

    private func submit() {
        guard !timer.draftGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        goalFocused = false
        timer.commitGoal()
    }

    private func prepareDurationEditor() {
        let current = timer.draftIntervalMinutes
        customDurationActive = !durationPresets.contains(current)
        customMinutesText = customDurationActive ? "\(current)" : ""
    }

    private func configureWindow(_ window: NSWindow, contentSize: CGSize) {
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let autosaveName = "BellCompanionApproved"
        let savedFrameKey = "NSWindow Frame \(autosaveName)"
        let hasSavedFrame = UserDefaults.standard.string(forKey: savedFrameKey) != nil
        let currentTopRight = NSPoint(x: window.frame.maxX, y: window.frame.maxY)
        let sizeChanged = abs(window.frame.width - contentSize.width) > 0.5 || abs(window.frame.height - contentSize.height) > 0.5

        if sizeChanged {
            window.setContentSize(contentSize)
            if hasSavedFrame {
                window.setFrameOrigin(NSPoint(x: currentTopRight.x - window.frame.width, y: currentTopRight.y - window.frame.height))
            }
        }

        window.setFrameAutosaveName(autosaveName)
        if !hasSavedFrame, let screen = window.screen ?? NSScreen.main {
            let visible = screen.visibleFrame
            window.setFrameOrigin(NSPoint(x: visible.maxX - window.frame.width - 24, y: visible.maxY - window.frame.height - 24))
        }
        window.orderFrontRegardless()
    }
}

private struct SubtleQuitButtonStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                hovering ? Color.white.opacity(0.10) : Color.clear,
                in: Circle()
            )
            .opacity(hovering ? 1 : 0.82)
            .onHover { hovering = $0 }
    }
}
