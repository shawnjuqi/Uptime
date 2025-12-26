import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running when window is closed (for background timer functionality)
        // This only affects closing windows, not explicit quit (Cmd+Q or Dock quit)
        return false
    }
}

