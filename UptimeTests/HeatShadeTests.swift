import Testing
import Foundation
@testable import Uptime

/// HeatShade is the single source of truth for tile coloring shared by the app
/// and the widget, so the band boundaries (<1h, 1–2h, 2–4h, 4h+) are pinned
/// exactly — including the edges, where an off-by-one would recolor tiles.
struct HeatShadeTests {
    @Test func zeroDurationHasNoIntensity() {
        #expect(HeatShade.intensity(for: 0) == 0)
    }

    @Test func negativeDurationHasNoIntensity() {
        #expect(HeatShade.intensity(for: -100) == 0)
    }

    @Test(arguments: [
        (1.0, 0.25),        // just above zero → first band
        (3599.0, 0.25),     // one second below 1h
        (3600.0, 0.5),      // exactly 1h → second band
        (7199.0, 0.5),      // one second below 2h
        (7200.0, 0.75),     // exactly 2h → third band
        (14399.0, 0.75),    // one second below 4h
        (14400.0, 1.0),     // exactly 4h → top band
        (100000.0, 1.0),    // far above 4h stays capped
    ])
    func bandBoundaries(duration: Double, expected: Double) {
        #expect(HeatShade.intensity(for: duration) == expected)
    }

    @Test func colorIsEmptyForZeroAndOpaqueForFullBand() {
        #expect(HeatShade.color(for: 0) == HeatShade.empty)
        #expect(HeatShade.color(for: 14400) != HeatShade.empty)
    }
}
