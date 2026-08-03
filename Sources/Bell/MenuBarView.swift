import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var timer: FocusTimer

    var body: some View {
        Text(timer.statusText)

        if !timer.isPromptVisible {
            Button(timer.isRunning ? "Pause" : "Resume") {
                timer.toggleRunning()
            }

            Button("Restart \(timer.intervalMinutes)-minute block") {
                timer.restart()
            }
        }

        Divider()

        SettingsLink {
            Text("Settings…")
        }

        Button("Show focus log") {
            NSWorkspace.shared.activateFileViewerSelecting([timer.log.fileURL])
        }

        Divider()

        Button("Quit Bell") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
