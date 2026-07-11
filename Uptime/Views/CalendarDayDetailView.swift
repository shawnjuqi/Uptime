import SwiftUI

struct CalendarDayDetailView: View {
    let date: Date
    let duration: TimeInterval
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(PillButtonStyle())
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                timeDisplay
            }
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    private var timeDisplay: some View {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        return HStack(alignment: .lastTextBaseline, spacing: 4) {
            segment(String(format: "%02d", hours), label: "hr")
            colon
            segment(String(format: "%02d", minutes), label: "min")
            colon
            segment(String(format: "%02d", seconds), label: "sec")
        }
    }
    
    private var colon: some View {
        Text(":")
            .font(.system(size: 64, design: .monospaced))
            .bold()
            .foregroundStyle(.white)
    }
    
    private func segment(_ digits: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            Text(digits)
                .font(.system(size: 64, design: .monospaced))
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
        }
    }
}
