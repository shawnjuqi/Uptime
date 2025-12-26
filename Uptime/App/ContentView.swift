import SwiftUI
import CoreData
import WidgetKit

enum NavigationDestination: Hashable {
    case timer
    case calendar
    case testing
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var sessionViewModel = SessionViewModel(viewContext: PersistenceController.shared.container.viewContext)
    @State private var calendarViewModel = CalendarViewModel(viewContext: PersistenceController.shared.container.viewContext)
    @State private var selectedDestination: NavigationDestination? = .timer
    @AppStorage("showTestingMode") private var showTestingMode = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedDestination) {
                NavigationLink(value: NavigationDestination.timer) {
                    Label("Timer", systemImage: "timer")
                }
                
                NavigationLink(value: NavigationDestination.calendar) {
                    Label("Calendar", systemImage: "calendar")
                }
                
                if showTestingMode {
                    NavigationLink(value: NavigationDestination.testing) {
                        Label("Testing", systemImage: "wrench.and.screwdriver")
                    }
                }
            }
            .navigationTitle("Uptime")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        WidgetHelper.reloadWidget()
                    } label: {
                        Label("Refresh Widget", systemImage: "arrow.clockwise")
                    }
                    .help("Refresh widget data")
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        SharedStorage.reset()
                        WidgetHelper.reloadWidget()
                        calendarViewModel.refresh()
                    } label: {
                        Label("Reset Widget Data", systemImage: "trash")
                    }
                    .help("Clear all widget data")
                }
            }
        } detail: {
            Group {
                switch selectedDestination {
                case .timer:
                    SessionView(viewModel: sessionViewModel)
                case .calendar:
                    CalendarView(viewModel: calendarViewModel)
                case .testing:
                    TestingView(sessionViewModel: sessionViewModel, calendarViewModel: calendarViewModel)
                case .none:
                    SessionView(viewModel: sessionViewModel)
                }
            }
        }
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
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
