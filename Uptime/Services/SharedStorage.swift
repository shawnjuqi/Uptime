import Foundation
import WidgetKit

struct SharedStorage {
    // 1. Use Constants for Keys to prevent typos
    private struct Keys {
        static let suiteName = "group.Oriented.Uptime"
        static let todayHours = "todayHours"
        static let lastUpdated = "lastUpdated"
        static let workDays = "workDays"
    }
    
    // 2. Optimized Formatter (Created once, reused statically)
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate] // YYYY-MM-DD
        return formatter
    }()
    
    // 3. Direct Access (Removes "failed forever" risk and redundant directory checks)
    static var defaults: UserDefaults? {
        return UserDefaults(suiteName: Keys.suiteName)
    }
    
    // MARK: - API
    
    static func saveTodayDuration(_ duration: TimeInterval) {
        guard let userDefaults = defaults else { return }
        
        let hours = duration / 3600
        userDefaults.set(hours, forKey: Keys.todayHours)
        userDefaults.set(Date(), forKey: Keys.lastUpdated)
        
        // 4. Trigger Widget Refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func getTodayHours() -> Double {
        return defaults?.double(forKey: Keys.todayHours) ?? 0
    }
    
    static func saveWorkDays(_ dates: [Date]) {
        guard let userDefaults = defaults else { return }
        
        // 5. Performance Fix: Use the static formatter, not a new one inside map
        let dateStrings = dates.map { dateFormatter.string(from: $0) }
        
        userDefaults.set(dateStrings, forKey: Keys.workDays)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func getWorkDays() -> [Date] {
        guard let dateStrings = defaults?.stringArray(forKey: Keys.workDays) else {
            return []
        }
        return dateStrings.compactMap { dateFormatter.date(from: $0) }
    }
    
    static func hasWorkToday() -> Bool {
        return getTodayHours() > 0
    }
    
    static func reset() {
        guard let userDefaults = defaults else { return }
        userDefaults.removeObject(forKey: Keys.todayHours)
        userDefaults.removeObject(forKey: Keys.lastUpdated)
        userDefaults.removeObject(forKey: Keys.workDays)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
