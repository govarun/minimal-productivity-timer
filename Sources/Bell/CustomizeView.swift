import AppKit
import SwiftUI

struct CustomizeView: View {
    @EnvironmentObject private var timer: FocusTimer

    private let presets = [25, 30, 35, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 5) {
                Text("BELL")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(Color.white.opacity(0.42))
                Text("Focus block")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.94))
            }

            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { minutes in
                    Button("\(minutes)m") {
                        timer.intervalMinutes = minutes
                    }
                    .buttonStyle(DurationButtonStyle(selected: timer.intervalMinutes == minutes))
                }
            }

            Stepper(
                "Every \(timer.intervalMinutes) minutes",
                value: $timer.intervalMinutes,
                in: 5...240,
                step: 5
            )
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.72))

            Divider()
                .overlay(Color.white.opacity(0.10))

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Local focus log")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.78))
                    Text(timer.log.fileURL.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.36))
                        .lineLimit(1)
                }
                Spacer()
                Button("Show") {
                    NSWorkspace.shared.activateFileViewerSelecting([timer.log.fileURL])
                }
            }

            Text("Silent. Local. Five-minute display changes only.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.38))
        }
        .padding(28)
        .frame(width: 490, height: 310)
        .background(BellTheme.charcoal)
    }
}

private struct DurationButtonStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(selected ? Color.black : Color.white.opacity(0.68))
            .frame(width: 70, height: 34)
            .background(
                selected ? Color.white.opacity(0.82) : Color.white.opacity(configuration.isPressed ? 0.10 : 0.05),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                if !selected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                }
            }
    }
}
