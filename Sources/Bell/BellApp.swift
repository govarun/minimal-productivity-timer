import SwiftUI

@main
struct BellApp: App {
    @StateObject private var timer = FocusTimer()

    var body: some Scene {
        Window("Bell", id: "overlay") {
            PromptView()
                .environmentObject(timer)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .appTermination) {
                Button("Quit Bell", action: timer.quit)
                    .keyboardShortcut("q")
            }
        }

        Settings {
            CustomizeView()
                .environmentObject(timer)
                .preferredColorScheme(.dark)
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(timer)
        } label: {
            Text(timer.isPromptVisible ? "→" : timer.quietTimeText)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.menu)
    }
}
