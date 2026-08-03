import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: make-icon.swift output.png\n", stderr)
    exit(2)
}

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()
guard let context = NSGraphicsContext.current else { exit(1) }
context.imageInterpolation = .high

let canvas = NSRect(origin: .zero, size: size)
let tile = NSBezierPath(roundedRect: canvas.insetBy(dx: 42, dy: 42), xRadius: 215, yRadius: 215)
NSGradient(colors: [
    NSColor(calibratedRed: 0.035, green: 0.055, blue: 0.12, alpha: 1),
    NSColor(calibratedRed: 0.075, green: 0.12, blue: 0.22, alpha: 1)
])!.draw(in: tile, angle: -55)

context.saveGraphicsState()
let glow = NSShadow()
glow.shadowColor = NSColor(calibratedRed: 0.47, green: 0.86, blue: 0.91, alpha: 0.42)
glow.shadowBlurRadius = 70
glow.shadowOffset = .zero
glow.set()
NSColor(calibratedRed: 0.47, green: 0.86, blue: 0.91, alpha: 0.15).setFill()
NSBezierPath(ovalIn: NSRect(x: 208, y: 208, width: 608, height: 608)).fill()
context.restoreGraphicsState()

let orbit = NSBezierPath(ovalIn: NSRect(x: 178, y: 178, width: 668, height: 668))
orbit.lineWidth = 26
NSColor(calibratedRed: 0.47, green: 0.86, blue: 0.91, alpha: 0.72).setStroke()
orbit.stroke()

let dot = NSBezierPath(ovalIn: NSRect(x: 489, y: 822, width: 46, height: 46))
NSColor(calibratedRed: 0.47, green: 0.86, blue: 0.91, alpha: 1).setFill()
dot.fill()

if let bell = NSImage(
    systemSymbolName: "bell.fill",
    accessibilityDescription: "Bell"
)?.withSymbolConfiguration(
    NSImage.SymbolConfiguration(pointSize: 440, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
) {
    let bellRect = NSRect(x: 292, y: 278, width: 440, height: 440)
    bell.draw(in: bellRect, from: .zero, operation: .sourceOver, fraction: 1)
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not render icon\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
