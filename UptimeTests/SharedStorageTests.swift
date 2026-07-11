import Testing
import Foundation
@testable import Uptime

/// SharedStorage bridges the app and the widget through app-group defaults.
/// The date-key round trip is pinned here because the day-key formatter already
/// caused a real bug (UTC shifting each key by a day in timezones behind UTC).
///
/// These tests write to the *real* shared suite, so each one snapshots the
/// affected keys and restores them on exit — user widget data is left untouched.
/// Serialized because they share one global defaults suite; running them in
/// parallel would let one test's reset clobber another's writes.
@Suite(.serialized)
struct SharedStorageTests {
    /// Runs `body` with the shared-storage keys saved beforehand and restored
    /// afterward, regardless of assertion outcome.
    private func preservingSharedStorage(_ body: () -> Void) {
        let defaults = SharedStorage.defaults
        let keys = ["todayHours", "lastUpdated", "dailyDurations"]
        let saved = keys.map { (key: $0, value: defaults?.object(forKey: $0)) }
        defer {
            for entry in saved {
                if let value = entry.value {
                    defaults?.set(value, forKey: entry.key)
                } else {
                    defaults?.removeObject(forKey: entry.key)
                }
            }
        }
        body()
    }

    @Test func todayDurationRoundTripsAsHours() {
        preservingSharedStorage {
            SharedStorage.saveTodayDuration(5400)   // 1.5h
            #expect(SharedStorage.getTodayHours() == 1.5)
            #expect(SharedStorage.hasWorkToday() == true)
        }
    }

    @Test func dailyDurationsRoundTripKeyedByDay() {
        preservingSharedStorage {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let input: [Date: TimeInterval] = [today: 7200, yesterday: 3600]

            SharedStorage.saveDailyDurations(input)
            let output = SharedStorage.getDailyDurations()

            // Keys are stored as YYYY-MM-DD in local time, so they must come back
            // mapped to the same start-of-day dates they went in as.
            #expect(output[today] == 7200)
            #expect(output[yesterday] == 3600)
        }
    }

    @Test func resetClearsStoredValues() {
        preservingSharedStorage {
            SharedStorage.saveTodayDuration(3600)
            SharedStorage.reset()
            #expect(SharedStorage.getTodayHours() == 0)
            #expect(SharedStorage.hasWorkToday() == false)
        }
    }
}
