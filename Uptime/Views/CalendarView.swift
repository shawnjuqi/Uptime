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
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(currentYear, format: .dateTime.year())
                .font(.title2)
                .bold()
            
            Spacer()
            
            Toggle("Show Days", isOn: $showDayNumbers)
                .toggleStyle(.switch)
            
            Button {
                changeYear(1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
    
    private func changeYear(_ direction: Int) {
        if let newYear = calendar.date(byAdding: .year, value: direction, to: currentYear) {
            currentYear = newYear
            viewModel.refresh()
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
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(12), spacing: 2), count: 7), spacing: 2) {
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
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(isWorkDay ? Color.green.opacity(0.7) : Color.gray.opacity(0.2))
                .frame(width: 12, height: 12)
                .clipShape(.rect(cornerRadius: 1))
            
            if showDayNumber {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 7))
                    .foregroundStyle(isWorkDay ? .white : .secondary)
            }
            
            if isToday {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 1)
                    .frame(width: 12, height: 12)
                    .clipShape(.rect(cornerRadius: 1))
            }
        }
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
}
