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
    private let spacing: CGFloat = 24
    private let cellSize: CGFloat = 24

    // Mirrors CalendarMonthGridView's own spacing so a column is exactly one
    // month wide — the block stays fixed-width and centered instead of the
    // months spreading apart as the window widens.
    private var gridSpacing: CGFloat { max(3, cellSize * 0.15) }
    private var monthWidth: CGFloat { cellSize * 7 + gridSpacing * 6 }
    private var totalWidth: CGFloat { monthWidth * CGFloat(columnCount) + spacing * CGFloat(columnCount - 1) }

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.fixed(monthWidth), spacing: spacing, alignment: .top),
                    count: columnCount
                ),
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
                }
            }
            .frame(width: totalWidth)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var months: [Date] {
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: year)) else {
            return []
        }
        return (0..<12).compactMap { calendar.date(byAdding: .month, value: $0, to: startOfYear) }
    }
}
