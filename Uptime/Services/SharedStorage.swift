import Foundation

/// App-group storage shared between the app and the widget extension.
/// Compiled into both targets, so it must not reference WidgetCenter —
/// after mutating, app-side callers reload widget timelines themselves.
struct SharedStorage {
    private struct Keys {
        static let suiteName = "group.Oriented.Uptime"
        static let todayHours = "todayHours"
        static let lastUpdated = "lastUpdated"
        static let workDays = "workDays"
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate] // YYYY-MM-DD
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

    static func saveWorkDays(_ dates: [Date]) {
        guard let userDefaults = defaults else { return }

        let dateStrings = dates.map { dateFormatter.string(from: $0) }
        userDefaults.set(dateStrings, forKey: Keys.workDays)
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
    }
}
