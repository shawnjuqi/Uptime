import Foundation

/// App-group storage shared between the app and the widget extension.
/// Compiled into both targets, so it must not reference WidgetCenter —
/// after mutating, app-side callers reload widget timelines themselves.
struct SharedStorage {
    private struct Keys {
        static let suiteName = "group.Oriented.Uptime"
        static let todayHours = "todayHours"
        static let lastUpdated = "lastUpdated"
        static let dailyDurations = "dailyDurations"
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate] // YYYY-MM-DD
        // Local time on both write and read; the default (UTC) shifts each
        // day key by one in timezones behind UTC, so tiles showed the wrong day.
        formatter.timeZone = .current
        return formatter
    }()

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: Keys.suiteName)
    }

    // MARK: - API

    static func saveTodayDuration(_ duration: TimeInterval) {
        guard let userDefaults = defaults else { return }

        userDefaults.set(duration / 3600, forKey: Keys.todayHours)
        userDefaults.set(Date(), forKey: Keys.lastUpdated)
    }

    static func getTodayHours() -> Double {
        return defaults?.double(forKey: Keys.todayHours) ?? 0
    }

    /// When the today total was last written; nil if never. Lets readers
    /// discard a stale value carried over past midnight.
    static func getLastUpdated() -> Date? {
        defaults?.object(forKey: Keys.lastUpdated) as? Date
    }

    /// Per-day tracked seconds for the current year, keyed by day, so the
    /// widget can shade tiles with the same bands as the in-app calendar.
    static func saveDailyDurations(_ durations: [Date: TimeInterval]) {
        guard let userDefaults = defaults else { return }

        var stored: [String: Double] = [:]
        for (date, duration) in durations {
            stored[dateFormatter.string(from: date)] = duration
        }
        userDefaults.set(stored, forKey: Keys.dailyDurations)
    }

    static func getDailyDurations() -> [Date: TimeInterval] {
        guard let stored = defaults?.dictionary(forKey: Keys.dailyDurations) as? [String: Double] else {
            return [:]
        }
        var result: [Date: TimeInterval] = [:]
        for (string, duration) in stored {
            if let date = dateFormatter.date(from: string) {
                result[date] = duration
            }
        }
        return result
    }

    static func hasWorkToday() -> Bool {
        return getTodayHours() > 0
    }

    static func reset() {
        guard let userDefaults = defaults else { return }
        userDefaults.removeObject(forKey: Keys.todayHours)
        userDefaults.removeObject(forKey: Keys.lastUpdated)
        userDefaults.removeObject(forKey: Keys.dailyDurations)
    }
}
