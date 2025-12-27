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
        // Generate sample work days for placeholder
        let calendar = Calendar.current
        let today = Date()
        var sampleWorkDays = Set<Date>()
        
        // Create a realistic pattern of work days
        for daysAgo in 0..<120 {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                // Random-ish pattern based on day number
                if daysAgo % 3 == 0 || daysAgo % 7 == 1 || daysAgo % 5 == 2 {
                    sampleWorkDays.insert(calendar.startOfDay(for: date))
                }
            }
        }
        
        return UptimeEntry(date: today, workDays: sampleWorkDays)
    }

    func getSnapshot(in context: Context, completion: @escaping (UptimeEntry) -> Void) {
        let today = Date()
        let calendar = Calendar.current
        let workDays = SharedStorage.getWorkDays()
        let entry = UptimeEntry(
            date: today,
            workDays: Set(workDays.map { calendar.startOfDay(for: $0) })
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UptimeEntry>) -> Void) {
        let currentDate = Date()
        let calendar = Calendar.current
        let workDays = SharedStorage.getWorkDays()
        let entry = UptimeEntry(
            date: currentDate,
            workDays: Set(workDays.map { calendar.startOfDay(for: $0) })
        )
        
        // Refresh every hour
        let nextUpdate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct UptimeEntry: TimelineEntry {
    let date: Date
    let workDays: Set<Date>
}

struct UptimeWidgetEntryView: View {
    var entry: UptimeTimelineProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        ContributionGridView(
            currentDate: entry.date,
            workDays: entry.workDays,
            widgetFamily: widgetFamily
        )
        .containerBackground(Color.black, for: .widget)
    }
}

struct ContributionGridView: View {
    let currentDate: Date
    let workDays: Set<Date>
    let widgetFamily: WidgetFamily
    private let calendar = Calendar.current
    
    // Number of rows (days of week)
    private let rows = 7
    
    // Columns based on widget size
    private var columns: Int {
        switch widgetFamily {
        case .systemSmall:
            return 7
        case .systemMedium:
            return 16
        case .systemLarge:
            return 16
        case .systemExtraLarge:
            return 24
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return 7
        @unknown default:
            return 14
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height
            
            // Calculate spacing and square size
            let spacing: CGFloat = 3
            let totalSpacingWidth = spacing * CGFloat(columns - 1)
            let totalSpacingHeight = spacing * CGFloat(rows - 1)
            
            // Calculate square size to fill available space
            let squareSizeByWidth = (availableWidth - totalSpacingWidth) / CGFloat(columns)
            let squareSizeByHeight = (availableHeight - totalSpacingHeight) / CGFloat(rows)
            let squareSize = min(squareSizeByWidth, squareSizeByHeight)
            
            // Center the grid
            let usedWidth = (squareSize * CGFloat(columns)) + totalSpacingWidth
            let usedHeight = (squareSize * CGFloat(rows)) + totalSpacingHeight
            let offsetX = (availableWidth - usedWidth) / 2
            let offsetY = (availableHeight - usedHeight) / 2
            
            // Build the grid - columns are weeks, rows are days of week
            HStack(spacing: spacing) {
                ForEach(0..<columns, id: \.self) { columnIndex in
                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { rowIndex in
                            let date = dateFor(column: columnIndex, row: rowIndex)
                            ContributionSquare(
                                isWorkDay: date != nil && workDays.contains(calendar.startOfDay(for: date!)),
                                isToday: date != nil && calendar.isDateInToday(date!),
                                isFutureDate: date != nil && date! > currentDate,
                                size: squareSize
                            )
                        }
                    }
                }
            }
            .frame(width: usedWidth, height: usedHeight)
            .offset(x: offsetX, y: offsetY)
        }
        .padding(2)
    }
    
    // Calculate date for a given grid position
    // Grid fills from right to left, with today being in the rightmost column
    private func dateFor(column: Int, row: Int) -> Date? {
        // Get today's weekday (1 = Sunday, 7 = Saturday in default calendar)
        let todayWeekday = calendar.component(.weekday, from: currentDate)
        
        // The rightmost column contains today
        // Each column to the left is one week earlier
        let weeksAgo = columns - 1 - column
        
        // Row represents day of week (0 = Sunday, 6 = Saturday)
        let targetWeekday = row + 1 // Convert to calendar weekday (1-7)
        
        // Calculate days from today
        let daysDifference = (todayWeekday - targetWeekday) + (weeksAgo * 7)
        
        return calendar.date(byAdding: .day, value: -daysDifference, to: currentDate)
    }
}

struct ContributionSquare: View {
    let isWorkDay: Bool
    let isToday: Bool
    let isFutureDate: Bool
    let size: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.2)
            .fill(squareColor)
            .frame(width: size, height: size)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                }
            }
    }
    
    private var squareColor: Color {
        if isFutureDate {
            return Color(white: 0.15)
        } else if isWorkDay {
            // White for work days (Cursor style)
            return Color.white
        } else {
            // Dark gray for empty days
            return Color(white: 0.15)
        }
    }
}

// Helper to generate sample work days for previews
private func sampleWorkDays(daysAgoList: [Int]) -> Set<Date> {
    let calendar = Calendar.current
    let today = Date()
    return Set(daysAgoList.compactMap { daysAgo in
        calendar.date(byAdding: .day, value: -daysAgo, to: today).map { calendar.startOfDay(for: $0) }
    })
}

#Preview(as: .systemSmall) {
    UptimeWidget()
} timeline: {
    UptimeEntry(
        date: Date(),
        workDays: sampleWorkDays(daysAgoList: [0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 21, 23, 25, 28, 30, 32, 35, 38, 40, 42])
    )
}

#Preview(as: .systemMedium) {
    UptimeWidget()
} timeline: {
    UptimeEntry(
        date: Date(),
        workDays: sampleWorkDays(daysAgoList: [0, 1, 3, 4, 6, 8, 9, 11, 13, 15, 16, 18, 20, 22, 24, 26, 28, 30, 33, 35, 38, 40, 43, 45, 48, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100])
    )
}
