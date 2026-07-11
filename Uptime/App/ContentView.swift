import SwiftUI

enum NavigationDestination: Hashable {
    case timer
    case stats
    case calendar
    case testing
}

struct ContentView: View {
    let sessionViewModel: SessionViewModel
    @State private var calendarViewModel = CalendarViewModel(viewContext: PersistenceController.shared.container.viewContext)
    @State private var statsViewModel = StatsViewModel(viewContext: PersistenceController.shared.container.viewContext)
    @State private var selectedDestination: NavigationDestination = .timer
    @State private var showStoreLoadError = PersistenceController.shared.storeLoadError != nil
    @AppStorage("showTestingMode") private var showTestingMode = false

    let menuBarService: MenuBarService

    init(sessionViewModel: SessionViewModel, menuBarService: MenuBarService) {
        self.sessionViewModel = sessionViewModel
        self.menuBarService = menuBarService
    }

    var body: some View {
        Group {
            switch selectedDestination {
            case .timer:
                SessionView(viewModel: sessionViewModel)
            case .stats:
                StatsView(viewModel: statsViewModel)
            case .calendar:
                CalendarView(viewModel: calendarViewModel)
            case .testing:
                TestingView(sessionViewModel: sessionViewModel, calendarViewModel: calendarViewModel)
            }
        }
        // Minimum floor so the window can't shrink below what Stats / the year
        // view need; opening size is left to the system default (unchanged).
        .frame(minWidth: 660, maxWidth: .infinity, minHeight: 560, maxHeight: .infinity)
        .background(Color.black)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Section", selection: $selectedDestination) {
                    Text("Timer").tag(NavigationDestination.timer)
                    Text("Stats").tag(NavigationDestination.stats)
                    Text("Calendar").tag(NavigationDestination.calendar)
                    if showTestingMode {
                        Text("Testing").tag(NavigationDestination.testing)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.vertical, 6)
            }
        }
        .toolbarBackground(Color.black, for: .windowToolbar)
        .background {
            // Invisible buttons keep cmd-1/2/3/4 switching between sections
            VStack {
                Button("Timer") { selectedDestination = .timer }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Stats") { selectedDestination = .stats }
                    .keyboardShortcut("2", modifiers: .command)
                Button("Calendar") { selectedDestination = .calendar }
                    .keyboardShortcut("3", modifiers: .command)
                if showTestingMode {
                    Button("Testing") { selectedDestination = .testing }
                        .keyboardShortcut("4", modifiers: .command)
                }
            }
            .frame(width: 0, height: 0)
            .hidden()
        }
        .onChange(of: sessionViewModel.isRunning) { oldValue, newValue in
            if !newValue {
                calendarViewModel.refresh()
                statsViewModel.refresh()
            }
        }
        .onChange(of: showTestingMode) { oldValue, newValue in
            if newValue {
                selectedDestination = .testing
            } else if selectedDestination == .testing {
                selectedDestination = .timer
            }
        }
        .onAppear {
            menuBarService.setup(sessionViewModel: sessionViewModel)
        }
        .alert("Session History Unavailable", isPresented: $showStoreLoadError) {
            Button("OK") { }
        } message: {
            Text("Your saved session data couldn't be opened. You can keep using Uptime, but sessions from this launch won't be saved. Try restarting the app or freeing up disk space.")
        }
    }
}
