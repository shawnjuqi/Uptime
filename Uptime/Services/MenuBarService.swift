import AppKit
import SwiftUI
import Observation

// Nonisolated storage for timer to allow cleanup in deinit
final class MenuBarTimerStorage: @unchecked Sendable {
    var timer: Timer?
}

@MainActor
@Observable
final class MenuBarService {
    private var statusItem: NSStatusItem?
    private let timerStorage = MenuBarTimerStorage()
    weak var sessionViewModel: SessionViewModel?
    
    func setup(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard statusItem?.button != nil else { return }
        
        // Set initial appearance
        updateMenuBarDisplay()
        
        // Create menu
        let menu = NSMenu()
        let titleItem = NSMenuItem(title: "Uptime", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        let openItem = NSMenuItem(title: "Open Uptime", action: #selector(openApp), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        
        // Start timer to update display
        startUpdateTimer()
    }
    
    func updateMenuBarDisplay() {
        guard let button = statusItem?.button,
              let sessionViewModel = sessionViewModel else { return }
        
        if sessionViewModel.isRunning {
            let timeString = formatTime(sessionViewModel.elapsedTime)
            // Use timer symbol with time text
            let image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Timer running")
            image?.isTemplate = true
            button.image = image
            button.title = timeString
            button.imagePosition = .imageLeading
            button.appearsDisabled = false
        } else {
            // Use clock symbol when not running
            let image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Uptime")
            image?.isTemplate = true
            button.image = image
            button.title = ""
            button.appearsDisabled = false
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            let hoursString = hours < 10 ? "0\(hours)" : "\(hours)"
            let minutesString = minutes < 10 ? "0\(minutes)" : "\(minutes)"
            let secondsString = seconds < 10 ? "0\(seconds)" : "\(seconds)"
            return "\(hoursString):\(minutesString):\(secondsString)"
        } else {
            let minutesString = minutes < 10 ? "0\(minutes)" : "\(minutes)"
            let secondsString = seconds < 10 ? "0\(seconds)" : "\(seconds)"
            return "\(minutesString):\(secondsString)"
        }
    }
    
    private func startUpdateTimer() {
        timerStorage.timer?.invalidate()
        timerStorage.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMenuBarDisplay()
            }
        }
    }
    
    @objc private func openApp() {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func cleanup() {
        timerStorage.timer?.invalidate()
        timerStorage.timer = nil
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }
    
    deinit {
        // Timer.invalidate() is thread-safe, so we can safely call it from deinit
        // Note: deinit is always nonisolated, so we can access timerStorage.timer
        // Note: statusItem cleanup requires main actor, so it will be cleaned up
        // when cleanup() is called explicitly or when the app terminates
        timerStorage.timer?.invalidate()
    }
}

