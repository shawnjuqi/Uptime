import SwiftUI

/// A year at a glance: twelve mini month grids, shaded like the month view
/// but without day numbers or weekday labels so the pattern reads cleanly.
struct CalendarYearView: View {
    let year: Date
    let viewModel: CalendarViewModel
    let onSelectDay: (Date) -> Void
    let formatDuration: (TimeInterval) -> String

    private let calendar = Calendar.current
    private let columnCount = 3
    private let spacing: CGFloat = 20

    var body: some View {
        GeometryReader { proxy in
            let columnWidth = (proxy.size.width - spacing * CGFloat(columnCount - 1) - 40) / CGFloat(columnCount)
            // 7 day-columns per month, leaving room for the grid's own spacing
            let cellSize = max(10, min(26, floor(columnWidth / 8)))

            ScrollView {
                LazyVGrid(
                    // .top so shorter months don't drop their titles below
                    // taller months in the same row
                    columns: Array(repeating: GridItem(.flexible(), spacing: spacing, alignment: .top), count: columnCount),
                    spacing: spacing
                ) {
                    ForEach(months, id: \.self) { month in
                        CalendarMonthGridView(
                            monthDate: month,
                            viewModel: viewModel,
                            showsMonthTitle: true,
                            usesShortMonthTitle: true,
                            showsWeekdayHeaders: false,
                            showsDayNumbers: false,
                            cellSize: cellSize,
                            onSelectDay: onSelectDay,
                            formatDuration: formatDuration
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }

    private var months: [Date] {
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: year)) else {
            return []
        }
        return (0..<12).compactMap { calendar.date(byAdding: .month, value: $0, to: startOfYear) }
    }
}
