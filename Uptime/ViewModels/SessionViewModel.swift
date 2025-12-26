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
    
    func setCustomDuration(hours: Int, minutes: Int) {
        targetDuration = TimeInterval(hours * 3600 + minutes * 60)
        isTimerEnabled = true
    }
    
    func disableTimer() {
        isTimerEnabled = false
    }
    
    func startSession() {
        guard !isRunning else { return }
        
        let startTime = Date()
        sessionStartTime = startTime
        currentSession = sessionService.createSession(startTime: startTime)
        isRunning = true
        
        // Schedule notification if timer is enabled
        if isTimerEnabled {
            scheduleNotification()
        }
        
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
    
    func pauseSession() {
        stopSession()
    }
    
    func resumeSession() {
        startSession()
    }
    
    private func onTimerComplete() {
        // Timer completed - could add haptic feedback or sound here
        NSSound.beep()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "Your work session timer has finished!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: targetDuration, repeats: false)
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

