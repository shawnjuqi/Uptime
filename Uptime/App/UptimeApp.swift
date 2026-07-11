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
                .background(Color.black)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 720, height: 620)
        .windowResizability(.contentMinSize)
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
