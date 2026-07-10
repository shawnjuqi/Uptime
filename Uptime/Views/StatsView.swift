import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var duration: TimeInterval = 0
    @State private var isShowingDatePicker = false
    
    private let sessionService: SessionService
    private let calendar = Calendar.current
    
    private var isShowingToday: Bool {
        !isShowingDatePicker || calendar.isDateInToday(selectedDate)
    }
    
    init(viewContext: NSManagedObjectContext) {
        self.sessionService = SessionService(viewContext: viewContext)
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Large Time Display
            VStack(spacing: 16) {
                Text(isShowingToday ? "Time Tracked Today" : formatDate(selectedDate))
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
                
                timeDisplay(duration)
            }
            
            Spacer()
            
            // Date Selection Toggle
            VStack(spacing: 12) {
                if isShowingDatePicker {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.colorScheme, .dark)
                    .onChange(of: selectedDate) { oldValue, newValue in
                        loadDuration()
                    }
                }
                
                Button {
                    withAnimation {
                        if isShowingDatePicker {
                            // Switch back to today
                            isShowingDatePicker = false
                            selectedDate = Date()
                        } else {
                            // Switch to date picker mode
                            isShowingDatePicker = true
                        }
                        loadDuration()
                    }
                } label: {
                    Text(isShowingDatePicker ? "Show Today" : "Select Another Day")
                }
                .buttonStyle(SessionControlButtonStyle(emphasized: true, width: 200))
            }
            .padding(.bottom, 40)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            loadDuration()
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            if isShowingToday {
                loadDuration()
            }
        }
    }
    
    private func loadDuration() {
        let dateToLoad = isShowingDatePicker ? selectedDate : Date()
        duration = sessionService.getTotalDuration(for: dateToLoad)
    }
    
    private func timeDisplay(_ timeInterval: TimeInterval) -> some View {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        return HStack(alignment: .lastTextBaseline, spacing: 4) {
            timeSegment(String(format: "%02d", hours), label: "hr")
            colonView
            timeSegment(String(format: "%02d", minutes), label: "min")
            colonView
            timeSegment(String(format: "%02d", seconds), label: "sec")
        }
    }
    
    private var colonView: some View {
        Text(":")
            .font(.system(size: 64, design: .monospaced))
            .bold()
            .foregroundStyle(.white)
    }
    
    private func timeSegment(_ digits: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            Text(digits)
                .font(.system(size: 64, design: .monospaced))
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
