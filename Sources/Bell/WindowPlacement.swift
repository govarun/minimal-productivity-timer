import CoreGraphics
import Foundation

enum WindowPlacement {
    static func bestVisibleFrame(
        for windowFrame: CGRect,
        screenFrames: [CGRect],
        fallback: CGRect?
    ) -> CGRect? {
        guard !screenFrames.isEmpty else { return fallback }

        let bestMatch = screenFrames.max { lhs, rhs in
            intersectionArea(windowFrame, lhs) < intersectionArea(windowFrame, rhs)
        }

        guard let bestMatch else { return fallback }
        return intersectionArea(windowFrame, bestMatch) > 0 ? bestMatch : (fallback ?? bestMatch)
    }

    static func clampedOrigin(for windowFrame: CGRect, within visibleFrame: CGRect) -> CGPoint {
        let maximumX = max(visibleFrame.minX, visibleFrame.maxX - windowFrame.width)
        let maximumY = max(visibleFrame.minY, visibleFrame.maxY - windowFrame.height)

        return CGPoint(
            x: min(max(windowFrame.minX, visibleFrame.minX), maximumX),
            y: min(max(windowFrame.minY, visibleFrame.minY), maximumY)
        )
    }

    private static func intersectionArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull else { return 0 }
        return intersection.width * intersection.height
    }
}
