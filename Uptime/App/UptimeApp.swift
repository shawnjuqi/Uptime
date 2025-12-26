import SwiftUI

@main
struct UptimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @AppStorage("showTestingMode") private var showTestingMode = false

    var body: some Scene {
        WindowGroup {
            ContentView(sessionViewModel: SessionViewModel.shared, menuBarService: MenuBarService.shared)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .commands {
            CommandMenu("Test") {
                Button(showTestingMode ? "Hide Testing Mode" : "Show Testing Mode") {
                    showTestingMode.toggle()
                }
                .keyboardShortcut("t", modifiers: [.option, .command])
            }
        }
    }
}
