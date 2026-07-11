import Testing
import Foundation
import CoreData
@testable import Uptime

/// SessionService is the aggregation layer every stat and calendar tile reads
/// from, so its day bucketing and inclusive/exclusive range boundaries are
/// pinned here against an in-memory store.
struct SessionServiceTests {
    @Test func totalDurationSumsAllSessionsForADay() {
        let context = TestStore.makeContext()
        let service = SessionService(viewContext: context)
        let today = Date()
        service.createTestSession(for: today, duration: 3600)
        service.createTestSession(for: today, duration: 1800)

        #expect(service.getTotalDuration(for: today) == 5400)
    }

    @Test func dailyDurationsBucketByStartOfDay() {
        let (service, _) = TestStore.seed([
            (daysAgo: 0, hours: 2),
            (daysAgo: 1, hours: 1),
            (daysAgo: 1, hours: 1),
        ])
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let daily = service.getDailyDurations(from: yesterday, to: today)

        #expect(daily[today] == 7200)
        #expect(daily[yesterday] == 7200)   // two 1h sessions merged
    }

    @Test func dailyDurationsRangeIsInclusiveOfBothBounds() {
        let (service, _) = TestStore.seed([
            (daysAgo: 0, hours: 1),
            (daysAgo: 3, hours: 1),
        ])
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let threeAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        let daily = service.getDailyDurations(from: threeAgo, to: today)

        #expect(daily[today] == 3600)      // upper bound included
        #expect(daily[threeAgo] == 3600)   // lower bound included
    }

    @Test func hasWorkCompletedReflectsPresenceOfSessions() {
        let context = TestStore.makeContext()
        let service = SessionService(viewContext: context)
        let today = Date()

        #expect(service.hasWorkCompleted(for: today) == false)
        service.createTestSession(for: today, duration: 600)
        #expect(service.hasWorkCompleted(for: today) == true)
    }

    @Test func deleteSessionsClearsOnlyThatDay() {
        let (service, _) = TestStore.seed([
            (daysAgo: 0, hours: 1),
            (daysAgo: 1, hours: 1),
        ])
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        service.deleteSessions(for: today)

        #expect(service.hasWorkCompleted(for: today) == false)
        #expect(service.hasWorkCompleted(for: yesterday) == true)
    }
}
