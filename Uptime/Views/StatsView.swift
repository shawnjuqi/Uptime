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
                Text(isShowingToday ? "Today" : formatDate(selectedDate))
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
                
                Text(formatTime(duration))
                    .font(.system(size: 72, design: .monospaced))
                    .bold()
                    .foregroundStyle(.white)
                
                Text("studied")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
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
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
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
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
