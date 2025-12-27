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
            Section {
                DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .foregroundStyle(.white)
                
                HStack {
                    Text("Duration:")
                        .foregroundStyle(.white)
                    Spacer()
                    Stepper(value: $testDurationHours, in: 0...23) {
                        Text("\(testDurationHours)h")
                            .foregroundStyle(.white)
                    }
                    .tint(.white)
                    Stepper(value: $testDurationMinutes, in: 0...59, step: 15) {
                        Text("\(testDurationMinutes)m")
                            .foregroundStyle(.white)
                    }
                    .tint(.white)
                }
                
                Button {
                    sessionViewModel.createTestSession(for: selectedDate, duration: testDuration)
                    calendarViewModel.refresh()
                } label: {
                    Label("Create Test Session", systemImage: "plus.circle.fill")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
            } header: {
                Text("Test Session Creation")
                    .foregroundStyle(.white)
            }
            
            Section {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Sessions for Selected Date", systemImage: "trash")
                        .foregroundStyle(.white)
                }
                
                Button {
                    showDeleteAllConfirmation = true
                } label: {
                    Label("Delete All Sessions", systemImage: "trash.fill")
                        .foregroundStyle(.white)
                }
            } header: {
                Text("Session Management")
                    .foregroundStyle(.white)
            }
            
            Section {
                Button {
                    SharedStorage.reset()
                    WidgetHelper.reloadWidget()
                    calendarViewModel.refresh()
                } label: {
                    Label("Reset Widget Data", systemImage: "trash")
                        .foregroundStyle(.white)
                }
            } header: {
                Text("Widget Management")
                    .foregroundStyle(.white)
            }
            
            Section {
                Text("Selected Date: \(selectedDate, format: .dateTime.month().day().year())")
                    .foregroundStyle(.white)
                Text("Test Duration: \(formatDuration(testDuration))")
                    .foregroundStyle(.white)
            } header: {
                Text("Info")
                    .foregroundStyle(.white)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .foregroundStyle(.white)
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

