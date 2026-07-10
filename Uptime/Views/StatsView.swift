import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var duration: TimeInterval = 0
    
    private let sessionService: SessionService
    
    init(viewContext: NSManagedObjectContext) {
        self.sessionService = SessionService(viewContext: viewContext)
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Time Tracked Today")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
                
                timeDisplay(duration)
            }
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            loadDuration()
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            loadDuration()
        }
    }
    
    private func loadDuration() {
        duration = sessionService.getTotalDuration(for: Date())
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
}
