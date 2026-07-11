import SwiftUI

struct StatsLast7DaysChart: View {
    let days: [StatsDayTotal]
    let averageDuration: TimeInterval
    let formatDuration: (TimeInterval) -> String
    
    /// Oldest → newest so the chart reads left to right in time.
    private var chartDays: [StatsDayTotal] {
        Array(days.reversed())
    }
    
    /// Hybrid scale: at least 2h so tiny days don't fill the chart;
    /// grows with the peak day when someone exceeds that floor.
    private let scaleFloor: TimeInterval = 2 * 60 * 60
    
    private var maxDuration: TimeInterval {
        let peak = chartDays.map(\.duration).max() ?? 0
        return max(peak, scaleFloor)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Text(formatDuration(averageDuration))
                    .font(StatsTypography.valueFont)
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text(" per day over the last 7 days")
                    .font(StatsTypography.font)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(chartDays) { day in
                    StatsDayBarColumn(
                        day: day,
                        maxDuration: maxDuration,
                        formatDuration: formatDuration
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96, alignment: .bottom)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Last 7 days")
        }
    }
}
