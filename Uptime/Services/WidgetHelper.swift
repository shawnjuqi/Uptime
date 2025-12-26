import Foundation
import AppKit
import WidgetKit

struct WidgetHelper {
    /// Reloads the widget timeline immediately
    static func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "UptimeWidget")
    }
    
    /// Opens System Settings to the widget configuration page
    /// Note: This opens general Desktop & Dock settings, not directly to widgets
    static func openWidgetSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.desktopscreeneffect") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Opens System Settings to Extensions (where widgets are managed)
    static func openExtensionsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.extensions") {
            NSWorkspace.shared.open(url)
        }
    }
}

