import SwiftUI

@main
struct UptimeApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("showTestingMode") private var showTestingMode = false
    @State private var menuBarService = MenuBarService()

    var body: some Scene {
        WindowGroup {
            ContentView(menuBarService: menuBarService)
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
