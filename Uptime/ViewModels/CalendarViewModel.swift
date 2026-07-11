import Foundation
import CoreData
import Observation

@MainActor
@Observable
final class CalendarViewModel {
    var scope: CalendarScope = .month
    /// Anchor date for the visible month (or year, in year scope).
    var focusedDate = Date()
    /// When set, the day-detail screen is shown.
    var inspectedDate: Date?
    /// Start-of-day → total tracked duration for the loaded year.
    var dailyDurations: [Date: TimeInterval] = [:]
    
    private let sessionService: SessionService
    private let calendar = Calendar.current

    init(viewContext: NSManagedObjectContext) {
        self.sessionService = SessionService(viewContext: viewContext)
        refresh()
    }

    func duration(for date: Date) -> TimeInterval {
        dailyDurations[calendar.startOfDay(for: date)] ?? 0
    }

    /// Absolute bands so a shade means the same amount of work regardless of
    /// the year: <1h, 1–2h, 2–4h, 4h+. Independent of the busiest day, so
    /// years stay comparable and one outlier can't wash everything out.
    func heatIntensity(for date: Date) -> Double {
        HeatShade.intensity(for: duration(for: date))
    }
    
    func hasWorkCompleted(for date: Date) -> Bool {
        duration(for: date) > 0
    }
    
    func selectDay(_ date: Date) {
        let day = calendar.startOfDay(for: date)
        guard day <= calendar.startOfDay(for: Date()) else { return }
        inspectedDate = day
    }
    
    func dismissDayDetail() {
        inspectedDate = nil
    }
    
    func shiftFocus(_ direction: Int) {
        shift(.month, by: direction)
    }

    func shiftYear(_ direction: Int) {
        shift(.year, by: direction)
    }

    private func shift(_ component: Calendar.Component, by direction: Int) {
        if let newDate = calendar.date(byAdding: component, value: direction, to: focusedDate) {
            focusedDate = newDate
            refresh()
        }
    }

    func showMonth(_ monthDate: Date) {
        focusedDate = monthDate
        scope = .month
        inspectedDate = nil
        refresh()
    }
    
    func refresh(for date: Date? = nil) {
        if let date {
            focusedDate = date
        }
        loadDurations(for: focusedDate)
    }
    
    private func loadDurations(for date: Date) {
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: date)),
              let yearInterval = calendar.dateInterval(of: .year, for: date) else {
            return
        }
        
        let endOfYear = yearInterval.end.addingTimeInterval(-1)
        dailyDurations = sessionService.getDailyDurations(from: startOfYear, to: endOfYear)

        // Mirror the current year's per-day durations for the widget's tiles
        if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            SharedStorage.saveDailyDurations(dailyDurations)
            WidgetHelper.reloadWidget()
        }
    }
}
