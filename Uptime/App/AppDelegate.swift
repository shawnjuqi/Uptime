import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running when window is closed (for background timer functionality)
        // This only affects closing windows, not explicit quit (Cmd+Q or Dock quit)
        // When user explicitly quits, the app will terminate normally
        return false
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Allow termination when user explicitly quits (Cmd+Q, Dock quit, etc.)
        // Cleanup will happen automatically via deinit methods
        return .terminateNow
    }
}

