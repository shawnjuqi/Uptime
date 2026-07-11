import SwiftUI

enum StatsTypography {
    /// Single type size for all Stats copy (hero clock digits stay larger).
    static let size: CGFloat = 15
    static let font: Font = .system(size: size)
    static let valueFont: Font = .system(size: size, weight: .semibold)
}

struct StatsView: View {
    let viewModel: StatsViewModel
    
    private let contentWidth: CGFloat = 520
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Hero stays full-width — it's the focal point, not a peer metric
                StatsCard {
                    StatsTodayHeroView(duration: viewModel.todayDuration)
                        .frame(maxWidth: .infinity)
                }
                
                // Comparable totals: side-by-side so you can scan them against each other
                HStack(alignment: .top, spacing: 12) {
                    StatsCard {
                        StatsStatBlock(
                            label: "This week",
                            value: Self.formatCompact(viewModel.thisWeekDuration)
                        )
                    }
                    
                    StatsCard {
                        StatsStatBlock(
                            label: "Last week",
                            value: Self.formatCompact(viewModel.lastWeekComparableDuration)
                        )
                    }
                }
                
                StatsCard {
                    HStack {
                        Text("Streak")
                            .font(StatsTypography.font)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text(Self.streakText(viewModel.streak))
                            .font(StatsTypography.valueFont)
                            .foregroundStyle(.white)
                    }
                }
                
                StatsCard {
                    StatsLast7DaysChart(
                        days: viewModel.last7Days,
                        averageDuration: viewModel.last7DaysAverage,
                        formatDuration: Self.formatCompact
                    )
                }
            }
            .frame(maxWidth: contentWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            viewModel.refresh()
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            viewModel.refresh()
        }
    }
    
    static func formatCompact(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(timeInterval.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }
    
    static func streakText(_ streak: Int) -> String {
        if streak <= 0 {
            return "None"
        }
        return streak == 1 ? "1 day" : "\(streak) days"
    }
}

/// Label-above-value block for compact side-by-side cards
struct StatsStatBlock: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(StatsTypography.font)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(StatsTypography.valueFont)
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatsTodayHeroView: View {
    let duration: TimeInterval
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Time Tracked Today")
                .font(StatsTypography.font)
                .foregroundStyle(.white.opacity(0.7))
            
            let totalSeconds = Int(duration)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                timeSegment(String(format: "%02d", hours), label: "hr")
                colonView
                timeSegment(String(format: "%02d", minutes), label: "min")
                colonView
                timeSegment(String(format: "%02d", seconds), label: "sec")
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var colonView: some View {
        Text(":")
            .font(.system(size: 64, design: .monospaced))
            .bold()
            .foregroundStyle(.white)
    }
    
    private func timeSegment(_ digits: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(StatsTypography.font)
                .foregroundStyle(.white.opacity(0.7))
            Text(digits)
                .font(.system(size: 64, design: .monospaced))
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
        }
    }
}
