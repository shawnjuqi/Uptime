import WidgetKit
import SwiftUI

struct UptimeWidget: Widget {
    let kind: String = "UptimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UptimeTimelineProvider()) { entry in
            UptimeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Uptime")
        .description("Display your work calendar")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct UptimeTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> UptimeEntry {
        // Placeholder shows sample data for preview (doesn't affect real snapshot)
        let calendar = Calendar.current
        let today = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return UptimeEntry(date: today, currentMonth: today, workDays: Set<Date>())
        }
        
        // Show sample work days (days 3, 5, 7, 10, 12, 15, 18, 20, 22, 25)
        let sampleDays = [3, 5, 7, 10, 12, 15, 18, 20, 22, 25]
        let workDays = sampleDays.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
        
        return UptimeEntry(
            date: today,
            currentMonth: today,
            workDays: Set(workDays.map { calendar.startOfDay(for: $0) })
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (UptimeEntry) -> Void) {
        let today = Date()
        let calendar = Calendar.current
        let workDays = SharedStorage.getWorkDays()
        let entry = UptimeEntry(
            date: today,
            currentMonth: today,
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
            currentMonth: currentDate,
            workDays: Set(workDays.map { calendar.startOfDay(for: $0) })
        )
        
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct UptimeEntry: TimelineEntry {
    let date: Date
    let currentMonth: Date
    let workDays: Set<Date>
}

struct UptimeWidgetEntryView: View {
    var entry: UptimeTimelineProvider.Entry
    private let calendar = Calendar.current
    
    var body: some View {
        CalendarGridView(
            month: entry.currentMonth,
            workDays: entry.workDays
        )
        .padding(4)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct CalendarGridView: View {
    let month: Date
    let workDays: Set<Date>
    private let calendar = Calendar.current
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height
            let dayCount = daysInMonth.count
            let columns = 7
            let rows = Int(ceil(Double(dayCount) / Double(columns)))
            
            // Calculate spacing and square size to fill space
            let spacing: CGFloat = 4
            let totalSpacingWidth = spacing * CGFloat(columns - 1)
            let totalSpacingHeight = spacing * CGFloat(rows - 1)
            
            // Calculate square size to fill available space
            let squareSizeByWidth = (availableWidth - totalSpacingWidth) / CGFloat(columns)
            let squareSizeByHeight = (availableHeight - totalSpacingHeight) / CGFloat(rows)
            let squareSize = min(squareSizeByWidth, squareSizeByHeight)
            
            // Center the grid if needed
            let usedWidth = (squareSize * CGFloat(columns)) + totalSpacingWidth
            let usedHeight = (squareSize * CGFloat(rows)) + totalSpacingHeight
            let offsetX = (availableWidth - usedWidth) / 2
            let offsetY = (availableHeight - usedHeight) / 2
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(squareSize), spacing: spacing), count: columns),
                spacing: spacing
            ) {
                ForEach(daysInMonth, id: \.self) { date in
                    DaySquare(
                        date: date,
                        isWorkDay: workDays.contains(calendar.startOfDay(for: date)),
                        isCurrentMonth: true,
                        size: squareSize
                    )
                }
            }
            .frame(width: usedWidth, height: usedHeight)
            .offset(x: offsetX, y: offsetY)
        }
    }
    
    private var daysInMonth: [Date] {
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        var days: [Date] = []
        
        // Add all days of current month only (no padding days)
        var currentDate = firstDay
        while calendar.isDate(currentDate, equalTo: month, toGranularity: .month) {
            days.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return days
    }
}

struct DaySquare: View {
    let date: Date
    let isWorkDay: Bool
    let isCurrentMonth: Bool
    let size: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(isWorkDay ? Color.green.opacity(0.7) : (isCurrentMonth ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)))
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: 0.5))
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date? {
        return self.date(from: self.dateComponents([.year, .month], from: date))
    }
}

#Preview(as: .systemSmall) {
    UptimeWidget()
} timeline: {
    let calendar = Calendar.current
    let today = Date()
    // Preview with some sample work days (not including today)
    let workDays = [3, 5, 7, 10, 12, 14, 17, 19, 21].compactMap { day in
        calendar.date(byAdding: .day, value: day - calendar.component(.day, from: today), to: today)
    }
    UptimeEntry(
        date: today,
        currentMonth: today,
        workDays: Set(workDays.map { calendar.startOfDay(for: $0) })
    )
}
