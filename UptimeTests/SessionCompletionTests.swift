import Testing
import Foundation
@testable import Uptime

/// Reaching the target must freeze the session at the target instead of counting
/// on: before this, a timer left running past its target kept accruing wall-clock
/// time until a manual Stop, inflating the recorded duration (and every stat that
/// sums it). The session stays open showing "Timer Complete!" until the user stops.
@MainActor
struct SessionCompletionTests {
    @Test func timerFreezesAtTargetAndRecordsOnlyTheTarget() async {
        let context = TestStore.makeContext()
        let queryService = SessionService(viewContext: context)
        let viewModel = SessionViewModel(viewContext: context)

        viewModel.setCustomDuration(hours: 0, minutes: 0, seconds: 1)
        viewModel.startSession()
        #expect(viewModel.isRunning)

        // Wait for the tick past the 1s target to fire, without ever calling stop.
        for _ in 0..<50 where !viewModel.isCompleted {
            try? await Task.sleep(for: .milliseconds(100))
        }

        // Frozen: stopped ticking, still open, pinned exactly at the target.
        #expect(viewModel.isCompleted)
        #expect(viewModel.isRunning == false)
        #expect(viewModel.currentSession != nil)
        #expect(viewModel.isTimerComplete)
        #expect(viewModel.elapsedTime == viewModel.targetDuration)

        // Time keeps passing but the frozen elapsed must not creep upward.
        try? await Task.sleep(for: .milliseconds(300))
        #expect(viewModel.elapsedTime == viewModel.targetDuration)

        // Nothing is saved until the user actually stops.
        #expect(queryService.getTotalDuration(for: Date()) == 0)

        viewModel.stopSession()
        #expect(viewModel.isCompleted == false)
        #expect(viewModel.currentSession == nil)
        #expect(queryService.getTotalDuration(for: Date()) == 1.0) // the target, not the overage
    }
}
