import SwiftUI

/// Single source of truth for tracked-time tile coloring, shared by the
/// in-app calendar and the widget so their shades stay identical.
/// Absolute bands: <1h, 1–2h, 2–4h, 4h+.
enum HeatShade {
    static let empty = Color(white: 0.15)

    static func intensity(for duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        switch duration {
        case ..<3600: return 0.25
        case ..<7200: return 0.5
        case ..<14400: return 0.75
        default: return 1
        }
    }

    static func color(for duration: TimeInterval) -> Color {
        let level = intensity(for: duration)
        return level <= 0 ? empty : Color.white.opacity(0.25 + level * 0.75)
    }
}
