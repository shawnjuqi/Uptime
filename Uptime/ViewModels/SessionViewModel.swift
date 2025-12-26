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
    
    private let sessionService: SessionService
    private let timerStorage = TimerStorage()
    private var sessionStartTime: Date?
    
    init(viewContext: NSManagedObjectContext) {
        self.sessionService = SessionService(viewContext: viewContext)
        requestNotificationPermission()
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
        
        // Schedule notification
        scheduleNotification()
        
        timerStorage.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.sessionStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
                
                // Check if timer completed
                if self.isTimerComplete {
                    self.onTimerComplete()
                }
            }
        }
    }
    
    func stopSession() {
        guard isRunning, let session = currentSession, sessionStartTime != nil else { return }
        
        let endTime = Date()
        sessionService.endSession(session, endTime: endTime)
        
        // Update shared storage for widget
        updateSharedStorage()
        
        timerStorage.timer?.invalidate()
        timerStorage.timer = nil
        cancelNotification()
        isRunning = false
        elapsedTime = 0
        currentSession = nil
        sessionStartTime = nil
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
    }
    
    func resumeSession() {
        guard !isRunning else { return }
        guard currentSession != nil, sessionStartTime != nil else { return }
        guard isTimerEnabled else { return }
        
        // Adjust sessionStartTime to account for elapsed time
        // This makes the timer continue from where it paused
        sessionStartTime = Date() - elapsedTime
        
        isRunning = true
        
        // Reschedule notification with remaining time
        let remainingTime = max(0, targetDuration - elapsedTime)
        if remainingTime > 0 {
            scheduleNotificationWithTimeInterval(remainingTime)
        }
        
        // Restart the timer
        timerStorage.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.sessionStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
                
                // Check if timer completed
                if self.isTimerComplete {
                    self.onTimerComplete()
                }
            }
        }
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
        let sessions = sessionService.getSessions(from: startOfYear, to: endOfYear)
        let workDays = Set(sessions.compactMap { $0.date })
        SharedStorage.saveWorkDays(Array(workDays))
        
        // Reload widget timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "UptimeWidget")
    }
    
    private func onTimerComplete() {
        // Timer completed - could add haptic feedback or sound here
        NSSound.beep()
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

