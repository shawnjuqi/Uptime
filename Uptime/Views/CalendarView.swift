import SwiftUI

struct CalendarView: View {
    @Bindable var viewModel: CalendarViewModel
    
    var body: some View {
        Group {
            if let inspectedDate = viewModel.inspectedDate {
                CalendarDayDetailView(
                    date: inspectedDate,
                    duration: viewModel.duration(for: inspectedDate),
                    onBack: viewModel.dismissDayDetail
                )
            } else {
                calendarBrowser
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            viewModel.refresh()
        }
    }
    
    private var calendarBrowser: some View {
        VStack(spacing: 16) {
            header

            switch viewModel.scope {
            case .month:
                // Header + weekday row stay pinned near the top; only the tile
                // rows below grow/shrink as months need 4–6 weeks.
                HStack {
                    Spacer(minLength: 0)
                    CalendarMonthGridView(
                        monthDate: viewModel.focusedDate,
                        viewModel: viewModel,
                        showsMonthTitle: false,
                        cellSize: 52,
                        onSelectDay: viewModel.selectDay,
                        formatDuration: Self.formatCompact
                    )
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)

            case .year:
                CalendarYearView(
                    year: viewModel.focusedDate,
                    viewModel: viewModel,
                    onSelectDay: viewModel.selectDay,
                    formatDuration: Self.formatCompact
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 28) {
                if viewModel.scope == .month {
                    stepper(
                        title: viewModel.focusedDate.formatted(.dateTime.month(.wide)),
                        minWidth: 120,
                        onPrev: { viewModel.shiftFocus(-1) },
                        onNext: { viewModel.shiftFocus(1) }
                    )
                }

                stepper(
                    title: viewModel.focusedDate.formatted(.dateTime.year()),
                    minWidth: 70,
                    onPrev: { viewModel.shiftYear(-1) },
                    onNext: { viewModel.shiftYear(1) }
                )
            }

            Picker("View", selection: $viewModel.scope) {
                ForEach(CalendarScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 180)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private func stepper(
        title: String,
        minWidth: CGFloat,
        onPrev: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            chevron("chevron.left", action: onPrev)

            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(minWidth: minWidth)
                .multilineTextAlignment(.center)

            chevron("chevron.right", action: onNext)
        }
    }

    private func chevron(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
        }
        .buttonStyle(.plain)
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
}
