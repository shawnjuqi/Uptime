import SwiftUI

struct TestingView: View {
    @Bindable var sessionViewModel: SessionViewModel
    @Bindable var calendarViewModel: CalendarViewModel
    
    @State private var selectedDate = Date()
    @State private var testDurationHours: Int = 1
    @State private var testDurationMinutes: Int = 0
    @State private var showDeleteConfirmation = false
    @State private var showDeleteAllConfirmation = false
    
    private var testDuration: TimeInterval {
        TimeInterval(testDurationHours * 3600 + testDurationMinutes * 60)
    }
    
    var body: some View {
        Form {
            Section("Test Session Creation") {
                DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                
                HStack {
                    Text("Duration:")
                    Spacer()
                    Stepper(value: $testDurationHours, in: 0...23) {
                        Text("\(testDurationHours)h")
                    }
                    Stepper(value: $testDurationMinutes, in: 0...59, step: 15) {
                        Text("\(testDurationMinutes)m")
                    }
                }
                
                Button {
                    sessionViewModel.createTestSession(for: selectedDate, duration: testDuration)
                    calendarViewModel.refresh()
                } label: {
                    Label("Create Test Session", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            
            Section("Session Management") {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Sessions for Selected Date", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                
                Button {
                    showDeleteAllConfirmation = true
                } label: {
                    Label("Delete All Sessions", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
            }
            
            Section("Info") {
                Text("Selected Date: \(selectedDate, format: .dateTime.month().day().year())")
                Text("Test Duration: \(formatDuration(testDuration))")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Testing Mode")
        .alert("Delete Sessions", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                sessionViewModel.deleteSessions(for: selectedDate)
                calendarViewModel.refresh()
            }
        } message: {
            Text("Are you sure you want to delete all sessions for \(selectedDate, format: .dateTime.month().day().year())?")
        }
        .alert("Delete All Sessions", isPresented: $showDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                sessionViewModel.deleteAllSessions()
                calendarViewModel.refresh()
            }
        } message: {
            Text("Are you sure you want to delete ALL sessions? This cannot be undone.")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

