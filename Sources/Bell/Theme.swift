import SwiftUI

enum BellTheme {
    static let black = Color.black
    static let charcoal = Color(white: 0.08)
    static let graphite = Color(white: 0.22)
    static let silver = Color(white: 0.78)
    static let white = Color.white
    static let muted = Color.white.opacity(0.46)
    static let hairline = Color.white.opacity(0.12)
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
