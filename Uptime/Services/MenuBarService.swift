import AppKit
import SwiftUI
import Observation

@MainActor
@Observable
final class MenuBarService {
    // Singleton instance to prevent deallocation during app termination
    static let shared = MenuBarService()
    
    private var statusItem: NSStatusItem?
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
    }
    
    func updateMenuBarDisplay() {
        guard let button = statusItem?.button,
              let sessionViewModel = sessionViewModel else { return }
        
        if sessionViewModel.isRunning {
            let timeString = formatTime(sessionViewModel.remainingTime)
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
    
    // Called by SessionViewModel when timer updates to ensure perfect sync
    func onTimerUpdate() {
        updateMenuBarDisplay()
    }
    
    @objc private func openApp() {
        NSApp.activate(ignoringOtherApps: true)
    }
}

