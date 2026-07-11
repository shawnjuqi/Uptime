import SwiftUI

struct CalendarMonthGridView: View {
    let monthDate: Date
    let viewModel: CalendarViewModel
    var showsMonthTitle = false
    var usesShortMonthTitle = false
    var showsWeekdayHeaders = true
    var showsDayNumbers = true
    var cellSize: CGFloat = 40
    var onSelectDay: (Date) -> Void
    var formatDuration: (TimeInterval) -> String
    
    private let calendar = Calendar.current
    
    private var gridSpacing: CGFloat {
        max(3, cellSize * 0.15)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: max(6, cellSize * 0.2)) {
            if showsMonthTitle {
                Button {
                    viewModel.showMonth(monthDate)
                } label: {
                    Text(monthTitle)
                        .font(usesShortMonthTitle ? .subheadline.weight(.semibold) : .headline)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellSize), spacing: gridSpacing), count: 7),
                spacing: gridSpacing
            ) {
                if showsWeekdayHeaders {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.system(size: max(10, cellSize * 0.28), weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: cellSize)
                    }
                }
                
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, cell in
                    if let date = cell {
                        CalendarDayCell(
                            date: date,
                            intensity: viewModel.heatIntensity(for: date),
                            duration: viewModel.duration(for: date),
                            showsDayNumber: showsDayNumbers,
                            size: cellSize,
                            formatDuration: formatDuration,
                            action: { onSelectDay(date) }
                        )
                    } else {
                        Color.clear
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }
    
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[firstWeekdayIndex...]) + Array(symbols[..<firstWeekdayIndex])
    }
    
    /// `nil` entries are leading padding outside the month.
    private var monthCells: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingEmpty = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var cells: [Date?] = Array(repeating: nil, count: leadingEmpty)
        var day = firstDay
        while day < monthInterval.end {
            cells.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return cells
    }
    
    private var monthTitle: String {
        if usesShortMonthTitle {
            monthDate.formatted(.dateTime.month(.abbreviated))
        } else {
            monthDate.formatted(.dateTime.month(.wide))
        }
    }
}
