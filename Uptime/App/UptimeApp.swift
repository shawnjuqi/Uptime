import SwiftUI

@main
struct UptimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @AppStorage("showTestingMode") private var showTestingMode = false
    @State private var menuBarService = MenuBarService()
    // Store SessionViewModel at app level to persist across window lifecycle
    @State private var sessionViewModel = SessionViewModel(viewContext: PersistenceController.shared.container.viewContext)

    var body: some Scene {
        WindowGroup {
            ContentView(sessionViewModel: sessionViewModel, menuBarService: menuBarService)
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
