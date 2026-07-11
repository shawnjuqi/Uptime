import Foundation
import CoreData
import Observation

@MainActor
@Observable
final class StatsViewModel {
    var todayDuration: TimeInterval = 0
    var thisWeekDuration: TimeInterval = 0
    var lastWeekComparableDuration: TimeInterval = 0
    var streak: Int = 0
    /// Newest → oldest, always 7 entries (missing days are 0).
    var last7Days: [StatsDayTotal] = []
    
    private let sessionService: SessionService
    private let calendar = Calendar.current
    
    var weekDelta: TimeInterval {
        thisWeekDuration - lastWeekComparableDuration
    }
    
    /// Average across the rolling last 7 days (including days with 0).
    /// Always divides by 7 so the value matches “per day over the last 7 days.”
    var last7DaysAverage: TimeInterval {
        let total = last7Days.reduce(0) { $0 + $1.duration }
        return total / 7
    }
    
    init(viewContext: NSManagedObjectContext) {
        self.sessionService = SessionService(viewContext: viewContext)
        refresh()
    }
    
    func refresh() {
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        guard let fetchStart = calendar.date(byAdding: .day, value: -60, to: today) else { return }
        let daily = sessionService.getDailyDurations(from: fetchStart, to: today)
        
        todayDuration = daily[today] ?? 0
        
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return }
        let thisWeekStartDay = calendar.startOfDay(for: thisWeekStart)
        
        thisWeekDuration = durationSum(in: daily, from: thisWeekStartDay, to: today)
        
        // Same weekday span last week (fair mid-week comparison)
        let daysIntoWeek = calendar.dateComponents([.day], from: thisWeekStartDay, to: today).day ?? 0
        if let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStartDay),
           let lastWeekSamePoint = calendar.date(byAdding: .day, value: daysIntoWeek, to: lastWeekStart) {
            lastWeekComparableDuration = durationSum(in: daily, from: lastWeekStart, to: lastWeekSamePoint)
        } else {
            lastWeekComparableDuration = 0
        }
        
        last7Days = (0..<7).compactMap { daysAgo in
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            return StatsDayTotal(date: day, duration: daily[day] ?? 0)
        }
        
        streak = calculateStreak(from: daily, today: today)
    }
    
    private func durationSum(in daily: [Date: TimeInterval], from start: Date, to end: Date) -> TimeInterval {
        var total: TimeInterval = 0
        var day = start
        while day <= end {
            total += daily[day] ?? 0
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return total
    }
    
    private func calculateStreak(from daily: [Date: TimeInterval], today: Date) -> Int {
        var day = today
        // Don't break the streak mid-morning before today's first session
        if (daily[day] ?? 0) == 0 {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        
        var count = 0
        while (daily[day] ?? 0) > 0 {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}
