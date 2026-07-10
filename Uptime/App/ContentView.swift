import SwiftUI
import CoreData
import WidgetKit

enum NavigationDestination: Hashable {
    case timer
    case calendar
    case stats
    case testing
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let sessionViewModel: SessionViewModel
    @State private var calendarViewModel = CalendarViewModel(viewContext: PersistenceController.shared.container.viewContext)
    @State private var selectedDestination: NavigationDestination? = .timer
    @State private var showStoreLoadError = PersistenceController.shared.storeLoadError != nil
    @AppStorage("showTestingMode") private var showTestingMode = false
    
    let menuBarService: MenuBarService
    
    init(sessionViewModel: SessionViewModel, menuBarService: MenuBarService) {
        self.sessionViewModel = sessionViewModel
        self.menuBarService = menuBarService
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedDestination) {
                NavigationLink(value: NavigationDestination.timer) {
                    Label("Timer", systemImage: "timer")
                        .foregroundStyle(.white)
                }
                .tint(.white)
                
                NavigationLink(value: NavigationDestination.calendar) {
                    Label("Calendar", systemImage: "calendar")
                        .foregroundStyle(.white)
                }
                .tint(.white)
                
                NavigationLink(value: NavigationDestination.stats) {
                    Label("Stats", systemImage: "chart.bar")
                        .foregroundStyle(.white)
                }
                .tint(.white)
                
                if showTestingMode {
                    NavigationLink(value: NavigationDestination.testing) {
                        Label("Testing", systemImage: "wrench.and.screwdriver")
                            .foregroundStyle(.white)
                    }
                    .tint(.white)
                }
            }
            .navigationTitle("Uptime")
            .listStyle(.sidebar)
            .foregroundStyle(.white)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        WidgetHelper.reloadWidget()
                    } label: {
                        Label("Refresh Widget", systemImage: "arrow.clockwise")
                            .foregroundStyle(.white)
                    }
                    .help("Refresh widget data")
                }
            }
            .toolbarBackground(Color.black, for: .windowToolbar)
            .scrollContentBackground(.hidden)
            .background(Color.black)
        } detail: {
            Group {
                switch selectedDestination {
                case .timer:
                    SessionView(viewModel: sessionViewModel)
                case .calendar:
                    CalendarView(viewModel: calendarViewModel)
                case .stats:
                    StatsView(viewContext: viewContext)
                case .testing:
                    TestingView(sessionViewModel: sessionViewModel, calendarViewModel: calendarViewModel)
                case .none:
                    SessionView(viewModel: sessionViewModel)
                }
            }
            .background(Color.black)
        }
        .preferredColorScheme(.dark)
        .onChange(of: sessionViewModel.isRunning) { oldValue, newValue in
            if !newValue {
                calendarViewModel.refresh()
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
