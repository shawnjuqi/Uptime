import SwiftUI

struct CalendarDayDetailView: View {
    let date: Date
    let duration: TimeInterval
    let onBack: () -> Void

    var body: some View {
        // Same centered [big display + caption below] layout as the timer
        // page, so the digits sit in the same spot.
        VStack(spacing: 16) {
            timeDisplay

            Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                .font(.title3)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .overlay(alignment: .topLeading) {
            Button(action: onBack) {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(PillButtonStyle())
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
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

    // Matches TimerDisplayView's segment styling exactly.
    private func segment(_ digits: String, label: String) -> some View {
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
