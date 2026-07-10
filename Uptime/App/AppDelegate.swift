import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }

    // Show notification banners even while the app is frontmost
    // (macOS suppresses them in the foreground by default)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner])
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running when window is closed (for background timer functionality)
        // This only affects closing windows, not explicit quit (Cmd+Q or Dock quit)
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        SessionViewModel.shared.stopSession()
    }
}

