import Foundation
import CoreData
import Observation
import UserNotifications
import AppKit
import WidgetKit

// Nonisolated storage for timer to allow cleanup in deinit
final class TimerStorage: @unchecked Sendable {
    var timer: Timer?
}

@MainActor
@Observable
final class SessionViewModel {
    // Singleton instance to prevent deallocation during app termination
    static let shared = SessionViewModel(viewContext: PersistenceController.shared.container.viewContext)
    
    var isRunning = false
    var elapsedTime: TimeInterval = 0
    var currentSession: WorkSession?
    var targetDuration: TimeInterval = 3600 // Default: 1 hour
    var isTimerEnabled = false
    /// True once the timer reaches its target: counting is frozen at the target
    /// and the session stays open (showing "Timer Complete!") until the user stops.
    private(set) var isCompleted = false
    
    private let sessionService: SessionService
    private let timerStorage = TimerStorage()
    private var sessionStartTime: Date?
    private var hasNotifiedCompletion = false
    private var pausedForSleep = false
    private var sleepBeganAt: Date?

    /// Minimum away time before the wake-up banner; shorter sleeps resume silently
    private let sleepNotificationThreshold: TimeInterval = 5 * 60

    init(viewContext: NSManagedObjectContext) {
        self.sessionService = SessionService(viewContext: viewContext)
        observeSystemSleep()
    }

    private func observeSystemSleep() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.systemWillSleep() }
        }
        center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.systemDidWake() }
        }
    }

    private func systemWillSleep() {
        guard isRunning else { return }
        pauseSession()
        pausedForSleep = true
        sleepBeganAt = Date()
    }

    private func systemDidWake() {
        // Only auto-resume sessions we paused; a manual pause stays paused
        guard pausedForSleep else { return }
        pausedForSleep = false
        resumeSession()

        if let sleepBeganAt {
            let awayTime = Date().timeIntervalSince(sleepBeganAt)
            if awayTime >= sleepNotificationThreshold {
                postSleepResumeNotification(awayFor: awayTime)
            }
        }
        sleepBeganAt = nil
    }

    private func postSleepResumeNotification(awayFor interval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Resumed"
        content.body = "Your Mac was asleep for \(formatAwayTime(interval)). That time wasn't counted."

        let request = UNNotificationRequest(identifier: "sleepResume", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func formatAwayTime(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var remainingTime: TimeInterval {
        guard isTimerEnabled else { return 0 }
        return max(0, targetDuration - elapsedTime)
    }
    
    var progress: Double {
        guard isTimerEnabled, targetDuration > 0 else { return 0 }
        return min(1.0, elapsedTime / targetDuration)
    }
    
    var isTimerComplete: Bool {
        isTimerEnabled && elapsedTime >= targetDuration
    }
    
    func setPresetDuration(_ minutes: Int) {
        targetDuration = TimeInterval(minutes * 60)
        isTimerEnabled = true
    }
    
    func setCustomDuration(hours: Int, minutes: Int, seconds: Int = 0) {
        targetDuration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
        isTimerEnabled = true
    }
    
    func resetTimer() {
        isTimerEnabled = false
    }
    
    func startSession() {
        guard !isRunning else { return }
        guard isTimerEnabled else { return } // Require timer to be set before starting
        guard targetDuration >= 1.0 else { return } // Timer must be at least 1 second
        
        let startTime = Date()
        sessionStartTime = startTime
        elapsedTime = Date().timeIntervalSince(startTime) // Initialize immediately to prevent skip
        currentSession = sessionService.createSession(startTime: startTime)
        isRunning = true
        hasNotifiedCompletion = false
        isCompleted = false

        // Notify MenuBarService of state change
        MenuBarService.shared.onTimerUpdate()

        // Prompts only on the very first session; a no-op once the user has answered
        requestNotificationPermission()
        scheduleNotification()

        startTicking()
    }

    private func startTicking() {
        timerStorage.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.sessionStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)

                // Notify MenuBarService immediately for perfect synchronization
                MenuBarService.shared.onTimerUpdate()

                if self.isTimerComplete && !self.hasNotifiedCompletion {
                    self.hasNotifiedCompletion = true
                    self.onTimerComplete()
                }
            }
        }
    }
    
    func stopSession() {
        // Allow stopping when running OR paused (both have a currentSession)
        guard let session = currentSession, let startTime = sessionStartTime else { return }

        let endTime = Date()
        // While running, elapsedTime is up to 1s stale (last tick), so recompute.
        // While paused, elapsedTime is frozen at the pause point and excludes paused time.
        let rawElapsed = isRunning ? endTime.timeIntervalSince(startTime) : elapsedTime
        // The target is a hard ceiling: completion freezes at the target and a
        // running timer overshoots by up to one tick, so never record past it.
        let finalElapsed = isTimerEnabled ? min(rawElapsed, targetDuration) : rawElapsed
        sessionService.endSession(session, endTime: endTime, elapsed: finalElapsed)
        
        // Update shared storage for widget
        updateSharedStorage()
        
        timerStorage.timer?.invalidate()
        timerStorage.timer = nil
        cancelNotification()
        isRunning = false
        isCompleted = false
        elapsedTime = 0
        currentSession = nil
        sessionStartTime = nil

        // Notify MenuBarService of state change
        MenuBarService.shared.onTimerUpdate()
    }

    func pauseSession() {
        guard isRunning, let startTime = sessionStartTime else { return }
        
        // Update elapsed time one final time for accuracy
        elapsedTime = Date().timeIntervalSince(startTime)
        
        // Stop the timer and cancel notification, but keep state
        timerStorage.timer?.invalidate()
        timerStorage.timer = nil
        cancelNotification()
        isRunning = false
        // Keep elapsedTime, currentSession, and sessionStartTime for resuming
        
        // Notify MenuBarService of state change
        MenuBarService.shared.onTimerUpdate()
    }
    
    func resumeSession() {
        guard !isRunning else { return }
        guard !isCompleted else { return } // A completed timer stays frozen at the target
        guard currentSession != nil, sessionStartTime != nil else { return }
        guard isTimerEnabled else { return }
        
        // Adjust sessionStartTime to account for elapsed time
        // This makes the timer continue from where it paused
        sessionStartTime = Date() - elapsedTime
        
        isRunning = true
        
        // Notify MenuBarService of state change
        MenuBarService.shared.onTimerUpdate()
        
        // Reschedule notification with remaining time
        let remainingTime = max(0, targetDuration - elapsedTime)
        if remainingTime > 0 {
            scheduleNotificationWithTimeInterval(remainingTime)
        }

        // Restart the timer
        startTicking()
    }
    
    private func updateSharedStorage() {
        let today = Date()
        let todayDuration = sessionService.getTotalDuration(for: today)
        SharedStorage.saveTodayDuration(todayDuration)
        
        // Reload widget timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "UptimeWidget")
    }
    
    private func updateSharedStorageForDate(_ date: Date) {
        let duration = sessionService.getTotalDuration(for: date)
        if Calendar.current.isDateInToday(date) {
            SharedStorage.saveTodayDuration(duration)
        }
        
        // Update work days in shared storage
        let calendar = Calendar.current
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: date)),
              let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) else {
            return
        }
        let durations = sessionService.getDailyDurations(from: startOfYear, to: endOfYear)
        SharedStorage.saveDailyDurations(durations)

        // Reload widget timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "UptimeWidget")
    }
    
    private func onTimerComplete() {
        NSSound.beep()
        // Freeze rather than end the session: the user should still see
        // "Timer Complete!" and choose when to Stop, and time must never pass the target.
        timerStorage.timer?.invalidate()
        timerStorage.timer = nil
        elapsedTime = targetDuration
        isRunning = false
        isCompleted = true
        MenuBarService.shared.onTimerUpdate()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func scheduleNotification() {
        scheduleNotificationWithTimeInterval(targetDuration)
    }
    
    private func scheduleNotificationWithTimeInterval(_ timeInterval: TimeInterval) {
        guard timeInterval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "Your work session timer has finished!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "sessionTimer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    nonisolated private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["sessionTimer"])
    }
    
    // Testing methods
    func createTestSession(for date: Date, duration: TimeInterval) {
        sessionService.createTestSession(for: date, duration: duration)
        updateSharedStorageForDate(date)
    }
    
    func deleteSessions(for date: Date) {
        sessionService.deleteSessions(for: date)
        updateSharedStorageForDate(date)
    }
    
    func deleteAllSessions() {
        sessionService.deleteAllSessions()
        SharedStorage.reset()
        WidgetCenter.shared.reloadTimelines(ofKind: "UptimeWidget")
    }
    
    deinit {
        // Timer.invalidate() is thread-safe, so we can safely call it from deinit
        timerStorage.timer?.invalidate()
        cancelNotification()
    }
}

