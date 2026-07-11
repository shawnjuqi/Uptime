import WidgetKit
import SwiftUI

struct UptimeWidget: Widget {
    let kind: String = "UptimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UptimeTimelineProvider()) { entry in
            UptimeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Uptime")
        .description("Track your work activity")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct UptimeTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> UptimeEntry {
        let calendar = Calendar.current
        let today = Date()

        // Create a realistic pattern of work days with varied durations
        var sampleDurations: [Date: TimeInterval] = [:]
        for daysAgo in 0..<120 {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                if daysAgo % 3 == 0 || daysAgo % 7 == 1 || daysAgo % 5 == 2 {
                    let hours = Double((daysAgo % 5) + 1) // 1…5h so bands show
                    sampleDurations[calendar.startOfDay(for: date)] = hours * 3600
                }
            }
        }

        return UptimeEntry(date: today, todayHours: 3.5, dailyDurations: sampleDurations)
    }

    func getSnapshot(in context: Context, completion: @escaping (UptimeEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UptimeEntry>) -> Void) {
        let currentDate = Date()
        let entry = makeEntry(for: currentDate)

        // Refresh every hour with safe date calculation
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func makeEntry(for date: Date) -> UptimeEntry {
        let calendar = Calendar.current
        let raw = SharedStorage.getDailyDurations()
        var normalized: [Date: TimeInterval] = [:]
        for (day, duration) in raw {
            normalized[calendar.startOfDay(for: day)] = duration
        }
        return UptimeEntry(
            date: date,
            todayHours: todayHours(),
            dailyDurations: normalized
        )
    }

    /// Stored today-total, discarded if it was written on an earlier day so
    /// the ring reads 0 at the start of a fresh day instead of yesterday's.
    private func todayHours() -> Double {
        guard let updated = SharedStorage.getLastUpdated(),
              Calendar.current.isDateInToday(updated) else {
            return 0
        }
        return SharedStorage.getTodayHours()
    }
}

struct UptimeEntry: TimelineEntry {
    let date: Date
    let todayHours: Double
    let dailyDurations: [Date: TimeInterval]
}

struct UptimeWidgetEntryView: View {
    var entry: UptimeTimelineProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    /// The ring represents the full 24-hour day, so it only fills completely
    /// at 24h tracked.
    private let dailyGoalHours: Double = 24

    var body: some View {
        content
            .containerBackground(Color.black, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        switch widgetFamily {
        case .systemSmall:
            ring

        case .systemMedium:
            HStack(spacing: 12) {
                ring
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                // 7-column grid fits the near-square right half better than 16
                grid(.systemSmall)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        case .systemLarge:
            VStack(spacing: 12) {
                ring
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                grid(.systemLarge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        default:
            grid(widgetFamily)
        }
    }

    private var ring: some View {
        WidgetProgressRing(hours: entry.todayHours, goalHours: dailyGoalHours)
    }

    private func grid(_ family: WidgetFamily) -> some View {
        ContributionGridView(
            currentDate: entry.date,
            dailyDurations: entry.dailyDurations,
            widgetFamily: family
        )
    }
}

struct WidgetProgressRing: View {
    let hours: Double
    let goalHours: Double

    private var progress: Double {
        guard goalHours > 0 else { return 0 }
        return min(1, max(0, hours / goalHours))
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth = max(3, size * 0.07)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: size * 0.02) {
                    Text(hoursText)
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("Today")
                        .font(.system(size: size * 0.075, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(size * 0.22)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var hoursText: String {
        let totalMinutes = Int((hours * 60).rounded())
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

struct ContributionGridView: View {
    let currentDate: Date
    let dailyDurations: [Date: TimeInterval]
    let widgetFamily: WidgetFamily
    private let calendar = Calendar.current
    
    // Number of rows (days of week)
    private let rows = 7
    
    // Columns based on widget size
    private var columns: Int {
        let cols: Int
        switch widgetFamily {
        case .systemSmall:
            cols = 7
        case .systemMedium:
            cols = 16
        case .systemLarge:
            cols = 16
        case .systemExtraLarge:
            cols = 24
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            cols = 7
        @unknown default:
            cols = 14
        }
        // Ensure columns is always positive
        return max(cols, 1)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(geometry.size.width, 1)
            let availableHeight = max(geometry.size.height, 1)
            
            // Ensure columns and rows are valid (columns already validated in computed property)
            let validColumns = max(columns, 1)
            let validRows = max(rows, 1)
            
            // Calculate spacing and square size
            let spacing: CGFloat = 3
            let totalSpacingWidth = spacing * CGFloat(max(validColumns - 1, 0))
            let totalSpacingHeight = spacing * CGFloat(max(validRows - 1, 0))
            
            // Calculate square size to fill available space with division by zero protection
            let squareSizeByWidth = max((availableWidth - totalSpacingWidth) / CGFloat(validColumns), 0)
            let squareSizeByHeight = max((availableHeight - totalSpacingHeight) / CGFloat(validRows), 0)
            let squareSize = max(min(squareSizeByWidth, squareSizeByHeight), 1)
            
            // Center the grid
            let usedWidth = (squareSize * CGFloat(validColumns)) + totalSpacingWidth
            let usedHeight = (squareSize * CGFloat(validRows)) + totalSpacingHeight
            let offsetX = (availableWidth - usedWidth) / 2
            let offsetY = (availableHeight - usedHeight) / 2
            
            // Build the grid - columns are weeks, rows are days of week
            HStack(spacing: spacing) {
                ForEach(0..<validColumns, id: \.self) { columnIndex in
                    VStack(spacing: spacing) {
                        ForEach(0..<validRows, id: \.self) { rowIndex in
                            let date = dateFor(column: columnIndex, row: rowIndex)
                            // Use optional binding instead of force unwrap
                            if let date = date {
                                ContributionSquare(
                                    duration: dailyDurations[calendar.startOfDay(for: date)] ?? 0,
                                    isToday: calendar.isDateInToday(date),
                                    isFutureDate: date > currentDate,
                                    size: squareSize
                                )
                            } else {
                                // Fallback for invalid dates
                                ContributionSquare(
                                    duration: 0,
                                    isToday: false,
                                    isFutureDate: false,
                                    size: squareSize
                                )
                            }
                        }
                    }
                }
            }
            .frame(width: usedWidth, height: usedHeight)
            .offset(x: offsetX, y: offsetY)
        }
        .padding(2)
    }
    
    // Today is the last (bottom-right) square; every cell above or to the
    // left is one day earlier — a rolling window of the last (columns*7)
    // days ending today, with no trailing future cells.
    private func dateFor(column: Int, row: Int) -> Date? {
        let offset = (columns - 1 - column) * 7 + (rows - 1 - row)
        return calendar.date(byAdding: .day, value: -offset, to: currentDate)
    }
}

struct ContributionSquare: View {
    let duration: TimeInterval
    let isToday: Bool
    let isFutureDate: Bool
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.2)
            .fill(squareColor)
            .frame(width: size, height: size)
    }

    private var squareColor: Color {
        // Same absolute-band shading as the in-app calendar
        isFutureDate ? HeatShade.empty : HeatShade.color(for: duration)
    }
}

// Helper to generate sample work days for previews
private func sampleDurations(daysAgoList: [Int]) -> [Date: TimeInterval] {
    let calendar = Calendar.current
    let today = Date()
    var result: [Date: TimeInterval] = [:]
    for daysAgo in daysAgoList {
        guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
        // Cycle 0.5h → 5h so all bands appear in the preview
        let hours = Double(daysAgo % 5) + 0.5
        result[calendar.startOfDay(for: date)] = hours * 3600
    }
    return result
}

// macOS doesn't support the widget canvas (#Preview(as:)), so preview the
// widget's SwiftUI views directly at approximate widget point sizes.

#Preview("Small — ring") {
    WidgetProgressRing(hours: 3.5, goalHours: 24)
        .padding(16)
        .frame(width: 170, height: 170)
        .background(Color.black)
}

#Preview("Medium — ring + grid") {
    HStack(spacing: 12) {
        WidgetProgressRing(hours: 3.5, goalHours: 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        ContributionGridView(
            currentDate: Date(),
            dailyDurations: sampleDurations(daysAgoList: [0, 1, 3, 4, 6, 8, 9, 11, 13, 15, 16, 18, 20, 22, 24, 26, 28, 30, 33, 35, 38, 40, 43, 45, 48]),
            widgetFamily: .systemSmall
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .padding(12)
    .frame(width: 345, height: 170)
    .background(Color.black)
}

#Preview("Large — ring + grid") {
    VStack(spacing: 12) {
        WidgetProgressRing(hours: 5.25, goalHours: 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        ContributionGridView(
            currentDate: Date(),
            dailyDurations: sampleDurations(daysAgoList: [0, 1, 3, 4, 6, 8, 9, 11, 13, 15, 16, 18, 20, 22, 24, 26, 28, 30, 33, 35, 38, 40, 43, 45, 48, 50, 55, 60, 65, 70]),
            widgetFamily: .systemLarge
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .padding(16)
    .frame(width: 345, height: 345)
    .background(Color.black)
}
