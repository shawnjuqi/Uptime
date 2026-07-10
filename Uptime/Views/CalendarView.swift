import SwiftUI

struct CalendarView: View {
    let viewModel: CalendarViewModel
    @State private var currentYear = Date()
    @State private var showDayNumbers = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 12) {
            CalendarHeaderView(
                currentYear: $currentYear,
                showDayNumbers: $showDayNumbers,
                viewModel: viewModel
            )
            
            YearlyCalendarGridView(
                currentYear: currentYear,
                showDayNumbers: showDayNumbers,
                viewModel: viewModel
            )
        }
        .padding()
        .background(Color.black)
        .onAppear {
            viewModel.refresh(for: currentYear)
        }
        .onChange(of: currentYear) { oldValue, newValue in
            viewModel.refresh(for: newValue)
        }
    }
}

struct CalendarHeaderView: View {
    @Binding var currentYear: Date
    @Binding var showDayNumbers: Bool
    let viewModel: CalendarViewModel
    private let calendar = Calendar.current
    
    var body: some View {
        HStack {
            Button {
                changeYear(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .tint(.white)
            
            Spacer()
            
            Text(currentYear, format: .dateTime.year())
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
            
            Spacer()
            
            Toggle("Show Days", isOn: $showDayNumbers)
                .toggleStyle(.switch)
                .foregroundStyle(.white)
                .tint(.white)
            
            Button {
                changeYear(1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .tint(.white)
        }
        .padding(.horizontal)
    }
    
    private func changeYear(_ direction: Int) {
        if let newYear = calendar.date(byAdding: .year, value: direction, to: currentYear) {
            currentYear = newYear
        }
    }
}

struct YearlyCalendarGridView: View {
    let currentYear: Date
    let showDayNumbers: Bool
    let viewModel: CalendarViewModel
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 24) {
                ForEach(monthsInYear, id: \.self) { monthDate in
                    MonthCalendarView(
                        monthDate: monthDate,
                        showDayNumbers: showDayNumbers,
                        viewModel: viewModel
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var monthsInYear: [Date] {
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: currentYear)) else {
            return []
        }
        
        var months: [Date] = []
        for month in 0..<12 {
            if let monthDate = calendar.date(byAdding: .month, value: month, to: startOfYear) {
                months.append(monthDate)
            }
        }
        return months
    }
}

struct MonthCalendarView: View {
    let monthDate: Date
    let showDayNumbers: Bool
    let viewModel: CalendarViewModel
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthDate, format: .dateTime.month(.wide))
                .font(.headline)
                .frame(height: 20, alignment: .leading)
                .padding(.horizontal, 4)
                .foregroundStyle(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(14), spacing: 3), count: 7), spacing: 3) {
                ForEach(daysInMonth, id: \.self) { date in
                    DaySquare(
                        date: date,
                        isWorkDay: viewModel.hasWorkCompleted(for: date),
                        showDayNumber: showDayNumbers,
                        isCurrentMonth: true
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var daysInMonth: [Date] {
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
            return []
        }
        
        var days: [Date] = []
        
        // Add all days of the current month only
        var currentDate = firstDay
        while calendar.isDate(currentDate, equalTo: monthDate, toGranularity: .month) {
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
    let showDayNumber: Bool
    let isCurrentMonth: Bool
    
    private let calendar = Calendar.current
    private let size: CGFloat = 14
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(squareColor)
                .frame(width: size, height: size)
            
            if showDayNumber {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 7))
                    .foregroundStyle(isWorkDay ? .black : .white.opacity(0.5))
            }
            
            if isToday {
                RoundedRectangle(cornerRadius: size * 0.2)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                    .frame(width: size, height: size)
            }
        }
    }
    
    private var squareColor: Color {
        if isWorkDay {
            // White for work days (Cursor style)
            return Color.white
        } else {
            // Dark gray for empty days
            return Color(white: 0.15)
        }
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
}
