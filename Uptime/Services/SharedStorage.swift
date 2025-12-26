import Foundation

struct SharedStorage {
    static let appGroupIdentifier = "group.Oriented.Uptime"
    
    static var sharedUserDefaults: UserDefaults? {
        // Access UserDefaults with App Group - this may log warnings during first access
        // The warnings are harmless and the container will be created automatically
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // Save today's work duration
    static func saveTodayDuration(_ duration: TimeInterval) {
        guard let defaults = sharedUserDefaults else {
            print("Warning: Could not access shared UserDefaults")
            return
        }
        let hours = duration / 3600
        defaults.set(hours, forKey: "todayHours")
        defaults.set(Date(), forKey: "lastUpdated")
        defaults.synchronize()
    }
    
    static func getTodayHours() -> Double {
        sharedUserDefaults?.double(forKey: "todayHours") ?? 0
    }
    
    // Save work days for calendar widget
    static func saveWorkDays(_ dates: [Date]) {
        guard let defaults = sharedUserDefaults else {
            print("Warning: Could not access shared UserDefaults")
            return
        }
        let dateStrings = dates.map { date in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            return formatter.string(from: date)
        }
        defaults.set(dateStrings, forKey: "workDays")
        defaults.synchronize()
    }
    
    static func getWorkDays() -> [Date] {
        guard let dateStrings = sharedUserDefaults?.stringArray(forKey: "workDays") else {
            return []
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return dateStrings.compactMap { formatter.date(from: $0) }
    }
    
    // Check if work was completed today
    static func hasWorkToday() -> Bool {
        return getTodayHours() > 0
    }
    
    // Reset all shared storage data
    static func reset() {
        sharedUserDefaults?.removeObject(forKey: "todayHours")
        sharedUserDefaults?.removeObject(forKey: "lastUpdated")
        sharedUserDefaults?.removeObject(forKey: "workDays")
        sharedUserDefaults?.synchronize()
    }
}

