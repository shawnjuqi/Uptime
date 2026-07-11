import Testing
import Foundation
import CoreData
@testable import Uptime

/// The streak and rolling-window math is the code most likely to break subtly
/// during a refactor and stay invisible until a user sees a wrong number, so it
/// is exercised end-to-end through a StatsViewModel over a seeded in-memory store.
@MainActor
struct StatsViewModelTests {
    private func statsVM(_ seed: [(daysAgo: Int, hours: Double)]) -> StatsViewModel {
        let (_, context) = TestStore.seed(seed)
        return StatsViewModel(viewContext: context)
    }

    // MARK: - Streak

    @Test func noSessionsMeansNoStreak() {
        #expect(statsVM([]).streak == 0)
    }

    @Test func workTodayGivesStreakOfOne() {
        #expect(statsVM([(daysAgo: 0, hours: 1)]).streak == 1)
    }

    @Test func consecutiveDaysAccumulate() {
        let vm = statsVM([
            (daysAgo: 0, hours: 1),
            (daysAgo: 1, hours: 1),
            (daysAgo: 2, hours: 1),
        ])
        #expect(vm.streak == 3)
    }

    @Test func gapBreaksTheStreak() {
        // Worked today and three days ago, but the days between are empty.
        let vm = statsVM([
            (daysAgo: 0, hours: 1),
            (daysAgo: 3, hours: 1),
        ])
        #expect(vm.streak == 1)
    }

    @Test func emptyTodayDoesNotBreakAnOngoingStreak() {
        // Nothing logged yet today, but yesterday and the day before have work:
        // the streak should count those two rather than reset to zero.
        let vm = statsVM([
            (daysAgo: 1, hours: 1),
            (daysAgo: 2, hours: 1),
        ])
        #expect(vm.streak == 2)
    }

    // MARK: - Rolling window

    @Test func todayDurationReflectsSeededWork() {
        let vm = statsVM([(daysAgo: 0, hours: 2)])
        #expect(vm.todayDuration == 2 * 3600)
    }

    @Test func last7DaysAverageDividesTotalBySeven() {
        // 7h total spread across the window → 1h average per day.
        let vm = statsVM([
            (daysAgo: 0, hours: 3),
            (daysAgo: 2, hours: 2),
            (daysAgo: 5, hours: 2),
        ])
        #expect(vm.last7DaysAverage == 3600)
    }

    @Test func last7DaysExcludesOlderWork() {
        // Work 10 days ago is outside the 7-day window and must not count.
        let vm = statsVM([
            (daysAgo: 0, hours: 1),
            (daysAgo: 10, hours: 5),
        ])
        #expect(vm.last7Days.count == 7)
        #expect(vm.last7DaysAverage == 3600.0 / 7)
    }
}
